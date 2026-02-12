from fastapi import FastAPI
from app.core.config import settings
from fastapi.middleware.cors import CORSMiddleware
from app.api import general, auth, users, medical_records, hospitals, medical
from app.api import family_access as family_access_api

# Note: Use Alembic migrations for production schema management
# from app.database import engine, Base
# Base.metadata.create_all(bind=engine)


app = FastAPI(
    title=settings.PROJECT_NAME,
    debug=settings.DEBUG
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.BACKEND_CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(general.router)
app.include_router(auth.router)
app.include_router(users.router)
app.include_router(medical_records.router)
app.include_router(medical.router)         
app.include_router(family_access_api.router)
app.include_router(hospitals.router)
