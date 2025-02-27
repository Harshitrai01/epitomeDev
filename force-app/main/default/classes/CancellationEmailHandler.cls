/*
 Owner: Harshit Rai
 Purpose: To Capture Inbound Email For Cancellation Of Plots And Save Attached Documents In Email Attachemnts
 */
global class CancellationEmailHandler implements Messaging.InboundEmailHandler {
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();

        try {
            String subject = email.subject;
            String threadIdentifier = '';
            if (email.references != null) {
                threadIdentifier = email.references[0];
            } else if (email.inReplyTo != null) {
                threadIdentifier = email.inReplyTo;
            }
            threadIdentifier = threadIdentifier.trim();
            
            List<EmailMessage> emailMessages = [ SELECT Id, RelatedToId FROM EmailMessage 
                                                	WHERE MessageIdentifier = :threadIdentifier LIMIT 1
        										];
            
            Id oppId;
            if (!emailMessages.isEmpty()) {
                oppId = emailMessages[0].RelatedToId;
                System.Debug('OpportunityId : '+oppId);
            } else {
                System.debug('No EmailMessage record found with MessageIdentifier: ' + threadIdentifier);
            }

            Opportunity opp = [SELECT Id FROM Opportunity WHERE Id = :oppId LIMIT 1];
            if (opp == null) {
                System.debug('No related Opportunity found for ID: ' + oppId);
                return result;
            }
            
            // Create an EmailMessage record so that the email appears in the activity timeline.
            EmailMessage emailActivity = new EmailMessage();
            emailActivity.RelatedToId = opp.Id;
            emailActivity.Subject = email.subject;
            // Use plainTextBody if available; otherwise fall back to htmlBody.
            emailActivity.TextBody = (email.plainTextBody != null ? email.plainTextBody : email.htmlBody);
            emailActivity.HtmlBody = email.htmlBody;
            emailActivity.FromAddress = envelope.fromAddress;
            if(email.toAddresses != null && email.toAddresses.size() > 0){
                emailActivity.ToAddress = String.join(email.toAddresses, ';');
            }
            emailActivity.MessageDate = System.now();
            emailActivity.Status = '2';
            emailActivity.Incoming = true;
            insert emailActivity;
            System.debug('Email activity inserted with id: ' + emailActivity.Id);

            // Step 3: Process Email Attachments
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

                // Step 4: Retrieve ContentDocument IDs and Link to Opportunity
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