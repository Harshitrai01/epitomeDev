/**
 *  * @author Varun Rawal

 * This class, `OpportunityEmailController`, is a controller for a Lightning Web Component (LWC) or Aura component.
 * It provides methods to fetch contacts, documents, email templates, and send emails with attachments related to an Opportunity.
 * The class is designed to handle email functionality in a Salesforce environment, including rendering email templates and attaching documents.
 *
 * Key Features:
 * - Fetches contacts associated with an Opportunity.
 * - Retrieves documents linked to a Contact.
 * - Fetches and renders email templates.
 * - Sends emails with attachments.
 * - Handles null checks and exceptions to ensure robust execution.
 */

public with sharing class OpportunityEmailController {

    /**
     * Inner class to wrap Contact details for LWC/Aura.
     */
    public class ContactWrapper {
        @AuraEnabled public String label; // Contact name with primary indicator
        @AuraEnabled public String value; // Contact ID
        @AuraEnabled public String email; // Contact email

        // Constructor to initialize the wrapper
        public ContactWrapper(String label, String value, String email) {
            this.label = label;
            this.value = value;
            this.email = email;
        }
    }

    /**
     * Fetches contacts associated with an Opportunity.
     *
     * @param opportunityId The ID of the Opportunity.
     * @return A list of ContactWrapper objects containing contact details.
     * @throws AuraHandledException If the Opportunity ID is null or empty.
     */
    @AuraEnabled
    public static List<ContactWrapper> getContacts(Id opportunityId) {
        // Null check: Ensure Opportunity ID is provided
        if (String.isEmpty(opportunityId)) {
            throw new AuraHandledException('Opportunity ID is required.');
        }

        // Query Opportunity Contact Roles for the given Opportunity ID
        List<OpportunityContactRole> contactRoles = [
            SELECT Contact.Id, Contact.Name, Contact.Email, IsPrimary 
            FROM OpportunityContactRole 
            WHERE OpportunityId = :opportunityId
        ];

        // Create a list of ContactWrapper objects to return
        List<ContactWrapper> contactOptions = new List<ContactWrapper>();
        for (OpportunityContactRole ocr : contactRoles) {
            String contactLabel = ocr.Contact.Name + (ocr.IsPrimary ? ' (Primary)' : '');
            contactOptions.add(new ContactWrapper(contactLabel, ocr.Contact.Id, ocr.Contact.Email));
        }

        system.debug('contactOptions--->' + contactOptions);
        return contactOptions;
    }

    /**
     * Fetches documents linked to a Contact.
     *
     * @param contactId The ID of the Contact.
     * @return A list of ContentDocument objects linked to the Contact.
     * @throws AuraHandledException If the Contact ID is null or empty.
     */
    @AuraEnabled
    public static List<ContentDocument> getDocuments(Id contactId) {
        // Null check: Ensure Contact ID is provided
        if (String.isEmpty(contactId)) {
            throw new AuraHandledException('Contact ID is required.');
        }

        // Query ContentDocumentLinks for the given Contact ID
        List<ContentDocumentLink> docLinks = [
            SELECT ContentDocumentId 
            FROM ContentDocumentLink 
            WHERE LinkedEntityId = :contactId
        ];

        // Extract ContentDocument IDs
        Set<Id> docIds = new Set<Id>();
        for (ContentDocumentLink link : docLinks) {
            docIds.add(link.ContentDocumentId);
        }

        // Return an empty list if no documents are found
        if (docIds.isEmpty()) {
            return new List<ContentDocument>();
        }

        // Query and return ContentDocument details
        return [
            SELECT Id, Title 
            FROM ContentDocument 
            WHERE Id IN :docIds
        ];
    }

    /**
     * Inner class to wrap EmailTemplate details for LWC/Aura.
     */
    public class EmailTemplateWrapper {
        @AuraEnabled public Id id { get; set; } // EmailTemplate ID
        @AuraEnabled public String name { get; set; } // EmailTemplate name
        @AuraEnabled public String subject { get; set; } // EmailTemplate subject
        @AuraEnabled public String htmlValue { get; set; } // EmailTemplate HTML body
        @AuraEnabled public String mergedHtmlValue { get; set; } // Merged HTML body with record data
    }

    /**
     * Fetches and renders email templates for an Opportunity.
     *
     * @param recordId The ID of the Opportunity.
     * @return A list of EmailTemplateWrapper objects containing template details.
     */
    @AuraEnabled
    public static List<EmailTemplateWrapper> getEmailTemplate(Id recordId) {
        List<EmailTemplateWrapper> wrappers = new List<EmailTemplateWrapper>();

        // Query email templates from the specified folder
        List<EmailTemplate> templates = [
            SELECT Id, Name, Subject, HtmlValue 
            FROM EmailTemplate 
            WHERE Folder.DeveloperName = 'Epitome_Opportunity_Templates'
        ];

        // Render each template with the Opportunity data
        for (EmailTemplate template : templates) {
            EmailTemplateWrapper wrapper = new EmailTemplateWrapper();
            wrapper.id = template.Id;
            wrapper.name = template.Name;
            wrapper.subject = template.Subject;
            wrapper.htmlValue = template.HtmlValue;

            // Merge the template with the Opportunity data
            Messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(template.Id, null, recordId);
            wrapper.mergedHtmlValue = email.getHtmlBody();

            wrappers.add(wrapper);
        }

        return wrappers;
    }

    /**
     * Sends an email with an attachment to a Contact.
     *
     * @param opportunityId The ID of the Opportunity.
     * @param contactId The ID of the Contact.
     * @param documentId The ID of the document to attach.
     * @param emailTemplateId The ID of the email template (not used in this method).
     * @param emailBody The HTML body of the email.
     * @throws AuraHandledException If any required parameter is null or empty.
     */
    @AuraEnabled
    public static void sendEmailWithAttachment(Id opportunityId, Id contactId, Id documentId, Id emailTemplateId, String emailBody) {
        // Null check: Ensure all required parameters are provided
        if (String.isEmpty(opportunityId) || String.isEmpty(contactId) || String.isEmpty(documentId) || String.isEmpty(emailBody)) {
            throw new AuraHandledException('All fields are required to send an email.');
        }

        // Fetch Opportunity details
        Opportunity opp = [
            SELECT Owner.Email, Custom_Email_Body__c, Custom_Email_Subject__c
            FROM Opportunity 
            WHERE Id = :opportunityId 
            LIMIT 1
        ];

        // Update Opportunity with custom email subject and body
        if (opp != null) {
            opp.Custom_Email_Subject__c = 'Important Document for You';
            opp.Custom_Email_Body__c = emailBody;
            update opp;
        }

        // Fetch Contact details
        Contact con = [
            SELECT Email 
            FROM Contact 
            WHERE Id = :contactId 
            LIMIT 1
        ];

        // Fetch the latest version of the document
        ContentVersion doc = [
            SELECT Title, VersionData, FileType 
            FROM ContentVersion 
            WHERE ContentDocumentId = :documentId 
            ORDER BY CreatedDate DESC 
            LIMIT 1
        ];

        // Create an email attachment
        Messaging.EmailFileAttachment emailAttachment = new Messaging.EmailFileAttachment();
        emailAttachment.setFileName(doc.Title + '.' + doc.FileType);
        emailAttachment.setContentType('application/' + doc.FileType);
        emailAttachment.setBody(doc.VersionData);

        // Create and send the email
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setSubject('Important Document for You');
        email.setToAddresses(new List<String>{con.Email});
        email.setSenderDisplayName('Opportunity Owner');
        email.setReplyTo(opp.Owner.Email);
        email.setHtmlBody(emailBody);
        email.setFileAttachments(new List<Messaging.EmailFileAttachment>{emailAttachment});

        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email});
    }
}