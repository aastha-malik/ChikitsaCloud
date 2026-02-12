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

def _get_bucket_variants():
    variants = [
        settings.SUPABASE_BUCKET,
        settings.SUPABASE_BUCKET.replace(" ", "-"),
        settings.SUPABASE_BUCKET.replace("-", " "),
        "medical-records",
        "medical records",
        "medicalrecords"
    ]
    return list(dict.fromkeys(variants))

def save_medical_record_file(file: UploadFile, user_id: uuid.UUID) -> str:
    validate_file(file)
    file_path = f"{user_id}/{uuid.uuid4()}_{file.filename}"
    
    try:
        file_content = file.file.read()
        bucket_variants = _get_bucket_variants()
        last_error = None

        for bucket in bucket_variants:
            try:
                print(f"[DEBUG] Attempting upload to bucket: '{bucket}'")
                supabase.storage.from_(bucket).upload(
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
                raise e

        print(f"[CRITICAL] All bucket variants failed for upload. Last error: {last_error}")
        file.file.seek(0)
        raise HTTPException(status_code=500, detail=f"Target Supabase bucket not found. Tried: {bucket_variants}")

    except Exception as e:
        print(f"Supabase Upload Error: {e}")
        if isinstance(e, HTTPException): raise e
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        file.file.close()

def delete_physical_file(relative_path: str):
    bucket_variants = _get_bucket_variants()
    for bucket in bucket_variants:
        try:
            supabase.storage.from_(bucket).remove([relative_path])
            return
        except Exception as e:
            if "not found" in str(e).lower():
                continue
            print(f"Failed to delete file {relative_path} from {bucket}: {e}")

def delete_user_storage(user_id: uuid.UUID):
    bucket_variants = _get_bucket_variants()
    for bucket in bucket_variants:
        try:
            files = supabase.storage.from_(bucket).list(f"{user_id}")
            if files:
                paths_to_delete = [f"{user_id}/{f['name']}" for f in files]
                supabase.storage.from_(bucket).remove(paths_to_delete)
        except Exception as e:
            continue

def get_signed_url(file_path: str, expires_in: int = 3600) -> str:
    bucket_variants = _get_bucket_variants()
    for bucket in bucket_variants:
        try:
            print(f"[DEBUG] Attempting signed URL from bucket: '{bucket}'")
            response = supabase.storage.from_(bucket).create_signed_url(
                file_path, expires_in
            )
            
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
            if "not found" in str(e).lower():
                continue
            print(f"[WARNING] Error with bucket '{bucket}': {e}")

    raise HTTPException(status_code=404, detail="Medical record file not found in any storage bucket.")
