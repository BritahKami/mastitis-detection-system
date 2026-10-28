import unittest
import asyncio
from datetime import datetime, timedelta, timezone
from pydantic import ValidationError
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from fastapi import HTTPException
from jose import jwt

from src.config.database import Base
from src.config.config import settings
from src.models.db_models import Farmer, OTPCode
from src.models.schemas import (
    FarmerRegisterRequest,
    FarmerLoginRequest,
    ForgotPasswordRequest,
    VerifyResetCodeRequest,
    ResetPasswordRequest,
    LoginStep2Request,
)
from src.controllers.auth_controller import AuthController
from src.middleware.auth_middleware import verify_password


class TestAuthOTPWorkflows(unittest.IsolatedAsyncioTestCase):
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

        # Seed test farmer
        AuthController.register_farmer(
            FarmerRegisterRequest(
                fname="Test",
                lname="Farmer",
                email="testfarmer@dairyfarm.com",
                password="password123"
            ),
            self.db
        )

    def tearDown(self):
        self.db.close()
        Base.metadata.drop_all(bind=self.engine)

    async def test_forgot_password_and_reset_flow(self):
        email = "testfarmer@dairyfarm.com"

        # 1. Request forgot password
        res = await AuthController.forgot_password(
            ForgotPasswordRequest(email=email),
            self.db
        )
        self.assertIn("verification code has been sent", res.message)

        # Retrieve generated OTP from DB
        otp_record = self.db.query(OTPCode).filter(
            OTPCode.email == email,
            OTPCode.purpose == "reset_password",
            OTPCode.is_used == False
        ).first()
        self.assertIsNotNone(otp_record)
        self.assertEqual(len(otp_record.code), 6)
        self.assertTrue(otp_record.expires_at > datetime.now(timezone.utc).replace(tzinfo=None))

        # 2. Verify invalid code fails
        with self.assertRaises(HTTPException) as cm:
            AuthController.verify_reset_code(
                VerifyResetCodeRequest(email=email, code="000000"),
                self.db
            )
        self.assertEqual(cm.exception.status_code, 400)

        # 3. Verify valid code passes
        verify_res = AuthController.verify_reset_code(
            VerifyResetCodeRequest(email=email, code=otp_record.code),
            self.db
        )
        self.assertEqual(verify_res.message, "Verification code is valid.")

        # 4. Reset password with short password fails (< 8 chars) at Pydantic schema validation
        with self.assertRaises(ValidationError):
            ResetPasswordRequest(
                email=email,
                code=otp_record.code,
                new_password="short"
            )

        # 5. Reset password successfully
        new_pwd = "new_secure_password_2026"
        reset_res = AuthController.reset_password(
            ResetPasswordRequest(
                email=email,
                code=otp_record.code,
                new_password=new_pwd
            ),
            self.db
        )
        self.assertIn("Password reset successfully", reset_res.message)

        # Check DB state
        self.db.refresh(otp_record)
        self.assertTrue(otp_record.is_used)

        farmer = self.db.query(Farmer).filter(Farmer.email == email).first()
        self.assertTrue(verify_password(new_pwd, farmer.password))
        self.assertFalse(verify_password("password123", farmer.password))

        # 6. Reusing same OTP fails
        with self.assertRaises(HTTPException) as cm:
            AuthController.reset_password(
                ResetPasswordRequest(
                    email=email,
                    code=otp_record.code,
                    new_password="another_password_123"
                ),
                self.db
            )
        self.assertEqual(cm.exception.status_code, 400)

    async def test_forgot_password_expired_code(self):
        email = "testfarmer@dairyfarm.com"
        await AuthController.forgot_password(
            ForgotPasswordRequest(email=email),
            self.db
        )
        otp = self.db.query(OTPCode).filter(
            OTPCode.email == email,
            OTPCode.purpose == "reset_password"
        ).first()

        # Simulate expiration
        otp.expires_at = datetime.now(timezone.utc).replace(tzinfo=None) - timedelta(minutes=5)
        self.db.commit()

        with self.assertRaises(HTTPException) as cm:
            AuthController.verify_reset_code(
                VerifyResetCodeRequest(email=email, code=otp.code),
                self.db
            )
        self.assertEqual(cm.exception.status_code, 400)
        self.assertIn("expired", cm.exception.detail.lower())

    async def test_two_factor_login_flow(self):
        email = "testfarmer@dairyfarm.com"

        # 1. Login step 1 with wrong password fails
        with self.assertRaises(HTTPException) as cm:
            await AuthController.login_step1(
                FarmerLoginRequest(email=email, password="wrongpassword"),
                self.db
            )
        self.assertEqual(cm.exception.status_code, 401)

        # 2. Login step 1 with correct password succeeds
        step1_res = await AuthController.login_step1(
            FarmerLoginRequest(email=email, password="password123"),
            self.db
        )
        self.assertIn("verification code has been sent", step1_res.message)

        login_otp = self.db.query(OTPCode).filter(
            OTPCode.email == email,
            OTPCode.purpose == "login",
            OTPCode.is_used == False
        ).first()
        self.assertIsNotNone(login_otp)
        self.assertEqual(len(login_otp.code), 6)

        # 3. Login step 2 with wrong code fails
        with self.assertRaises(HTTPException) as cm:
            AuthController.login_step2(
                LoginStep2Request(email=email, code="999999"),
                self.db
            )
        self.assertEqual(cm.exception.status_code, 400)

        # 4. Login step 2 with correct code succeeds and returns valid JWT
        token_res = AuthController.login_step2(
            LoginStep2Request(email=email, code=login_otp.code),
            self.db
        )
        self.assertEqual(token_res.token_type, "bearer")
        self.assertTrue(len(token_res.access_token) > 20)

        # Decode and verify token
        payload = jwt.decode(
            token_res.access_token,
            settings.JWT_SECRET_KEY,
            algorithms=[settings.JWT_ALGORITHM]
        )
        farmer = self.db.query(Farmer).filter(Farmer.email == email).first()
        self.assertEqual(int(payload.get("sub")), farmer.farmer_id)

        # 5. Reusing the login code fails
        with self.assertRaises(HTTPException) as cm:
            AuthController.login_step2(
                LoginStep2Request(email=email, code=login_otp.code),
                self.db
            )
        self.assertEqual(cm.exception.status_code, 400)


if __name__ == "__main__":
    unittest.main()
