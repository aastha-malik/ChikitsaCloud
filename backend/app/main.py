from fastapi import FastAPI
from app.database import engine, Base
from app.api import general, auth, users, medical_records
from app.api import family_access as family_access_api
# Import models here so they registers with Base before create_all
from app.models import user, emergency_contact, medical_record, family_access 

# Create tables (Simplest way for SQLite to start)
Base.metadata.create_all(bind=engine)

app = FastAPI(title="Chikitsa Cloud API")

# Include routers
app.include_router(general.router)
app.include_router(auth.router)
app.include_router(users.router)
app.include_router(medical_records.router)
app.include_router(family_access_api.router)
