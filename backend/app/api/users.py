from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from uuid import UUID

from app.database import get_db
from app.services import user_service
from app.schemas.user import UserProfileCreate, UserProfileUpdate, UserProfileOut, EmergencyContactCreate, EmergencyContactOut
from app.models.user import AuthUser

# TODO: Replace with real `get_current_user` dependency when implementing JWT
# For now, we mock it by passing a user_id or assuming the latest created user
# In production, this MUST use `dependencies=[Depends(get_current_user)]`

router = APIRouter(prefix="/users", tags=["Users"])

# --- Mock Auth Dependency ---
def get_current_user_id():
    # TEMPORARY: In real app, extracting from JWT token
    # For testing without JWT, the user will need to provide this or we hardcode for dev
    raise HTTPException(status_code=401, detail="Authentication required (Not implemented yet)")

# Use this to inject user_id via query param for TESTING ONLY until JWT is ready
# In Phase 1.3 we added JWT logic but didn't hook it up to endpoints fully yet.
# Ideally, we should parse the "Authorization: Bearer <token>" header here.

# --- User Profile Endpoints ---

@router.post("/profile", response_model=UserProfileOut)
def create_profile(
    profile: UserProfileCreate, 
    user_id: UUID, # Passing mainly for testing convenience now
    db: Session = Depends(get_db)
):
    return user_service.create_user_profile(db, user_id, profile)

@router.get("/profile", response_model=UserProfileOut)
def get_profile(user_id: UUID, db: Session = Depends(get_db)):
    profile = user_service.get_user_profile(db, user_id)
    if not profile:
        raise HTTPException(status_code=404, detail="Profile not found")
    return profile

@router.put("/profile", response_model=UserProfileOut)
def update_profile(
    profile: UserProfileUpdate, 
    user_id: UUID, # Passing mainly for testing convenience now
    db: Session = Depends(get_db) 
):
    return user_service.update_user_profile(db, user_id, profile)

# --- Emergency Contact Endpoints ---

@router.post("/emergency-contacts", response_model=EmergencyContactOut)
def add_emergency_contact(
    contact: EmergencyContactCreate, 
    user_id: UUID, 
    db: Session = Depends(get_db)
):
    return user_service.create_emergency_contact(db, user_id, contact)

@router.get("/emergency-contacts", response_model=List[EmergencyContactOut])
def list_emergency_contacts(user_id: UUID, db: Session = Depends(get_db)):
    return user_service.get_emergency_contacts(db, user_id)

@router.delete("/emergency-contacts/{contact_id}")
def delete_emergency_contact(
    contact_id: UUID, 
    user_id: UUID, 
    db: Session = Depends(get_db)
):
    return user_service.delete_emergency_contact(db, user_id, contact_id)
