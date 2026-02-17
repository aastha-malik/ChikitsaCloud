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
