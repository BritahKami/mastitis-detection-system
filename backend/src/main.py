import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI, status
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text
from src.config.config import settings
from src.config.database import SessionLocal
from src.services.ml_service import ml_service
from src.middleware.error_handler import register_exception_handlers
from src.routes.api_router import api_router

# Configure structured logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s"
)
logger = logging.getLogger("mds.main")


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Application lifespan context manager:
    - On startup: loads pre-trained Random Forest ML model into shared memory.
    - On shutdown: cleans up resources if needed.
    """
    logger.info("Starting Mastitis Detection System Backend...")
    ml_service.model_path = settings.ML_MODEL_PATH
    is_loaded = ml_service.load_model()
    if is_loaded:
        logger.info("Random Forest ML model successfully loaded into shared memory.")
    else:
        logger.warning("ML model operating in veterinary rule-based heuristic fallback mode.")

    yield

    logger.info("Shutting down Mastitis Detection System Backend...")


# Initialize FastAPI instance
app = FastAPI(
    title=settings.PROJECT_NAME,
    version="1.0.0",
    description=(
        "Production REST API connecting Flutter Mobile Client, "
        "ESP32 IoT Sensing Module, and Machine Learning Model for "
        "Mastitis Detection."
    ),
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan
)

# Register CORS Middleware for Flutter Mobile Clients (Android, iOS, Web)
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS if isinstance(settings.CORS_ORIGINS, list) else [settings.CORS_ORIGINS],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register Global Exception Handlers
register_exception_handlers(app)

# Mount Modular API Router under configured prefix (/api)
app.include_router(api_router, prefix=settings.API_V1_STR)


@app.get("/health", tags=["Health Check"], status_code=status.HTTP_200_OK)
def health_check():
    """
    Health check probe verifying server, database connection, and ML model status.
    """
    db_status = "healthy"
    try:
        db = SessionLocal()
        db.execute(text("SELECT 1"))
        db.close()
    except Exception as e:
        db_status = f"unhealthy: {str(e)}"

    return {
        "status": "healthy" if db_status == "healthy" else "degraded",
        "database": db_status,
        "ml_model_loaded": ml_service._is_loaded,
        "ml_model_path": settings.ML_MODEL_PATH
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "src.main:app",
        host=settings.HOST,
        port=settings.PORT,
        reload=settings.DEBUG
    )
