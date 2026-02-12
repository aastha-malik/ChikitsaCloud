import random
import string
from datetime import datetime, timedelta, timezone
from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from app.models.user import AuthUser
from app.schemas.auth import UserSignup, VerifyEmail, UserLogin
from app.core import security
from app.services import email_service

def create_user(db: Session, user_data: UserSignup):
    print(f"[DEBUG] Starting signup for email: {user_data.email}")
    # 1. Check if email exists
    existing_user = db.query(AuthUser).filter(AuthUser.email == user_data.email).first()
    if existing_user:
        print(f"[WARNING] Signup failed: Email {user_data.email} already registered")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )
    
    # 2. Hash password
    hashed_password = security.get_password_hash(user_data.password)
    
    # 3. Generate Verification Code (6 digits)
    # code = ''.join(random.choices(string.digits, k=6))
    # print(f"[DEBUG] Generated verification code for {user_data.email}: {code}")
    # expires_at = datetime.now(timezone.utc) + timedelta(minutes=15)
    
    # 4. Create User Record (Auto-verified)
    new_user = AuthUser(
        email=user_data.email,
        password_hash=hashed_password,
        auth_provider="email",
        is_email_verified=True,  # Bypass verification
        email_verification_code=None,
        email_verification_expires_at=None
    )
    
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    print(f"[DEBUG] User created in DB with ID: {new_user.id}")
    
    # 5. Send Email (Disabled)
    # try:
    #     email_service.send_verification_email(new_user.email, code)
    # except Exception as e:
    #     print(f"[CRITICAL] Backend failed to send email. MANUAL VERIFICATION CODE for {new_user.email} is: {code}")
    
    return {
        "message": "User created successfully.", 
        "user_id": str(new_user.id),
        "access_token": security.create_access_token(data={"sub": str(new_user.id)}),
        "token_type": "bearer"
    }

# def verify_email(db: Session, data: VerifyEmail):
#     user = db.query(AuthUser).filter(AuthUser.email == data.email).first()
#     
#     # 1. Check user exists
#     if not user:
#         raise HTTPException(status_code=404, detail="User not found")
#     
#     # 2. Check already verified
#     if user.is_email_verified:
#         return {"message": "Email already verified"}
#     
#     # 3. Validate code match
#     if user.email_verification_code != data.verification_code:
#         raise HTTPException(status_code=400, detail="Invalid verification code")
#     
#     # 4. Validate expiry
#     if user.email_verification_expires_at < datetime.now(timezone.utc):
#         raise HTTPException(status_code=400, detail="Verification code expired")
#     
#     # 5. Success: Update user
#     user.is_email_verified = True
#     user.email_verification_code = None
#     user.email_verification_expires_at = None
#     
#     db.commit()
#     
#     return {
#         "message": "Email verified successfully",
#         "access_token": security.create_access_token(data={"sub": str(user.id)}),
#         "token_type": "bearer",
#         "user_id": str(user.id)
#     }

def authenticate_user(db: Session, data: UserLogin):
    user = db.query(AuthUser).filter(AuthUser.email == data.email).first()
    
    # 1. Check user exists
    if not user:
        raise HTTPException(status_code=401, detail="Invalid credentials")
    
    # 2. Check auth provider
    if user.auth_provider != "email":
        raise HTTPException(status_code=400, detail=f"Please login with {user.auth_provider}")
        
    # 3. Check password
    if not user.password_hash or not security.verify_password(data.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid credentials")
        
    # 4. Check verification (Disabled)
    # if not user.is_email_verified:
    #     raise HTTPException(status_code=403, detail="Email not verified")
        
    return {
        "message": "Login successful",
        "access_token": security.create_access_token(data={"sub": str(user.id)}),
        "token_type": "bearer",
        "user_id": str(user.id)
    }

# def resend_verification(db: Session, email: str):
#     print(f"[DEBUG] Resending verification code to: {email}")
#     user = db.query(AuthUser).filter(AuthUser.email == email).first()
#     
#     if not user:
#         print(f"[WARNING] Resend failed: User {email} not found")
#         raise HTTPException(status_code=404, detail="User not found")
#     
#     if user.is_email_verified:
#         print(f"[INFO] Resend ignored: User {email} already verified")
#         raise HTTPException(status_code=400, detail="Email already verified")
#     
#     # Generate NEW code
#     code = ''.join(random.choices(string.digits, k=6))
#     print(f"[DEBUG] Generated NEW verification code for {email}: {code}")
#     expires_at = datetime.now(timezone.utc) + timedelta(minutes=15)
#     
#     user.email_verification_code = code
#     user.email_verification_expires_at = expires_at
#     db.commit()
#     
#     try:
#         email_service.send_verification_email(email, code)
#     except Exception as e:
#         print(f"[CRITICAL] Backend failed to resend email. MANUAL CODE for {email} is: {code}")
#         
#     return {"message": "Verification code resent successfully"}

def delete_user_account(db: Session, user_id: str):
    user = db.query(AuthUser).filter(AuthUser.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # cascade="all, delete-orphan" in AuthUser model handles profile, contacts, and metadata deletion.
    # We still need to delete physical medical files and handle family relations that might not cascade via ORM.
    from app.services import storage_service
    from app.models.family_access import FamilyInviteToken, FamilyAccessRequest, FamilyMedicalAccess
    
    storage_service.delete_user_storage(user.id)
    
    # Explicitly delete family related data where user is owner or viewer/requester
    db.query(FamilyInviteToken).filter(FamilyInviteToken.owner_user_id == user.id).delete()
    db.query(FamilyAccessRequest).filter(
        (FamilyAccessRequest.owner_user_id == user.id) | (FamilyAccessRequest.requester_user_id == user.id)
    ).delete()
    db.query(FamilyMedicalAccess).filter(
        (FamilyMedicalAccess.owner_user_id == user.id) | (FamilyMedicalAccess.viewer_user_id == user.id)
    ).delete()
    
    db.delete(user)
    db.commit()
    return {"message": "Account deleted successfully"}
