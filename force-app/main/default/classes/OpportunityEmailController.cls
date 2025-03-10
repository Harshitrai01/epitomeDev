public with sharing class OpportunityEmailController {
    
    public class ContactWrapper {
    @AuraEnabled public String label;
    @AuraEnabled public String value;
    @AuraEnabled public String email;
    
    public ContactWrapper(String label, String value, String email) {
        this.label = label;
        this.value = value;
        this.email = email;
    }
}

@AuraEnabled
public static List<ContactWrapper> getContacts(Id opportunityId) {
    if (String.isEmpty(opportunityId)) {
        throw new AuraHandledException('Opportunity ID is required.');
    }
    
    // Query Opportunity Contact Roles for the given Opportunity ID
    List<OpportunityContactRole> contactRoles = [
        SELECT Contact.Id, Contact.Name, Contact.Email, IsPrimary 
        FROM OpportunityContactRole 
        WHERE OpportunityId = :opportunityId
    ];
    
    List<ContactWrapper> contactOptions = new List<ContactWrapper>();
    
    for (OpportunityContactRole ocr : contactRoles) {
        String contactLabel = ocr.Contact.Name + (ocr.IsPrimary ? ' (Primary)' : '');
        contactOptions.add(new ContactWrapper(contactLabel, ocr.Contact.Id, ocr.Contact.Email));
    }
    
    system.debug('contactOptions--->'+contactOptions);
    return contactOptions;
}
    
    @AuraEnabled
    public static List<ContentDocument> getDocuments(Id contactId) {
        if (String.isEmpty(contactId)) {
            throw new AuraHandledException('Contact ID is required.');
        }
        
        List<ContentDocumentLink> docLinks = [
            SELECT ContentDocumentId 
            FROM ContentDocumentLink 
            WHERE LinkedEntityId = :contactId
        ];
        
        Set<Id> docIds = new Set<Id>();
        for (ContentDocumentLink link : docLinks) {
            docIds.add(link.ContentDocumentId);
        }
        
        if (docIds.isEmpty()) {
            return new List<ContentDocument>();
        }
        
        return [
            SELECT Id, Title 
            FROM ContentDocument 
            WHERE Id IN :docIds
        ];
    }
    
    // @AuraEnabled
    // public static List<EmailTemplate> getEmailTemplates() {
    //     return [
    //         SELECT Id, Name, Subject, HtmlValue 
    //         FROM EmailTemplate 
    //         WHERE Folder.DeveloperName = 'Epitome_Opportunity_Templates'
    //     ];
    // }
    
    public class EmailTemplateWrapper {
        @AuraEnabled public Id id { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String subject { get; set; }
        @AuraEnabled public String htmlValue { get; set; }
        @AuraEnabled public String mergedHtmlValue { get; set; } // This will hold the merged HTML body
    }
    @AuraEnabled
    public static List<EmailTemplateWrapper> getEmailTemplate(Id recordId) {
        List<EmailTemplateWrapper> wrappers = new List<EmailTemplateWrapper>();
        
        // Query the email templates
        List<EmailTemplate> templates = [
            SELECT Id, Name, Subject, HtmlValue 
            FROM EmailTemplate 
            WHERE Folder.DeveloperName = 'Epitome_Opportunity_Templates'
        ];
        
        // Render each template with the record data
        for (EmailTemplate template : templates) {
            EmailTemplateWrapper wrapper = new EmailTemplateWrapper();
            wrapper.id = template.Id;
            wrapper.name = template.Name;
            wrapper.subject = template.Subject;
            wrapper.htmlValue = template.HtmlValue;
            
            // Merge the template with the record data
            Messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(template.Id, null, recordId);
            wrapper.mergedHtmlValue = email.getHtmlBody();
            
            wrappers.add(wrapper);
        }
        
        return wrappers;
    }
    
    
    @AuraEnabled
    public static void sendEmailWithAttachment(Id opportunityId, Id contactId, Id documentId, Id emailTemplateId, String emailBody) {
        if (String.isEmpty(opportunityId) || String.isEmpty(contactId) || String.isEmpty(documentId) || String.isEmpty(emailBody)) {
            throw new AuraHandledException('All fields are required to send an email.');
        }
        
        Opportunity opp = [
            SELECT Owner.Email ,Custom_Email_Body__c,Custom_Email_Subject__c
            FROM Opportunity 
            WHERE Id = :opportunityId 
            LIMIT 1
        ];
        if(opp!=null){
            opp.Custom_Email_Subject__c='Important Document for You';
            opp.Custom_Email_Body__c=emailBody;

            update opp;
        }
        
        Contact con = [
            SELECT Email 
            FROM Contact 
            WHERE Id = :contactId 
            LIMIT 1
        ];
        
        ContentVersion doc = [
            SELECT Title, VersionData, FileType 
            FROM ContentVersion 
            WHERE ContentDocumentId = :documentId 
            ORDER BY CreatedDate DESC 
            LIMIT 1
        ];
        
        Messaging.EmailFileAttachment emailAttachment = new Messaging.EmailFileAttachment();
        emailAttachment.setFileName(doc.Title + '.' + doc.FileType);
        emailAttachment.setContentType('application/' + doc.FileType);
        emailAttachment.setBody(doc.VersionData);
        
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