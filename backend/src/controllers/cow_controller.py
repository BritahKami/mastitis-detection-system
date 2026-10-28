from typing import List
from sqlalchemy.orm import Session
from sqlalchemy import text
from fastapi import HTTPException, status
from src.models.db_models import Farmer, Cow, SensorReading
from src.models.schemas import (
    CowRegisterRequest,
    CowResponse,
    CowDetailResponse,
    HistoricalTestRecord
)


class CowController:
    """
    Controller handling Dairy Cow Registration, Listing, and Detailed Profile retrieval.
    """

    @staticmethod
    def register_cow(
        payload: CowRegisterRequest,
        current_farmer: Farmer,
        db: Session
    ) -> CowResponse:
        """
        Registers a new cow for the authenticated farmer.
        Defaults health_status to 'Healthy' per database schema specification.
        """
        new_cow = Cow(
            farmer_id=current_farmer.farmer_id,
            cow_tag=payload.cow_tag.strip(),
            breed=payload.breed.strip(),
            age=payload.age,
            health_status="Pending"
        )
        db.add(new_cow)
        db.commit()
        db.refresh(new_cow)

        return CowResponse.model_validate(new_cow)

    @staticmethod
    def get_all_cows(
        current_farmer: Farmer,
        db: Session
    ) -> List[CowResponse]:
        """
        Retrieves all cows owned by the authenticated farmer, ordered newest first.
        Synchronizes dynamic health_status and last_tested timestamps.
        """
        cows = (
            db.query(Cow)
            .filter(Cow.farmer_id == current_farmer.farmer_id)
            .order_by(Cow.cow_id.desc())
            .all()
        )
        results = []
        for c in cows:
            resp = CowResponse.model_validate(c)
            if resp.last_tested is None:
                latest_reading = (
                    db.query(SensorReading.reading_time)
                    .filter(SensorReading.cow_id == c.cow_id)
                    .order_by(SensorReading.reading_time.desc())
                    .first()
                )
                if latest_reading:
                    resp.last_tested = latest_reading[0]
            results.append(resp)
        return results

    @staticmethod
    def get_cow_profile(
        cow_id: int,
        current_farmer: Farmer,
        db: Session
    ) -> CowDetailResponse:
        """
        Fetches the complete cow profile and utilizes a SQL JOIN between
        Sensor_Reading and Detection_Result to return an array of all historical test records
        without query limit or slicing truncation, ordered newest to oldest.
        """
        # 1. Enforce farmer ownership
        cow = (
            db.query(Cow)
            .filter(Cow.cow_id == cow_id, Cow.farmer_id == current_farmer.farmer_id)
            .first()
        )
        if not cow:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Cow with ID {cow_id} not found or does not belong to your account."
            )

        # 2. Query combined historical sensor readings and detection results via SQL JOIN
        history_query = text("""
            SELECT 
                sr.reading_id,
                dr.result_id,
                sr.temperature,
                sr.pH,
                sr.electrical_conductivity,
                sr.reading_time,
                dr.prediction,
                dr.detection_time
            FROM Sensor_Reading sr
            LEFT JOIN Detection_Result dr ON sr.reading_id = dr.reading_id
            WHERE sr.cow_id = :cow_id
            ORDER BY sr.reading_time DESC, sr.reading_id DESC
        """)

        rows = db.execute(history_query, {"cow_id": cow_id}).mappings().all()

        history_records: List[HistoricalTestRecord] = []
        for row in rows:
            pred = row["prediction"]
            history_records.append(
                HistoricalTestRecord(
                    reading_id=row["reading_id"],
                    result_id=row["result_id"],
                    temperature=float(row["temperature"]),
                    pH=float(row["pH"]),
                    electrical_conductivity=float(row["electrical_conductivity"]),
                    reading_time=row["reading_time"],
                    prediction=pred,
                    diagnostic_status=pred,
                    detection_time=row["detection_time"]
                )
            )

        last_tested_val = cow.last_tested
        if last_tested_val is None and history_records:
            last_tested_val = history_records[0].reading_time

        return CowDetailResponse(
            cow_id=cow.cow_id,
            cow_tag=cow.cow_tag,
            breed=cow.breed,
            age=cow.age,
            health_status=cow.health_status,
            last_tested=last_tested_val,
            history=history_records
        )
