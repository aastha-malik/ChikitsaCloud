from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from uuid import UUID

from app.database import get_db
from app.services import user_service
from app.api.deps import get_current_user
from app.models.user import AuthUser
from app.schemas.user import (
    UserProfileCreate,
    UserProfileUpdate,
    UserProfileOut,
    EmergencyContactCreate,
    EmergencyContactOut,
    EmergencyContactUpdate,
    ConsolidatedProfileOut,
    UserProfileUpdateConsolidated
)

router = APIRouter(prefix="/users", tags=["Users"])

@router.get("/search", response_model=UserProfileOut)
def search_user_by_email(
    email: str,
    db: Session = Depends(get_db)
):
    user = db.query(AuthUser).filter(AuthUser.email == email).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    profile = user_service.get_user_profile(db, user.id)
    if not profile:
        # Return a shell profile if they have an account but no profile yet
        return {"user_id": user.id, "name": email.split('@')[0]}
    
    return profile

# -------- Consolidated Profile --------

@router.get("/profile", response_model=ConsolidatedProfileOut)
def get_full_profile(
    current_user: AuthUser = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    profile = user_service.get_user_profile(db, current_user.id)
    if not profile:
        # Create an empty profile if none exists
        profile = user_service.create_user_profile(db, current_user.id, UserProfileCreate(name=current_user.email.split('@')[0]))
    
    emergency_contacts = user_service.get_emergency_contacts(db, current_user.id)
    
    return {
        "personal_details": profile,
        "emergency_contacts": emergency_contacts,
        "allergies": profile.allergies
    }

@router.put("/profile", response_model=ConsolidatedProfileOut)
def update_full_profile(
    update_data: UserProfileUpdateConsolidated,
    current_user: AuthUser = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if update_data.personal_details:
        user_service.update_user_profile(db, current_user.id, update_data.personal_details)
    
    if update_data.emergency_contact:
        user_service.update_emergency_contact(db, current_user.id, update_data.emergency_contact)
        
    profile = user_service.get_user_profile(db, current_user.id)
    emergency_contacts = user_service.get_emergency_contacts(db, current_user.id)
    
    return {
        "personal_details": profile,
        "emergency_contacts": emergency_contacts,
        "allergies": profile.allergies
    }

# -------- Emergency Contacts --------

@router.post("/emergency-contacts", response_model=EmergencyContactOut)
def add_emergency_contact(
    contact: EmergencyContactCreate,
    current_user: AuthUser = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    return user_service.create_emergency_contact(db, current_user.id, contact)

@router.get("/emergency-contacts", response_model=List[EmergencyContactOut])
def list_emergency_contacts(
    current_user: AuthUser = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    return user_service.get_emergency_contacts(db, current_user.id)

@router.put("/emergency-contacts/{contact_id}", response_model=EmergencyContactOut)
def update_emergency_contact(
    contact_id: UUID,
    contact_data: EmergencyContactUpdate,
    current_user: AuthUser = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    return user_service.update_emergency_contact_by_id(db, current_user.id, contact_id, contact_data)

@router.delete("/emergency-contacts/{contact_id}")
def delete_emergency_contact(
    contact_id: UUID,
    current_user: AuthUser = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    return user_service.delete_emergency_contact(db, current_user.id, contact_id)
