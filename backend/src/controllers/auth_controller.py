from sqlalchemy.orm import Session
from sqlalchemy import text
from fastapi import HTTPException, status
from src.models.db_models import Farmer
from src.models.schemas import (
    FarmerRegisterRequest,
    FarmerLoginRequest,
    TokenResponse,
    FarmerProfileResponse,
    MessageResponse
)
from src.middleware.auth_middleware import hash_password, verify_password, create_access_token


class AuthController:
    """
    Controller handling Farmer Authentication and Profile business logic.
    """

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
        Authenticates farmer credentials and returns a signed JWT access token.
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
