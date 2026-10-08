import logging
from fastapi import FastAPI, Request, status
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from sqlalchemy.exc import SQLAlchemyError, IntegrityError

logger = logging.getLogger("mds.error_handler")


def register_exception_handlers(app: FastAPI):
    """
    Registers global exception handlers for consistent API error responses.
    """

    @app.exception_handler(RequestValidationError)
    async def validation_exception_handler(request: Request, exc: RequestValidationError):
        logger.warning(f"Validation error on {request.method} {request.url.path}: {exc.errors()}")
        return JSONResponse(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            content={
                "error": "Validation Error",
                "detail": exc.errors(),
                "path": request.url.path
            }
        )

    @app.exception_handler(IntegrityError)
    async def db_integrity_error_handler(request: Request, exc: IntegrityError):
        logger.error(f"Database integrity conflict on {request.method} {request.url.path}: {str(exc.orig)}")
        return JSONResponse(
            status_code=status.HTTP_409_CONFLICT,
            content={
                "error": "Database Conflict",
                "detail": "A database constraint or uniqueness violation occurred.",
                "path": request.url.path
            }
        )

    @app.exception_handler(SQLAlchemyError)
    async def db_general_error_handler(request: Request, exc: SQLAlchemyError):
        logger.error(f"Database error on {request.method} {request.url.path}: {str(exc)}")
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content={
                "error": "Database Error",
                "detail": "An internal database error occurred. Transaction was rolled back.",
                "path": request.url.path
            }
        )

    @app.exception_handler(Exception)
    async def generic_exception_handler(request: Request, exc: Exception):
        logger.exception(f"Unhandled exception on {request.method} {request.url.path}: {str(exc)}")
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content={
                "error": "Internal Server Error",
                "detail": "An unexpected error occurred processing your request.",
                "path": request.url.path
            }
        )
