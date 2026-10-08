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
    MessageResponse
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
    summary="Authenticate farmer and retrieve JWT token"
)
def login(
    payload: FarmerLoginRequest,
    db: Session = Depends(get_db)
):
    """
    Validates email and password, returning a signed JWT access token.
    """
    return AuthController.login_farmer(payload, db)


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
