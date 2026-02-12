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
        
        # Helper to try different bucket IDs
        bucket_variants = [
            settings.SUPABASE_BUCKET,
            settings.SUPABASE_BUCKET.replace(" ", "-"),
            settings.SUPABASE_BUCKET.replace("-", " "),
            "medical-records",
            "medical records",
            "medicalrecords"
        ]
        # Remove duplicates while preserving order
        bucket_variants = list(dict.fromkeys(bucket_variants))

        last_error = None
        for bucket in bucket_variants:
            try:
                print(f"[DEBUG] Attempting upload to bucket: '{bucket}'")
                response = supabase.storage.from_(bucket).upload(
                    file_path,
                    file_content,
                    {"content-type": file.content_type}
                )
                print(f"[SUCCESS] Uploaded to bucket: '{bucket}'")
                return file_path
            except Exception as e:
                last_error = e
                if "Bucket not found" in str(e):
                    continue
                else:
                    raise e

        # If we get here, all variants failed
        print(f"[CRITICAL] All bucket variants failed. Last error: {last_error}")
        # Reset file pointer if needed
        file.file.seek(0)
        raise HTTPException(status_code=500, detail=f"Target Supabase bucket not found. Tried: {bucket_variants}")

    except Exception as e:
        print(f"Supabase Upload Error: {e}")
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(status_code=500, detail=str(e))
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
    Tries multiple bucket variants to find where the file is stored.
    """
    bucket_variants = [
        settings.SUPABASE_BUCKET,
        settings.SUPABASE_BUCKET.replace(" ", "-"),
        "medical-records",
        "medical records",
        "medicalrecords"
    ]
    bucket_variants = list(dict.fromkeys(bucket_variants))

    for bucket in bucket_variants:
        try:
            print(f"[DEBUG] Attempting signed URL from bucket: '{bucket}'")
            response = supabase.storage.from_(bucket).create_signed_url(
                file_path, expires_in
            )
            
            # Handle different response formats
            signed_url = None
            if isinstance(response, str):
                signed_url = response
            elif isinstance(response, dict) and 'signedURL' in response:
                signed_url = response['signedURL']
            elif hasattr(response, 'signed_url'):
                signed_url = response.signed_url
            
            if signed_url:
                print(f"[SUCCESS] Generated signed URL from bucket: '{bucket}'")
                return signed_url
                
        except Exception as e:
            if "Bucket not found" in str(e):
                continue
            print(f"[WARNING] Error with bucket '{bucket}': {e}")

    raise HTTPException(status_code=404, detail="Could not retrieve file. Storage bucket not found.")
