from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from src.config.database import get_db
from src.middleware.auth_middleware import get_current_farmer
from src.models.db_models import Farmer
from src.models.schemas import (
    TestInitiationResponse,
    TestPollPendingResponse,
    DetectionResultResponse
)
from src.controllers.test_controller import TestController

router = APIRouter(prefix="/cows", tags=["Diagnostic Testing Workflow"])


@router.post(
    "/{cow_id}/initiate-test",
    response_model=TestInitiationResponse,
    status_code=status.HTTP_200_OK,
    summary="Step 1: Initiate diagnostic test from mobile app"
)
def initiate_test(
    cow_id: int,
    current_farmer: Farmer = Depends(get_current_farmer),
    db: Session = Depends(get_db)
):
    """
    Step 1 of Asynchronous Testing Workflow:
    Updates cow health_status to 'Pending' in the database, notifying the system
    that hardware telemetry is awaited from the IoT ESP32 sensing module.
    """
    return TestController.initiate_test(cow_id, current_farmer, db)


@router.get(
    "/{cow_id}/latest-result",
    response_model=DetectionResultResponse,
    responses={
        202: {
            "model": TestPollPendingResponse,
            "description": "Hardware telemetry still pending from IoT ESP32 module."
        },
        200: {
            "model": DetectionResultResponse,
            "description": "Inference complete. Combined sensor readings and prediction returned."
        }
    },
    summary="Step 2 & Step 6: Short polling endpoint for mobile client"
)
def poll_latest_result(
    cow_id: int,
    current_farmer: Farmer = Depends(get_current_farmer),
    db: Session = Depends(get_db)
):
    """
    Steps 2 & 6 of Asynchronous Testing Workflow:
    The mobile app polls this endpoint every 2 seconds.
    - Returns HTTP 202 Accepted while health_status is 'Pending'.
    - Returns HTTP 200 OK once the IoT reading and ML prediction are stored,
      providing combined sensor values and mastitis prediction to resolve polling.
    """
    return TestController.poll_latest_result(cow_id, current_farmer, db)
