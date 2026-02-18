import smtplib
import traceback
import requests
from email.message import EmailMessage
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from app.core.config import settings

def _send_email_core(to_email: str, subject: str, html_content: str, plain_text_content: str) -> bool:
    """
    Internal function to handle the actual sending via HTTP Bridge or SMTP.
    """
    # 1. Try HTTP Bridge (Google Apps Script) - ideal for Render/Cloud where SMTP is blocked
    if settings.EMAIL_BRIDGE_URL:
        try:
            print(f"[DEBUG] Attempting to send '{subject}' via HTTP bridge")
            # Payload designed for Google Apps Script Web App
            payload = {
                "to": to_email,
                "subject": subject,
                "htmlBody": html_content, # Changed from body to htmlBody to be more explicit
                "body": plain_text_content, # Fallback/plain
            }
            
            response = requests.post(
                settings.EMAIL_BRIDGE_URL,
                json=payload,
                timeout=10
            )
            
            if response.status_code == 200:
                print(f"[SUCCESS] Email sent via HTTP bridge to {to_email}")
                return True
            else:
                print(f"[WARNING] HTTP bridge returned status {response.status_code}: {response.text}")
        except Exception as e:
            print(f"[WARNING] HTTP bridge failed: {str(e)}")
    
    # 2. Fallback to SMTP
    try:
        print(f"[DEBUG] Attempting to send '{subject}' via SMTP")
        msg = MIMEMultipart('alternative')
        msg['Subject'] = subject
        msg['From'] = settings.SMTP_EMAIL
        msg['To'] = to_email
        
        part1 = MIMEText(plain_text_content, 'plain')
        part2 = MIMEText(html_content, 'html')
        msg.attach(part1)
        msg.attach(part2)

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
        
        print(f"[SUCCESS] Email sent via SMTP to {to_email}")
        return True
    except Exception as e:
        print(f"[ERROR] Failed to send email via SMTP to {to_email}: {str(e)}")
        # If in debug mode, maybe re-raise? For now, we return False.
        return False

def send_verification_email(to_email: str, code: str):
    subject = "ChikitsaCloud - Verify Your Email"
    
    html_body = f"""<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <style>
        body {{ font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f5f5f5; margin: 0; padding: 0; }}
        .container {{ max-width: 600px; margin: 0 auto; background-color: #ffffff; }}
        .header {{ background: linear-gradient(135deg, #2A8B8B 0%, #1e6b6b 100%); padding: 30px; text-align: center; color: white; }}
        .content {{ padding: 40px 30px; }}
        .code-box {{ background: #e0f2f1; border: 2px solid #2A8B8B; border-radius: 8px; padding: 20px; text-align: center; margin: 30px 0; }}
        .code {{ font-size: 36px; font-weight: bold; color: #2A8B8B; letter-spacing: 5px; font-family: monospace; margin: 0; }}
        .footer {{ background-color: #f8fafc; padding: 20px; text-align: center; color: #94a3b8; font-size: 12px; }}
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1 style="margin:0;">ChikitsaCloud</h1>
            <p style="margin:5px 0 0;">Verify Your Email</p>
        </div>
        <div class="content">
            <h2 style="color: #1e293b;">Welcome!</h2>
            <p style="color: #64748b; font-size: 16px;">Please use the code below to verify your email address. This code will expire in 15 minutes.</p>
            
            <div class="code-box">
                <p style="margin:0 0 10px; color:#1e6b6b; font-weight:600; font-size:12px; text-transform:uppercase;">Verification Code</p>
                <p class="code">{code}</p>
            </div>
            
            <p style="color: #64748b; font-size: 14px;">If you didn't requests this, please ignore this email.</p>
        </div>
        <div class="footer">
            <p>© 2026 ChikitsaCloud. All rights reserved.</p>
        </div>
    </div>
</body>
</html>"""

    plain_text = f"""
Welcome to ChikitsaCloud!

Your verification code is: {code}

This code expires in 15 minutes.
"""
    return _send_email_core(to_email, subject, html_body, plain_text)

def send_password_reset_email(to_email: str, code: str):
    subject = "ChikitsaCloud - Reset Your Password"
    
    html_body = f"""<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <style>
        body {{ font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f5f5f5; margin: 0; padding: 0; }}
        .container {{ max-width: 600px; margin: 0 auto; background-color: #ffffff; }}
        .header {{ background: linear-gradient(135deg, #FF6B6B 0%, #EE5253 100%); padding: 30px; text-align: center; color: white; }}
        .content {{ padding: 40px 30px; }}
        .code-box {{ background: #ffebee; border: 2px solid #FF6B6B; border-radius: 8px; padding: 20px; text-align: center; margin: 30px 0; }}
        .code {{ font-size: 36px; font-weight: bold; color: #FF6B6B; letter-spacing: 5px; font-family: monospace; margin: 0; }}
        .footer {{ background-color: #f8fafc; padding: 20px; text-align: center; color: #94a3b8; font-size: 12px; }}
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1 style="margin:0;">ChikitsaCloud</h1>
            <p style="margin:5px 0 0;">Password Reset Request</p>
        </div>
        <div class="content">
            <h2 style="color: #1e293b;">Reset Your Password</h2>
            <p style="color: #64748b; font-size: 16px;">We received a request to reset your password. Use the code below to proceed.</p>
            
            <div class="code-box">
                <p style="margin:0 0 10px; color:#c62828; font-weight:600; font-size:12px; text-transform:uppercase;">Reset Code</p>
                <p class="code">{code}</p>
            </div>
            
            <p style="color: #64748b; font-size: 14px;">This code expires in 10 minutes. If you didn't request a password reset, you can safely ignore this email.</p>
        </div>
        <div class="footer">
            <p>© 2026 ChikitsaCloud. All rights reserved.</p>
        </div>
    </div>
</body>
</html>"""

    plain_text = f"""
Reset Your Password

Use the following code to reset your ChikitsaCloud password:

{code}

This code expires in 10 minutes.
If you didn't request this, please ignore this email.
"""
    return _send_email_core(to_email, subject, html_body, plain_text)

