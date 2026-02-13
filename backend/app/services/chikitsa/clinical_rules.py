class ClinicalKnowledgeBase:
    """
    Contains medical logic to determine personalized reference ranges.
    These ranges are used ONLY for AI-based risk flagging
    and NOT for medical diagnosis.
    """

    @staticmethod
    def get_bp_range(age: int):
        """
        Age-adjusted blood pressure ranges.
        """
        if age > 65:
            return (90, 140), (60, 90)   
        return (90, 120), (60, 80)       

    @staticmethod
    def get_heart_rate_range(age: int, active_status: str = "Average"):
        """
        Resting heart rate varies with fitness.
        """
        if active_status.lower() == "athlete":
            return (40, 100)
        return (60, 100)

    @staticmethod
    def get_hemoglobin_range(gender: str, age: int):
        """
        Age and gender-specific hemoglobin ranges.
        """
        if age < 18:
            return (11.0, 16.0)

        if gender.lower() == "male":
            return (13.8, 17.2)
        else:
            return (12.1, 15.1)

    @staticmethod
    def get_creatinine_range(gender: str):
        """
        Sex-specific creatinine reference ranges.
        """
        if gender.lower() == "male":
            return (0.74, 1.35)
        else:
            return (0.59, 1.04)

    @staticmethod
    def get_glucose_range(type: str):
        """
        Blood glucose reference ranges.
        """
        if type == "Fasting":
            return (70, 99)
        return (70, 140)  

    @staticmethod
    def get_cholesterol_range(age: int):
        """
        Total cholesterol reference ranges.
        """
        if age < 20:
            return (120, 170)
        return (125, 200)
