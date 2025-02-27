/*
 Owner: Harshit Rai
 Purpose: To Send Plot Cancellation Mail To Customer
 */
public with sharing class SendCancellationEmail {
    
    @AuraEnabled
    public static void sendEmailForCancellation(String oppId) {
        try {
            
            Opportunity opp = [SELECT Id, Contact__c, Contact__r.Name, Contact__r.Email, Owner.Name 
                               FROM Opportunity 
                               WHERE Id = :oppId LIMIT 1];

            if (opp.Contact__c == null || String.isEmpty(opp.Contact__r.Email)) {
                throw New AuraHandledException('No Contact Email found. Email not sent.');
            }

            List<ContentVersion> attachmentList = [SELECT Title, VersionData, FileType, ContentDocumentId
                                                   FROM ContentVersion 
                                                   WHERE Title = 'Cancellation Document' 
                                                   ORDER BY CreatedDate DESC 
                                                   LIMIT 1];

            if (attachmentList.isEmpty()) {
                System.debug('No attachment found. Email will be sent without an attachment.');
            }

            // Assign customer & agent names
            String customerName = (opp.Contact__r.Name != null) ? opp.Contact__r.Name : 'Customer';
            String agentName = (opp.Owner.Name != null) ? opp.Owner.Name : 'Epitome Team';
            String customerEmail = opp.Contact__r.Email;

            
            String emailBody = '<!DOCTYPE html>' +
            '<html>' +
            '<head>' +
            '    <meta charset="UTF-8">' +
            '    <title>Cancellation Document Request</title>' +
            '</head>' +
            '<body style="font-family: Arial, sans-serif; font-size: 14px; color: #333; line-height: 1.6; background-color: #f4f4f4; margin: 0; padding: 0;">' +
            '    <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="background-color: #f4f4f4; padding: 20px;">' +
            '        <tr><td align="center">' +
            '            <table role="presentation" width="600px" cellspacing="0" cellpadding="0" border="0" style="background-color: #ffffff; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);">' +
            '                <tr><td>' +
            '                    <p style="margin-bottom: 15px;">Dear ' + customerName + ',</p>' +
            '                    <p style="margin-bottom: 15px;">I hope this message finds you well.</p>' +
            '                    <p style="margin-bottom: 15px;">Please find attached the cancellation document required to process your refund. Kindly complete the form and send it back at your earliest convenience.</p>' +
            '                    <p style="margin-bottom: 15px;">If you have any questions or need further assistance, please do not hesitate to call us.</p>' +
            '                    <p style="margin-bottom: 15px;">Thank you for your cooperation.</p>' +
            '                    <p style="margin-bottom: 5px;">Best regards,</p>' +
            '                    <p style="margin-bottom: 5px; font-weight: bold;">' + agentName + '</p>' +
            '                    <p style="margin-bottom: 5px;">Epitome Projects LLP</p>' +
            '                </td></tr>' +
            '                <tr><td style="text-align: center; padding-top: 20px; font-size: 12px; color: #777;">' +
            '                    <p style="margin: 0;">Epitome Projects LLP. All Rights Reserved.</p>' +
            '                </td></tr>' +
            '            </table>' +
            '        </td></tr>' +
            '    </table>' +
            '</body>' +
            '</html>';

            // Create email
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[]{customerEmail});
            String emailSubject = 'Plot Cancellation Document Request [OppId: ' + oppId + ']';
            email.setSubject(emailSubject);
            email.setHtmlBody(emailBody);
            email.setWhatId(oppId);
            email.setTreatTargetObjectAsRecipient(false);
            email.setSaveAsActivity(true);
            
            // Query EmailServicesAddress records into a list to avoid query exceptions if no records are found.
            List<EmailServicesAddress> esaList = [
                SELECT LocalPart, EmailDomainName 
                FROM EmailServicesAddress 
                WHERE DeveloperName = 'CancellationEmailHandler'
                LIMIT 1
            ];
            
            if (!esaList.isEmpty()) {
                EmailServicesAddress esa = esaList[0];
                if (esa.LocalPart != null && esa.EmailDomainName != null) {
                    String replyToAddress = esa.LocalPart + '@' + esa.EmailDomainName;
                    email.setReplyTo(replyToAddress);
                } else {
                    throw New AuraHandledException('One or both fields LocalPart, EmailDomainName From EmailServicesAddress are null.');
                }
            } else {
                throw New AuraHandledException('No EmailServicesAddress record found for DeveloperName: CancellationEmailHandler');
            }

            
            if (!attachmentList.isEmpty()) {
                Messaging.EmailFileAttachment attachmentFile = new Messaging.EmailFileAttachment();
                attachmentFile.setFilename(attachmentList[0].Title + '.' + attachmentList[0].FileType);
                attachmentFile.setBody(attachmentList[0].VersionData);
                email.setFileAttachments(new Messaging.EmailFileAttachment[]{attachmentFile});
            }
            
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
            
            // Attach documents to email seperately.
            /*
             List<EmailMessage> emList = [
                SELECT Id 
                FROM EmailMessage 
                WHERE RelatedToId = :opp.Id 
                  AND Subject = :emailSubject 
                ORDER BY MessageDate DESC 
                LIMIT 1
            ];
            if (!emList.isEmpty() && !attachmentList.isEmpty()) {
                EmailMessage emRecord = emList[0];
                System.debug('Found EmailMessage record with Id: ' + emRecord.Id);
                
                // Create a ContentDocumentLink to link the file to the EmailMessage record so it appears in the timeline.
                ContentDocumentLink cdl = new ContentDocumentLink();
                // Use the ContentDocumentId from the queried ContentVersion.
                cdl.ContentDocumentId = attachmentList[0].ContentDocumentId;
                cdl.LinkedEntityId = emRecord.Id;
                cdl.ShareType = 'V';  // 'V' for Viewer
                insert cdl;
				
                System.debug('Successfully linked attachment to EmailMessage record.');
            }*/
            
            
        
        } catch (Exception e) {
            throw New AuraHandledException(e.getMessage());
        }
    }
}