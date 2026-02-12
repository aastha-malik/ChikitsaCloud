
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
import joblib


data = pd.read_csv(r'C:\Users\asus\Desktop\AB\chikitsacloud_synthetic_medical_data.csv')


X = data[['age', 'gender', 'height_cm', 'weight_kg', 'bmi', 
          'systolic_bp', 'diastolic_bp', 'glucose', 'cholesterol']]
y = data['risk_label']


print("Training Model...")
model = RandomForestClassifier(n_estimators=100, random_state=42)
model.fit(X, y)


joblib.dump(model, "chikitsacloud_risk_model.pkl")

print("✅ Model saved as 'chikitsacloud_risk_model.pkl'")
