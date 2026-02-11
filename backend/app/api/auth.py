from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.schemas.auth import UserSignup, VerifyEmail, UserLogin
from app.services import auth_service

router = APIRouter(prefix="/auth", tags=["Authentication"])

@router.post("/signup")
def signup(user: UserSignup, db: Session = Depends(get_db)):
    """
    Register a new user with email and password.
    Sends a mocked verification code to the console.
    """
    return auth_service.create_user(db, user)

@router.post("/verify-email")
def verify_email(data: VerifyEmail, db: Session = Depends(get_db)):
    """
    Verify use email using the code sent during signup.
    """
    return auth_service.verify_email(db, data)

@router.post("/login")
def login(data: UserLogin, db: Session = Depends(get_db)):
    """
    Login with email and password.
    Returns a dummy token if successful.
    """
    return auth_service.authenticate_user(db, data)
