/**
 * @author Varun Rawal
 *
 * This class, `downloadDocumentCmpController`, is a controller for a Lightning Web Component (LWC) or Aura component.
 * It provides methods to fetch related files for a record, check for associated contacts, and copy documents to a Contact record.
 * The class is designed to handle file management and document sharing in a Salesforce environment.
 *
 * Key Features:
 * - Fetches related files for a given record (Opportunity, Account, Contact, etc.).
 * - Checks if an Opportunity has associated contacts.
 * - Copies documents to a Contact record.
 * - Handles null checks and exceptions to ensure robust execution.
 */

public with sharing class downloadDocumentCmpController {

    /**
     * Wrapper class to hold file details.
     */
    public class FileWrapper {
        @AuraEnabled public Id ContentDocumentId { get; set; }
        @AuraEnabled public String Title { get; set; }
        @AuraEnabled public String DocumentType { get; set; }

        // Constructor to initialize the wrapper object
        public FileWrapper(Id contentDocumentId, String title, String documentType) {
            this.ContentDocumentId = contentDocumentId;
            this.Title = title;
            this.DocumentType = documentType;
        }
    }

    /**
     * Fetches related files for a given record ID.
     *
     * @param recordId The ID of the record (Opportunity, Account, Contact, etc.).
     * @return A list of FileWrapper objects containing ContentDocumentId, Title, and Document_Type__c.
     */
    @AuraEnabled(cacheable=true)
    public static List<FileWrapper> getRelatedFilesByRecordId(String recordId) {
        try {
            // Null check: Ensure recordId is not empty
            if (String.isEmpty(recordId)) {
                throw new AuraHandledException('Record ID is required.');
            }

            // Query all ContentDocumentLinks associated with the given record
            List<ContentDocumentLink> files = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :recordId];

            // Extract ContentDocument IDs
            List<ID> fileIDs = new List<ID>();
            for (ContentDocumentLink docLink : files) {
                fileIDs.add(docLink.ContentDocumentId);
            }

            // Fetch document details from ContentVersion, including Document_Type__c
            List<ContentVersion> docs = [
                SELECT ContentDocumentId, Title, Document_Type__c 
                FROM ContentVersion 
                WHERE ContentDocumentId IN :fileIDs
            ];

            // Create a list of wrapper objects
            List<FileWrapper> wrapperList = new List<FileWrapper>();
            for (ContentVersion doc : docs) {
                wrapperList.add(new FileWrapper(doc.ContentDocumentId, doc.Title, doc.Document_Type__c));
            }

            return wrapperList;
        } catch (Exception ex) {
            // Handle exceptions and return a meaningful error message
            throw new AuraHandledException('Error fetching related files: ' + ex.getMessage());
        }
    }

    /**
     * Checks if an Opportunity has associated contacts.
     *
     * @param opportunityId The ID of the Opportunity.
     * @return A list of Contact records associated with the Opportunity.
     */
    @AuraEnabled(cacheable=true)
    public static List<Contact> checkOpportunityContact(Id opportunityId) {
        try {
            // Null check: Ensure opportunityId is not empty
            if (String.isEmpty(opportunityId)) {
                throw new AuraHandledException('Opportunity ID is required.');
            }

            // Query contacts linked to the Opportunity via OpportunityContactRole
            List<Contact> contacts = [
                SELECT Id, Name, Email, Phone FROM Contact 
                WHERE Id IN (
                    SELECT ContactId FROM OpportunityContactRole WHERE OpportunityId = :opportunityId
                )
            ];

            return contacts;
        } catch (Exception ex) {
            // Handle exceptions and return a meaningful error message
            throw new AuraHandledException('Error fetching contact details: ' + ex.getMessage());
        }
    }

    /**
     * Fetches related files for a given Contact ID.
     *
     * @param contactId The ID of the Contact.
     * @return A list of FileWrapper objects containing ContentDocumentId, Title, and Document_Type__c.
     */
    @AuraEnabled(cacheable=true)
    public static List<FileWrapper> getRelatedFilesByContactId(Id contactId) {
        try {
            // Null check: Ensure contactId is not empty
            if (String.isEmpty(contactId)) {
                throw new AuraHandledException('Contact ID is required.');
            }

            // Query all ContentDocumentLinks associated with the given Contact
            List<ContentDocumentLink> files = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :contactId];

            // Extract ContentDocument IDs
            List<ID> fileIDs = new List<ID>();
            for (ContentDocumentLink docLink : files) {
                fileIDs.add(docLink.ContentDocumentId);
            }

            // Fetch document details from ContentVersion, including Document_Type__c
            List<ContentVersion> docs = [
                SELECT ContentDocumentId, Title, Document_Type__c 
                FROM ContentVersion 
                WHERE ContentDocumentId IN :fileIDs
            ];

            // Create a list of wrapper objects
            List<FileWrapper> wrapperList = new List<FileWrapper>();
            for (ContentVersion doc : docs) {
                wrapperList.add(new FileWrapper(doc.ContentDocumentId, doc.Title, doc.Document_Type__c));
            }

            return wrapperList;
        } catch (Exception ex) {
            // Handle exceptions and return a meaningful error message
            throw new AuraHandledException('Error fetching related files: ' + ex.getMessage());
        }
    }

    /**
     * Copies a document to a Contact record.
     *
     * @param contactId The ID of the Contact.
     * @param documentId The ID of the Document.
     * @return A response string indicating success ('true') or failure ('false').
     */
    @AuraEnabled
    public static string copyDocumentsToContact(Id contactId, Id documentId) {
        try {
            string response = '';

            // Null check: Ensure contactId and documentId are valid before proceeding
            if (contactId != null && contactId != 'undefined' && documentId != null && documentId != 'undefined') {
                // Create a new ContentDocumentLink to associate the document with the Contact
                ContentDocumentLink newLink = new ContentDocumentLink(
                    ContentDocumentId = documentId,
                    LinkedEntityId = contactId,
                    ShareType = 'V' // Viewer permission
                );
                insert newLink;
                response = 'true';
            } else {
                response = 'false';
            }
            return response;
        } catch (Exception ex) {
            // Handle exceptions and return a meaningful error message
            throw new AuraHandledException('Error copying document: ' + ex.getMessage());
        }
    }
}