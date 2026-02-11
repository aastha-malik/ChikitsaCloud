from pydantic import BaseModel
from typing import Optional, List, Literal
from datetime import date
from uuid import UUID

# --- Profile Schemas ---
class UserProfileBase(BaseModel):
    name: str
    date_of_birth: Optional[date] = None
    gender: Optional[str] = None
    blood_group: Optional[str] = None
    phone_country_code: Optional[str] = None
    phone_number: Optional[int] = None
    height: Optional[float] = None
    weight: Optional[float] = None
    country: Optional[str] = None
    allergies: List[str] = []

class UserProfileCreate(UserProfileBase):
    pass

class UserProfileUpdate(UserProfileBase):
    name: Optional[str] = None # Name is optional in update

class UserProfileOut(UserProfileBase):
    id: UUID
    user_id: UUID
    class Config:
        from_attributes = True

# --- Emergency Contact Schemas ---
RELATIONSHIP_TYPES = Literal["Parent/Guardian", "Partner", "Child", "Friend"]

class EmergencyContactBase(BaseModel):
    name: str
    relation: str # Relaxed for reading
    phone_country_code: Optional[str] = None
    phone_number: Optional[int] = None

class EmergencyContactCreate(BaseModel):
    name: str
    relation: RELATIONSHIP_TYPES # Strict for writing
    phone_country_code: Optional[str] = None
    phone_number: Optional[int] = None

class EmergencyContactOut(EmergencyContactBase):
    id: UUID
    user_id: UUID
    class Config:
        from_attributes = True

class EmergencyContactUpdate(BaseModel):
    name: Optional[str] = None
    relation: Optional[RELATIONSHIP_TYPES] = None # Strict for updating
    phone_country_code: Optional[str] = None
    phone_number: Optional[int] = None

# --- Consolidated Profile Schema ---
class ConsolidatedProfileOut(BaseModel):
    personal_details: UserProfileOut
    emergency_contacts: List[EmergencyContactOut]
    allergies: List[str]

class UserProfileUpdateConsolidated(BaseModel):
    personal_details: Optional[UserProfileUpdate] = None
    emergency_contact: Optional[EmergencyContactUpdate] = None
