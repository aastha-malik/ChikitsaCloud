function doPost(e) {
    try {
        const data = JSON.parse(e.postData.contents);

        // Check if email should be sent as HTML
        if (data.isHtml && data.body) {
            // Send HTML email with plain text fallback
            const options = {
                htmlBody: data.body
            };

            GmailApp.sendEmail(
                data.to,
                data.subject,
                data.plainText || "Please view this email in an HTML-compatible email client.",
                options
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
