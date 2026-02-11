from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    # Database
    DATABASE_URL: str = "postgresql://postgres:chikitsa_cloud_password@db.lpzrzjforpbfahvsyscz.supabase.co:5432/postgres"
    
    # Email (Gmail SMTP)
    SMTP_EMAIL: str = "aasthamalik1810@gmail.com"
    SMTP_PASSWORD: str = "chikitsa_cloud_password"
    SMTP_SERVER: str = "smtp.gmail.com"
    SMTP_PORT: int = 587

    # App
    SECRET_KEY: str = "changethis"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

settings = Settings()
