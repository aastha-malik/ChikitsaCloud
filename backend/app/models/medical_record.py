import uuid
from sqlalchemy import Column, String, DateTime, ForeignKey, Text, Enum
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base

class MedicalRecord(Base):
    __tablename__ = "medical_records"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("auth_users.id"), nullable=False)
    
    title = Column(String, nullable=False)
    record_type = Column(String, nullable=False)  # lab_report, prescription, scan_image, discharge_summary, other
    file_path = Column(Text, nullable=False)
    ai_insight = Column(Text, nullable=True)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationship
    auth_user = relationship("AuthUser", back_populates="medical_records")
