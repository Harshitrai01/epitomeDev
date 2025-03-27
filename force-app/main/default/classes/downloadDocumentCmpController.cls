/**********
Apex Class Name : downloadDocumentCmpController
Apex Test Class Name: 
Created Date: March 10, 2025
@description : This class is a controller for a Lightning Web Component (LWC) or Aura component. It provides methods to fetch related files for a record, check for associated contacts, and copy documents to a Contact record.
@author : Ayush Nanda 
Modify By : Varun Rawal
Modify Date: 
**********/

public with sharing class downloadDocumentCmpController {

    /*
    **********
    Class Name : FileWrapper
    author: Varun Rawal
    description: Wrapper class to hold file details.
    **********
    */
    public class FileWrapper {
        @AuraEnabled public Id contentDocumentId { get; set; }
        @AuraEnabled public String title { get; set; }
        @AuraEnabled public String documentType { get; set; }

        // Constructor to initialize the wrapper object
        public FileWrapper(Id contentDocumentId, String title, String documentType) {
            this.contentDocumentId = contentDocumentId;
            this.title = title;
            this.documentType = documentType;
        }
    }

    /*
    **********
    Method Name : getRelatedFilesByRecordId
    author: Varun Rawal
    description: Fetches related files for a given record ID.
    @params: 
        - recordId: The ID of the record (Opportunity, Account, Contact, etc.).
    @return: A list of FileWrapper objects containing ContentDocumentId, Title, and Document_Type__c.
    **********
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

    /*
    **********
    Method Name : checkOpportunityContact
    author: Varun Rawal
    description: Checks if an Opportunity has associated contacts.
    @params: 
        - opportunityId: The ID of the Opportunity.
    @return: A list of Contact records associated with the Opportunity.
    **********
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

    /*
    **********
    Method Name : getRelatedFilesByContactId
    author: Varun Rawal
    description: Fetches related files for a given Contact ID.
    @params: 
        - contactId: The ID of the Contact.
    @return: A list of FileWrapper objects containing ContentDocumentId, Title, and Document_Type__c.
    **********
    */
    @AuraEnabled(cacheable=true)
    public static List<FileWrapper> getRelatedFilesByContactId(Id contactId, Id oppId) {
        try {
            // Null check: Ensure contactId is not empty
            if (String.isEmpty(contactId)) {
                throw new AuraHandledException('Contact ID is required.');
            }

            // Null check: Ensure opportunityId is not empty
            if (String.isEmpty(oppId)) {
                throw new AuraHandledException('Opportunity ID is required.');
            }

            Opportunity opp = [SELECT Id, Name,Plot_Name__c FROM Opportunity WHERE Id = :oppId LIMIT 1];

if (opp == null) {
    throw new AuraHandledException('Opportunity is Empty.');
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
    AND Title LIKE :('%' +'__'+opp.Plot_Name__c+'__'+opp.Name)
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

    /*
    **********
    Method Name : copyDocumentsToContact
    author: Varun Rawal
    description: Copies a document to a Contact record. While updating or inserting, use as user.
    @params: 
        - contactId: The ID of the Contact.
        - documentId: The ID of the Document.
    @return: A response string indicating success ('true') or failure ('false').
    **********
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
                insert newLink; // Insert as the current user
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