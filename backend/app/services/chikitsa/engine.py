from .clinical_rules import ClinicalKnowledgeBase
from .schemas import EvaluationResult, SeverityColor
from app.ML.ml_model import ml_model_instance
from typing import Dict, Any, List

class ChikitsaEngine:
    def __init__(self):
        self.kb = ClinicalKnowledgeBase()

    def determine_severity(self, value, low, high, is_critical_metric=False):
        if low <= value <= high:
            return (
                SeverityColor.WHITE,
                "Normal",
                "Value is within the healthy range for your profile."
            )

        midpoint = (low + high) / 2
        deviation_pct = abs(value - midpoint) / midpoint * 100
        direction = "High" if value > high else "Low"

        if deviation_pct > 50 or (is_critical_metric and deviation_pct > 30):
            return (
                SeverityColor.PURPLE,
                f"Critically {direction}",
                "Immediate medical attention recommended."
            )

        if deviation_pct > 25:
            return (
                SeverityColor.RED,
                f"Significantly {direction}",
                "Requires clinical attention."
            )

        if deviation_pct > 10:
            return (
                SeverityColor.YELLOW,
                f"Moderately {direction}",
                "Suspicious deviation; monitoring advised."
            )

        return (
            SeverityColor.LIGHT_YELLOW,
            f"Slightly {direction}",
            "Minor deviation; lifestyle adjustment may help."
        )

    def evaluate_param(self, name: str, value: float, unit: str, patient_age: int, patient_gender: str, patient_bmi: float) -> EvaluationResult:
        low, high = None, None
        factors = []
        is_critical = False

        if name == "Systolic BP":
            low, high = self.kb.get_bp_range(patient_age)[0]
            is_critical = True
            factors.append(f"Age: {patient_age}")

        elif name == "Diastolic BP":
            low, high = self.kb.get_bp_range(patient_age)[1]
            is_critical = True
            factors.append(f"Age: {patient_age}")

        elif name == "Hemoglobin":
            low, high = self.kb.get_hemoglobin_range(patient_gender, patient_age)
            factors.append(f"Gender: {patient_gender}")

        elif name == "Creatinine":
            low, high = self.kb.get_creatinine_range(patient_gender)
            factors.append(f"Gender: {patient_gender}")

        elif name == "Blood Sugar (Fasting)":
            low, high = self.kb.get_glucose_range("Fasting")
            if patient_bmi > 25:
                factors.append(f"BMI: {patient_bmi:.2f} (Overweight risk factor)")

        elif name == "SpO2":
            low, high = 95, 100
            is_critical = True

        elif name == "Cholesterol":
            low, high = self.kb.get_cholesterol_range(patient_age)
            is_critical = True
            factors.append(f"Age: {patient_age}")

        if low is None:
            return EvaluationResult(
                parameter_name=name,
                patient_value=value,
                unit=unit,
                personalized_range="Unavailable",
                deviation_level="Unknown",
                severity_color=SeverityColor.YELLOW.value,
                explanation="No reference range available.",
                influencing_factors=[]
            )

        severity_enum, deviation_lvl, expl_base = self.determine_severity(
            value, low, high, is_critical
        )

        explanation = expl_base
        if severity_enum != SeverityColor.WHITE:
            explanation += f" {deviation_lvl} values may indicate physiological stress."
        else:
            explanation = "Excellent. Maintain current lifestyle."

        return EvaluationResult(
            parameter_name=name,
            patient_value=value,
            unit=unit,
            personalized_range=f"{low} - {high}",
            deviation_level=deviation_lvl,
            severity_color=severity_enum.value,
            explanation=explanation,
            influencing_factors=factors
        )

def run_chikitsa_engine(data: Dict[str, Any]):
    engine = ChikitsaEngine()
    patient_age = data.get("age", 30)
    patient_gender = data.get("gender", "Male")
    height = data.get("height", 170)
    weight = data.get("weight", 70)
    bmi = weight / ((height / 100) ** 2) if height > 0 else 0

    params = [
        ("Systolic BP", data.get("bp_systolic"), "mmHg"),
        ("Diastolic BP", data.get("bp_diastolic"), "mmHg"),
        ("SpO2", data.get("spo2"), "%"),
        ("Hemoglobin", data.get("hemoglobin"), "g/dL"),
        ("Creatinine", data.get("creatinine"), "mg/dL"),
        ("Blood Sugar (Fasting)", data.get("blood_sugar"), "mg/dL"),
        ("Cholesterol", data.get("cholesterol"), "mg/dL"),
    ]

    results = []
    for name, val, unit in params:
        if val is not None and val > 0:
            results.append(engine.evaluate_param(name, val, unit, patient_age, patient_gender, bmi))

    # ML Risk Prediction
    try:
        class PatientObj:
            def __init__(self, age, gender, h, w, b):
                self.age = age
                self.gender = gender
                self.height_cm = h
                self.weight_kg = w
                self.bmi = b
        
        patient = PatientObj(patient_age, patient_gender, height, weight, bmi)
        ml_input = {
            "Systolic BP": data.get("bp_systolic"),
            "Diastolic BP": data.get("bp_diastolic"),
            "Blood Sugar (Fasting)": data.get("blood_sugar"),
            "Cholesterol": data.get("cholesterol")
        }
        ml_risk = ml_model_instance.predict(patient, ml_input)
        risk_map = {0: "Low Risk", 1: "Moderate Risk", 2: "High Risk", 3: "Critical Risk"}
        risk_label = risk_map.get(ml_risk, "Unknown")
    except Exception:
        ml_risk = -1
        risk_label = "Error"

    return {
        "overall_health_risk": risk_label,
        "ml_risk_score": ml_risk,
        "flagged_parameters": [res.to_dict() for res in results if res.severity_color != SeverityColor.WHITE.value],
        "all_analysis": [res.to_dict() for res in results],
        "summary": f"Analysis complete. {len([r for r in results if r.severity_color != SeverityColor.WHITE.value])} parameter(s) flagged."
    }
