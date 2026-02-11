from pydantic import BaseModel
from uuid import UUID
from datetime import datetime
from typing import List

class MedicalRecordBase(BaseModel):
    record_category: str

class MedicalRecordCreate(MedicalRecordBase):
    pass

class MedicalRecordOut(MedicalRecordBase):
    id: UUID
    user_id: UUID
    file_path: str
    file_type: str
    original_filename: str
    uploaded_at: datetime

    class Config:
        from_attributes = True

class MedicalRecordList(BaseModel):
    id: UUID
    record_category: str
    file_type: str
    uploaded_at: datetime
    original_filename: str

    class Config:
        from_attributes = True
