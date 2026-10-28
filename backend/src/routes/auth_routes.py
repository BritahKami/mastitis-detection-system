from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from src.config.database import get_db
from src.middleware.auth_middleware import get_current_farmer
from src.models.db_models import Farmer
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
from src.controllers.auth_controller import AuthController

router = APIRouter(prefix="/auth", tags=["Authentication & Profile"])


@router.post(
    "/register",
    response_model=MessageResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Register a new farmer account"
)
def register(
    payload: FarmerRegisterRequest,
    db: Session = Depends(get_db)
):
    """
    Registers a new farmer in the MySQL Farmer table with bcrypt-hashed credentials.
    """
    return AuthController.register_farmer(payload, db)


@router.post(
    "/login",
    response_model=TokenResponse,
    status_code=status.HTTP_200_OK,
    summary="Direct authenticate farmer and retrieve JWT token (Legacy)"
)
def login(
    payload: FarmerLoginRequest,
    db: Session = Depends(get_db)
):
    """
    Validates email and password, returning a signed JWT access token.
    """
    return AuthController.login_farmer(payload, db)


@router.post(
    "/login-step1",
    response_model=LoginStep1Response,
    status_code=status.HTTP_200_OK,
    summary="2FA Login Step 1: Validate credentials & dispatch OTP code"
)
async def login_step1(
    payload: FarmerLoginRequest,
    db: Session = Depends(get_db)
):
    """
    Validates farmer email and password, generates a 6-digit OTP code,
    stores it in the database with an expiration timestamp, and emails it to the farmer.
    """
    return await AuthController.login_step1(payload, db)


@router.post(
    "/login-step2",
    response_model=TokenResponse,
    status_code=status.HTTP_200_OK,
    summary="2FA Login Step 2: Verify OTP code & return JWT access token"
)
def login_step2(
    payload: LoginStep2Request,
    db: Session = Depends(get_db)
):
    """
    Verifies the submitted 6-digit OTP code against the database.
    If valid and unexpired, marks code as used and issues signed JWT access token.
    """
    return AuthController.login_step2(payload, db)


@router.post(
    "/forgot-password",
    response_model=MessageResponse,
    status_code=status.HTTP_200_OK,
    summary="Request password reset OTP code"
)
async def forgot_password(
    payload: ForgotPasswordRequest,
    db: Session = Depends(get_db)
):
    """
    Generates a secure 6-digit numeric OTP code for the requested registered email,
    stores it in the otp_codes table with expiration timestamp, and sends it via email.
    """
    return await AuthController.forgot_password(payload, db)


@router.post(
    "/verify-reset-code",
    response_model=MessageResponse,
    status_code=status.HTTP_200_OK,
    summary="Verify password reset OTP code"
)
def verify_reset_code(
    payload: VerifyResetCodeRequest,
    db: Session = Depends(get_db)
):
    """
    Checks validity and expiration of the supplied 6-digit password reset OTP code.
    """
    return AuthController.verify_reset_code(payload, db)


@router.post(
    "/reset-password",
    response_model=MessageResponse,
    status_code=status.HTTP_200_OK,
    summary="Reset account password with verified OTP"
)
def reset_password(
    payload: ResetPasswordRequest,
    db: Session = Depends(get_db)
):
    """
    Verifies reset OTP code, bcrypt hashes new password (min 8 chars),
    updates the password in the MySQL Farmer table, and sets is_used = TRUE on the OTP.
    """
    return AuthController.reset_password(payload, db)


@router.get(
    "/profile",
    response_model=FarmerProfileResponse,
    status_code=status.HTTP_200_OK,
    summary="Retrieve authenticated farmer profile"
)
def get_profile(
    current_farmer: Farmer = Depends(get_current_farmer),
    db: Session = Depends(get_db)
):
    """
    Returns profile information for the authenticated farmer along with
    the dynamic count of registered cows (`total_cows`).
    """
    return AuthController.get_farmer_profile(current_farmer, db)
