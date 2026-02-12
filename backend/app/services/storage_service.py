import uuid
from typing import Optional
from fastapi import UploadFile, HTTPException, status
from supabase import create_client, Client
from app.core.config import settings

# Initialize Supabase client
supabase: Client = create_client(settings.SUPABASE_URL, settings.SUPABASE_KEY)

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
    Saves file to Supabase Storage bucket.
    Returns: Public URL or Path to file.
    """
    validate_file(file)
    
    # Generate unique path: {user_id}/{uuid}_{filename}
    file_path = f"{user_id}/{uuid.uuid4()}_{file.filename}"
    
    try:
        # Read file content
        file_content = file.file.read()
        
        # Upload to Supabase Storage
        # https://supabase.com/docs/reference/python/storage-from-upload
        response = supabase.storage.from_(settings.SUPABASE_BUCKET).upload(
            file_path,
            file_content,
            {"content-type": file.content_type}
        )
        
        # If response implies failure (depends on version, usually throws error or returns dict)
        # Assuming success if no exception raised.
        
        return file_path
        
    except Exception as e:
        # Reset file pointer if needed, though we are done with it
        file.file.seek(0)
        print(f"Supabase Upload Error: {e}")
        raise HTTPException(status_code=500, detail=f"Could not save file to cloud storage: {str(e)}")
    finally:
        file.file.close()

def delete_physical_file(relative_path: str):
    """
    Deletes file from Supabase Storage.
    relative_path is the path in the bucket.
    """
    try:
        supabase.storage.from_(settings.SUPABASE_BUCKET).remove([relative_path])
    except Exception as e:
        print(f"Failed to delete file {relative_path}: {e}")

def delete_user_storage(user_id: uuid.UUID):
    """
    Deletes all files for a user.
    Note: Supabase Storage folder deletion is tricky. 
    We list files in the user's 'folder' and delete them.
    """
    try:
        # List files in the user 'folder' (prefix)
        # Note: 'list' might return nothing if folder doesn't strictly exist as an object
        files = supabase.storage.from_(settings.SUPABASE_BUCKET).list(f"{user_id}")
        
        if files:
            paths_to_delete = [f"{user_id}/{f['name']}" for f in files]
            if paths_to_delete:
                supabase.storage.from_(settings.SUPABASE_BUCKET).remove(paths_to_delete)
                
    except Exception as e:
        print(f"Failed to delete storage for user {user_id}: {e}")
