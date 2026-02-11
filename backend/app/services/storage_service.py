import shutil
import uuid
import os
from pathlib import Path
from fastapi import UploadFile, HTTPException, status
from typing import Tuple

# Define relative path to storage from the backend execution context
PROJECT_ROOT = Path(__file__).resolve().parents[3] # ChikitsaCloud-main root
STORAGE_DIR_NAME = "Medical_storage"
STORAGE_PATH = PROJECT_ROOT / STORAGE_DIR_NAME

# Ensure storage root exists
STORAGE_PATH.mkdir(exist_ok=True)

ALLOWED_TYPES = {
    "application/pdf",
    "image/jpeg",
    "image/png"
}

def validate_file(file: UploadFile):
    if file.content_type not in ALLOWED_TYPES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid file type. Allowed: PDF, JPG, PNG"
        )
    return True

def save_medical_record_file(file: UploadFile, user_id: uuid.UUID) -> str:
    """
    Saves file to Medical_storage/{user_id}/{uuid}_{original_name}
    Returns: relative path for storage in DB
    """
    validate_file(file)
    
    # Generate path
    user_record_dir = STORAGE_PATH / str(user_id)
    user_record_dir.mkdir(parents=True, exist_ok=True)
    
    # Sanitize and unique filename
    unique_filename = f"{uuid.uuid4()}_{file.filename}"
    destination_path = user_record_dir / unique_filename
    
    try:
        with destination_path.open("wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Could not save file: {str(e)}")
    finally:
        file.file.close()
        
    # Return relative path for DB
    return f"{STORAGE_DIR_NAME}/{user_id}/{unique_filename}"

def delete_physical_file(relative_path: str):
    abs_path = PROJECT_ROOT / relative_path
    if abs_path.exists():
        os.remove(abs_path)

def delete_user_storage(user_id: uuid.UUID):
    """
    Deletes the entire directory for a specific user.
    """
    user_record_dir = STORAGE_PATH / str(user_id)
    if user_record_dir.exists() and user_record_dir.is_dir():
        shutil.rmtree(user_record_dir)
