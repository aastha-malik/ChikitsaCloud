from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def verify_password(plain_password: str, hashed_password: str) -> bool:
    # bcrypt has a 72-byte limit; truncate to avoid errors
    return pwd_context.verify(plain_password[:72], hashed_password)

def get_password_hash(password: str) -> str:
    # bcrypt has a 72-byte limit; truncate to avoid errors
    return pwd_context.hash(password[:72])
