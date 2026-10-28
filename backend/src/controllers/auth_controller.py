from datetime import datetime, timedelta, timezone
import secrets
from sqlalchemy.orm import Session
from sqlalchemy import text
from fastapi import HTTPException, status
from src.config.config import settings
from src.models.db_models import Farmer, OTPCode
from src.models.schemas import (
    FarmerRegisterRequest,
    FarmerLoginRequest,
    TokenResponse,
    FarmerProfileResponse,
    MessageResponse,
    ForgotPasswordRequest,
    VerifyResetCodeRequest,
    ResetPasswordRequest,
    LoginStep1Response,
    LoginStep2Request,
)
from src.middleware.auth_middleware import hash_password, verify_password, create_access_token
from src.services.email_service import email_service


class AuthController:
    """
    Controller handling Farmer Authentication, 2FA, OTP verification, and Profile business logic.
    """

    @staticmethod
    def _generate_otp_code() -> str:
        """Generates a cryptographically secure 6-digit numeric OTP."""
        return f"{secrets.randbelow(1000000):06d}"

    @staticmethod
    def register_farmer(payload: FarmerRegisterRequest, db: Session) -> MessageResponse:
        """
        Registers a new farmer, hashes password with bcrypt, and commits to Farmer table.
        """
        # 1. Enforce unique email check
        existing_farmer = db.query(Farmer).filter(Farmer.email == payload.email).first()
        if existing_farmer:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="A farmer account with this email address already exists."
            )

        # 2. Hash password securely
        hashed_password = hash_password(payload.password)

        # 3. Create and persist new Farmer entity
        new_farmer = Farmer(
            fname=payload.fname.strip(),
            lname=payload.lname.strip(),
            email=payload.email.strip().lower(),
            password=hashed_password
        )
        db.add(new_farmer)
        db.commit()
        db.refresh(new_farmer)

        return MessageResponse(message="Farmer registered successfully.")

    @staticmethod
    def login_farmer(payload: FarmerLoginRequest, db: Session) -> TokenResponse:
        """
        Authenticates farmer credentials and returns a signed JWT access token (Legacy / Direct).
        """
        farmer = db.query(Farmer).filter(Farmer.email == payload.email.strip().lower()).first()
        if not farmer or not verify_password(payload.password, farmer.password):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid email or password credentials."
            )

        # Issue JWT token embedded with farmer_id in subject claim
        access_token = create_access_token(data={"sub": str(farmer.farmer_id)})
        return TokenResponse(access_token=access_token, token_type="bearer")

    @classmethod
    async def login_step1(cls, payload: FarmerLoginRequest, db: Session) -> LoginStep1Response:
        """
        Two-Factor Login Step 1:
        Validates credentials, generates 6-digit OTP code, saves it to otp_codes,
        and emails it to the user.
        """
        email = payload.email.strip().lower()
        farmer = db.query(Farmer).filter(Farmer.email == email).first()
        if not farmer or not verify_password(payload.password, farmer.password):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid email or password credentials."
            )

        # Invalidate any previously unconsumed login OTPs for this email
        db.query(OTPCode).filter(
            OTPCode.email == email,
            OTPCode.purpose == "login",
            OTPCode.is_used == False
        ).update({"is_used": True})

        # Generate fresh secure OTP code
        code = cls._generate_otp_code()
        expires_at = datetime.now(timezone.utc).replace(tzinfo=None) + timedelta(minutes=settings.OTP_EXPIRE_MINUTES)

        otp_record = OTPCode(
            email=email,
            code=code,
            purpose="login",
            expires_at=expires_at,
            is_used=False
        )
        db.add(otp_record)
        db.commit()

        # Send asynchronous 2FA email
        await email_service.send_otp_email(
            to_email=email,
            code=code,
            purpose="login",
            expire_minutes=settings.OTP_EXPIRE_MINUTES
        )

        return LoginStep1Response(
            message="A 6-digit verification code has been sent to your email.",
            email=email
        )

    @staticmethod
    def login_step2(payload: LoginStep2Request, db: Session) -> TokenResponse:
        """
        Two-Factor Login Step 2:
        Verifies the 6-digit OTP code, marks it used, and returns the signed JWT token.
        """
        email = payload.email.strip().lower()
        code = payload.code.strip()

        otp_record = db.query(OTPCode).filter(
            OTPCode.email == email,
            OTPCode.code == code,
            OTPCode.purpose == "login",
            OTPCode.is_used == False
        ).order_by(OTPCode.id.desc()).first()

        if not otp_record:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid verification code. Please check and try again."
            )

        if otp_record.expires_at < datetime.now(timezone.utc).replace(tzinfo=None):
            otp_record.is_used = True
            db.commit()
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Verification code has expired. Please request a new one."
            )

        # Mark OTP used
        otp_record.is_used = True
        db.commit()

        # Retrieve farmer and issue JWT token
        farmer = db.query(Farmer).filter(Farmer.email == email).first()
        if not farmer:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Farmer account not found."
            )

        access_token = create_access_token(data={"sub": str(farmer.farmer_id)})
        return TokenResponse(access_token=access_token, token_type="bearer")

    @classmethod
    async def forgot_password(cls, payload: ForgotPasswordRequest, db: Session) -> MessageResponse:
        """
        Requests password reset:
        Verifies account existence, generates 6-digit OTP code, saves to database,
        and emails the reset code to the user.
        """
        email = payload.email.strip().lower()
        farmer = db.query(Farmer).filter(Farmer.email == email).first()
        if not farmer:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="No registered account found with this email address."
            )

        # Invalidate any prior active password reset OTPs
        db.query(OTPCode).filter(
            OTPCode.email == email,
            OTPCode.purpose == "reset_password",
            OTPCode.is_used == False
        ).update({"is_used": True})

        code = cls._generate_otp_code()
        expires_at = datetime.now(timezone.utc).replace(tzinfo=None) + timedelta(minutes=settings.OTP_EXPIRE_MINUTES)

        otp_record = OTPCode(
            email=email,
            code=code,
            purpose="reset_password",
            expires_at=expires_at,
            is_used=False
        )
        db.add(otp_record)
        db.commit()

        # Send asynchronous password reset email
        await email_service.send_otp_email(
            to_email=email,
            code=code,
            purpose="reset_password",
            expire_minutes=settings.OTP_EXPIRE_MINUTES
        )

        return MessageResponse(message="A verification code has been sent to your email.")

    @staticmethod
    def verify_reset_code(payload: VerifyResetCodeRequest, db: Session) -> MessageResponse:
        """
        Validates whether the password reset OTP is correct and unexpired.
        """
        email = payload.email.strip().lower()
        code = payload.code.strip()

        otp_record = db.query(OTPCode).filter(
            OTPCode.email == email,
            OTPCode.code == code,
            OTPCode.purpose == "reset_password",
            OTPCode.is_used == False
        ).order_by(OTPCode.id.desc()).first()

        if not otp_record:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid verification code. Please check and try again."
            )

        if otp_record.expires_at < datetime.now(timezone.utc).replace(tzinfo=None):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Verification code has expired. Please request a new one."
            )

        return MessageResponse(message="Verification code is valid.")

    @staticmethod
    def reset_password(payload: ResetPasswordRequest, db: Session) -> MessageResponse:
        """
        Resets farmer's password after verifying OTP:
        Verifies code, ensures minimum 8 characters, hashes password with bcrypt,
        updates Farmer table, and marks the OTP as used.
        """
        email = payload.email.strip().lower()
        code = payload.code.strip()

        if len(payload.new_password) < 8:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="New password must be at least 8 characters long."
            )

        otp_record = db.query(OTPCode).filter(
            OTPCode.email == email,
            OTPCode.code == code,
            OTPCode.purpose == "reset_password",
            OTPCode.is_used == False
        ).order_by(OTPCode.id.desc()).first()

        if not otp_record:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid or already used verification code."
            )

        if otp_record.expires_at < datetime.now(timezone.utc).replace(tzinfo=None):
            otp_record.is_used = True
            db.commit()
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Verification code has expired. Please request a new one."
            )

        farmer = db.query(Farmer).filter(Farmer.email == email).first()
        if not farmer:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Farmer account not found."
            )

        # Hash and update password
        farmer.password = hash_password(payload.new_password)
        otp_record.is_used = True

        # Invalidate all remaining reset codes for this email
        db.query(OTPCode).filter(
            OTPCode.email == email,
            OTPCode.purpose == "reset_password"
        ).update({"is_used": True})

        db.commit()

        return MessageResponse(message="Password reset successfully. You can now log in.")

    @staticmethod
    def get_farmer_profile(current_farmer: Farmer, db: Session) -> FarmerProfileResponse:
        """
        Retrieves authenticated farmer profile alongside dynamically computed total_cows count.
        """
        query = text("""
            SELECT 
                f.farmer_id,
                f.fname,
                f.lname,
                f.email,
                COALESCE(COUNT(c.cow_id), 0) AS total_cows
            FROM Farmer f
            LEFT JOIN Cow c ON f.farmer_id = c.farmer_id
            WHERE f.farmer_id = :farmer_id
            GROUP BY f.farmer_id, f.fname, f.lname, f.email
        """)

        result = db.execute(query, {"farmer_id": current_farmer.farmer_id}).mappings().first()
        if not result:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Farmer record not found."
            )

        return FarmerProfileResponse(
            farmer_id=result["farmer_id"],
            fname=result["fname"],
            lname=result["lname"],
            email=result["email"],
            total_cows=int(result["total_cows"])
        )
