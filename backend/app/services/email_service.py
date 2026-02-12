import smtplib
import traceback
from email.message import EmailMessage
from app.core.config import settings

def send_verification_email(to_email: str, code: str):
    print(f"[DEBUG] Starting email send process to: {to_email}")
    msg = EmailMessage()
    msg.set_content(f"""\
Hello!

Your verification code for Chikitsa Cloud is: {code}

This code expires in 15 minutes.

If you didn't request this, please ignore this email.
""")

    msg['Subject'] = 'Verify your email - Chikitsa Cloud'
    msg['From'] = settings.SMTP_EMAIL
    msg['To'] = to_email

    try:
        # Use SSL for port 465, or STARTTLS for port 587
        if str(settings.SMTP_PORT) == "465":
            print(f"[DEBUG] Attempting SMTP_SSL connection to {settings.SMTP_SERVER}:465")
            with smtplib.SMTP_SSL(settings.SMTP_SERVER, 465, timeout=10) as server:
                server.login(settings.SMTP_EMAIL, settings.SMTP_PASSWORD)
                server.send_message(msg)
        else:
            print(f"[DEBUG] Attempting SMTP connection to {settings.SMTP_SERVER}:{settings.SMTP_PORT}")
            with smtplib.SMTP(settings.SMTP_SERVER, settings.SMTP_PORT, timeout=10) as server:
                server.starttls()
                server.login(settings.SMTP_EMAIL, settings.SMTP_PASSWORD)
                server.send_message(msg)
        print(f"[SUCCESS] Email sent successfully to {to_email}")
    except Exception as e:
        # If port 587 failed, try 465 as a fallback automatically
        if str(settings.SMTP_PORT) != "465":
            try:
                print(f"[INFO] Port {settings.SMTP_PORT} failed, trying port 465 with SSL as fallback...")
                with smtplib.SMTP_SSL(settings.SMTP_SERVER, 465, timeout=10) as server:
                    server.login(settings.SMTP_EMAIL, settings.SMTP_PASSWORD)
                    server.send_message(msg)
                print(f"[SUCCESS] Email sent successfully to {to_email} via fallback port 465")
                return
            except Exception as fallback_e:
                print(f"[ERROR] Fallback to 465 also failed: {str(fallback_e)}")
        
        print(f"[ERROR] Failed to send email to {to_email}")
        print(f"[ERROR] Details: {str(e)}")
        # We don't raise here to allow create_user to return the success message 
        # (even if email failed, user can be manually verified if they see logs)
        # But we print it clearly.
        print(f"[CRITICAL] MANUAL VERIFICATION CODE for {to_email} is: {code}")
