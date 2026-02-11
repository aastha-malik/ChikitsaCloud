from pydantic import BaseModel
from uuid import UUID
from datetime import datetime
from typing import Optional, List

class MedicalRecordBase(BaseModel):
    title: str
    record_type: str # lab_report, prescription, scan_image, discharge_summary, other

class MedicalRecordCreate(MedicalRecordBase):
    pass

class MedicalRecordOut(MedicalRecordBase):
    id: UUID
    user_id: UUID
    file_path: str
    ai_insight: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True
