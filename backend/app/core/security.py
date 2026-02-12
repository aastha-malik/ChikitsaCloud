from datetime import datetime, timedelta, timezone
from typing import Optional

from jose import JWTError, jwt
from passlib.context import CryptContext

from app.core.config import settings

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def _truncate_bcrypt_bytes(password: str) -> bytes:
    """
    Bcrypt only considers the first 72 BYTES of the password.
    We explicitly truncate at the byte level to avoid ValueError
    with long or multi-byte (e.g. emoji) passwords.
    """
    password_bytes = password.encode("utf-8")
    if len(password_bytes) > 72:
        password_bytes = password_bytes[:72]
    return password_bytes


def verify_password(plain_password: str, hashed_password: str) -> bool:
    # Passlib accepts bytes; we truncate at 72 bytes before verifying.
    return pwd_context.verify(_truncate_bcrypt_bytes(plain_password), hashed_password)


def get_password_hash(password: str) -> str:
    # Truncate to 72 bytes before hashing to avoid backend errors.
    return pwd_context.hash(_truncate_bcrypt_bytes(password))


def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        expire = datetime.now(timezone.utc) + timedelta(
            minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES
        )
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(
        to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM
    )
    return encoded_jwt


def verify_token(token: str):
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        return payload
    except JWTError:
        return None
