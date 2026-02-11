from pydantic import BaseModel
from typing import Optional, List
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
class EmergencyContactBase(BaseModel):
    name: str
    relation: Optional[str] = None
    phone_country_code: Optional[str] = None
    phone_number: Optional[int] = None

class EmergencyContactCreate(EmergencyContactBase):
    pass

class EmergencyContactOut(EmergencyContactBase):
    id: UUID
    user_id: UUID
    class Config:
        from_attributes = True
