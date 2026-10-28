from datetime import datetime
from typing import Optional, List, Any
from pydantic import BaseModel, EmailStr, Field


# =============================================================================
# Generic & Message Schemas
# =============================================================================

class MessageResponse(BaseModel):
    message: str


# =============================================================================
# Farmer Authentication & Profile Schemas
# =============================================================================

class FarmerRegisterRequest(BaseModel):
    fname: str = Field(..., min_length=1, max_length=50, description="Farmer first name")
    lname: str = Field(..., min_length=1, max_length=50, description="Farmer last name")
    email: EmailStr = Field(..., description="Unique email address")
    password: str = Field(..., min_length=6, max_length=100, description="Password (min 6 chars)")


class FarmerLoginRequest(BaseModel):
    email: EmailStr = Field(..., description="Registered email address")
    password: str = Field(..., description="Account password")


class LoginStep1Response(BaseModel):
    message: str
    email: str


class LoginStep2Request(BaseModel):
    email: EmailStr = Field(..., description="Registered email address")
    code: str = Field(..., min_length=6, max_length=6, description="6-digit OTP code")


class ForgotPasswordRequest(BaseModel):
    email: EmailStr = Field(..., description="Registered email address to receive reset code")


class VerifyResetCodeRequest(BaseModel):
    email: EmailStr = Field(..., description="Registered email address")
    code: str = Field(..., min_length=6, max_length=6, description="6-digit OTP code")


class ResetPasswordRequest(BaseModel):
    email: EmailStr = Field(..., description="Registered email address")
    code: str = Field(..., min_length=6, max_length=6, description="6-digit OTP code")
    new_password: str = Field(..., min_length=8, max_length=100, description="New password (min 8 characters)")


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"


class FarmerProfileResponse(BaseModel):
    farmer_id: int
    fname: str
    lname: str
    email: str
    total_cows: int

    class Config:
        from_attributes = True


# =============================================================================
# Cow Management Schemas
# =============================================================================

class CowRegisterRequest(BaseModel):
    cow_tag: str = Field(..., min_length=1, max_length=20, description="Unique tag/ear tag number")
    breed: str = Field(..., min_length=1, max_length=50, description="Breed of the cow")
    age: int = Field(..., ge=0, le=30, description="Age in years")
    health_status: str = Field(default="Pending", description="Initial health status")


class CowResponse(BaseModel):
    cow_id: int
    farmer_id: int
    cow_tag: str
    breed: str
    age: int
    health_status: str = "Pending"

    class Config:
        from_attributes = True


class HistoricalTestRecord(BaseModel):
    reading_id: int
    result_id: Optional[int] = None
    temperature: float
    pH: float
    electrical_conductivity: float
    reading_time: datetime
    prediction: Optional[str] = None
    detection_time: Optional[datetime] = None

    class Config:
        from_attributes = True


class CowDetailResponse(BaseModel):
    cow_id: int
    cow_tag: str
    breed: str
    age: int
    health_status: str
    history: List[HistoricalTestRecord]

    class Config:
        from_attributes = True


# =============================================================================
# Asynchronous Diagnostic Testing Schemas
# =============================================================================

class TestInitiationResponse(BaseModel):
    message: str
    cow_id: int
    health_status: str
    timestamp: datetime


class TestPollPendingResponse(BaseModel):
    status: str = "Pending"
    cow_id: int
    message: str


class LatestResultPayload(BaseModel):
    result_id: int
    reading_id: int
    temperature: float
    pH: float
    electrical_conductivity: float
    reading_time: datetime
    prediction: str
    detection_time: datetime


class TestPollCompletedResponse(BaseModel):
    status: str = "Completed"
    cow_id: int
    cow_tag: str
    health_status: str
    result: LatestResultPayload


# =============================================================================
# IoT ESP32 Telemetry & Inference Schemas
# =============================================================================

class IoTSensorReadingRequest(BaseModel):
    cow_id: int = Field(..., gt=0, description="Target cow ID undergoing test")
    temperature: float = Field(..., ge=0.0, le=45.0, description="Milk temperature in Celsius")
    pH: float = Field(..., ge=4.0, le=10.0, description="Milk pH value")
    electrical_conductivity: float = Field(..., ge=1.0, le=15.0, description="Conductivity in mS/cm")


class IoTProcessingResponse(BaseModel):
    status: str
    reading_id: int
    result_id: int
    prediction: str
    cow_health_status: str


# =============================================================================
# Alert & Notification Schemas
# =============================================================================

class AlertResponse(BaseModel):
    alert_id: int
    result_id: int
    cow_tag: Optional[str] = None
    message: str
    status: str
    send_time: datetime

    class Config:
        from_attributes = True


class AlertReadResponse(BaseModel):
    message: str
    alert_id: int


class AlertBulkReadResponse(BaseModel):
    message: str
    updated_count: int
