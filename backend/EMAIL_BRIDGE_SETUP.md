# Email Bridge Setup for Render Deployment

## Problem
Render.com blocks outbound SMTP connections (ports 25, 465, 587), causing email verification to fail with "Network is unreachable" error.

## Solution
Use Google Apps Script as an HTTP-to-Email bridge.

## Setup Instructions

### Step 1: Create Google Apps Script

1. Go to https://script.google.com/
2. Click "New Project"
3. Replace the default code with:

```javascript
function doPost(e) {
  try {
    const data = JSON.parse(e.postData.contents);
    
    // Send email using Gmail
    GmailApp.sendEmail(
      data.to,
      data.subject,
      data.body
    );
    
    return ContentService.createTextOutput(JSON.stringify({
      success: true,
      message: "Email sent successfully"
    })).setMimeType(ContentService.MimeType.JSON);
    
  } catch (error) {
    return ContentService.createTextOutput(JSON.stringify({
      success: false,
      error: error.toString()
    })).setMimeType(ContentService.MimeType.JSON);
  }
}
```

4. Click "Deploy" → "New deployment"
5. Select type: "Web app"
6. Set:
   - Execute as: **Me**
   - Who has access: **Anyone**
7. Click "Deploy"
8. Copy the Web App URL (looks like: `https://script.google.com/macros/s/XXXXX/exec`)

### Step 2: Update Environment Variables

Add the following to your `.env` file (local) and Render environment variables:

```bash
EMAIL_BRIDGE_URL=https://script.google.com/macros/s/YOUR_SCRIPT_ID/exec
```

### Step 3: Deploy to Render

1. Push changes to GitHub
2. Render will auto-deploy
3. Add `EMAIL_BRIDGE_URL` in Render dashboard:
   - Go to your service
   - Environment tab
   - Add new variable: `EMAIL_BRIDGE_URL` = `<your-script-url>`

## How It Works

1. **Production (Render)**: Uses HTTP bridge (Google Apps Script)
2. **Local Development**: Falls back to SMTP

The code automatically tries HTTP bridge first, then falls back to SMTP if bridge URL is not configured.

## Testing

Test the email service:

```bash
curl -X POST https://your-render-url.onrender.com/auth/signup \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "password": "password123"}'
```

Check logs for:
- `[DEBUG] Attempting to send via HTTP bridge`
- `[SUCCESS] Verification email sent via HTTP bridge to test@example.com`

## Security Notes

- The Google Apps Script runs under your Google account
- Only accepts POST requests with JSON payload
- No authentication required (URL is the secret)
- Consider adding IP whitelisting or API key if needed
