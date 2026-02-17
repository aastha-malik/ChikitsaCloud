import smtplib
import traceback
import requests
from email.message import EmailMessage
from app.core.config import settings

def send_verification_email(to_email: str, code: str):
    print(f"[DEBUG] Starting email send process to: {to_email}")
    
    # Try HTTP bridge first (for Render deployment)
    if settings.EMAIL_BRIDGE_URL:
        try:
            print(f"[DEBUG] Attempting to send via HTTP bridge")
            response = requests.post(
                settings.EMAIL_BRIDGE_URL,
                json={
                    "to": to_email,
                    "subject": "Chikitsa Cloud - Email Verification",
                    "body": f"""Welcome to Chikitsa Cloud!

Your email verification code is: {code}

This code will expire in 15 minutes.

If you did not request this, please ignore this email."""
                },
                timeout=10
            )
            
            if response.status_code == 200:
                print(f"[SUCCESS] Verification email sent via HTTP bridge to {to_email}")
                return True
            else:
                print(f"[WARNING] HTTP bridge returned status {response.status_code}: {response.text}")
        except Exception as e:
            print(f"[WARNING] HTTP bridge failed: {str(e)}")
    
    # Fallback to SMTP (for local development)
    print(f"[DEBUG] Attempting to send via SMTP")
    msg = EmailMessage()
    msg.set_content(f"""
    Welcome to Chikitsa Cloud!
    
    Your email verification code is: {code}
    
    This code will expire in 15 minutes.
    
    If you did not request this, please ignore this email.
    """)
    
    msg['Subject'] = 'Chikitsa Cloud - Email Verification'
    msg['From'] = settings.SMTP_EMAIL
    msg['To'] = to_email

    try:
        # Use SMTP_SSL for 465, or starttls for 587
        if settings.SMTP_PORT == 465:
            with smtplib.SMTP_SSL(settings.SMTP_SERVER, settings.SMTP_PORT) as server:
                server.login(settings.SMTP_EMAIL, settings.SMTP_PASSWORD)
                server.send_message(msg)
        else:
            with smtplib.SMTP(settings.SMTP_SERVER, settings.SMTP_PORT) as server:
                server.starttls()
                server.login(settings.SMTP_EMAIL, settings.SMTP_PASSWORD)
                server.send_message(msg)
        
        print(f"[SUCCESS] Verification email sent via SMTP to {to_email}")
        return True
    except Exception as e:
        print(f"[ERROR] Failed to send email to {to_email}: {str(e)}")
        traceback.print_exc()
        return False

