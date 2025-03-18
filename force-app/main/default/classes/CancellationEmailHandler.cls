/*
*********************************************************
Apex Class Name    : CancellationEmailHandler
Created Date       : [Insert Date]
@description       : This class is used to capture inbound emails for the cancellation of plots and save attached documents 
                     as email attachments. It implements the Messaging.InboundEmailHandler interface to process inbound emails.
@author            : Harshit Rai
Modification Log:
Ver   Date         Author               Modification
1.0   [Insert Date] Harshit Rai         Initial Version
*********************************************************
*/
global class CancellationEmailHandler implements Messaging.InboundEmailHandler {

    /*
    *********************************************************
    @Method Name    : handleInboundEmail
    @author         : Harshit Rai
    @description    : Processes inbound emails to capture cancellation requests, save email details as an activity, 
                       and store email attachments as ContentVersion records linked to the Opportunity.
    @param          : email - Messaging.InboundEmail object containing the email details.
    @param          : envelope - Messaging.InboundEnvelope object containing envelope details.
    @return         : Messaging.InboundEmailResult - Result of the email processing.
    *********************************************************
    */
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();

        try {
            // Step 1: Extract email subject and thread identifier
            String subject = email.subject;
            String threadIdentifier = '';
            if (email.references != null) {
                threadIdentifier = email.references[0];
            } else if (email.inReplyTo != null) {
                threadIdentifier = email.inReplyTo;
            }
            threadIdentifier = threadIdentifier.trim();

            // Step 2: Query EmailMessage to find the related Opportunity
            List<EmailMessage> emailMessages = [
                SELECT Id, RelatedToId 
                FROM EmailMessage 
                WHERE MessageIdentifier = :threadIdentifier 
                LIMIT 1
            ];

            Id oppId;
            if (!emailMessages.isEmpty()) {
                oppId = emailMessages[0].RelatedToId;
                System.debug('OpportunityId : ' + oppId);
            } else {
                System.debug('No EmailMessage record found with MessageIdentifier: ' + threadIdentifier);
            }

            // Step 3: Query Opportunity to ensure it exists
            Opportunity opp = [SELECT Id FROM Opportunity WHERE Id = :oppId LIMIT 1];
            if (opp == null) {
                System.debug('No related Opportunity found for ID: ' + oppId);
                return result;
            }

            // Step 4: Create an EmailMessage record for the activity timeline
            EmailMessage emailActivity = new EmailMessage();
            emailActivity.RelatedToId = opp.Id;
            emailActivity.Subject = email.subject;
            emailActivity.TextBody = (email.plainTextBody != null ? email.plainTextBody : email.htmlBody);
            emailActivity.HtmlBody = email.htmlBody;
            emailActivity.FromAddress = envelope.fromAddress;
            if (email.toAddresses != null && email.toAddresses.size() > 0) {
                emailActivity.ToAddress = String.join(email.toAddresses, ';');
            }
            emailActivity.MessageDate = System.now();
            emailActivity.Status = '2';
            emailActivity.Incoming = true;
            insert emailActivity;
            System.debug('Email activity inserted with id: ' + emailActivity.Id);

            // Step 5: Process email attachments
            if (email.binaryAttachments != null && !email.binaryAttachments.isEmpty()) {
                List<ContentVersion> contentVersionList = new List<ContentVersion>();

                for (Messaging.InboundEmail.BinaryAttachment attachment : email.binaryAttachments) {
                    ContentVersion content = new ContentVersion();
                    content.Title = attachment.filename;
                    content.PathOnClient = '/' + attachment.filename;
                    content.VersionData = attachment.body;
                    content.IsMajorVersion = true;
                    contentVersionList.add(content);
                }
                insert contentVersionList;
                System.debug(contentVersionList.size() + ' Attachments saved.');

                // Step 6: Link attachments to the EmailMessage record
                List<ContentDocumentLink> contentLinks = new List<ContentDocumentLink>();

                for (ContentVersion cv : [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :contentVersionList]) {
                    ContentDocumentLink link = new ContentDocumentLink();
                    link.ContentDocumentId = cv.ContentDocumentId;
                    link.LinkedEntityId = emailActivity.Id;
                    link.ShareType = 'V';
                    contentLinks.add(link);
                }
                insert contentLinks;
                System.debug('Successfully linked attachments to EmailMessage: ' + emailActivity.Id);
            } else {
                System.debug('No attachments found in email.');
            }

        } catch (Exception e) {
            System.debug('Error processing inbound email: ' + e.getMessage() + '\n' + e.getStackTraceString());
        }

        return result;
    }
}