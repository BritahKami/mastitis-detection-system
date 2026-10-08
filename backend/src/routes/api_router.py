from fastapi import APIRouter
from src.routes.auth_routes import router as auth_router
from src.routes.cow_routes import router as cow_router
from src.routes.test_routes import router as test_router
from src.routes.iot_routes import router as iot_router
from src.routes.alert_routes import router as alert_router

api_router = APIRouter()

# Register modular sub-routers
api_router.include_router(auth_router)
api_router.include_router(cow_router)
api_router.include_router(test_router)
api_router.include_router(iot_router)
api_router.include_router(alert_router)
