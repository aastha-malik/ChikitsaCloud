import shutil
import uuid
import os
from pathlib import Path
from fastapi import UploadFile, HTTPException, status
from typing import Tuple

# Define relative path to storage from the backend execution context
# Assuming backend is running from `backend/` directory
# So storage is at `../medical_storage`
PROJECT_ROOT = Path(__file__).resolve().parents[3] # internal/app/services/backend -> root
STORAGE_DIR_NAME = "medical_storage"
STORAGE_PATH = PROJECT_ROOT / STORAGE_DIR_NAME

# Ensure storage root exists
STORAGE_PATH.mkdir(exist_ok=True)

ALLOWED_EXTENSIONS = {
    "pdf": "application/pdf",
    "jpg": "image/jpeg",
    "jpeg": "image/jpeg",
    "png": "image/png"
}
MAX_FILE_SIZE_MB = 10 ## FOR LATER USE 

def validate_file(file: UploadFile) -> str:
    # 1. Check extension
    filename = file.filename.lower()
    ext = filename.split(".")[-1] if "." in filename else ""
    
    if ext not in ALLOWED_EXTENSIONS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid file type. Allowed: {', '.join(ALLOWED_EXTENSIONS.keys())}"
        )
    
    # 2. Check content type (Mime)
    if file.content_type != ALLOWED_EXTENSIONS[ext]:
         raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid content type for extension {ext}"
        )
         
    # 3. Check file size (Naive check using seek/tell if possible or just reading chunk)
    # Using specific middleware is better, but here we can check file.size if spooled
    return ext

def save_upload_file(file: UploadFile, user_id: uuid.UUID) -> Tuple[str, str]:
    """
    Saves file to medical_storage/medical_records/{user_id}/{uuid}.{ext}
    Returns: (relative_path, saved_filename)
    """
    ext = validate_file(file)
    
    # Generate path
    unique_filename = f"{uuid.uuid4()}.{ext}"
    user_record_dir = STORAGE_PATH / "medical_records" / str(user_id)
    user_record_dir.mkdir(parents=True, exist_ok=True)
    
    destination_path = user_record_dir / unique_filename
    
    try:
        with destination_path.open("wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Could not save file: {str(e)}")
    finally:
        file.file.close()
        
    # Return relative path for DB
    relative_path = f"{STORAGE_DIR_NAME}/medical_records/{user_id}/{unique_filename}"
    return relative_path, unique_filename
