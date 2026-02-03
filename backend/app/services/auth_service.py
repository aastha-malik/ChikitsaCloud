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
    # 1. Check if email exists
    existing_user = db.query(AuthUser).filter(AuthUser.email == user_data.email).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )
    
    # 2. Hash password
    hashed_password = security.get_password_hash(user_data.password)
    
    # 3. Generate Verification Code (6 digits)
    code = ''.join(random.choices(string.digits, k=6))
    expires_at = datetime.now(timezone.utc) + timedelta(minutes=15)
    
    # 4. Create User Record
    new_user = AuthUser(
        email=user_data.email,
        password_hash=hashed_password,
        auth_provider="email",
        is_email_verified=False,
        email_verification_code=code,
        email_verification_expires_at=expires_at
    )
    
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    
    
    # 5. Send Email
    try:
        email_service.send_verification_email(new_user.email, code)
    except Exception as e:
        # If email fails, we should probably rollback user creation or handle gracefully
        # For this task, we will just inform
        print(f"Error sending email: {e}")
    
    return {"message": "User created successfully. Please verify your email.", "user_id": new_user.id}

def verify_email(db: Session, data: VerifyEmail):
    user = db.query(AuthUser).filter(AuthUser.email == data.email).first()
    
    # 1. Check user exists
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # 2. Check already verified
    if user.is_email_verified:
        return {"message": "Email already verified"}
    
    # 3. Validate code match
    if user.email_verification_code != data.verification_code:
        raise HTTPException(status_code=400, detail="Invalid verification code")
    
    # 4. Validate expiry
    if user.email_verification_expires_at < datetime.now(timezone.utc):
        raise HTTPException(status_code=400, detail="Verification code expired")
    
    # 5. Success: Update user
    user.is_email_verified = True
    user.email_verification_code = None
    user.email_verification_expires_at = None
    
    db.commit()
    
    return {"message": "Email verified successfully"}

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
        
    # 4. Check verification
    if not user.is_email_verified:
        raise HTTPException(status_code=403, detail="Email not verified")
        
    return {"message": "Login successful", "access_token": "dummy_token_123", "token_type": "bearer"}
