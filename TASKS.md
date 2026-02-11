# Chikitsa - Project Task List

## Phase 0: Project Initialization & Infrastructure

### 0.1 Directory Structure Setup
- [ ] Create root `backend/` directory
- [ ] Create root `frontend/` directory
- [ ] Create `frontend/websites/` directory (for Web App)
- [ ] Create `frontend/app/` directory (for Mobile App)

### 0.2 Backend Initialization (Python/FastAPI)
- [ ] Initialize Python environment in `backend/`
- [ ] Create `requirements.txt` with dependencies:
    - `fastapi`
    - `uvicorn[standard]`
    - `sqlalchemy`
    - `alembic` (for migrations)
    - `pydantic`
    - `pydantic-settings`
    - `psycopg2-binary` (PostgreSQL driver)
    - `python-jose[cryptography]` (JWT auth)
    - `passlib[bcrypt]` (Hashing)
    - `python-multipart` (File uploads)
- [ ] Create basic folder structure:
    - `backend/app/main.py`
    - `backend/app/api/`
    - `backend/app/core/`
    - `backend/app/models/`
    - `backend/app/services/`
    - `backend/app/database.py`

### 0.3 Frontend Web Initialization (Next.js)
- [ ] Initialize Next.js project in `frontend/websites/`
    - Command: `npx create-next-app@latest . --typescript --tailwind --eslint`
- [ ] configure `globals.css` with basic theme variables.

### 0.4 Frontend Mobile Initialization (Flutter)
- [ ] Initialize Flutter project in `frontend/app/`
    - Command: `flutter create .`
- [ ] specific directory structure inside `lib/`:
    - `src/screens/`
    - `src/widgets/`
    - `src/services/`
    - `src/models/`

---

## Phase 1: Authentication, Database & Core API (Backend Focus)

### 1.1 Database Configuration
- [ ] Setup `database.py` with SQLAlchemy engine and session local.
- [ ] Setup `core/config.py` for environment variables (DB URL, Secret Keys).
- [ ] Implement `models/user.py`:
    - Attributes: `id`, `name`, `email`, `phone`, `dob`, `created_at`
- [ ] Implement `models/emergency_contact.py`:
    - Attributes: `id`, `user_id`, `name`, `relation`, `phone`
- [ ] Setup Alembic and run initial migration.

### 1.2 Authentication System
- [ ] Implement `core/security.py` (Password hashing, JWT token creation/verification).
- [ ] Create `api/auth.py`:
    - `POST /register`: Create new user.
    - `POST /login`: authenticate and return JWT.
- [ ] Implement `api/users.py`:
    - `GET /me`: Get current user profile.

### 1.3 Medical Record Storage (Core)
- [ ] Implement `models/medical_record.py`:
    - Attributes: `id`, `user_id`, `record_type`, `file_url`, `report_date`, `uploaded_at`
- [ ] Implement `services/storage_service.py`:
    - Logic to save uploaded files (Local folder or S3 if configured - start with local).
- [ ] Create `api/records.py`:
    - `POST /upload`: Upload a medical record file.
    - `GET /records`: List user records.

---

## Phase 2: SOS & Emergency Features

### 2.1 Backend Implementation
- [ ] Create `api/sos.py`:
    - `POST /sos/trigger`: Send alerts to emergency contacts.
- [ ] Implement `services/notification_service.py` (Mock for now, or SMS integration).
- [ ] Expose public endpoint for Emergency Access (QR code link logic).

### 2.2 Frontend (Mobile App - Flutter)
- [ ] **Auth Screens**: Login & Signup screens connecting to Backend API.
- [ ] **Home Screen**: Dashboard showing "SOS" big button and recent records.
- [ ] **SOS Logic**: One-tap SOS trigger integration.
- [ ] **Emergency Contacts**: Screen to add/edit contacts.

---

## Phase 3: Hospital Discovery

### 3.1 Backend Implementation
- [ ] Implement `models/hospital.py`:
    - `id`, `name`, `phone`, `latitude`, `longitude`
- [ ] Create `api/hospitals.py`:
    - `GET /hospitals/nearby`: Search by lat/long.

### 3.2 Frontend (Web & Mobile)
- [ ] **Map Interface**: Use map plugin (Google Maps or OpenStreetMap) to show nearby hospitals on Mobile.
- [ ] **Web Dashboard**: Simple view for users to manage their profile on `frontend/websites`.

---

## Phase 4: AI Integration & Educational Insights

### 4.1 Backend AI Service Integration
- [ ] Implement `services/ai_client.py`:
    - Logic to call external AI service via REST API.
- [ ] Implement `models/insight.py`:
    - `id`, `record_id`, `parameter`, `value`, `reference_range`, `status`, `explanation`
- [ ] Update `api/records.py`:
    - Trigger AI analysis after file upload.
    - Store returned insights in DB.

### 4.2 Frontend Presentation
- [ ] **Record Detail View**: Show original file + AI generated "Educational" insights (highlight abnormal values).
- [ ] **Disclaimer UI**: Clearly label AI insights as "Educational Purposes Only - Not a Diagnosis".

---

## Phase 5: Security & Scaling
- [ ] Audit API permissions (Ensure users can only access their own data).
- [ ] Optimize database queries.
- [ ] Setup Docker/Deployment configuration (optional).
