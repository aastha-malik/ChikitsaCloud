import uuid
from sqlalchemy import Column, String, DateTime, ForeignKey, Date, Numeric, Text, ARRAY, Boolean
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base

class AuthUser(Base):
    __tablename__ = "auth_users"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email = Column(String, unique=True, index=True, nullable=False)
    password_hash = Column(String, nullable=True) # Nullable for OAuth
    
    auth_provider = Column(String, default="email", nullable=False)
    is_email_verified = Column(Boolean, default=False)
    email_verification_code = Column(String, nullable=True)
    email_verification_expires_at = Column(DateTime(timezone=True), nullable=True)

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now(), server_default=func.now())

    # Relationship
    # Relationship
    profile = relationship("UserProfile", back_populates="auth_user", uselist=False, cascade="all, delete-orphan")
    emergency_contacts = relationship("EmergencyContact", back_populates="auth_user", cascade="all, delete-orphan")
    medical_records = relationship("MedicalRecord", back_populates="auth_user", cascade="all, delete-orphan")



class UserProfile(Base):
    __tablename__ = "user_profiles"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("auth_users.id"), unique=True, nullable=False)
    
    name = Column(Text, nullable=False)
    date_of_birth = Column(Date, nullable=True)
    phone_country_code = Column(String, nullable=True) # e.g. "+91"
    phone_number = Column(Numeric, nullable=True) # numeric as requested
    
    gender = Column(String, nullable=True)
    blood_group = Column(String, nullable=True)
    height = Column(Numeric, nullable=True)
    weight = Column(Numeric, nullable=True)
    country = Column(String, nullable=True)
    
    allergies = Column(ARRAY(String), default=[])
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now(), server_default=func.now())

    # Relationship
    auth_user = relationship("AuthUser", back_populates="profile")
