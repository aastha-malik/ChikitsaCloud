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
        print(f"[DEBUG] Attempting SMTP connection to {settings.SMTP_SERVER}:{settings.SMTP_PORT}")
        with smtplib.SMTP(settings.SMTP_SERVER, settings.SMTP_PORT) as server:
            server.set_debuglevel(0) # Set to 1 for protocol level logs
            server.starttls()
            print(f"[DEBUG] SMTP Login as {settings.SMTP_EMAIL}")
            server.login(settings.SMTP_EMAIL, settings.SMTP_PASSWORD)
            server.send_message(msg)
            print(f"[SUCCESS] Email sent successfully to {to_email}")
    except Exception as e:
        print(f"[ERROR] Failed to send email to {to_email}")
        print(f"[ERROR] Details: {str(e)}")
        print(f"[ERROR] Traceback: {traceback.format_exc()}")
        raise e
