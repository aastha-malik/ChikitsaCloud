import smtplib
from email.message import EmailMessage
from app.core.config import settings

def send_verification_email(to_email: str, code: str):
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
        # SMTP_SSL is for 465, but we use starttls on 587
        with smtplib.SMTP(settings.SMTP_SERVER, settings.SMTP_PORT) as server:
            server.starttls()
            server.login(settings.SMTP_EMAIL, settings.SMTP_PASSWORD)
            server.send_message(msg)
            print(f"Email sent successfully to {to_email}")
    except Exception as e:
        print(f"Failed to send email: {e}")
        # In production, we might want to log this properly or retry
        # For now, we print and let the flow continue (or raise if critical)
        raise e
