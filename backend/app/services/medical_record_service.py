from sqlalchemy.orm import Session
from sqlalchemy import and_
from fastapi import HTTPException, status
from uuid import UUID
from typing import List

from app.models.medical_record import MedicalRecord
from app.services import family_access_service

def list_medical_records(db: Session, requester_id: UUID, target_owner_id: UUID) -> List[MedicalRecord]:
    """
    List medical records for a specific owner.
    Enforces ownership or family access permissions.
    """
    # 1. Enforce permissions
    family_access_service.enforce_medical_record_access(db, requester_id, target_owner_id)

    
    # 2. Query records
    records = db.query(MedicalRecord).filter(
        MedicalRecord.user_id == target_owner_id
    ).all()
    
    return records


def get_medical_record_for_viewing(db: Session, record_id: UUID, requester_id: UUID):
    """
    Get a single medical record's metadata and absolute path.
    Enforces ownership or family access permissions.
    """
    from app.services.storage_service import PROJECT_ROOT
    from pathlib import Path
    import os

    # 1. Get Record
    record = db.query(MedicalRecord).filter(MedicalRecord.id == record_id).first()
    if not record:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Medical record not found"
        )
    
    # 2. Enforce permissions (Owner or Family Access)
    family_access_service.enforce_medical_record_access(db, requester_id, record.user_id)

    
    # 3. Resolve Absolute Path safely
    # record.file_path is like "medical_storage/medical_records/..."
    abs_path = PROJECT_ROOT / record.file_path
    
    # Security: Ensure the path is within PROJECT_ROOT/medical_storage
    storage_root = PROJECT_ROOT / "medical_storage"
    if not str(abs_path.resolve()).startswith(str(storage_root.resolve())):
         raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid file path"
        )

    # 4. Check if file exists on disk
    if not abs_path.exists() or not abs_path.is_file():
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="File not found on storage"
        )
        
    return record, abs_path


def delete_medical_record(db: Session, record_id: UUID, requester_id: UUID):
    """
    Delete a medical record from database and disk.
    ONLY the owner can delete.
    """
    from app.services.storage_service import PROJECT_ROOT
    from pathlib import Path
    import os

    # 1. Get Record
    record = db.query(MedicalRecord).filter(MedicalRecord.id == record_id).first()
    if not record:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Medical record not found"
        )
    
    # 2. Strict Ownership Check: Only owner can delete
    if record.user_id != requester_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only the owner can delete this record. Family members are not permitted."
        )
    
    # 3. Get file path for cleanup
    relative_path = record.file_path
    abs_path = PROJECT_ROOT / relative_path
    
    try:
        # 4. Delete from Database first
        db.delete(record)
        db.commit()
        
        # 5. Delete from Disk (cleanup)
        if abs_path.exists() and abs_path.is_file():
            os.remove(abs_path)
            
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to delete record: {str(e)}"
        )
        
    return {"message": "Medical record and file deleted successfully"}

