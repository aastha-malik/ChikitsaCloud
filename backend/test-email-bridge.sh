#!/bin/bash

# Test Google Apps Script Email Bridge
# Replace YOUR_BRIDGE_URL with the actual URL from Google Apps Script

BRIDGE_URL="YOUR_BRIDGE_URL_HERE"

curl -X POST "$BRIDGE_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "aasthamalik1810@gmail.com",
    "subject": "Test Email from ChikitsaCloud",
    "body": "This is a test email to verify the bridge is working!"
  }'

echo ""
echo "Check your email inbox for the test message!"
