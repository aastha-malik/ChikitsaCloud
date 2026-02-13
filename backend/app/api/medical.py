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
    # 1️⃣ Fetch user profile from DB (Optional fallback)
    user = user_service.get_user_profile(db, data.user_id)

    # 2️⃣ Determine Age, Gender, Height, Weight with fallbacks
    age = data.age
    gender = data.gender
    height = data.height
    weight = data.weight
    name = "Guest"

    if user:
        name = user.name
        if age is None and user.date_of_birth:
            age = calculate_age(user.date_of_birth)
        if gender is None:
            gender = user.gender
        if height is None and user.height:
            height = float(user.height)
        if weight is None and user.weight:
            weight = float(user.weight)

    # 3️⃣ Determine Age, Gender, Height, Weight with fallbacks
    # We use defaults (30, Male, 170, 70) if nothing is found to ensure the endpoint always works
    age = age or 30
    gender = gender or "Male"
    height = height or 170
    weight = weight or 70

    patient_data = {
        "name": name,
        "age": age,
        "gender": gender,
        "height": height,
        "weight": weight,
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
