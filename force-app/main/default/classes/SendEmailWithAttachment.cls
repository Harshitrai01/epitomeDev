/**********
Apex Class Name : SendEmailWithAttachment
Apex Test Class Name: 
Created Date: March 10, 2025
@description : This class is used to send emails with attachments based on Contact IDs and file titles. It retrieves documents linked to Contacts, filters them by title, and attaches them to emails before sending.
@author : Varun Rawal
Modify By : 
Modify Date: 
**********/

public with sharing class SendEmailWithAttachment {
    
    /**********
    Method Name : sendEmailWithAttachments
    @author: Varun Rawal
    @description: This invocable method sends emails with attachments. It processes a list of `EmailRequest` objects, retrieves documents linked to Contacts, filters them by title, and sends emails with the filtered documents as attachments.
    @params: emailRequests - A list of `EmailRequest` objects containing email details and Contact IDs.
    @return: void
    **********/
    @InvocableMethod(label='Send Email with Attachments' description='Sends an email with attachments based on ContactId and file title')
    public static void sendEmailWithAttachments(List<EmailRequest> emailRequests) {
        // Null check: Ensure the input list is not null or empty
        if (emailRequests == null || emailRequests.isEmpty()) {
            System.debug('emailRequests is Empty or Null');
        } else {
            // Collect Contact IDs for bulk query
            Set<Id> contactIds = new Set<Id>();
            Map<Id, EmailRequest> emailRequestMap = new Map<Id, EmailRequest>();
            
            for (EmailRequest req : emailRequests) {
                // Null check: Ensure Contact ID is provided
                if (req.contactId != null) {
                    contactIds.add(req.contactId);
                    emailRequestMap.put(req.contactId, req);
                }
            }
            
            // Step 1: Retrieve ContentDocumentLink records linked to given Contact IDs
            Map<Id, Set<Id>> contactToDocumentIdsMap = new Map<Id, Set<Id>>();
            Map<Id, Id> documentToContactMap = new Map<Id, Id>();
            
            for (ContentDocumentLink cdl : [
                SELECT ContentDocumentId, LinkedEntityId 
                FROM ContentDocumentLink 
                WHERE LinkedEntityId IN :contactIds
            ]) {
                if (!contactToDocumentIdsMap.containsKey(cdl.LinkedEntityId)) {
                    contactToDocumentIdsMap.put(cdl.LinkedEntityId, new Set<Id>());
                }
                contactToDocumentIdsMap.get(cdl.LinkedEntityId).add(cdl.ContentDocumentId);
                documentToContactMap.put(cdl.ContentDocumentId, cdl.LinkedEntityId);
            }
            
            // Step 2: Query ContentDocuments matching the title criteria
            Map<Id, List<Messaging.EmailFileAttachment>> contactAttachmentsMap = new Map<Id, List<Messaging.EmailFileAttachment>>();
            
            if (!documentToContactMap.isEmpty()) {
                List<ContentDocument> documents = [ 
                    SELECT Id, Title, LatestPublishedVersionId, FileExtension 
                    FROM ContentDocument 
                    WHERE Id IN :documentToContactMap.keySet()
                ];
                
                Set<Id> contentDocumentIds = new Set<Id>();
                for (ContentDocument doc : documents) {
                    // Null check: Ensure fileTypeName is provided and matches the document title
                    if (emailRequests[0].fileTypeName != null && doc.Title.contains(emailRequests[0].fileTypeName)) {
                        contentDocumentIds.add(doc.Id);
                    }
                }
                
                // Step 3: Retrieve the actual file content (Latest Version)
                List<ContentVersion> contentVersions = [
                    SELECT Id, VersionData, Title, ContentDocumentId, FileExtension 
                    FROM ContentVersion 
                    WHERE ContentDocumentId IN :contentDocumentIds
                ];
                
                // Map files to contacts
                for (ContentVersion cv : contentVersions) {
                    Id contactId = documentToContactMap.get(cv.ContentDocumentId);
                    if (contactId != null) {
                        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                        // Set the file name with the correct extension
                        attachment.setFileName(cv.Title + '.' + cv.FileExtension);
                        attachment.setBody(cv.VersionData);
                        
                        if (!contactAttachmentsMap.containsKey(contactId)) {
                            contactAttachmentsMap.put(contactId, new List<Messaging.EmailFileAttachment>());
                        }
                        contactAttachmentsMap.get(contactId).add(attachment);
                    }
                }
            }
            
            // Step 4: Sending emails
            List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
            
            for (Id contactId : contactIds) {
                EmailRequest req = emailRequestMap.get(contactId);
                // Null check: Ensure recipient email is provided
                if (req == null || String.isEmpty(req.recipientEmail)) continue;
                
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(new List<String>{req.recipientEmail});
                email.setSubject(req.subject);
                email.setHTMLBody(req.body);
                email.setSaveAsActivity(true);
                
                // Attach files if available
                if (contactAttachmentsMap.containsKey(contactId)) {
                    email.setFileAttachments(contactAttachmentsMap.get(contactId));
                }
                
                emails.add(email);
            }
            
            // Send Emails
            if (!emails.isEmpty()) {
                try {
                    Messaging.sendEmail(emails);
                } catch (Exception e) {
                    // Log the error if email sending fails
                    System.debug('Error sending emails: ' + e.getMessage());
                }
            }
        }
    }
    
    /**********
    Inner Class Name : EmailRequest
    @description : This inner class structures email request details for the invocable method.
    @author : Varun Rawal
    **********/
    public class EmailRequest {
        @InvocableVariable(label='Recipient Email' required=true)
        public String recipientEmail;
        
        @InvocableVariable(label='Subject' required=true)
        public String subject;
        
        @InvocableVariable(label='Body' required=true)
        public String body;
        
        @InvocableVariable(label='Contact ID' required=true)
        public Id contactId;
        
        @InvocableVariable(label='File Type Name' required=true)
        public String fileTypeName;
    }
}