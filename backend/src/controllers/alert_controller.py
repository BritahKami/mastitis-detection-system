from typing import List
from sqlalchemy.orm import Session
from sqlalchemy import text
from fastapi import HTTPException, status
from src.models.db_models import Farmer, Alert
from src.models.schemas import (
    AlertResponse,
    AlertReadResponse,
    AlertBulkReadResponse
)


class AlertController:
    """
    Controller handling Farmer Alerts & Notification management.
    """

    @staticmethod
    def get_alerts(current_farmer: Farmer, db: Session) -> List[AlertResponse]:
        """
        Retrieves all notification alerts for the authenticated farmer,
        joined with Cow details to include the cow's ear tag, ordered newest first.
        """
        query = text("""
            SELECT 
                a.alert_id,
                a.result_id,
                c.cow_tag,
                a.message,
                a.status,
                a.send_time
            FROM Alert a
            JOIN Detection_Result dr ON a.result_id = dr.result_id
            JOIN Cow c ON dr.cow_id = c.cow_id
            WHERE a.farmer_id = :farmer_id
            ORDER BY a.send_time DESC
        """)

        rows = db.execute(query, {"farmer_id": current_farmer.farmer_id}).mappings().all()

        return [
            AlertResponse(
                alert_id=row["alert_id"],
                result_id=row["result_id"],
                cow_tag=row["cow_tag"],
                message=row["message"],
                status=row["status"],
                send_time=row["send_time"]
            )
            for row in rows
        ]

    @staticmethod
    def mark_alert_as_read(
        alert_id: int,
        current_farmer: Farmer,
        db: Session
    ) -> AlertReadResponse:
        """
        Updates a single alert's status to 'Read'. Enforces ownership security.
        """
        alert = (
            db.query(Alert)
            .filter(Alert.alert_id == alert_id, Alert.farmer_id == current_farmer.farmer_id)
            .first()
        )
        if not alert:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Alert with ID {alert_id} not found."
            )

        alert.status = "Read"
        db.commit()

        return AlertReadResponse(
            message="Alert marked as read.",
            alert_id=alert_id
        )

    @staticmethod
    def mark_all_alerts_read(
        current_farmer: Farmer,
        db: Session
    ) -> AlertBulkReadResponse:
        """
        Bulk updates all unread alerts for the authenticated farmer to 'Read'.
        """
        updated_count = (
            db.query(Alert)
            .filter(Alert.farmer_id == current_farmer.farmer_id, Alert.status == "Unread")
            .update({"status": "Read"}, synchronize_session=False)
        )
        db.commit()

        return AlertBulkReadResponse(
            message="All unread alerts marked as read.",
            updated_count=updated_count
        )
