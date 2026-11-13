import unittest
from datetime import datetime, timezone
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from fastapi.responses import JSONResponse

from src.config.database import Base
from src.models.db_models import Farmer, Cow, SensorReading, DetectionResult
from src.models.schemas import (
    IoTSensorReadingRequest,
    DetectionResultResponse
)
from src.controllers.test_controller import TestController
from src.controllers.iot_controller import IoTController
from src.routes.iot_routes import ingest_sensor_reading
from src.services.session_service import session_manager


class TestIoTPipelineWorkflows(unittest.TestCase):
    def setUp(self):
        # Create an in-memory SQLite engine for tests
        self.engine = create_engine(
            "sqlite:///:memory:",
            connect_args={"check_same_thread": False}
        )
        Base.metadata.create_all(bind=self.engine)
        self.TestingSessionLocal = sessionmaker(
            autocommit=False, autoflush=False, bind=self.engine
        )
        self.db = self.TestingSessionLocal()

        # Clear session manager lock
        session_manager.clear_session()

        # Ensure ML model is loaded for inference
        import os
        from src.services.ml_service import ml_service
        backend_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        ml_service.model_path = os.path.join(backend_dir, "models", "mastitis_rf_model.joblib")
        ml_service.load_model()

        # Seed test farmer
        self.farmer = Farmer(
            fname="John",
            lname="Doe",
            email="farmer@test.com",
            password="hashedpassword"
        )
        self.db.add(self.farmer)
        self.db.commit()
        self.db.refresh(self.farmer)

        # Seed test cow COW-008
        self.cow = Cow(
            farmer_id=self.farmer.farmer_id,
            cow_tag="COW-008",
            breed="Friesian",
            age=4,
            health_status="Healthy"
        )
        self.db.add(self.cow)
        self.db.commit()
        self.db.refresh(self.cow)

    def tearDown(self):
        session_manager.clear_session()
        self.db.close()
        Base.metadata.drop_all(bind=self.engine)

    def test_idle_esp32_telemetry_returns_200_ignored(self):
        """
        Issue 2: Verify that when NO active session exists, ESP32 telemetry
        returns 200 OK with {"status": "ignored", "message": "No active test session"}
        instead of throwing HTTPException 400.
        """
        payload = IoTSensorReadingRequest(
            temperature=38.6,
            pH=6.60,
            electrical_conductivity=4.90
        )
        response = ingest_sensor_reading(payload=payload, db=self.db)

        self.assertIsInstance(response, JSONResponse)
        self.assertEqual(response.status_code, 200)
        import json
        body = json.loads(response.body.decode("utf-8"))
        self.assertEqual(body["status"], "ignored")
        self.assertEqual(body["message"], "No active test session")

    def test_full_test_lifecycle_and_multiple_telemetry_readings(self):
        """
        Issue 1 & 2:
        1. Farmer initiates test -> cow status 'Pending', session lock activated for COW-008.
        2. Short polling returns 202 Accepted while pending.
        3. ESP32 sends 1st reading -> saved to DB, ML inference executed, session stays locked.
        4. ESP32 sends 2nd reading -> also successfully processed without 400 error!
        5. Polling endpoint returns DetectionResultResponse with real DB values and cow tag COW-008.
        """
        # Step 1: Initiate test
        init_res = TestController.initiate_test(
            cow_id=self.cow.cow_id,
            current_farmer=self.farmer,
            db=self.db
        )
        self.assertEqual(init_res.health_status, "Pending")
        self.assertEqual(init_res.status, "testing")
        self.assertIsNotNone(init_res.expires_at)
        self.assertEqual(session_manager.get_active_cow_id(), self.cow.cow_id)

        # Step 2: Poll while pending -> 202 Accepted
        poll_res_pending = TestController.poll_latest_result(
            cow_id=self.cow.cow_id,
            current_farmer=self.farmer,
            db=self.db
        )
        self.assertIsInstance(poll_res_pending, JSONResponse)
        self.assertEqual(poll_res_pending.status_code, 202)

        # Step 3: ESP32 sends 1st telemetry reading (e.g., Temp: 39.8, pH: 6.95, Cond: 6.40)
        reading1 = IoTSensorReadingRequest(
            temperature=39.8,
            pH=6.95,
            electrical_conductivity=6.40
        )
        res1 = ingest_sensor_reading(payload=reading1, db=self.db)
        self.assertEqual(res1.status, "Processed")
        self.assertIsNotNone(res1.reading_id)
        self.assertIsNotNone(res1.result_id)

        # Verify session lock is STILL active (Issue 2 fix: clear_session was NOT called prematurely)
        self.assertEqual(session_manager.get_active_cow_id(), self.cow.cow_id)
        active_sess = session_manager.get_active_session()
        self.assertIsNotNone(active_sess)
        self.assertIsNotNone(active_sess["latest_reading"])
        self.assertEqual(active_sess["latest_reading"]["temperature"], 39.8)

        # Step 4: ESP32 sends 2nd telemetry reading in same session (e.g., Temp: 40.1, pH: 7.05, Cond: 6.65)
        reading2 = IoTSensorReadingRequest(
            temperature=40.1,
            pH=7.05,
            electrical_conductivity=6.65
        )
        # In the buggy version, this triggered 400 Bad Request!
        res2 = ingest_sensor_reading(payload=reading2, db=self.db)
        self.assertEqual(res2.status, "Processed")
        self.assertNotEqual(res2.reading_id, res1.reading_id)

        # Session lock still remains intact
        self.assertEqual(session_manager.get_active_cow_id(), self.cow.cow_id)

        # Step 5: Poll latest result -> returns 200 OK with DetectionResultResponse
        poll_res_completed = TestController.poll_latest_result(
            cow_id=self.cow.cow_id,
            current_farmer=self.farmer,
            db=self.db
        )
        self.assertIsInstance(poll_res_completed, DetectionResultResponse)
        self.assertEqual(poll_res_completed.cow_id, self.cow.cow_id)
        self.assertEqual(poll_res_completed.cow_tag, "COW-008")
        # Ensure values map directly from the 2nd (latest) reading in DB
        self.assertAlmostEqual(poll_res_completed.temperature, 40.1, places=1)
        self.assertAlmostEqual(poll_res_completed.pH, 7.05, places=2)
        self.assertAlmostEqual(poll_res_completed.electrical_conductivity, 6.65, places=2)
        self.assertIn(poll_res_completed.diagnostic_status, ["Mastitis Present", "Mastitis Absent"])
        self.assertEqual(poll_res_completed.diagnostic_status, poll_res_completed.prediction)

        # Verify backward compatible nested result
        self.assertIsNotNone(poll_res_completed.result)
        self.assertAlmostEqual(poll_res_completed.result.temperature, 40.1, places=1)
        self.assertAlmostEqual(poll_res_completed.result.pH, 7.05, places=2)
        self.assertAlmostEqual(poll_res_completed.result.electrical_conductivity, 6.65, places=2)

    def test_timezone_and_dashboard_status_synchronization(self):
        """
        Verify that:
        1. Test initiation timestamp uses Africa/Nairobi timezone (UTC+3).
        2. Sensor telemetry ingestion atomically updates Cow.health_status and Cow.last_tested.
        3. CowController.get_all_cows returns the synchronized health_status and last_tested.
        """
        from src.controllers.cow_controller import CowController
        from zoneinfo import ZoneInfo

        # Initial check
        cows_initial = CowController.get_all_cows(current_farmer=self.farmer, db=self.db)
        self.assertEqual(len(cows_initial), 1)
        self.assertIsNone(cows_initial[0].last_tested)

        # 1. Initiate test
        init_res = TestController.initiate_test(
            cow_id=self.cow.cow_id,
            current_farmer=self.farmer,
            db=self.db
        )
        self.assertEqual(init_res.timestamp.tzinfo, ZoneInfo("Africa/Nairobi"))

        # 2. Process sensor reading
        payload = IoTSensorReadingRequest(
            cow_id=self.cow.cow_id,
            temperature=39.5,
            pH=6.90,
            electrical_conductivity=6.50
        )
        proc_res = IoTController.process_sensor_reading(
            payload=payload,
            db=self.db,
            active_cow_id=self.cow.cow_id
        )
        self.assertEqual(proc_res.status, "Processed")

        # Refresh cow from database
        self.db.refresh(self.cow)
        self.assertEqual(self.cow.health_status, proc_res.cow_health_status)
        self.assertIsNotNone(self.cow.last_tested)

        # 3. CowController.get_all_cows reflects synchronized status and last_tested
        cows_after = CowController.get_all_cows(current_farmer=self.farmer, db=self.db)
        self.assertEqual(len(cows_after), 1)
        cow_response = cows_after[0]
        self.assertEqual(cow_response.health_status, proc_res.cow_health_status)
        self.assertIsNotNone(cow_response.last_tested)

    def test_cow_profile_unlimited_test_history(self):
        """
        Verify that CowController.get_cow_profile returns all historical tests
        without any slicing or truncation limit, ordered from newest to oldest,
        with all telemetry metrics populated.
        """
        from src.controllers.cow_controller import CowController
        from zoneinfo import ZoneInfo
        from datetime import datetime, timedelta

        eat_tz = ZoneInfo("Africa/Nairobi")
        base_time = datetime.now(eat_tz)

        # Ingest 7 test readings for this cow
        for i in range(7):
            reading_time = base_time + timedelta(hours=i)
            sr = SensorReading(
                cow_id=self.cow.cow_id,
                temperature=38.0 + (i * 0.2),
                pH=6.50 + (i * 0.05),
                electrical_conductivity=4.50 + (i * 0.3),
                reading_time=reading_time
            )
            self.db.add(sr)
            self.db.flush()

            dr = DetectionResult(
                cow_id=self.cow.cow_id,
                reading_id=sr.reading_id,
                prediction="Mastitis Present" if i % 2 == 1 else "Mastitis Absent",
                detection_time=reading_time
            )
            self.db.add(dr)

        self.db.commit()

        # Retrieve cow profile
        profile = CowController.get_cow_profile(
            cow_id=self.cow.cow_id,
            current_farmer=self.farmer,
            db=self.db
        )

        # Verify all 7 records are returned without truncation
        self.assertEqual(len(profile.history), 7)

        # Verify ordered newest first (i = 6 is newest)
        first_record = profile.history[0]
        self.assertAlmostEqual(first_record.temperature, 38.0 + (6 * 0.2), places=1)
        self.assertAlmostEqual(first_record.pH, 6.50 + (6 * 0.05), places=2)
        self.assertAlmostEqual(first_record.electrical_conductivity, 4.50 + (6 * 0.3), places=2)
        self.assertIsNotNone(first_record.result_id)
        self.assertIsNotNone(first_record.reading_id)
        self.assertIsNotNone(first_record.prediction)
        self.assertEqual(first_record.diagnostic_status, first_record.prediction)

        # Oldest record is last (i = 0)
        last_record = profile.history[-1]
        self.assertAlmostEqual(last_record.temperature, 38.0, places=1)

    def test_alert_generation_and_retrieval_pipeline(self):
        """
        End-to-End Alert Pipeline Verification:
        1. Ingestion creates Alert record when Mastitis Present / At Risk.
        2. Alert adheres to schema: alert_id, result_id, farmer_id, message (with cow tag prefix), status='Unread', send_time.
        3. Alert retrieval (GET /api/alerts via AlertController.get_alerts) is filtered by authenticated farmer_id.
        4. Alerts are ordered chronologically newest first.
        5. Single read and bulk read status transitions work correctly.
        """
        from src.models.db_models import Alert
        from src.controllers.alert_controller import AlertController

        # 1. Process positive mastitis telemetry
        payload_positive = IoTSensorReadingRequest(
            cow_id=self.cow.cow_id,
            temperature=40.5,
            pH=7.10,
            electrical_conductivity=6.90
        )
        proc_res = IoTController.process_sensor_reading(
            payload=payload_positive,
            db=self.db,
            active_cow_id=self.cow.cow_id
        )
        self.assertEqual(proc_res.status, "Processed")
        self.assertEqual(proc_res.prediction, "Mastitis Present")
        self.assertEqual(proc_res.cow_health_status, "At Risk")

        # 2. Query Alert table directly and verify schema adherence
        alert = self.db.query(Alert).filter(Alert.result_id == proc_res.result_id).first()
        self.assertIsNotNone(alert)
        self.assertEqual(alert.farmer_id, self.farmer.farmer_id)
        self.assertEqual(alert.result_id, proc_res.result_id)
        self.assertEqual(alert.status, "Unread")
        self.assertTrue(alert.message.startswith(f"{self.cow.cow_tag}: Mastitis Present"))
        self.assertIsNotNone(alert.send_time)

        # 3. Test Alert Retrieval for authenticated farmer
        alerts = AlertController.get_alerts(current_farmer=self.farmer, db=self.db)
        self.assertGreaterEqual(len(alerts), 1)
        farmer_alert = alerts[0]
        self.assertEqual(farmer_alert.alert_id, alert.alert_id)
        self.assertEqual(farmer_alert.result_id, proc_res.result_id)
        self.assertEqual(farmer_alert.farmer_id, self.farmer.farmer_id)
        self.assertEqual(farmer_alert.cow_tag, self.cow.cow_tag)
        self.assertEqual(farmer_alert.status, "Unread")
        self.assertTrue(farmer_alert.message.startswith(f"{self.cow.cow_tag}: Mastitis Present"))
        self.assertEqual(farmer_alert.send_time, alert.send_time)

        # 4. Verify tenant isolation: a different farmer receives NO alerts
        other_farmer = Farmer(
            fname="Jane",
            lname="Smith",
            email="jane@otherfarm.com",
            password="hashedpassword"
        )
        self.db.add(other_farmer)
        self.db.commit()
        self.db.refresh(other_farmer)

        other_alerts = AlertController.get_alerts(current_farmer=other_farmer, db=self.db)
        self.assertEqual(len(other_alerts), 0)

        # 5. Mark alert as Read
        read_res = AlertController.mark_alert_as_read(
            alert_id=alert.alert_id,
            current_farmer=self.farmer,
            db=self.db
        )
        self.assertEqual(read_res.alert_id, alert.alert_id)
        self.db.refresh(alert)
        self.assertEqual(alert.status, "Read")

        # 6. Bulk mark as read
        bulk_res = AlertController.mark_all_alerts_read(
            current_farmer=self.farmer,
            db=self.db
        )
        self.assertIsInstance(bulk_res.updated_count, int)

    def test_five_reading_bounded_session_and_alert_deduplication(self):
        """
        Verify that:
        1. When a test is initiated, the session accepts only the first 5 valid sensor readings.
        2. Once the 5th reading is processed, session lock automatically closes.
        3. Trailing readings (6th, 7th) are ignored with 200 OK {"status": "ignored", "message": "No active test session"}.
        4. Exactly 5 readings and 5 detection results are stored in the database and returned in cow profile history.
        5. Across all 5 positive (Mastitis Present) readings, exactly 1 unread alert is created (no duplicates).
        6. GET /api/cows/{cow_id}/latest-result cleanly returns the 5th (latest) result before and after the session closes.
        """
        import json
        from src.controllers.alert_controller import AlertController
        from src.controllers.cow_controller import CowController
        from src.models.db_models import Alert

        # 1. Initiate test session for COW-008
        init_res = TestController.initiate_test(
            cow_id=self.cow.cow_id,
            current_farmer=self.farmer,
            db=self.db
        )
        self.assertEqual(init_res.health_status, "Pending")
        self.assertEqual(session_manager.get_active_cow_id(), self.cow.cow_id)
        self.assertEqual(session_manager.get_reading_count(), 0)

        # 2. Ingest 5 positive (Mastitis Present) sensor readings from ESP32
        # Values known to trigger Mastitis Present: Temp: 40.5, pH: 7.10, Cond: 6.90
        processed_responses = []
        for i in range(1, 6):
            payload = IoTSensorReadingRequest(
                temperature=40.0 + (i * 0.1),
                pH=7.00 + (i * 0.02),
                electrical_conductivity=6.80 + (i * 0.05)
            )
            res = ingest_sensor_reading(payload=payload, db=self.db)
            self.assertEqual(res.status, "Processed")
            self.assertEqual(res.prediction, "Mastitis Present")
            processed_responses.append(res)
            
            # Check latest-result endpoint returns this latest reading
            poll_res = TestController.poll_latest_result(
                cow_id=self.cow.cow_id,
                current_farmer=self.farmer,
                db=self.db
            )
            self.assertIsInstance(poll_res, DetectionResultResponse)
            self.assertEqual(poll_res.reading_id, res.reading_id)
            self.assertEqual(poll_res.result_id, res.result_id)
            self.assertEqual(poll_res.prediction, "Mastitis Present")

        # 3. Verify session lock is now automatically CLOSED after the 5th reading
        self.assertIsNone(session_manager.get_active_cow_id())
        self.assertIsNone(session_manager.get_active_session())

        # 4. Ingest 6th and 7th readings (trailing 5-second ESP32 packets)
        for trailing_i in [6, 7]:
            trailing_payload = IoTSensorReadingRequest(
                temperature=40.8,
                pH=7.15,
                electrical_conductivity=7.00
            )
            res_trailing = ingest_sensor_reading(payload=trailing_payload, db=self.db)
            self.assertIsInstance(res_trailing, JSONResponse)
            self.assertEqual(res_trailing.status_code, 200)
            body = json.loads(res_trailing.body.decode("utf-8"))
            self.assertEqual(body["status"], "ignored")
            self.assertEqual(body["message"], "No active test session")

        # 5. Verify database storage: exactly 5 sensor readings and 5 detection results
        db_readings = self.db.query(SensorReading).filter(SensorReading.cow_id == self.cow.cow_id).all()
        db_results = self.db.query(DetectionResult).filter(DetectionResult.cow_id == self.cow.cow_id).all()
        self.assertEqual(len(db_readings), 5)
        self.assertEqual(len(db_results), 5)

        # 6. Verify Cow Profile History: returns exactly those 5 readings
        cow_profile = CowController.get_cow_profile(
            cow_id=self.cow.cow_id,
            current_farmer=self.farmer,
            db=self.db
        )
        self.assertEqual(len(cow_profile.history), 5)
        self.assertEqual(cow_profile.history[0].reading_id, processed_responses[4].reading_id)
        self.assertEqual(cow_profile.history[-1].reading_id, processed_responses[0].reading_id)

        # 7. Alert Deduplication: exactly 1 unread alert created across all 5 positive readings
        db_alerts = (
            self.db.query(Alert)
            .join(DetectionResult, Alert.result_id == DetectionResult.result_id)
            .filter(DetectionResult.cow_id == self.cow.cow_id, Alert.status == "Unread")
            .all()
        )
        self.assertEqual(len(db_alerts), 1)

        # 8. AlertController.get_alerts returns only 1 alert for this farmer
        farmer_alerts = AlertController.get_alerts(current_farmer=self.farmer, db=self.db)
        cow_alerts = [a for a in farmer_alerts if a.cow_tag == self.cow.cow_tag]
        self.assertEqual(len(cow_alerts), 1)
        self.assertEqual(cow_alerts[0].status, "Unread")

        # 9. GET /api/cows/{cow_id}/latest-result still returns the 5th reading cleanly after session closed
        final_poll = TestController.poll_latest_result(
            cow_id=self.cow.cow_id,
            current_farmer=self.farmer,
            db=self.db
        )
        self.assertIsInstance(final_poll, DetectionResultResponse)
        self.assertEqual(final_poll.reading_id, processed_responses[4].reading_id)
        self.assertEqual(final_poll.result_id, processed_responses[4].result_id)
        self.assertEqual(final_poll.health_status, "At Risk")
        self.assertEqual(final_poll.diagnostic_status, "Mastitis Present")


if __name__ == "__main__":
    unittest.main()
