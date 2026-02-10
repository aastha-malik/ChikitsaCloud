from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from uuid import UUID

from app.database import get_db
from app.services import user_service
from app.services.chikitsa.engine import run_chikitsa_engine
from app.utils.age import calculate_age
from app.schemas.medical import MedicalInput

router = APIRouter(prefix="/medical", tags=["Medical"])


@router.post("/analyze")
def analyze_medical_data(
    data: MedicalInput,
    db: Session = Depends(get_db)
):
    # 1️⃣ Fetch user profile from DB
    user = user_service.get_user_profile(db, data.user_id)

    if not user:
        raise HTTPException(status_code=404, detail="User profile not found")

    if not user.date_of_birth or not user.gender:
        raise HTTPException(
            status_code=400,
            detail="User profile incomplete (DOB or gender missing)"
        )

    # 2️⃣ Calculate age
    age = calculate_age(user.date_of_birth)

    # 3️⃣ Merge DB data + input data
    patient_data = {
        "name": user.name,
        "age": age,
        "gender": user.gender,
        "height": data.height,
        "weight": data.weight,
        "bp_systolic": data.bp_systolic,
        "bp_diastolic": data.bp_diastolic,
        "spo2": data.spo2,
        "hemoglobin": data.hemoglobin,
        "creatinine": data.creatinine,
        "blood_sugar": data.blood_sugar,
        "cholesterol": data.cholesterol
    }

    # 4️⃣ Run CHIKITSACLOUD engine
    return run_chikitsa_engine(patient_data)
