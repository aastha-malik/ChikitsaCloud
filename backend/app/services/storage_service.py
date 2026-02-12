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
        
        # Determine bucket to use
        bucket_name = settings.SUPABASE_BUCKET
        
        print(f"[DEBUG] Attempting upload to bucket: '{bucket_name}'")
        
        try:
            # Upload to Supabase Storage
            response = supabase.storage.from_(bucket_name).upload(
                file_path,
                file_content,
                {"content-type": file.content_type}
            )
        except Exception as e:
            if "Bucket not found" in str(e) and " " in bucket_name:
                fallback_bucket = bucket_name.replace(" ", "-")
                print(f"[INFO] Bucket '{bucket_name}' not found. Trying fallback: '{fallback_bucket}'")
                response = supabase.storage.from_(fallback_bucket).upload(
                    file_path,
                    file_content,
                    {"content-type": file.content_type}
                )
            else:
                raise e
        
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
        bucket_name = settings.SUPABASE_BUCKET
        try:
            supabase.storage.from_(bucket_name).remove([relative_path])
        except Exception as e:
            if "Bucket not found" in str(e) and " " in bucket_name:
                supabase.storage.from_(bucket_name.replace(" ", "-")).remove([relative_path])
            else:
                raise e
    except Exception as e:
        print(f"Failed to delete file {relative_path}: {e}")

def delete_user_storage(user_id: uuid.UUID):
    """
    Deletes all files for a user.
    """
    try:
        bucket_name = settings.SUPABASE_BUCKET
        try:
            files = supabase.storage.from_(bucket_name).list(f"{user_id}")
        except Exception as e:
            if "Bucket not found" in str(e) and " " in bucket_name:
                bucket_name = bucket_name.replace(" ", "-")
                files = supabase.storage.from_(bucket_name).list(f"{user_id}")
            else:
                raise e
        
        if files:
            paths_to_delete = [f"{user_id}/{f['name']}" for f in files]
            if paths_to_delete:
                supabase.storage.from_(bucket_name).remove(paths_to_delete)
                
    except Exception as e:
        print(f"Failed to delete storage for user {user_id}: {e}")

def get_signed_url(file_path: str, expires_in: int = 3600) -> str:
    """
    Generates a signed URL for a file in Supabase Storage.
    """
    try:
        bucket_name = settings.SUPABASE_BUCKET
        try:
            response = supabase.storage.from_(bucket_name).create_signed_url(
                file_path, expires_in
            )
        except Exception as e:
            if "Bucket not found" in str(e) and " " in bucket_name:
                bucket_name = bucket_name.replace(" ", "-")
                response = supabase.storage.from_(bucket_name).create_signed_url(
                    file_path, expires_in
                )
            else:
                raise e

        if isinstance(response, dict) and 'signedURL' in response:
            return response['signedURL']
        return str(response)
    except Exception as e:
        print(f"Failed to generate signed URL for {file_path}: {e}")
        raise HTTPException(status_code=500, detail="Failed to generate file access URL")
