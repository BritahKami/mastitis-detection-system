import os
import unittest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from src.config.database import Base
from src.models.db_models import Farmer, Cow, SensorReading, DetectionResult
from src.models.schemas import CowRegisterRequest, IoTSensorReadingRequest
from src.controllers.cow_controller import CowController
from src.controllers.iot_controller import IoTController
from src.controllers.test_controller import TestController
from fastapi import HTTPException
from src.services.ml_service import ml_service, MastitisMLService
from src.services.session_service import session_manager


class TestMDSEnhancements(unittest.TestCase):
    def setUp(self):
        self.engine = create_engine(
            "sqlite:///:memory:",
            connect_args={"check_same_thread": False}
        )
        Base.metadata.create_all(bind=self.engine)
        self.TestingSessionLocal = sessionmaker(
            autocommit=False, autoflush=False, bind=self.engine
        )
        self.db = self.TestingSessionLocal()
        session_manager.clear_session()

        backend_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        ml_service.model_path = os.path.join(backend_dir, "models", "mastitis_rf_model.joblib")
        ml_service.load_model()

        # Seed test farmer
        self.farmer = Farmer(
            fname="Alice",
            lname="Smith",
            email="alice@farm.com",
            password="hashedpassword"
        )
        self.db.add(self.farmer)
        self.db.commit()
        self.db.refresh(self.farmer)

    def tearDown(self):
        session_manager.clear_session()
        self.db.close()
        Base.metadata.drop_all(bind=self.engine)

    def test_predict_proba_and_confidence_score(self):
        """
        Verify that ml_service computes class probabilities and confidence score correctly.
        """
        res = ml_service.predict(
            temperature=39.4,
            ph=6.85,
            electrical_conductivity=6.42
        )
        # Should unpack into label and confidence_score
        label, confidence = res
        self.assertIn(label, ["Mastitis Present", "Mastitis Absent"])
        self.assertIsInstance(confidence, float)
        self.assertGreaterEqual(confidence, 50.0)
        self.assertLessEqual(confidence, 100.0)
        self.assertEqual(res.confidence_score, confidence)
        self.assertEqual(res.prediction, label)

    def test_pure_random_forest_classification_and_probabilities(self):
        """
        Verify that healthy and mastitic telemetry classifications are derived
        purely from the loaded Random Forest model and predict_proba probabilities.
        """
        # Healthy milk sample
        healthy_res = ml_service.predict(
            temperature=38.6,
            ph=6.60,
            electrical_conductivity=4.80
        )
        self.assertEqual(healthy_res.prediction, "Mastitis Absent")
        self.assertGreaterEqual(healthy_res.confidence_score, 50.0)
        self.assertLessEqual(healthy_res.confidence_score, 100.0)

        # Mastitic milk sample
        mastitic_res = ml_service.predict(
            temperature=40.5,
            ph=7.10,
            electrical_conductivity=6.90
        )
        self.assertEqual(mastitic_res.prediction, "Mastitis Present")
        self.assertGreaterEqual(mastitic_res.confidence_score, 50.0)
        self.assertLessEqual(mastitic_res.confidence_score, 100.0)

    def test_predict_raises_runtime_error_when_model_unavailable(self):
        """
        Verify that ml_service explicitly raises a RuntimeError when no model is loaded,
        without falling back to veterinary threshold rules.
        """
        unloaded_service = MastitisMLService(model_path="non_existent_model.joblib")
        with self.assertRaises(RuntimeError) as cm:
            unloaded_service.predict(
                temperature=40.5,
                ph=7.10,
                electrical_conductivity=6.90
            )
        self.assertIn("unavailable", str(cm.exception).lower())

    def test_iot_controller_raises_503_when_model_unavailable(self):
        """
        Verify that IoTController raises HTTP 503 when the ML model is unavailable,
        rather than substituting rule-based heuristics.
        """
        cow = Cow(
            farmer_id=self.farmer.farmer_id,
            cow_tag="COW-ERR",
            breed="Friesian",
            age=3,
            health_status="Pending"
        )
        self.db.add(cow)
        self.db.commit()
        self.db.refresh(cow)

        payload = IoTSensorReadingRequest(
            cow_id=cow.cow_id,
            temperature=39.4,
            pH=6.85,
            electrical_conductivity=6.42
        )

        original_loaded = ml_service._is_loaded
        original_model = ml_service.model
        try:
            ml_service._is_loaded = False
            ml_service.model = None

            with self.assertRaises(HTTPException) as cm:
                IoTController.process_sensor_reading(
                    payload=payload,
                    db=self.db,
                    active_cow_id=cow.cow_id
                )
            self.assertEqual(cm.exception.status_code, 503)
            self.assertIn("unavailable", cm.exception.detail.lower())
        finally:
            ml_service._is_loaded = original_loaded
            ml_service.model = original_model

    def test_iot_telemetry_stores_and_returns_confidence_score(self):
        """
        Verify that IoT telemetry processing stores confidence_score in Detection_Result
        and returns it in response.
        """
        cow = Cow(
            farmer_id=self.farmer.farmer_id,
            cow_tag="COW-001",
            breed="Friesian",
            age=3,
            health_status="Pending"
        )
        self.db.add(cow)
        self.db.commit()
        self.db.refresh(cow)

        payload = IoTSensorReadingRequest(
            cow_id=cow.cow_id,
            temperature=39.4,
            pH=6.85,
            electrical_conductivity=6.42
        )
        resp = IoTController.process_sensor_reading(payload=payload, db=self.db, active_cow_id=cow.cow_id)
        self.assertIsNotNone(resp.confidence_score)
        self.assertGreaterEqual(resp.confidence_score, 50.0)

        # Check DB record
        det_record = self.db.query(DetectionResult).filter(DetectionResult.result_id == resp.result_id).first()
        self.assertIsNotNone(det_record)
        self.assertIsNotNone(det_record.confidence_score)

        # Check latest-result poll returns confidence_score
        poll_resp = TestController.poll_latest_result(cow_id=cow.cow_id, current_farmer=self.farmer, db=self.db)
        self.assertEqual(poll_resp.confidence_score, resp.confidence_score)
        self.assertIsNotNone(poll_resp.result.confidence_score)

        # Check cow profile history returns confidence_score
        profile = CowController.get_cow_profile(cow_id=cow.cow_id, current_farmer=self.farmer, db=self.db)
        self.assertTrue(len(profile.history) > 0)
        self.assertEqual(profile.history[0].confidence_score, resp.confidence_score)

    def test_sequential_cow_tag_generation(self):
        """
        Verify next cow tag auto-generation:
        - Default COW-001 when empty
        - Increments to highest suffix: COW-001 -> COW-002, COW-011 -> COW-012
        """
        # Initially no cows -> COW-001
        next_tag_resp = CowController.get_next_cow_tag(self.farmer, self.db)
        self.assertEqual(next_tag_resp.next_tag, "COW-001")

        # Register first cow with omitted tag -> auto-assigned COW-001
        reg_req = CowRegisterRequest(
            cow_tag=None,
            breed="Jersey",
            age=2
        )
        cow1 = CowController.register_cow(reg_req, self.farmer, self.db)
        self.assertEqual(cow1.cow_tag, "COW-001")

        # Next tag should now be COW-002
        next_tag_resp2 = CowController.get_next_cow_tag(self.farmer, self.db)
        self.assertEqual(next_tag_resp2.next_tag, "COW-002")

        # Manually register COW-011
        reg_req2 = CowRegisterRequest(
            cow_tag="COW-011",
            breed="Ayrshire",
            age=4
        )
        cow2 = CowController.register_cow(reg_req2, self.farmer, self.db)
        self.assertEqual(cow2.cow_tag, "COW-011")

        # Next tag should be COW-012
        next_tag_resp3 = CowController.get_next_cow_tag(self.farmer, self.db)
        self.assertEqual(next_tag_resp3.next_tag, "COW-012")

        # Duplicate registration of COW-011 should raise 400
        from fastapi import HTTPException
        with self.assertRaises(HTTPException) as cm:
            CowController.register_cow(
                CowRegisterRequest(cow_tag="COW-011", breed="Guernsey", age=3),
                self.farmer,
                self.db
            )
        self.assertEqual(cm.exception.status_code, 400)

    def test_per_farmer_isolation_and_composite_uniqueness(self):
        """
        Verify multi-farmer scoping:
        1. Farmer 1 (Alice) has COW-001 and COW-002.
        2. Farmer 2 (Bob) queries next-tag and gets COW-001 (NOT COW-003!).
        3. Farmer 2 registers COW-001 successfully (composite pair allowed).
        4. Farmer 2 queries next-tag and gets COW-002.
        5. Farmer 2 attempts duplicate registration of COW-001 -> rejected with HTTP 400.
        6. Farmer 1 attempts duplicate registration of COW-001 -> rejected with HTTP 400.
        """
        farmer2 = Farmer(
            fname="Bob",
            lname="Jones",
            email="bob@farm.com",
            password="hashedpassword"
        )
        self.db.add(farmer2)
        self.db.commit()
        self.db.refresh(farmer2)

        # Farmer 1 registers COW-001 and COW-002
        CowController.register_cow(
            CowRegisterRequest(cow_tag="COW-001", breed="Friesian", age=3),
            self.farmer,
            self.db
        )
        CowController.register_cow(
            CowRegisterRequest(cow_tag="COW-002", breed="Jersey", age=2),
            self.farmer,
            self.db
        )

        # Farmer 1's next tag is COW-003
        self.assertEqual(CowController.compute_next_tag(self.farmer, self.db), "COW-003")

        # Farmer 2 has no cows yet -> next tag MUST be COW-001
        self.assertEqual(CowController.compute_next_tag(farmer2, self.db), "COW-001")

        # Farmer 2 registers their own COW-001 -> SUCCESS (no collision with Farmer 1's COW-001)
        cow_f2_1 = CowController.register_cow(
            CowRegisterRequest(cow_tag=None, breed="Ayrshire", age=4),
            farmer2,
            self.db
        )
        self.assertEqual(cow_f2_1.cow_tag, "COW-001")
        self.assertEqual(cow_f2_1.farmer_id, farmer2.farmer_id)

        # Farmer 2's next tag is now COW-002
        self.assertEqual(CowController.compute_next_tag(farmer2, self.db), "COW-002")

        # Farmer 2 registering duplicate COW-001 fails
        from fastapi import HTTPException
        with self.assertRaises(HTTPException) as cm:
            CowController.register_cow(
                CowRegisterRequest(cow_tag="COW-001", breed="Guernsey", age=1),
                farmer2,
                self.db
            )
        self.assertEqual(cm.exception.status_code, 400)

        # Farmer 1 registering duplicate COW-001 fails
        with self.assertRaises(HTTPException) as cm:
            CowController.register_cow(
                CowRegisterRequest(cow_tag="COW-001", breed="Guernsey", age=1),
                self.farmer,
                self.db
            )
        self.assertEqual(cm.exception.status_code, 400)


if __name__ == "__main__":
    unittest.main()
