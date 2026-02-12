import bcrypt
from datetime import datetime, timedelta, timezone
from typing import Optional

from jose import JWTError, jwt

from app.core.config import settings

# We use bcrypt library directly because passlib is deprecated and has bugs
# with newer bcrypt versions and Python 3.12+.


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
    if not hashed_password:
        return False
    try:
        # bcrypt expects bytes for both password and hash
        password_bytes = _truncate_bcrypt_bytes(plain_password)
        hashed_bytes = hashed_password.encode("utf-8")
        return bcrypt.checkpw(password_bytes, hashed_bytes)
    except (ValueError, Exception):
        return False


def get_password_hash(password: str) -> str:
    # Truncate to 72 bytes before hashing to avoid backend errors.
    password_bytes = _truncate_bcrypt_bytes(password)
    # gensalt() defaults to 12 rounds, matching passlib's common default.
    hashed_bytes = bcrypt.hashpw(password_bytes, bcrypt.gensalt())
    return hashed_bytes.decode("utf-8")


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
