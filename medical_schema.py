import json
from dataclasses import dataclass, field, asdict
from typing import Optional, List, Dict, Any
from enum import Enum

class SeverityColor(Enum):
    PURPLE = "🟣"        # Extremely critical / life-threatening
    RED = "🔴"           # Critical, immediate attention
    YELLOW = "🟡"        # Suspicious, needs monitoring
    LIGHT_YELLOW = "🟨"  # Slight deviation, lifestyle adjustment
    WHITE = "⚪"         # Normal

@dataclass
class PatientDemographics:
    age: int
    gender: str  # 'Male' or 'Female'
    height_cm: float
    weight_kg: float
    
    @property
    def bmi(self) -> float:
        return round(self.weight_kg / ((self.height_cm / 100) ** 2), 2)

@dataclass
class MedicalParameter:
    name: str
    value: float
    unit: str
    category: str  # e.g., "Vitals", "Lab", "Urine"

@dataclass
class EvaluationResult:
    parameter_name: str
    patient_value: float
    unit: str
    personalized_range: str
    deviation_level: str  # e.g., "High", "Low", "Normal"
    severity_color: str
    explanation: str
    influencing_factors: List[str]
    
    def to_dict(self):
        return {
            "Parameter Name": self.parameter_name,
            "Patient Value": f"{self.patient_value} {self.unit}",
            "Personalized Normal Range": self.personalized_range,
            "Deviation Level": self.deviation_level,
            "Severity Color Code": self.severity_color,
            "Explanation Text": self.explanation,
            "Influencing Factors": self.influencing_factors
        }
