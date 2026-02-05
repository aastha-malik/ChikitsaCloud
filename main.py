import json
from medical_schema import PatientDemographics, MedicalParameter
from engine import ChikitsaEngine
from ml_model import MLHealthRiskModel  


COLOR_MAP = {
    "🟣": "\033[95m", "🔴": "\033[91m", "🟡": "\033[93m", 
    "🟨": "\033[33m", "⚪": "\033[92m"
}
RESET = "\033[0m"

def get_float(prompt):
    return float(input(prompt))

def print_colored_result(result):
    color = COLOR_MAP.get(result.severity_color, "")
    print(f"{result.parameter_name}: {color}{result.patient_value} {result.unit}{RESET} "
          f"[{result.severity_color} {result.deviation_level}]")
    print("-" * 60)

def main():
    print("\n===== CHIKITSACLOUD | AI Medical Data Evaluation =====\n")

    
    age = int(input("Enter Age: "))
    gender = input("Enter Gender (Male/Female): ")
    height = get_float("Enter Height (cm): ")
    weight = get_float("Enter Weight (kg): ")

    patient = PatientDemographics(
        age=age, gender=gender, height_cm=height, weight_kg=weight
    )
    print(f"\nCalculated BMI: {patient.bmi:.2f}")
    print("-" * 60)

    
    medical_data = [
        MedicalParameter("Systolic BP", get_float("Enter Systolic BP (mmHg): "), "mmHg", "Vitals"),
        MedicalParameter("Diastolic BP", get_float("Enter Diastolic BP (mmHg): "), "mmHg", "Vitals"),
        MedicalParameter("SpO2", get_float("Enter SpO2 (%): "), "%", "Vitals"),
        MedicalParameter("Hemoglobin", get_float("Enter Hemoglobin (g/dL): "), "g/dL", "Lab"),
        MedicalParameter("Creatinine", get_float("Enter Creatinine (mg/dL): "), "mg/dL", "Lab"),
        MedicalParameter("Blood Sugar (Fasting)", get_float("Enter Blood Sugar (mg/dL): "), "mg/dL", "Lab"),
        MedicalParameter("Cholesterol", get_float("Enter Cholesterol (mg/dL): "), "mg/dL", "Lab") 
    ]

    
    engine = ChikitsaEngine()
    results = []
    
    
    ml_input_values = {} 

    print("\n===== RULE ENGINE ANALYSIS =====\n")
    for param in medical_data:
        evaluation = engine.evaluate(patient, param)
        results.append(evaluation)
        ml_input_values[param.name] = param.value  
        print_colored_result(evaluation)

    
    print("\n===== ML RISK PREDICTION =====\n")
    try:
        ml_model = MLHealthRiskModel()
        risk_score = ml_model.predict(patient, ml_input_values)
        
        risk_map = {0: "Low Risk", 1: "Moderate Risk", 2: "High Risk", 3: "Critical Risk"}
        risk_text = risk_map.get(risk_score, "Unknown Risk")
        
        print(f"Predicted Health Risk Level: {risk_score} ({risk_text})")
    except Exception as e:
        risk_score = -1
        risk_text = "Error"
        print(f"ML Model Failed: {e}")

    
    final_output = {
        "platform": "CHIKITSACLOUD",
        "status": "success",
        "patient_context": {
            "age": patient.age,
            "bmi": patient.bmi
        },
        "ml_risk_prediction": {
            "score": risk_score,
            "label": risk_text
        },
        "analysis": [res.to_dict() for res in results]
    }

    print("\n===== STRUCTURED JSON OUTPUT =====\n")
    print(json.dumps(final_output, indent=4))

if __name__ == "__main__":

    main()

