from fastapi import APIRouter, Depends, status
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
    Ingests milk telemetry from the physical ESP32 sensing module:
    1. Saves readings into the Sensor_Reading table.
    2. Runs in-memory Random Forest ML inference in exact feature order:
       [temperature, pH, electrical_conductivity].
    3. Saves output into Detection_Result table linked to reading_id.
    4. Updates Cow health_status to 'At Risk' (if Mastitis Present) or 'Healthy' (if Absent).
    5. Dispatches an unread Alert entry if Mastitis is detected.
    """
    return IoTController.process_sensor_reading(payload, db)
