from pydantic_settings import BaseSettings, SettingsConfigDict
from typing import List

class Settings(BaseSettings):
    # App
    PROJECT_NAME: str = "Chikitsa Cloud API"
    DEBUG: bool = False
    
    # Database
    DATABASE_URL: str
    
    # Email (Generic SMTP)
    SMTP_EMAIL: str
    SMTP_PASSWORD: str
    SMTP_SERVER: str 
    SMTP_PORT: int
    
    # Auth
    SECRET_KEY: str
    ALGORITHM: str
    ACCESS_TOKEN_EXPIRE_MINUTES: int
    
    
    # Supabase (Storage & Auth)
    SUPABASE_URL: str
    SUPABASE_KEY: str
    SUPABASE_BUCKET: str = "medical records"

    # CORS
    BACKEND_CORS_ORIGINS: List[str] = ["*"]

    model_config = SettingsConfigDict(env_file=".env", extra="ignore", case_sensitive=True)

settings = Settings()
