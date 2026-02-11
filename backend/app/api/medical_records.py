from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from sqlalchemy.orm import Session
from typing import List
from uuid import UUID

from app.database import get_db
from app.services import storage_service
from app.models.medical_record import MedicalRecord
from app.schemas import medical_record as schemas
from app.schemas.medical_record import MedicalRecordOut

router = APIRouter(prefix="/medical-records", tags=["Medical Records"])

@router.post("/upload", response_model=MedicalRecordOut)
def upload_medical_record(
    user_id: UUID = Form(...), # Temporary until Auth Middleware
    record_category: str = Form(...),
    file: UploadFile = File(...),
    db: Session = Depends(get_db)
):
    """
    Upload a medical record (PDF/Image).
    Saves file to disk and metadata to DB.
    """
    # 1. Save File to Disk
    relative_path, saved_filename = storage_service.save_upload_file(file, user_id)
    
    # 2. Save Metadata to DB
    new_record = MedicalRecord(
        user_id=user_id,
        file_path=relative_path,
        file_type=file.content_type,
        record_category=record_category,
        original_filename=file.filename
    )
    
    db.add(new_record)
    db.commit()
    db.refresh(new_record)
    
    return new_record


@router.get("/", response_model=List[schemas.MedicalRecordList])
def list_medical_records(
    requester_id: UUID,        # TODO: Replace with current_user from JWT
    owner_id: UUID,            # The user whose records we want to see
    db: Session = Depends(get_db)
):
    """
    List medical records for a user.
    Enforces ownership or family access permissions.
    """
    from app.services import medical_record_service
    return medical_record_service.list_medical_records(db, requester_id, owner_id)


@router.get("/{record_id}")
def get_medical_record(
    record_id: UUID,
    requester_id: UUID,        # TODO: Replace with current_user from JWT
    db: Session = Depends(get_db)
):
    """
    View/Download a medical record file.
    Enforces permission checks and streams the file securely.
    """
    from fastapi.responses import FileResponse
    from app.services import medical_record_service
    
    record, abs_path = medical_record_service.get_medical_record_for_viewing(db, record_id, requester_id)
    
    return FileResponse(
        path=abs_path,
        filename=record.original_filename,
        media_type=record.file_type
    )


@router.delete("/{record_id}")
def delete_medical_record(
    record_id: UUID,
    requester_id: UUID,        # TODO: Replace with current_user from JWT
    db: Session = Depends(get_db)
):
    """
    Delete a medical record.
    ONLY the owner can delete.
    Removes both database entry and physical file.
    """
    from app.services import medical_record_service
    return medical_record_service.delete_medical_record(db, record_id, requester_id)

