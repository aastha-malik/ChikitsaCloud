import smtplib
import traceback
from email.message import EmailMessage
from app.core.config import settings

def send_verification_email(to_email: str, code: str):
    # print(f"[DEBUG] Starting email send process to: {to_email}")
    # msg = EmailMessage()
    # ... (omitted logic)
    print(f"[INFO] Email verification disabled. Skipping email to {to_email}")
    pass
