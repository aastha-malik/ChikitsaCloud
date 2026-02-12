from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form, Query
from fastapi.responses import FileResponse, RedirectResponse
from sqlalchemy.orm import Session
from typing import List, Optional
from uuid import UUID

from app.database import get_db
from app.api.deps import get_current_user
from app.models.user import AuthUser
from app.services import medical_record_service
from app.schemas import medical_record as schemas

router = APIRouter(prefix="/records", tags=["Medical Records"])

@router.post("", response_model=schemas.MedicalRecordOut)
async def create_record(
    title: str = Form(...),
    record_type: str = Form(...),
    file: UploadFile = File(...),
    current_user: AuthUser = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    return medical_record_service.create_medical_record(
        db, current_user.id, title, record_type, file
    )

@router.get("", response_model=List[schemas.MedicalRecordOut])
async def list_records(
    owner_id: Optional[UUID] = Query(None),
    current_user: AuthUser = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    return medical_record_service.list_user_records(db, current_user.id, owner_id)

@router.delete("/{record_id}")
async def delete_record(
    record_id: UUID,
    current_user: AuthUser = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    return medical_record_service.delete_record(db, current_user.id, record_id)

@router.get("/{record_id}/file")
async def get_record_file(
    record_id: UUID,
    current_user: AuthUser = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # record_service now returns (record, signed_url)
    record, signed_url = medical_record_service.get_record_file(db, current_user.id, record_id)
    return RedirectResponse(url=signed_url)
