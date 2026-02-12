from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from app.database import get_db
from app.schemas.auth import UserSignup, VerifyEmail, UserLogin, ResendVerification
from app.services import auth_service
from app.api.deps import get_current_user
from app.models.user import AuthUser
from typing import Optional

router = APIRouter(prefix="/auth", tags=["Authentication"])

@router.post("/signup")
def signup(user: UserSignup, db: Session = Depends(get_db)):
    """
    Register a new user with email and password.
    Sends a mocked verification code to the console.
    """
    return auth_service.create_user(db, user)

# @router.post("/verify-email")
# def verify_email(data: VerifyEmail, db: Session = Depends(get_db)):
#     """
#     Verify use email using the code sent during signup.
#     """
#     return auth_service.verify_email(db, data)

@router.post("/token")
def login_for_swagger(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    """
    Dedicated endpoint for Swagger UI Authorize button.
    Uses Form Data as required by OAuth2 standard.
    """
    login_data = UserLogin(email=form_data.username, password=form_data.password)
    return auth_service.authenticate_user(db, login_data)

@router.post("/login")
def login(data: UserLogin, db: Session = Depends(get_db)):
    """
    Login endpoint for the Mobile App.
    Uses JSON body.
    """
    return auth_service.authenticate_user(db, data)

# @router.post("/resend-verification")
# def resend_verification(data: ResendVerification, db: Session = Depends(get_db)):
#     """
#     Resend verification code to the user's email.
#     """
#     return auth_service.resend_verification(db, data.email)

@router.delete("/account")
def delete_account(
    current_user: AuthUser = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Deletes the current user's account and all associated data.
    """
    return auth_service.delete_user_account(db, current_user.id)
