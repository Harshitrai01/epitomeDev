/*
*********************************************************
Apex Class Name    : PaymentReceiptQueueable
Created Date       : 20th March 2024
@description       : For Sending Payment Reciept To Customer
@author            : Harshit Kumar Rai
*********************************************************
*/

public with sharing class PaymentReceiptQueueable implements Queueable, Database.AllowsCallouts {
    private Map<String, String> idToEmailMap;
    private List<Id> recordIds;
    
    public PaymentReceiptQueueable(Map<String, String> idToEmailMap, List<Id> recordIds) {
        this.idToEmailMap = idToEmailMap;
        this.recordIds = recordIds;
    }
    
    public void execute(QueueableContext context) {
        sendPaymentReceipts(idToEmailMap,recordIds);
    }
    
    /*
    *********************************************************
    @Method Name    : sendPaymentReceipts
    @author         : Harshit Kumar Rai
    @description    : To Send Payment Reciept To Customer 
    ********************************************************
    */
    public static void sendPaymentReceipts(Map<String, String> paymentMap, List<Id> recordIds) {
        // List to store emails to be sent
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        
        // Loop through each payment ID and corresponding email
        for (Id paymentId : recordIds) {
            if (paymentMap.containsKey(paymentId)) {
                String recipientEmail = paymentMap.get(paymentId);
                
                // Construct email
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(new String[]{recipientEmail});
                email.setSubject('Your Payment Receipt from Epitome Projects LLP');
                
                // HTML Body
                String emailBody = 
                    '<!DOCTYPE html>' +
                    '<html>' +
                    '<head>' +
                    '    <meta charset="UTF-8">' +
                    '    <title>Payment Receipt</title>' +
                    '    <style>' +
                    '        body { font-family: Arial, sans-serif; color: #333; margin: 0; padding: 20px; }' +
                    '        .container { border: 1px solid #ddd; border-radius: 8px; padding: 20px; max-width: 600px; margin: auto; background-color: #f9f9f9; }' +
                    '        .header { background-color: #4CAF50; color: #fff; padding: 10px; text-align: center; border-radius: 8px 8px 0 0; font-size: 18px; font-weight: bold; }' +
                    '        .content { padding: 15px 0; font-size: 14px; line-height: 1.6; }' +
                    '        .footer { font-size: 12px; color: #555; text-align: center; margin-top: 20px; border-top: 1px solid #ddd; padding-top: 10px; }' +
                    '        .highlight { color: #4CAF50; font-weight: bold; }' +
                    '    </style>' +
                    '</head>' +
                    '<body>' +
                    '    <div class="container">' +
                    '        <div class="header">Your Payment Receipt</div>' +
                    '        <div class="content">' +
                    '            <p>Dear Customer,</p>' +
                    '            <p>Please find your payment receipt attached below for your reference.</p>' +
                    '            <p>For any queries, please contact <span class="highlight">Epitome Team</span>.</p>' +
                    '            <p class="highlight">This is a system-generated email; please do not reply to this email.</p>' +
                    '            <p>Thanks for choosing <span class="highlight">Epitome Projects LLP</span>.</p>' +
                    '        </div>' +
                    '        <div class="footer">' +
                    '            Warm Regards,<br>' +
                    '            <strong>Epitome Projects LLP</strong>' +
                    '        </div>' +
                    '    </div>' +
                    '</body>' +
                    '</html>';
                
                email.setHtmlBody(emailBody);
                
                PageReference pdfPage = Page.paymentReceiptPdf;
                pdfPage.getParameters().put('id', paymentId);
                Blob pdfBlob;
                if(!test.isrunningtest()){
                    pdfBlob = pdfPage.getContentAsPDF();
                }
                else{
                    pdfBlob= Blob.valueOf('test');
                }
                
                // Attach the PDF
                Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                attachment.setFileName('Payment_Receipt' + '.pdf');
                attachment.setBody(pdfBlob);
                attachment.setContentType('application/pdf');
                email.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });
                // Add email to list
                emails.add(email);
            }
        }
        // Send the emails
        if (!emails.isEmpty()) {
            Messaging.SendEmailResult[] results = Messaging.sendEmail(emails, false);
        }
    }
    
}