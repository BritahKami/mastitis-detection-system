from typing import List
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from src.config.database import get_db
from src.middleware.auth_middleware import get_current_farmer
from src.models.db_models import Farmer
from src.models.schemas import (
    AlertResponse,
    AlertReadResponse,
    AlertBulkReadResponse
)
from src.controllers.alert_controller import AlertController

router = APIRouter(prefix="/alerts", tags=["Alerts & Notifications"])


@router.get(
    "",
    response_model=List[AlertResponse],
    status_code=status.HTTP_200_OK,
    summary="Retrieve all alerts for authenticated farmer"
)
def list_alerts(
    current_farmer: Farmer = Depends(get_current_farmer),
    db: Session = Depends(get_db)
):
    """
    Returns all notifications for the authenticated farmer, joined with cow details
    to include ear tag numbers, ordered newest first.
    """
    return AlertController.get_alerts(current_farmer, db)


@router.put(
    "/{alert_id}/read",
    response_model=AlertReadResponse,
    status_code=status.HTTP_200_OK,
    summary="Mark single alert as Read"
)
def mark_read(
    alert_id: int,
    current_farmer: Farmer = Depends(get_current_farmer),
    db: Session = Depends(get_db)
):
    """
    Updates a single alert's status from 'Unread' to 'Read'.
    Enforces ownership verification.
    """
    return AlertController.mark_alert_as_read(alert_id, current_farmer, db)


@router.put(
    "/mark-all-read",
    response_model=AlertBulkReadResponse,
    status_code=status.HTTP_200_OK,
    summary="Bulk update all farmer alerts to Read"
)
def mark_all_read(
    current_farmer: Farmer = Depends(get_current_farmer),
    db: Session = Depends(get_db)
):
    """
    Bulk updates all unread alerts for the authenticated farmer to 'Read'.
    """
    return AlertController.mark_all_alerts_read(current_farmer, db)
