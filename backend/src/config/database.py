from typing import Generator
from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker, Session
from src.config.config import settings

# Configure SQLAlchemy engine with MySQL connection pooling
engine = create_engine(
    settings.DATABASE_URL,
    pool_pre_ping=True,       # Validates connection health before issuing queries
    pool_size=10,              # Persistent connection pool size
    max_overflow=20,           # Maximum extra connections allowed during traffic spikes
    pool_recycle=3600,         # Recycles connections every hour to avoid MySQL timeout
    echo=settings.DEBUG
)

# Thread-safe database session factory
SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine
)

# Declarative base class for ORM models
Base = declarative_base()


def get_db() -> Generator[Session, None, None]:
    """
    FastAPI dependency yielding an isolated database session per request.
    Guarantees session closure upon request completion or exception.
    """
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
