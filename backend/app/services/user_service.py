from sqlalchemy.orm import Session
from app.models.user import UserProfile
from app.models.emergency_contact import EmergencyContact
from app.schemas.user import UserProfileCreate, UserProfileUpdate, EmergencyContactCreate
from uuid import UUID
from fastapi import HTTPException, status

# --- User Profile Logic ---
def get_user_profile(db: Session, user_id: UUID):
    return db.query(UserProfile).filter(UserProfile.user_id == user_id).first()

def create_user_profile(db: Session, user_id: UUID, profile_data: UserProfileCreate):
    existing_profile = get_user_profile(db, user_id)
    if existing_profile:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, 
            detail="Profile already exists"
        )
    
    new_profile = UserProfile(user_id=user_id, **profile_data.model_dump())
    db.add(new_profile)
    db.commit()
    db.refresh(new_profile)
    return new_profile

def update_user_profile(db: Session, user_id: UUID, profile_data: UserProfileUpdate):
    profile = get_user_profile(db, user_id)
    if not profile:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, 
            detail="Profile not found"
        )
    
    # Update only provided fields
    update_data = profile_data.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(profile, key, value)
        
    db.add(profile)
    db.commit()
    db.refresh(profile)
    return profile

# --- Emergency Contact Logic ---
def get_emergency_contacts(db: Session, user_id: UUID):
    return db.query(EmergencyContact).filter(EmergencyContact.user_id == user_id).all()

def create_emergency_contact(db: Session, user_id: UUID, contact_data: EmergencyContactCreate):
    new_contact = EmergencyContact(user_id=user_id, **contact_data.model_dump())
    db.add(new_contact)
    db.commit()
    db.refresh(new_contact)
    return new_contact

def delete_emergency_contact(db: Session, user_id: UUID, contact_id: UUID):
    contact = db.query(EmergencyContact).filter(
        EmergencyContact.id == contact_id, 
        EmergencyContact.user_id == user_id
    ).first()
    
    if not contact:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, 
            detail="Contact not found or does not belong to user"
        )
        
    db.delete(contact)
    db.commit()
    return {"message": "Emergency contact deleted successfully"}

def update_emergency_contact(db: Session, user_id: UUID, contact_data):
    # This might be deprecated soon if we use update_by_id
    contact = db.query(EmergencyContact).filter(EmergencyContact.user_id == user_id).first()
    
    update_data = contact_data.model_dump(exclude_unset=True)
    if not contact:
        # Create new if none exists
        contact = EmergencyContact(user_id=user_id, **update_data)
        db.add(contact)
    else:
        # Update existing
        for key, value in update_data.items():
            setattr(contact, key, value)
        db.add(contact)
        
    db.commit()
    db.refresh(contact)
    return contact

def update_emergency_contact_by_id(db: Session, user_id: UUID, contact_id: UUID, contact_data):
    contact = db.query(EmergencyContact).filter(
        EmergencyContact.id == contact_id,
        EmergencyContact.user_id == user_id
    ).first()
    
    if not contact:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Contact not found or does not belong to user"
        )
        
    update_data = contact_data.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(contact, key, value)
        
    db.add(contact)
    db.commit()
    db.refresh(contact)
    return contact
