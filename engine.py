from medical_schema import (
    PatientDemographics, MedicalParameter, EvaluationResult, SeverityColor
)
from clinical_rules import ClinicalKnowledgeBase

class ChikitsaEngine:
    def __init__(self):
        self.kb = ClinicalKnowledgeBase()

    def determine_severity(self, value, low, high, is_critical_metric=False):
        """
        Calculates severity based on how far the value deviates from the range.
        """
        if low <= value <= high:
            return SeverityColor.WHITE, "Normal", "Value is within the healthy range for your profile."

        
        midpoint = (low + high) / 2
        deviation_pct = abs(value - midpoint) / midpoint * 100
        
        direction = "High" if value > high else "Low"

        
        if deviation_pct > 50 or (is_critical_metric and deviation_pct > 30):
            return SeverityColor.PURPLE, f"Critically {direction}", "Immediate medical attention required."
        
        if deviation_pct > 25:
            return SeverityColor.RED, f"Significantly {direction}", "Requires clinical attention."
        
        if deviation_pct > 10:
            return SeverityColor.YELLOW, f"Moderately {direction}", "Suspicious deviation, monitoring recommended."
            
        return SeverityColor.LIGHT_YELLOW, f"Slightly {direction}", "Minor deviation, consider lifestyle adjustments."

    def evaluate(self, patient: PatientDemographics, param: MedicalParameter) -> EvaluationResult:
        low, high = 0, 0
        factors = []
        is_critical = False

        
        
        if param.name == "Systolic BP":
            low, high = self.kb.get_bp_range(patient.age)[0]
            factors.append(f"Age: {patient.age}")
            is_critical = True 
            
        elif param.name == "Diastolic BP":
            low, high = self.kb.get_bp_range(patient.age)[1]
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
                    param.name, param.value, param.unit, f"{low}-{high}", "Critically Low",
                    SeverityColor.PURPLE.value, "Hypoxia detected. Emergency.", ["Vital Sign"]
                )

        else:
            
            low, high = 0, 100 

        
        severity_enum, deviation_lvl, expl_base = self.determine_severity(
            param.value, low, high, is_critical
        )

        
        explanation = f"{expl_base} {deviation_lvl} values may indicate underlying strain."
        if severity_enum == SeverityColor.WHITE:
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

