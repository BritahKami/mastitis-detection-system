from datetime import datetime
from zoneinfo import ZoneInfo
from typing import Optional
from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from src.models.db_models import Cow, SensorReading, DetectionResult, Alert
from src.models.schemas import IoTSensorReadingRequest, IoTProcessingResponse
from src.services.ml_service import ml_service

EAT_TZ = ZoneInfo("Africa/Nairobi")


class IoTController:
    """
    Controller handling ESP32 IoT telemetry ingestion, Machine Learning inference,
    database persistence, cow health status transition, and automated alert dispatch.
    """

    @staticmethod
    def process_sensor_reading(
        payload: IoTSensorReadingRequest,
        db: Session,
        active_cow_id: Optional[int] = None  # Accepts active 3-minute session lock cow_id
    ) -> IoTProcessingResponse:
        """
        Steps 3, 4, 5 of the asynchronous testing workflow:
        1. Binds incoming telemetry to active 3-minute session lock cow_id (if present).
        2. Ingests raw telemetry (temperature, pH, electrical_conductivity).
        3. Persists telemetry in Sensor_Reading table.
        4. Invokes in-memory Random Forest model with strict feature order.
        5. Persists prediction in Detection_Result table linked directly to reading_id.
        6. Updates Cow health_status to 'At Risk' or 'Healthy' and updates last_tested.
        7. Automatically dispatches an Alert if Mastitis Present.
        8. Commits all state changes atomically.
        """
        # Determine target cow_id (Active 3-minute session lock takes priority over payload)
        target_cow_id = active_cow_id or payload.cow_id

        # 1. Verify cow exists in database
        cow = db.query(Cow).filter(Cow.cow_id == target_cow_id).first()
        if not cow:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Cow with ID {target_cow_id} is not registered in the system."
            )

        eat_now = datetime.now(EAT_TZ)

        try:
            # 2. Insert into Sensor_Reading table bound to target_cow_id
            sensor_reading = SensorReading(
                cow_id=target_cow_id,
                temperature=payload.temperature,
                pH=payload.pH,
                electrical_conductivity=payload.electrical_conductivity,
                reading_time=eat_now
            )
            db.add(sensor_reading)
            db.flush()  # Flushes to obtain auto-generated reading_id

            # 3. ML Inference using exact feature ordering
            prediction_label, confidence_score = ml_service.predict(
                temperature=payload.temperature,
                ph=payload.pH,
                electrical_conductivity=payload.electrical_conductivity
            )

            # 4. Insert into Detection_Result table bound to target_cow_id
            detection_result = DetectionResult(
                cow_id=target_cow_id,
                reading_id=sensor_reading.reading_id,
                prediction=prediction_label,
                confidence_score=confidence_score,
                detection_time=eat_now
            )
            db.add(detection_result)
            db.flush()  # Flushes to obtain auto-generated result_id

            # 5. Update Cow health status and last_tested timestamp
            new_health_status = "At Risk" if prediction_label == "Mastitis Present" else "Healthy"
            cow.health_status = new_health_status
            cow.last_tested = eat_now

            # 6. Generate Alert if Mastitis is detected and no unread alert already exists for this cow
            if prediction_label == "Mastitis Present" or new_health_status == "At Risk":
                # Deduplication safeguard: check if an unread alert already exists for target cow_id
                existing_unread = (
                    db.query(Alert)
                    .join(DetectionResult, Alert.result_id == DetectionResult.result_id)
                    .filter(
                        DetectionResult.cow_id == target_cow_id,
                        Alert.status == "Unread"
                    )
                    .first()
                )
                if not existing_unread:
                    alert_message = (
                        f"{cow.cow_tag}: Mastitis Present - "
                        f"Temp: {payload.temperature:.1f}°C, pH: {payload.pH:.2f}, "
                        f"Cond: {payload.electrical_conductivity:.2f} mS/cm."
                    )
                    alert = Alert(
                        result_id=detection_result.result_id,
                        farmer_id=cow.farmer_id,
                        message=alert_message,
                        status="Unread",
                        send_time=eat_now
                    )
                    db.add(alert)
                    db.flush()

            # 7. Atomically commit the entire transaction
            db.commit()

            return IoTProcessingResponse(
                status="Processed",
                reading_id=sensor_reading.reading_id,
                result_id=detection_result.result_id,
                prediction=prediction_label,
                confidence_score=confidence_score,
                cow_health_status=new_health_status
            )

        except Exception as e:
            db.rollback()
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"IoT telemetry processing and ML inference failed: {str(e)}"
            )