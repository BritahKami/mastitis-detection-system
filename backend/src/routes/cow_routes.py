from typing import List
from fastapi import APIRouter, Depends, status, HTTPException
from sqlalchemy.orm import Session
from src.config.database import get_db
from src.middleware.auth_middleware import get_current_farmer
from src.models.db_models import Farmer
from src.models.schemas import (
    CowRegisterRequest,
    CowResponse,
    CowDetailResponse
)
from src.controllers.cow_controller import CowController
from src.services.session_service import session_manager

router = APIRouter(prefix="/cows", tags=["Cow Management"])


@router.post(
    "",
    response_model=CowResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Register a new cow in herd"
)
def register_cow(
    payload: CowRegisterRequest,
    current_farmer: Farmer = Depends(get_current_farmer),
    db: Session = Depends(get_db)
):
    """
    Registers a new cow for the authenticated farmer.
    Defaults health_status to 'Pending'.
    """
    return CowController.register_cow(payload, current_farmer, db)


@router.get(
    "",
    response_model=List[CowResponse],
    status_code=status.HTTP_200_OK,
    summary="List all cows for authenticated farmer"
)
def list_cows(
    current_farmer: Farmer = Depends(get_current_farmer),
    db: Session = Depends(get_db)
):
    """
    Retrieves all dairy cows associated with the logged-in farmer account.
    """
    return CowController.get_all_cows(current_farmer, db)


@router.get(
    "/{cow_id}",
    response_model=CowDetailResponse,
    status_code=status.HTTP_200_OK,
    summary="Get cow details and joined historical test records"
)
def get_cow(
    cow_id: int,
    current_farmer: Farmer = Depends(get_current_farmer),
    db: Session = Depends(get_db)
):
    """
    Retrieves cow profile information along with an array of historical test records
    by joining Sensor_Reading and Detection_Result tables.
    """
    return CowController.get_cow_profile(cow_id, current_farmer, db)


@router.post(
    "/{cow_id}/initiate-test",
    status_code=status.HTTP_200_OK,
    summary="Start an active 3-minute diagnostic test session for a cow"
)
def start_cow_test(
    cow_id: int,
    current_farmer: Farmer = Depends(get_current_farmer),
    db: Session = Depends(get_db)
):
    """
    Locks incoming ESP32 sensor telemetry to this specific cow_id for 3 minutes.
    Called when the farmer taps 'Select cow to test' in the mobile app.
    """
    # 1. Verify the cow exists and belongs to the logged-in farmer
    cow = CowController.get_cow_profile(cow_id, current_farmer, db)
    if not cow:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Cow with ID {cow_id} not found"
        )

    # 2. Lock session for 3 minutes using the database column cow_tag
    session_data = session_manager.start_session(
        cow_id=cow_id,
        cow_tag=cow.cow_tag
    )

    return {
        "status": "testing",
        "message": f"Active test session initialized for {cow.cow_tag}",
        "cow_id": cow_id,
        "expires_at": session_data["expires_at"].isoformat()
    }