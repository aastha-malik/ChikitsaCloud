from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from uuid import UUID

from app.database import get_db
from app.services import user_service
from app.schemas.user import (
    UserProfileCreate,
    UserProfileUpdate,
    UserProfileOut,
    EmergencyContactCreate,
    EmergencyContactOut
)

router = APIRouter(prefix="/users", tags=["Users"])

# -------------------------------
# TEMP AUTH DEPENDENCY (NO JWT YET)
# -------------------------------
def get_current_user_id(user_id: UUID):
    return user_id


# -------- User Profile --------

@router.post("/profile", response_model=UserProfileOut)
def create_profile(
    profile: UserProfileCreate,
    user_id: UUID = Depends(get_current_user_id),
    db: Session = Depends(get_db)
):
    return user_service.create_user_profile(db, user_id, profile)


@router.get("/profile", response_model=UserProfileOut)
def get_profile(
    user_id: UUID = Depends(get_current_user_id),
    db: Session = Depends(get_db)
):
    profile = user_service.get_user_profile(db, user_id)
    if not profile:
        raise HTTPException(status_code=404, detail="Profile not found")
    return profile


@router.put("/profile", response_model=UserProfileOut)
def update_profile(
    profile: UserProfileUpdate,
    user_id: UUID = Depends(get_current_user_id),
    db: Session = Depends(get_db)
):
    return user_service.update_user_profile(db, user_id, profile)


# -------- Emergency Contacts --------

@router.post("/emergency-contacts", response_model=EmergencyContactOut)
def add_emergency_contact(
    contact: EmergencyContactCreate,
    user_id: UUID = Depends(get_current_user_id),
    db: Session = Depends(get_db)
):
    return user_service.create_emergency_contact(db, user_id, contact)


@router.get("/emergency-contacts", response_model=List[EmergencyContactOut])
def list_emergency_contacts(
    user_id: UUID = Depends(get_current_user_id),
    db: Session = Depends(get_db)
):
    return user_service.get_emergency_contacts(db, user_id)


@router.delete("/emergency-contacts/{contact_id}")
def delete_emergency_contact(
    contact_id: UUID,
    user_id: UUID = Depends(get_current_user_id),
    db: Session = Depends(get_db)
):
    return user_service.delete_emergency_contact(db, user_id, contact_id)
