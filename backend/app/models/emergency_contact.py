import uuid
from sqlalchemy import Column, String, DateTime, ForeignKey, Numeric, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base

class EmergencyContact(Base):
    __tablename__ = "emergency_contacts"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("auth_users.id"), nullable=False)
    
    name = Column(Text, nullable=False)
    relation = Column(String, nullable=True)
    phone_country_code = Column(String, nullable=True) # e.g. "+91"
    phone_number = Column(Numeric, nullable=True) # numeric as requested
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now(), server_default=func.now())
    
    # Relationship
    auth_user = relationship("AuthUser", back_populates="emergency_contacts")
