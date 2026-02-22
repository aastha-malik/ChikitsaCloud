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
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body {{ 
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; 
            background-color: #F8F9FA; 
            margin: 0; 
            padding: 0; 
            -webkit-font-smoothing: antialiased;
        }}
        .wrapper {{
            width: 100%;
            table-layout: fixed;
            background-color: #F8F9FA;
            padding-bottom: 40px;
        }}
        .container {{ 
            max-width: 600px; 
            margin: 40px auto; 
            background-color: #ffffff; 
            border-radius: 20px;
            overflow: hidden;
            box-shadow: 0 20px 40px rgba(0,0,0,0.08);
        }}
        .header {{ 
            background: linear-gradient(135deg, #FF6B6B 0%, #EE5253 100%); 
            padding: 40px 30px; 
            text-align: center; 
            color: white; 
        }}
        .header h1 {{
            margin: 0;
            font-size: 28px;
            font-weight: 800;
            letter-spacing: -0.5px;
            text-transform: uppercase;
        }}
        .header-bg {{
            opacity: 0.1;
            position: absolute;
            top: 0; right: 0;
        }}
        .content {{ 
            padding: 40px 40px; 
            text-align: center;
        }}
        .icon-container {{
            width: 64px;
            height: 64px;
            background: #FFEBEB;
            border-radius: 16px;
            margin: 0 auto 24px;
            display: flex;
            align-items: center;
            justify-content: center;
        }}
        .code-box {{ 
            background: #FFF5F5; 
            border: 2px dashed #FF6B6B; 
            border-radius: 16px; 
            padding: 30px; 
            text-align: center; 
            margin: 32px 0; 
        }}
        .code {{ 
            font-size: 42px; 
            font-weight: 800; 
            color: #EE5253; 
            letter-spacing: 8px; 
            font-family: 'Courier New', Courier, monospace; 
            margin: 0; 
        }}
        .footer {{ 
            padding: 30px; 
            text-align: center; 
            color: #94A3B8; 
            font-size: 13px;
            border-top: 1px solid #F1F5F9;
        }}
        .btn {{
            display: inline-block;
            padding: 16px 32px;
            background-color: #EE5253;
            color: white;
            text-decoration: none;
            border-radius: 12px;
            font-weight: 700;
            margin-top: 20px;
        }}
        .help-text {{
            color: #64748B;
            font-size: 14px;
            line-height: 1.6;
        }}
    </style>
</head>
<body>
    <div class="wrapper">
        <div class="container">
            <div class="header">
                <h1>ChikitsaCloud</h1>
                <p style="margin:8px 0 0; font-weight: 500; opacity: 0.9;">Security Notification</p>
            </div>
            <div class="content">
                <div style="font-size: 48px; margin-bottom: 20px;">🔐</div>
                <h2 style="color: #1E293B; margin: 0 0 12px; font-size: 24px; font-weight: 700;">Password Reset Request</h2>
                <p class="help-text">We received a request to reset your password. If you didn't make this request, you can safely ignore this email.</p>
                
                <div class="code-box">
                    <p style="margin:0 0 12px; color:#EE5253; font-weight:700; font-size:12px; text-transform:uppercase; letter-spacing: 1px;">Use this SECURE code to reset</p>
                    <p class="code">{code}</p>
                </div>
                
                <p class="help-text" style="font-size: 13px;">This code is valid for <b>10 minutes</b> and can only be used once.</p>
            </div>
            <div class="footer">
                <p style="margin: 0 0 10px;">© 2026 ChikitsaCloud Inc. • Secure Health Access</p>
                <p style="margin: 0;">If you're having trouble, contact our support team.</p>
            </div>
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

def send_feedback_email(rating: int, message: str, timestamp: str):
    """
    Sends the user feedback to the developer/admin email.
    """
    subject = f"New Feedback Received: {rating} Stars"
    
    # We send it to the SMTP_EMAIL (the owner)
    to_email = settings.SMTP_EMAIL
    
    html_body = f"""<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <style>
        body {{ font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f8fafc; margin: 0; padding: 20px; }}
        .card {{ max-width: 500px; margin: 0 auto; background: white; border-radius: 12px; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.1); overflow: hidden; border: 1px solid #e2e8f0; }}
        .header {{ background: #1e293b; color: white; padding: 20px; text-align: center; }}
        .rating {{ font-size: 32px; color: #f59e0b; margin: 10px 0; }}
        .content {{ padding: 30px; line-height: 1.6; color: #334155; }}
        .message-box {{ background: #f1f5f9; padding: 15px; border-radius: 8px; font-style: italic; margin-top: 10px; border-left: 4px solid #94a3b8; }}
        .footer {{ padding: 15px; background: #f8fafc; text-align: center; font-size: 12px; color: #94a3b8; border-top: 1px solid #e2e8f0; }}
    </style>
</head>
<body>
    <div class="card">
        <div class="header">
            <h2 style="margin:0;">New User Feedback</h2>
            <div class="rating">{"★" * rating}{"☆" * (5-rating)}</div>
        </div>
        <div class="content">
            <p><strong>Rating:</strong> {rating} / 5</p>
            <p><strong>Submitted At:</strong> {timestamp}</p>
            <p><strong>Feedback Message:</strong></p>
            <div class="message-box">
                {message if message else "No message provided."}
            </div>
        </div>
        <div class="footer">
            ChikitsaCloud Feedback System
        </div>
    </div>
</body>
</html>"""

    plain_text = f"""
NEW FEEDBACK RECEIVED
---------------------
Rating: {rating}/5
Timestamp: {timestamp}

Message:
{message if message else "No message provided."}
"""
    return _send_email_core(to_email, subject, html_body, plain_text)

