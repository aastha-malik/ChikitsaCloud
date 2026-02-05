import joblib
import numpy as np
import os
import pandas as pd

class MLHealthRiskModel:
    def __init__(self, model_path="chikitsacloud_risk_model.pkl"):
        if not os.path.exists(model_path):
            raise FileNotFoundError(f"Model file {model_path} not found. Run train_model.py first.")
        self.model = joblib.load(model_path)

    def predict(self, patient, values):
        # 1. Prepare gender
        gender_val = 1 if patient.gender.lower() in ["male", "m"] else 0
        
        # 2. Create DataFrame (Fixed indentation)
        features_df = pd.DataFrame([[  
            patient.age,
            gender_val,
            patient.height_cm,
            patient.weight_kg,
            patient.bmi,
            values.get("Systolic BP", 120),
            values.get("Diastolic BP", 80),
            values.get("Blood Sugar (Fasting)", 100),
            values.get("Cholesterol", 180)
        ]], columns=['age', 'gender', 'height_cm', 'weight_kg', 'bmi', 
                     'systolic_bp', 'diastolic_bp', 'glucose', 'cholesterol'])
        
        # 3. Predict (Fixed variable name from 'features' to 'features_df')
        try:
            prediction = self.model.predict(features_df)[0]
            return int(prediction)
        except Exception as e:
            return f"Error: {e}"