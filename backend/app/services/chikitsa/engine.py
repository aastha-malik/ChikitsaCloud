from app.ML.ml_model import ml_model_instance

def run_chikitsa_engine(data: dict):
    """
    Evaluates patient medical data and returns health risks and flags.
    """
    flags = []
    risk_score = 0
    
    # 1. Blood Pressure Analysis
    sys = data.get("bp_systolic")
    dia = data.get("bp_diastolic")
    if sys and dia:
        if sys >= 140 or dia >= 90:
            flags.append({
                "parameter": "Blood Pressure",
                "severity": "High",
                "explanation": f"BP is high ({sys}/{dia}). Normal range is around 120/80."
            })
            risk_score += 2
        elif sys <= 90 or dia <= 60:
            flags.append({
                "parameter": "Blood Pressure",
                "severity": "Low",
                "explanation": f"BP is low ({sys}/{dia}). May cause dizziness."
            })
            risk_score += 1

    # 2. SpO2 Analysis
    spo2 = data.get("spo2")
    if spo2 and spo2 < 95:
        flags.append({
            "parameter": "Oxygen Saturation (SpO2)",
            "severity": "Warning",
            "explanation": f"SpO2 is {spo2}%. Below 95% indicates potential respiratory issues."
        })
        risk_score += 2

    # 3. Hemoglobin Analysis
    hb = data.get("hemoglobin")
    gender = data.get("gender", "").lower()
    if hb:
        if (gender == "female" and hb < 12) or (gender == "male" and hb < 13.5) or hb < 12:
            flags.append({
                "parameter": "Hemoglobin",
                "severity": "Warning",
                "explanation": f"Hemoglobin is low ({hb} g/dL). Potential signs of anemia."
            })
            risk_score += 1

    # 4. Blood Sugar Analysis
    sugar = data.get("blood_sugar")
    if sugar and sugar > 140:
        flags.append({
            "parameter": "Blood Sugar",
            "severity": "High",
            "explanation": f"Blood sugar is elevated ({sugar} mg/dL). Monitor your intake."
        })
        risk_score += 2

    # 5. Cholesterol Analysis
    cholest = data.get("cholesterol")
    if cholest and cholest > 200:
        flags.append({
            "parameter": "Total Cholesterol",
            "severity": "Warning",
            "explanation": f"Cholesterol is high ({cholest} mg/dL). Consider a heart-healthy diet."
        })
        risk_score += 1

    # 6. ML Risk Prediction
    try:
        class TempPatient:
            def __init__(self, data):
                self.age = data.get("age")
                self.gender = data.get("gender")
                self.height_cm = data.get("height")
                self.weight_kg = data.get("weight")
                self.bmi = (
                    data.get("weight") / ((data.get("height") / 100) ** 2)
                    if data.get("height") else 0
                )

        patient_obj = TempPatient(data)

        ml_values = {
            "Systolic BP": data.get("bp_systolic"),
            "Diastolic BP": data.get("bp_diastolic"),
            "Blood Sugar (Fasting)": data.get("blood_sugar"),
            "Cholesterol": data.get("cholesterol")
        }

        ml_prediction = ml_model_instance.predict(patient_obj, ml_values)

    except Exception as e:
        ml_prediction = None

    # Overall Risk Assessment
    if risk_score == 0:
        risk_level = "Low"
    elif risk_score <= 2:
        risk_level = "Mild"
    elif risk_score <= 4:
        risk_level = "Moderate"
    else:
        risk_level = "High"

    return {
        "overall_health_risk": risk_level,
        "ml_risk_prediction": ml_prediction,
        "flagged_parameters": flags,
        "summary": f"Analysis complete for {data.get('name', 'Patient')}. {len(flags)} parameter(s) flagged."
    }
