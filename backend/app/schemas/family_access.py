from pydantic import BaseModel
from uuid import UUID
from datetime import datetime
from typing import Optional, List

# --- Access Request Schemas ---
class AccessRequestCreate(BaseModel):
    owner_user_id: UUID

class AccessRequestResponse(BaseModel):
    accept: bool  # True = accept, False = reject

class AccessRequestOut(BaseModel):
    id: UUID
    requester_user_id: UUID
    owner_user_id: UUID
    status: str
    created_at: datetime
    responded_at: Optional[datetime] = None
    
    requester_name: Optional[str] = None
    requester_email: Optional[str] = None
    owner_name: Optional[str] = None
    owner_email: Optional[str] = None

    class Config:
        from_attributes = True

# --- Family Access Schemas ---
class FamilyAccessOut(BaseModel):
    id: UUID
    owner_user_id: UUID
    viewer_user_id: UUID
    can_view_medical_records: bool
    created_at: datetime
    
    owner_name: Optional[str] = None
    owner_email: Optional[str] = None
    viewer_name: Optional[str] = None
    viewer_email: Optional[str] = None
    
    class Config:
        from_attributes = True

# --- Invite Token Schemas ---
class InviteTokenCreate(BaseModel):
    expires_in_hours: int = 24  # Default 24 hours

class InviteTokenOut(BaseModel):
    invite_token: str
    expires_at: datetime
    created_at: datetime
    
    class Config:
        from_attributes = True

class InviteTokenRedeem(BaseModel):
    invite_token: str
