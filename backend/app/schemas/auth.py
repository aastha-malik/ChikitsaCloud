import re
from pydantic import BaseModel, EmailStr, field_validator

PASSWORD_RULES = (
    "Password must be at least 8 characters and include an uppercase letter, "
    "a lowercase letter, a number, and a special character (!@#$%^&* etc.)"
)

def validate_password_strength(password: str) -> str:
    if len(password) < 8:
        raise ValueError(PASSWORD_RULES)
    if not re.search(r"[A-Z]", password):
        raise ValueError(PASSWORD_RULES)
    if not re.search(r"[a-z]", password):
        raise ValueError(PASSWORD_RULES)
    if not re.search(r"\d", password):
        raise ValueError(PASSWORD_RULES)
    if not re.search(r"[!@#$%^&*(),.?\":{}|<>\-_=+\[\]\\;'/`~]", password):
        raise ValueError(PASSWORD_RULES)
    return password

class UserSignup(BaseModel):
    email: EmailStr
    password: str

    @field_validator("password")
    @classmethod
    def password_strength(cls, v: str) -> str:
        return validate_password_strength(v)

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class VerifyEmail(BaseModel):
    email: EmailStr
    verification_code: str

class ResendVerification(BaseModel):
    email: EmailStr

class ResetPasswordRequest(BaseModel):
    email: EmailStr
    code: str
    new_password: str

    @field_validator("new_password")
    @classmethod
    def password_strength(cls, v: str) -> str:
        return validate_password_strength(v)

class GoogleLoginRequest(BaseModel):
    id_token: str
