from pydantic import BaseModel
from uuid import UUID

class MedicalInput(BaseModel):
    user_id: UUID
    height: float
    weight: float
    bp_systolic: float
    bp_diastolic: float
    spo2: float
    hemoglobin: float
    creatinine: float
    blood_sugar: float
    cholesterol: float
