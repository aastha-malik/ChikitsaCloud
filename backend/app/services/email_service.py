import smtplib
import traceback
import requests
from email.message import EmailMessage
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from app.core.config import settings

def send_verification_email(to_email: str, code: str):
    print(f"[DEBUG] Starting email send process to: {to_email}")
    
    # HTML email template
    html_body = f"""
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
            body {{
                margin: 0;
                padding: 0;
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                background-color: #f5f5f5;
            }}
            .email-container {{
                max-width: 600px;
                margin: 0 auto;
                background-color: #ffffff;
            }}
            .header {{
                background: linear-gradient(135deg, #2A8B8B 0%, #1e6b6b 100%);
                padding: 40px 20px;
                text-align: center;
            }}
            .logo {{
                color: #ffffff;
                font-size: 32px;
                font-weight: bold;
                margin: 0;
                letter-spacing: 1px;
            }}
            .tagline {{
                color: #e0f2f1;
                font-size: 14px;
                margin: 10px 0 0 0;
            }}
            .content {{
                padding: 40px 30px;
            }}
            .greeting {{
                font-size: 24px;
                color: #1e293b;
                margin: 0 0 20px 0;
                font-weight: 600;
            }}
            .message {{
                font-size: 16px;
                color: #64748b;
                line-height: 1.6;
                margin: 0 0 30px 0;
            }}
            .code-container {{
                background: linear-gradient(135deg, #e0f2f1 0%, #b2dfdb 100%);
                border-radius: 12px;
                padding: 30px;
                text-align: center;
                margin: 30px 0;
                border: 2px solid #2A8B8B;
            }}
            .code-label {{
                font-size: 14px;
                color: #1e6b6b;
                font-weight: 600;
                margin: 0 0 15px 0;
                text-transform: uppercase;
                letter-spacing: 1px;
            }}
            .code {{
                font-size: 42px;
                font-weight: bold;
                color: #2A8B8B;
                letter-spacing: 8px;
                font-family: 'Courier New', monospace;
                margin: 0;
                text-shadow: 2px 2px 4px rgba(0,0,0,0.1);
            }}
            .expiry {{
                font-size: 14px;
                color: #f97316;
                margin: 15px 0 0 0;
                font-weight: 500;
            }}
            .info-box {{
                background-color: #f8fafc;
                border-left: 4px solid #2A8B8B;
                padding: 20px;
                margin: 30px 0;
                border-radius: 4px;
            }}
            .info-box p {{
                margin: 0;
                font-size: 14px;
                color: #475569;
                line-height: 1.6;
            }}
            .footer {{
                background-color: #f8fafc;
                padding: 30px;
                text-align: center;
                border-top: 1px solid #e2e8f0;
            }}
            .footer-text {{
                font-size: 13px;
                color: #94a3b8;
                margin: 5px 0;
            }}
            .footer-link {{
                color: #2A8B8B;
                text-decoration: none;
            }}
            .security-icon {{
                font-size: 48px;
                margin-bottom: 10px;
            }}
        </style>
    </head>
    <body>
        <div class="email-container">
            <!-- Header -->
            <div class="header">
                <h1 class="logo">🏥 ChikitsaCloud</h1>
                <p class="tagline">Your Personal Health Record Companion</p>
            </div>
            
            <!-- Content -->
            <div class="content">
                <h2 class="greeting">Welcome to ChikitsaCloud! 👋</h2>
                
                <p class="message">
                    Thank you for signing up! We're excited to help you manage your medical records securely and efficiently.
                </p>
                
                <p class="message">
                    To complete your registration, please verify your email address using the code below:
                </p>
                
                <!-- Verification Code -->
                <div class="code-container">
                    <p class="code-label">Your Verification Code</p>
                    <p class="code">{code}</p>
                    <p class="expiry">⏰ Expires in 15 minutes</p>
                </div>
                
                <!-- Info Box -->
                <div class="info-box">
                    <p>
                        <strong>🔒 Security Note:</strong><br>
                        If you didn't create an account with ChikitsaCloud, please ignore this email. 
                        Your security is our priority.
                    </p>
                </div>
                
                <p class="message">
                    Once verified, you'll have access to:
                </p>
                <ul style="color: #64748b; line-height: 1.8; margin: 0 0 20px 20px;">
                    <li>📂 Secure medical record storage</li>
                    <li>👨‍👩‍👧 Family access sharing</li>
                    <li>🏥 Nearby hospital discovery</li>
                    <li>📱 Access from anywhere, anytime</li>
                </ul>
            </div>
            
            <!-- Footer -->
            <div class="footer">
                <p class="footer-text">
                    <strong>ChikitsaCloud</strong><br>
                    Your health data, owned by you.
                </p>
                <p class="footer-text">
                    Need help? Contact us at <a href="mailto:support@chikitsacloud.com" class="footer-link">support@chikitsacloud.com</a>
                </p>
                <p class="footer-text" style="margin-top: 20px;">
                    © 2026 ChikitsaCloud. All rights reserved.
                </p>
            </div>
        </div>
    </body>
    </html>
    """
    
    # Plain text fallback
    plain_text = f"""
Welcome to Chikitsa Cloud!

Your email verification code is: {code}

This code will expire in 15 minutes.

If you did not request this, please ignore this email.

---
ChikitsaCloud - Your Personal Health Record Companion
    """
    
    # Try HTTP bridge first (for Render deployment)
    if settings.EMAIL_BRIDGE_URL:
        try:
            print(f"[DEBUG] Attempting to send via HTTP bridge")
            response = requests.post(
                settings.EMAIL_BRIDGE_URL,
                json={
                    "to": to_email,
                    "subject": "ChikitsaCloud - Verify Your Email",
                    "body": html_body,
                    "plainText": plain_text,
                    "isHtml": True
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
    msg = MIMEMultipart('alternative')
    msg['Subject'] = 'ChikitsaCloud - Verify Your Email'
    msg['From'] = settings.SMTP_EMAIL
    msg['To'] = to_email
    
    # Attach both plain text and HTML versions
    part1 = MIMEText(plain_text, 'plain')
    part2 = MIMEText(html_body, 'html')
    msg.attach(part1)
    msg.attach(part2)

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

