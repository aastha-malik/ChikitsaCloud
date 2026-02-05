# train_model.py
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
import joblib

# 1. Load Data
data = pd.read_csv(r'C:\Users\asus\Desktop\AB\chikitsacloud_synthetic_medical_data.csv')

# 2. Define Features (X) and Target (y)
# MUST match the order in ml_model.py
X = data[['age', 'gender', 'height_cm', 'weight_kg', 'bmi', 
          'systolic_bp', 'diastolic_bp', 'glucose', 'cholesterol']]
y = data['risk_label']

# 3. Train Model
print("Training Model...")
model = RandomForestClassifier(n_estimators=100, random_state=42)
model.fit(X, y)

# 4. Save Model
joblib.dump(model, "chikitsacloud_risk_model.pkl")
print("✅ Model saved as 'chikitsacloud_risk_model.pkl'")