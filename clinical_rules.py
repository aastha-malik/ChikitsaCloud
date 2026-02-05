from medical_schema import PatientDemographics

class ClinicalKnowledgeBase:
    """
    Contains medical logic to determine personalized ranges.
    Note: These are simplified standard guidelines for demonstration.
    """

    @staticmethod
    def get_bp_range(age: int):
        # BP targets loosen slightly with age
        if age > 65:
            return (90, 140), (60, 90)  # Systolic, Diastolic
        return (90, 120), (60, 80)

    @staticmethod
    def get_heart_rate_range(age: int, active_status: str = "Average"):
        # Athletes may have lower resting HR
        if active_status == "Athlete":
            return (40, 100)
        return (60, 100)

    @staticmethod
    def get_hemoglobin_range(gender: str, age: int):
        if age < 18:
            return (11.0, 16.0) # Pediatric simplified
        if gender.lower() == 'male':
            return (13.8, 17.2)
        else:
            return (12.1, 15.1)

    @staticmethod
    def get_creatinine_range(gender: str):
        if gender.lower() == 'male':
            return (0.74, 1.35)
        else:
            return (0.59, 1.04)

    @staticmethod
    def get_glucose_range(type: str):
        if type == "Fasting":
            return (70, 99)
        return (70, 140) # Random/Post-prandial
