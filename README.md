#   ChikitsaCloud

ChikitsaCloud is a cloud-based medical record management system that allows users to securely store, manage, and share medical documents while discovering nearby hospitals in real time.

---

## 📌 Problem Statement

Medical records are often stored physically or scattered across multiple platforms, making them difficult to access during emergencies. Sharing reports with family members or doctors can be inconvenient and insecure.

There is a need for a centralized, secure, and easily accessible digital medical record system.

---

## 💡 Solution

ChikitsaCloud provides a secure cloud platform where users can:

- Upload and store medical records (PDFs & Images)
- Categorize and manage records efficiently
- Share records with family members via QR & invite system
- Discover nearby hospitals using GPS or manual location
- Access medical information anytime, anywhere

---

## ✨ Key Features

- 🔐 User Authentication (Register / Login)
- 📂 Upload medical records (PDF, Image)
- 🏷 Add custom record name and type
- ☁ Cloud storage integration using Supabase
- 📍 Nearby hospital discovery
- 👨‍👩‍👧 Family access via QR-based sharing
- 📱 Mobile-first application built with Flutter

---

## 🛠 Tech Stack

### Frontend
- Flutter
- Dart

### Backend
- FastAPI
- Python

### Database & Cloud Storage
- Supabase (PostgreSQL-based database + storage)

### Deployment
- Backend deployed on Render
- APK distributed via Google Drive

---

## 🌐 Live Demo & Access

### 📱 Download APK

You can download and install the app using the link below:

```
https://drive.google.com/file/d/10A-i4ca3aM3ZiWz79QTj451qiwctJ6P_/view?usp=sharing
```

⚠ Note:
Since the app is not published on the Google Play Store, Android may show a security warning during installation.  
Enable **"Install from Unknown Sources"** temporarily to install the APK.

---

### 🔎 Test Backend APIs (Live Swagger UI)

The backend is deployed and accessible via Swagger UI:

```
https://chikitsacloud-pn0c.onrender.com/docs#/
```

You can directly test API endpoints from the deployed Swagger interface.

---

## 🏗 System Architecture

```
User → Flutter App → FastAPI Backend → Supabase Database
                                      ↘ Supabase Storage
```

### Application Flow

1. User uploads a medical file from the Flutter app.
2. The request is sent to the FastAPI backend.
3. Backend validates user authentication.
4. File is stored in Supabase Storage.
5. Metadata (record name, type, file URL, user ID) is stored in Supabase database.
6. Records are fetched and displayed securely when requested.

---

## 🔐 Security Considerations

- Authentication-based access control
- Backend validation before storage
- Secure cloud storage via Supabase
- Controlled sharing via QR-based invite system
- Separation of file storage and metadata handling

---

## 🚀 Local Installation & Setup

### Clone Repository

```bash
git clone https://github.com/YOUR-USERNAME/ChikitsaCloud.git
cd ChikitsaCloud
```

---

### Backend Setup

```bash
cd backend
python -m venv venv
source venv/bin/activate   # Linux / Mac
venv\Scripts\activate      # Windows
pip install -r requirements.txt
uvicorn main:app --reload
```

Backend runs at:
```
http://127.0.0.1:8000
```

---

### Frontend Setup

```bash
cd frontend
flutter pub get
flutter run
```

---

## 📱 Screenshots

_Add application screenshots here_

Example:

```
![Login Screen](screenshots/login.png)
![Dashboard](screenshots/dashboard.png)
```

---

## 🔮 Future Improvements

- Role-based access control (RBAC)
- End-to-end encryption of medical files
- Doctor dashboard
- Appointment booking integration
- Play Store deployment
- CI/CD pipeline integration

---

## 👩‍💻 Contributors

- Aastha Malik
- Vanisha
- Shubham

---

## 📄 License

This project is developed for educational and demonstration purposes.
