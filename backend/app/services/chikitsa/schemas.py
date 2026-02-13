from pydantic import BaseModel, Field
from typing import List, Optional
from enum import Enum

class SeverityColor(str, Enum):
    PURPLE = "🟣"        
    RED = "🔴"           
    YELLOW = "🟡"        
    LIGHT_YELLOW = "🟨"  
    WHITE = "⚪"         

class EvaluationResult(BaseModel):
    parameter_name: str
    patient_value: float
    unit: str
    personalized_range: str
    deviation_level: str
    severity_color: str
    explanation: str
    influencing_factors: List[str]

    def to_dict(self):
        return {
            "parameter": self.parameter_name,
            "value": self.patient_value,
            "unit": self.unit,
            "range": self.personalized_range,
            "deviation": self.deviation_level,
            "severity": self.severity_color,
            "explanation": self.explanation,
            "factors": self.influencing_factors
        }
