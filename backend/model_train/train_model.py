import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
import joblib


data = pd.read_csv("chikitsacloud_synthetic_medical_data.csv")


X = data[['age', 'gender', 'height_cm', 'weight_kg', 'bmi',
          'systolic_bp', 'diastolic_bp', 'glucose', 'cholesterol']]
y = data['risk_label']


X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42
)


model = RandomForestClassifier(n_estimators=100, random_state=42)

print("Training Model...")
model.fit(X_train, y_train)


accuracy = model.score(X_test, y_test)
print("Accuracy:", accuracy)


joblib.dump(model, "chikitsacloud_risk_model.pkl")
print("✅ Model saved as 'chikitsacloud_risk_model.pkl'")
