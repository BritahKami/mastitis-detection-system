from datetime import datetime
from zoneinfo import ZoneInfo
from typing import Union
from sqlalchemy.orm import Session
from sqlalchemy import text
from fastapi import HTTPException, status
from fastapi.responses import JSONResponse
from src.models.db_models import Farmer, Cow
from src.models.schemas import (
    TestInitiationResponse,
    TestPollPendingResponse,
    DetectionResultResponse,
    LatestResultPayload
)
from src.services.session_service import session_manager

EAT_TZ = ZoneInfo("Africa/Nairobi")


class TestController:
    """
    Controller managing the asynchronous diagnostic testing lifecycle:
    - Step 1: Mobile App triggers test initiation -> transitions Cow to 'Pending' & locks session
    - Step 2 & 6: Mobile App short polls -> returns 202 Accepted while Pending, 200 OK once resolved
    """

    @staticmethod
    def initiate_test(
        cow_id: int,
        current_farmer: Farmer,
        db: Session
    ) -> TestInitiationResponse:
        """
        Step 1: Mobile application initiates a diagnostic test for a specific cow.
        Transitions the cow's health_status to 'Pending' and sets the 3-minute IoT session lock.
        """
        cow = (
            db.query(Cow)
            .filter(Cow.cow_id == cow_id, Cow.farmer_id == current_farmer.farmer_id)
            .first()
        )
        if not cow:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Cow with ID {cow_id} not found in your registered herd."
            )

        # Set status to Pending
        cow.health_status = "Pending"
        db.commit()
        db.refresh(cow)

        # Start 3-minute session lock for ESP32 telemetry ingestion
        session_data = session_manager.start_session(
            cow_id=cow.cow_id,
            cow_tag=cow.cow_tag
        )

        now = datetime.now(EAT_TZ)
        return TestInitiationResponse(
            message=f"Active test session initialized for {cow.cow_tag}. Awaiting IoT sensor telemetry.",
            cow_id=cow.cow_id,
            health_status="Pending",
            timestamp=now,
            status="testing",
            expires_at=session_data["expires_at"]
        )

    @staticmethod
    def poll_latest_result(
        cow_id: int,
        current_farmer: Farmer,
        db: Session
    ) -> Union[JSONResponse, DetectionResultResponse]:
        """
        Step 2 & Step 6: Mobile App polls every 2 seconds.
        - While cow.health_status == 'Pending': returns HTTP 202 Accepted.
        - When completed: returns HTTP 200 OK with combined Sensor_Reading + Detection_Result,
          resolving the polling cycle.
        """
        cow = (
            db.query(Cow)
            .filter(Cow.cow_id == cow_id, Cow.farmer_id == current_farmer.farmer_id)
            .first()
        )
        if not cow:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Cow with ID {cow_id} not found."
            )

        # Step 2: Still Pending -> Return HTTP 202 Accepted
        if cow.health_status == "Pending":
            pending_payload = TestPollPendingResponse(
                status="Pending",
                cow_id=cow_id,
                message="Sensor data acquisition in progress. Please continue polling."
            )
            return JSONResponse(
                status_code=status.HTTP_202_ACCEPTED,
                content=pending_payload.model_dump()
            )

        # Step 6: Processed -> Fetch latest Detection_Result joined with Sensor_Reading and Cow
        query = text("""
            SELECT 
                dr.result_id,
                sr.reading_id,
                dr.cow_id,
                c.cow_tag,
                sr.temperature,
                sr.pH,
                sr.electrical_conductivity,
                sr.reading_time,
                dr.prediction,
                dr.confidence_score,
                dr.detection_time,
                c.health_status
            FROM Detection_Result dr
            JOIN Sensor_Reading sr ON dr.reading_id = sr.reading_id
            JOIN Cow c ON dr.cow_id = c.cow_id
            WHERE dr.cow_id = :cow_id
            ORDER BY dr.result_id DESC, dr.detection_time DESC
            LIMIT 1
        """)

        latest_record = db.execute(query, {"cow_id": cow_id}).mappings().first()

        if not latest_record:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"No diagnostic test results recorded for Cow {cow.cow_tag}."
            )

        temp_val = float(latest_record["temperature"])
        ph_val = float(latest_record["pH"])
        cond_val = float(latest_record["electrical_conductivity"])
        pred_val = str(latest_record["prediction"])
        health_val = str(latest_record["health_status"])
        conf_val = float(latest_record["confidence_score"]) if latest_record["confidence_score"] is not None else None

        return DetectionResultResponse(
            status="Completed",
            cow_id=cow.cow_id,
            cow_tag=latest_record["cow_tag"],
            health_status=health_val,
            diagnostic_status=pred_val,
            prediction=pred_val,
            confidence_score=conf_val,
            temperature=temp_val,
            pH=ph_val,
            electrical_conductivity=cond_val,
            reading_id=latest_record["reading_id"],
            result_id=latest_record["result_id"],
            reading_time=latest_record["reading_time"],
            detection_time=latest_record["detection_time"],
            result=LatestResultPayload(
                result_id=latest_record["result_id"],
                reading_id=latest_record["reading_id"],
                temperature=temp_val,
                pH=ph_val,
                electrical_conductivity=cond_val,
                reading_time=latest_record["reading_time"],
                prediction=pred_val,
                confidence_score=conf_val,
                detection_time=latest_record["detection_time"]
            )
        )
