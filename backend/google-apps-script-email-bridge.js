function doPost(e) {
    try {
        const data = JSON.parse(e.postData.contents);

        // Check if email should be sent as HTML
        if (data.isHtml) {
            // Send HTML email using Gmail
            GmailApp.sendEmail(
                data.to,
                data.subject,
                "", // Plain text body (empty for HTML-only)
                {
                    htmlBody: data.body
                }
            );
        } else {
            // Send plain text email
            GmailApp.sendEmail(
                data.to,
                data.subject,
                data.body
            );
        }

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
