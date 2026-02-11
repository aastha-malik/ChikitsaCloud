from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.database import engine, Base
from app.api import general, auth, users, medical_records, hospitals, medical
from app.api import family_access as family_access_api

# ... (models and table creation)
Base.metadata.create_all(bind=engine)

app = FastAPI(title="Chikitsa Cloud API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(general.router)
app.include_router(auth.router)
app.include_router(users.router)
app.include_router(medical_records.router)
app.include_router(medical.router)          # 🟢 NEW
app.include_router(family_access_api.router)
app.include_router(hospitals.router)
