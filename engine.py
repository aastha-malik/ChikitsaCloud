from medical_schema import (
    PatientDemographics, MedicalParameter, EvaluationResult, SeverityColor
)
from clinical_rules import ClinicalKnowledgeBase


class ChikitsaEngine:
    def __init__(self):
        self.kb = ClinicalKnowledgeBase()

    def determine_severity(self, value, low, high, is_critical_metric=False):
        """
        Determines severity based on deviation from personalized range.
        """
        if low <= value <= high:
            return (
                SeverityColor.WHITE,
                "Normal",
                "Value is within the healthy range for your profile."
            )

        midpoint = (low + high) / 2
        deviation_pct = abs(value - midpoint) / midpoint * 100
        direction = "High" if value > high else "Low"

        # Extreme deviation
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

    def evaluate(self, patient: PatientDemographics, param: MedicalParameter) -> EvaluationResult:
        low, high = None, None
        factors = []
        is_critical = False

        

        if param.name == "Systolic BP":
            low, high = self.kb.get_bp_range(patient.age)[0]
            is_critical = True
            factors.append(f"Age: {patient.age}")

        elif param.name == "Diastolic BP":
            low, high = self.kb.get_bp_range(patient.age)[1]
            is_critical = True
            factors.append(f"Age: {patient.age}")

        elif param.name == "Hemoglobin":
            low, high = self.kb.get_hemoglobin_range(patient.gender, patient.age)
            factors.append(f"Gender: {patient.gender}")

        elif param.name == "Creatinine":
            low, high = self.kb.get_creatinine_range(patient.gender)
            factors.append(f"Gender: {patient.gender}")

        elif param.name == "Blood Sugar (Fasting)":
            low, high = self.kb.get_glucose_range("Fasting")
            if patient.bmi > 25:
                factors.append(f"BMI: {patient.bmi} (Overweight risk factor)")

        elif param.name == "SpO2":
            low, high = 95, 100
            is_critical = True

            if param.value < 88:
                return EvaluationResult(
                    parameter_name=param.name,
                    patient_value=param.value,
                    unit=param.unit,
                    personalized_range=f"{low} - {high}",
                    deviation_level="Critically Low",
                    severity_color=SeverityColor.PURPLE.value,
                    explanation="Oxygen saturation is dangerously low. Emergency attention advised.",
                    influencing_factors=["Vital Sign"]
                )

        elif param.name == "Cholesterol":
            low, high = self.kb.get_cholesterol_range(patient.age)
            is_critical = True
            factors.append(f"Age: {patient.age}")

        else:
            return EvaluationResult(
                param.name,
                param.value,
                param.unit,
                "Unavailable",
                "Unknown",
                SeverityColor.YELLOW.value,
                "No reference range available for this parameter.",
                []
            )

        

        severity_enum, deviation_lvl, expl_base = self.determine_severity(
            param.value, low, high, is_critical
        )

        
        if param.name == "Creatinine" and severity_enum == SeverityColor.RED:
            midpoint = (low + high) / 2
            deviation_pct = abs(param.value - midpoint) / midpoint * 100
            if deviation_pct < 15:
                severity_enum = SeverityColor.YELLOW
                deviation_lvl = "Borderline High"
                expl_base = "Creatinine is slightly above expected range."

        explanation = expl_base
        if severity_enum != SeverityColor.WHITE:
            explanation += f" {deviation_lvl} values may indicate physiological stress."
        else:
            explanation = "Excellent. Maintain current lifestyle."

        return EvaluationResult(
            parameter_name=param.name,
            patient_value=param.value,
            unit=param.unit,
            personalized_range=f"{low} - {high}",
            deviation_level=deviation_lvl,
            severity_color=severity_enum.value,
            explanation=explanation,
            influencing_factors=factors
        )

