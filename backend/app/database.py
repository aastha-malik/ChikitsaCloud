from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base

# PostgreSQL connection URL
SQLALCHEMY_DATABASE_URL = (
    "postgresql://postgres:chikitsa_cloud_password@db.lpzrzjforpbfahvsyscz.supabase.co:5432/postgres"
)

engine = create_engine(SQLALCHEMY_DATABASE_URL)

SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine
)

Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
