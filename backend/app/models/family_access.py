import uuid
from sqlalchemy import Column, String, DateTime, ForeignKey, Boolean, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base

class FamilyAccessRequest(Base):
    __tablename__ = "family_access_requests"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    requester_user_id = Column(UUID(as_uuid=True), ForeignKey("auth_users.id"), nullable=False)
    owner_user_id = Column(UUID(as_uuid=True), ForeignKey("auth_users.id"), nullable=False)
    
    status = Column(String, default="pending", nullable=False) # pending, accepted, rejected
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    responded_at = Column(DateTime(timezone=True), nullable=True)
    
    # Prevent duplicate pending requests
    __table_args__ = (
        UniqueConstraint('requester_user_id', 'owner_user_id', 'status', 
                        name='unique_pending_request'),
    )
    
    # Relationships
    requester = relationship("AuthUser", foreign_keys=[requester_user_id], backref="sent_access_requests")
    owner = relationship("AuthUser", foreign_keys=[owner_user_id], backref="received_access_requests")


class FamilyMedicalAccess(Base):
    __tablename__ = "family_medical_access"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    owner_user_id = Column(UUID(as_uuid=True), ForeignKey("auth_users.id"), nullable=False)
    viewer_user_id = Column(UUID(as_uuid=True), ForeignKey("auth_users.id"), nullable=False)
    
    can_view_medical_records = Column(Boolean, default=True, nullable=False)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Ensure one access record per owner-viewer pair
    __table_args__ = (
        UniqueConstraint('owner_user_id', 'viewer_user_id', 
                        name='unique_family_access'),
    )
    
    # Relationships
    owner = relationship("AuthUser", foreign_keys=[owner_user_id], backref="granted_access")
    viewer = relationship("AuthUser", foreign_keys=[viewer_user_id], backref="received_access")


class FamilyInviteToken(Base):
    __tablename__ = "family_invite_tokens"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    owner_user_id = Column(UUID(as_uuid=True), ForeignKey("auth_users.id"), nullable=False)
    
    invite_token = Column(String(64), unique=True, nullable=False, index=True)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    expires_at = Column(DateTime(timezone=True), nullable=False)
    
    is_used = Column(Boolean, default=False, nullable=False)
    used_by_user_id = Column(UUID(as_uuid=True), ForeignKey("auth_users.id"), nullable=True)
    used_at = Column(DateTime(timezone=True), nullable=True)
    
    # Relationship
    owner = relationship("AuthUser", foreign_keys=[owner_user_id], backref="invite_tokens")
    used_by = relationship("AuthUser", foreign_keys=[used_by_user_id])
