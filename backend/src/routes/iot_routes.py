from typing import Union
from fastapi import APIRouter, Depends, status
from fastapi.responses import JSONResponse
from sqlalchemy.orm import Session
from src.config.database import get_db
from src.models.schemas import (
    IoTSensorReadingRequest,
    IoTProcessingResponse,
    IoTIgnoredResponse
)
from src.controllers.iot_controller import IoTController
from src.services.session_service import session_manager

router = APIRouter(prefix="/iot", tags=["IoT ESP32 Telemetry & ML Ingestion"])


@router.post(
    "/sensor-reading",
    response_model=Union[IoTProcessingResponse, IoTIgnoredResponse],
    status_code=status.HTTP_200_OK,
    responses={
        200: {
            "description": "Telemetry processed or ignored when idle.",
        },
        201: {
            "model": IoTProcessingResponse,
            "description": "Telemetry processed and saved to database.",
        }
    },
    summary="Step 3 & 4: Ingest ESP32 telemetry, run ML model, update cow, create alert"
)
def ingest_sensor_reading(
    payload: IoTSensorReadingRequest,
    db: Session = Depends(get_db)
):
    """
    Steps 3, 4, 5 of Asynchronous Testing Workflow:
    1. Checks for an active 3-minute test session lock set by 'Select cow to test'.
    2. If NO active session exists: Returns 200 OK with {"status": "ignored", "message": "No active test session"}.
    3. If active session exists:
       - Ingests milk telemetry from ESP32.
       - Saves readings into Sensor_Reading bound to target_cow_id.
       - Runs Random Forest ML inference.
       - Saves output into Detection_Result table.
       - Updates Cow health_status ('At Risk' or 'Healthy').
       - Updates latest reading in session_manager during the 3-minute session window.
       - Does NOT clear the session prematurely, allowing ongoing telemetry during test.
    """
    # 1. Retrieve active cow_id from 5-reading bounded session lock
    active_cow_id = session_manager.get_active_cow_id()

    # 2. If NO active session exists (idle ESP32 telemetry or 5 readings completed), return 200 OK ignored
    if not active_cow_id:
        return JSONResponse(
            status_code=status.HTTP_200_OK,
            content={
                "status": "ignored",
                "message": "No active test session"
            }
        )

    target_cow_id = active_cow_id

    # 3. Delegate to controller using the resolved target_cow_id
    response = IoTController.process_sensor_reading(
        payload=payload,
        db=db,
        active_cow_id=target_cow_id
    )

    # 4. Record valid reading, update latest telemetry, and increment session counter.
    # Once the 5th valid reading is processed, session_manager automatically clears/closes
    # the active test session lock so trailing 5-second ESP32 packets are ignored.
    session_manager.record_reading({
        "reading_id": response.reading_id,
        "result_id": response.result_id,
        "temperature": payload.temperature,
        "pH": payload.pH,
        "electrical_conductivity": payload.electrical_conductivity,
        "prediction": response.prediction,
        "cow_health_status": response.cow_health_status
    })

    return response
