from pydantic import BaseModel
from uuid import UUID
from typing import Optional

class MedicalInput(BaseModel):
    user_id: UUID
    age: Optional[int] = None
    gender: Optional[str] = None
    height: Optional[float] = None
    weight: Optional[float] = None
    bp_systolic: float
    bp_diastolic: float
    spo2: float
    hemoglobin: float
    creatinine: float
    blood_sugar: float
    cholesterol: float
