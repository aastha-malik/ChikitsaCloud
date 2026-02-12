from sqlalchemy.orm import Session
from fastapi import HTTPException, status, UploadFile
from uuid import UUID
from typing import List, Optional
import os
from pathlib import Path

from app.models.medical_record import MedicalRecord
from app.services import storage_service, family_access_service

def create_medical_record(db: Session, user_id: UUID, title: str, record_type: str, file: UploadFile):
    # 1. Validate record_type
    allowed_types = ["lab_report", "prescription", "scan_image", "discharge_summary", "other"]
    if record_type not in allowed_types:
        raise HTTPException(status_code=400, detail=f"Invalid record_type. Allowed: {allowed_types}")
    
    # 2. Save file
    file_path = storage_service.save_medical_record_file(file, user_id)
    
    # 3. Create metadata
    new_record = MedicalRecord(
        user_id=user_id,
        title=title,
        record_type=record_type,
        file_path=file_path
    )
    
    db.add(new_record)
    db.commit()
    db.refresh(new_record)
    return new_record

def list_user_records(db: Session, requester_id: UUID, owner_id: Optional[UUID] = None):
    target_id = owner_id if owner_id else requester_id
    
    # Check family access if viewing someone else's records
    if target_id != requester_id:
        family_access_service.enforce_medical_record_access(db, requester_id, target_id)
        
    return db.query(MedicalRecord).filter(
        MedicalRecord.user_id == target_id
    ).order_by(MedicalRecord.created_at.desc()).all()

def delete_record(db: Session, user_id: UUID, record_id: UUID):
    record = db.query(MedicalRecord).filter(
        MedicalRecord.id == record_id,
        MedicalRecord.user_id == user_id
    ).first()
    
    if not record:
        raise HTTPException(status_code=404, detail="Record not found or access denied")
    
    # Delete file
    storage_service.delete_physical_file(record.file_path)
    
    # Delete DB entry
    db.delete(record)
    db.commit()
    return {"message": "Record deleted successfully"}

def get_record_file(db: Session, requester_id: UUID, record_id: UUID):
    record = db.query(MedicalRecord).filter(MedicalRecord.id == record_id).first()
    if not record:
        raise HTTPException(status_code=404, detail="Record not found")
    
    # Check access
    if record.user_id != requester_id:
        family_access_service.enforce_medical_record_access(db, requester_id, record.user_id)
    
    # Get signed URL from cloud storage instead of local file
    signed_url = storage_service.get_signed_url(record.file_path)
    return record, signed_url
