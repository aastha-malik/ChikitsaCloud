# 🚀 QUICK FIX: Email Verification Setup (5 Minutes)

## The Problem
Your Render deployment shows: `OSError: [Errno 101] Network is unreachable`

This is because **Render blocks SMTP ports**. The fix is already deployed, you just need to add one environment variable.

---

## ✅ Step-by-Step Solution

### Step 1: Create Google Apps Script (2 minutes)

1. **Open**: https://script.google.com/
2. **Click**: "New Project" (top left)
3. **Delete** the default code
4. **Copy-paste** the code from `google-apps-script-email-bridge.js` in this folder
5. **Click**: "Deploy" → "New deployment"
6. **Select**: Type = "Web app"
7. **Configure**:
   - Execute as: **Me (your-email@gmail.com)**
   - Who has access: **Anyone**
8. **Click**: "Deploy"
9. **Authorize**: Grant permissions when prompted
10. **Copy**: The Web App URL (looks like `https://script.google.com/macros/s/AKfycby.../exec`)

### Step 2: Add to Render (1 minute)

1. **Go to**: https://dashboard.render.com/
2. **Select**: Your ChikitsaCloud service
3. **Click**: "Environment" tab (left sidebar)
4. **Click**: "Add Environment Variable"
5. **Add**:
   - Key: `EMAIL_BRIDGE_URL`
   - Value: `<paste-the-url-from-step-1>`
6. **Click**: "Save Changes"

Render will auto-redeploy (takes ~2 minutes).

---

## 🧪 Test It

After Render redeploys, try signing up again. You should see in the logs:

```
[DEBUG] Attempting to send via HTTP bridge
[SUCCESS] Verification email sent via HTTP bridge to user@example.com
```

Instead of the old error:
```
[ERROR] Failed to send email: Network is unreachable
```

---

## 🔍 Troubleshooting

### If you still see errors:

1. **Check Render logs** for `[DEBUG] Attempting to send via HTTP bridge`
   - If you DON'T see this → Environment variable not set correctly
   - If you DO see this + error → Google Apps Script issue

2. **Test Google Apps Script directly**:
   ```bash
   curl -X POST "YOUR_SCRIPT_URL" \
     -H "Content-Type: application/json" \
     -d '{"to":"your-email@gmail.com","subject":"Test","body":"Test email"}'
   ```
   
   Should return: `{"success":true,"message":"Email sent successfully"}`

3. **Common issues**:
   - Script not deployed as "Anyone" can access
   - Wrong URL copied (must end with `/exec`)
   - Gmail authorization not granted

---

## 📝 Current Status

✅ Code is deployed to Render (as of 16:10:04 UTC)
❌ EMAIL_BRIDGE_URL not set yet (that's why it's still trying SMTP)

Once you add the environment variable, emails will work immediately!
