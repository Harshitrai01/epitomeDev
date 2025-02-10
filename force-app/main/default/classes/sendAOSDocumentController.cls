/**
 * @File        : sendAOSDocumentController.cls
 * @Author      : [Jaidev SIngh]
 * @Company     : [SaasWorx Consulting Pvt Ldt]
 * @Created Date: [05-02-2025]
 * @Modified Date: [07-02-2025] (Last Modified)
 * @Description : This Apex controller is designed for a Lightning component to manage document retrieval  
 *                and email sending functionalities for AOS (Agreement of Sale) documents.  
 *                
 *                Features:
 *                1. Fetches ContentDocuments associated with a given Contact ID.  
 *                2. Sends an AOS document via email to the Contact using a predefined email template.  
 *                3. Retrieves Contact, Opportunity, and User details to dynamically populate the email.  
 *                4. Attaches the selected document (ContentVersion) as a PDF in the email.  
 *                
 *                The controller ensures that the required records exist and handles errors gracefully  
 *                using AuraHandledException.
 */

public with sharing class sendAOSDocumentController {
    @AuraEnabled(cacheable=true)
    public static List<ContentDocument> getDocumentsByContactId(Id contactId) {
        List<ContentDocumentLink> documentLinks = [
            SELECT ContentDocumentId, ContentDocument.Title 
            FROM ContentDocumentLink 
            WHERE LinkedEntityId = :contactId
        ];
        
        List<ContentDocument> documents = new List<ContentDocument>();
        for (ContentDocumentLink docLink : documentLinks) {
            ContentDocument doc = [SELECT Title FROM ContentDocument WHERE Id = :docLink.ContentDocumentId LIMIT 1];
            documents.add(doc);
        }
        return documents;
    }

    @AuraEnabled
    public static String sendDocumentEmail(Id contactId, Id documentId, Id opportunityId) {
        try {
            // Retrieve Contact Email
            Contact contact = [SELECT Name, Email FROM Contact WHERE Id = :contactId LIMIT 1];
            if (contact == null || String.isEmpty(contact.Email)) {
                throw new AuraHandledException('Contact does not have an email address.');
            }

            // Retrieve Opportunity Details
            Opportunity opp = [SELECT Plot_Name__c, Base_Price_per_Sq_Ft__c, Sale_Value_Amount__c, Collected_Amount__c FROM Opportunity WHERE Id = :opportunityId LIMIT 1];

            // Retrieve the Current User Details
            User currentUser = [SELECT Name, CompanyName, Phone, Email FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

            // Retrieve the Document (ContentVersion)
            ContentVersion contentVersion = [SELECT Title, VersionData FROM ContentVersion WHERE ContentDocumentId = :documentId LIMIT 1];
            if (contentVersion == null) {
                throw new AuraHandledException('Document not found.');
            }

            // Fetch the Email Template
            EmailTemplate template = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'AOS_Email_Template' LIMIT 1];

            // Create the Email Message
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setTemplateId(template.Id);
            mail.setTargetObjectId(contactId);  // Merge fields (like {!Contact.Name}) will resolve automatically
            mail.setWhatId(opportunityId);  // This is for opportunity-related merge fields
            mail.setSaveAsActivity(false);

            // Attach the document
            Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
            attachment.setFileName(contentVersion.Title);
            attachment.setBody(contentVersion.VersionData);
            attachment.setContentType('application/pdf');  

            mail.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });

            // Send the Email
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });

            return 'Email sent successfully.';
        } catch (Exception e) {
            throw new AuraHandledException('Error sending email: ' + e.getMessage());
        }
    }
}