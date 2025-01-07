public class LeadWhatsAppSender {
    
    public static void sendMessage(String recipientPhoneNumber, String messageText) {
        String phoneNumberId = '517125364821559';
        String accessToken = 'EAAIk7ZBMSYXIBO2sI2GCf5fwvGs7ksXuJJHZBySxYOJuU5rN2Od0iC2ce5MGwFBdMRQdCpqLRTrLHPzRbcpcMm6ET7xN6TihvzjkuOq3k5IQS4DGEdC3zkVFzlWIhgRdVeYJnlTZAnTcIz7NJHJKooATzaaEVr1LaRymieUbavFVX0HdaOKZBBb6pfkZBzSVg0LidfzUB480SLKdXLD4ZAYVCJ11cZD';
        String endpoint = 'https://graph.facebook.com/v21.0/' + phoneNumberId + '/messages';
        String jsonBody = '{"messaging_product": "whatsapp", "to": "' + recipientPhoneNumber + '", "text": { "body": "' + messageText + '" }}';
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('Authorization', 'Bearer ' + accessToken);
        req.setHeader('Content-Type', 'application/json');
        req.setBody(jsonBody);
        System.debug('Body-->>'+jsonBody);
        
        Http http = new Http();
        HttpResponse res = http.send(req);
     
        if (res.getStatusCode() == 200) {
            System.debug('Message sent successfully: ' + res.getBody());
        } else {
            System.debug('Failed to send message. Status Code: ' + res.getStatusCode());
            System.debug('Response: ' + res.getBody());
        }
    }
    
    public static void sendEmail() {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        
        mail.setToAddresses(new String[] {'harshit.rai@saasworx.ai'});
        
        // Set the email subject
        mail.setSubject('Test Email from Apex');
        
        // Set the email body (plain text or HTML format)
        String body = '<p>Hi Harshit,</p>';
        body += '<p>This is a test email sent from Salesforce Apex.</p>';
        body += '<p>Regards,<br/>Your Salesforce System</p>';
        
        // Set the email body as HTML
        mail.setHtmlBody(body);
        
        // Send the email
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}