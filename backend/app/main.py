from fastapi import FastAPI
from app.database import engine, Base
from app.api import general, auth, users
# Import models here so they registers with Base before create_all
from app.models import user, emergency_contact 

# Create tables (Simplest way for SQLite to start)
Base.metadata.create_all(bind=engine)

app = FastAPI(title="Chikitsa Cloud API")

# Include routers
app.include_router(general.router)
app.include_router(auth.router)
app.include_router(users.router)
