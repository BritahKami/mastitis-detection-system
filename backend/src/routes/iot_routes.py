from fastapi import APIRouter, Depends, status
from src.services.session_service import session_manager
from sqlalchemy.orm import Session
from src.config.database import get_db
from src.models.schemas import (
    IoTSensorReadingRequest,
    IoTProcessingResponse
)
from src.controllers.iot_controller import IoTController

router = APIRouter(prefix="/iot", tags=["IoT ESP32 Telemetry & ML Ingestion"])


@router.post(
    "/sensor-reading",
    response_model=IoTProcessingResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Step 3 & 4: Ingest ESP32 telemetry, run ML model, update cow, create alert"
)
def ingest_sensor_reading(
    payload: IoTSensorReadingRequest,
    db: Session = Depends(get_db)
):
    """
    Steps 3, 4, 5 of Asynchronous Testing Workflow:
    1. Checks for an active 3-minute test session lock set by 'Select cow to test'.
    2. Ingests milk telemetry from the physical ESP32 sensing module.
    3. Saves readings into Sensor_Reading bound to the active cow_id.
    4. Runs Random Forest ML inference: [temperature, pH, electrical_conductivity].
    5. Saves output into Detection_Result table.
    6. Updates Cow health_status to 'At Risk' (if Present) or 'Healthy' (if Absent).
    7. Dispatches an unread Alert entry if Mastitis is detected.
    8. Clears the session lock.
    """
    # 1. Retrieve active cow_id from 3-minute session lock (returns None if expired or no lock)
    active_cow_id = session_manager.get_active_cow_id()

    # 2. Delegate to controller with active_cow_id binding
    response = IoTController.process_sensor_reading(
        payload=payload,
        db=db,
        active_cow_id=active_cow_id
    )

    # 3. Clear session lock after successful processing
    if active_cow_id:
        session_manager.clear_session()

    return response
