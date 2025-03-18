/**
 *  * @author Varun Rawal

 * This class, `KYCVerificationController`, is a controller for Lightning Web Components (LWC) or Aura components.
 * It provides methods to handle KYC (Know Your Customer) verification processes, including fetching contact details,
 * managing document upload configurations, updating sub-document types, and checking file sizes for uploads.
 *
 * Key Features:
 * - Fetches contact details associated with an Opportunity.
 * - Retrieves document upload configuration settings.
 * - Updates the sub-document type field on an Opportunity record.
 * - Validates and processes file uploads, including size checks and renaming.
 * - Handles exceptions and null checks gracefully to ensure robust functionality.
 */

public with sharing class KYCVerificationController {

    /**
     * This method fetches contact details associated with a given Opportunity.
     * It is annotated with @AuraEnabled(cacheable=true) to allow client-side caching in LWC.
     *
     * @param opportunityId The ID of the Opportunity to fetch associated contacts.
     * @return A list of Contact records associated with the Opportunity.
     * @throws AuraHandledException If the Opportunity ID is invalid or an error occurs during the query.
     */
    @AuraEnabled(cacheable=true)
    public static List<Contact> checkOpportunityContact(Id opportunityId) {
        List<Contact> contacts = new List<Contact>();
        
        try {
            // Validate that the opportunityId parameter is not empty or null
            if (String.isEmpty(opportunityId)) {
                throw new AuraHandledException('Opportunity ID is required.');
            }

            // Query the Contact records associated with the given Opportunity
            contacts = [
                SELECT Id, Name, Email, Phone 
                FROM Contact 
                WHERE Id IN (
                    SELECT ContactId 
                    FROM OpportunityContactRole 
                    WHERE OpportunityId = :opportunityId
                )
            ];

            return contacts;

        } catch (Exception ex) {
            // Handle any unexpected exceptions and provide a user-friendly error message
            throw new AuraHandledException('Error fetching contact details: ' + ex.getMessage());
        }
    }

    /**
     * This method retrieves document upload configuration settings.
     * It is annotated with @AuraEnabled(cacheable=true) to allow client-side caching in LWC.
     *
     * @return A list of Document_Upload_Specification__c records containing the file size limit.
     * @throws AuraHandledException If an error occurs during the query.
     */
    @AuraEnabled(cacheable=true)
    public static List<Document_Upload_Specification__c> getConfiguration() {
        List<Document_Upload_Specification__c> configRecords = new List<Document_Upload_Specification__c>();

        try {
            // Query the Document_Upload_Specification__c object to retrieve the file size limit
            configRecords = [
                SELECT File_Size_Limit__c
                FROM Document_Upload_Specification__c 
                WHERE Name = 'Specification'
            ];
            
            return configRecords;
        } catch (Exception ex) {
            // Handle any unexpected exceptions and provide a user-friendly error message
            throw new AuraHandledException('Error fetching document upload configuration: ' + ex.getMessage());
        }
    }

    /**
     * This method updates the Sub_Document_Type__c field on an Opportunity record.
     * It appends a new value to the field if it is not already present.
     *
     * @param recordId The ID of the Opportunity record to update.
     * @param newValue The new value to append to the Sub_Document_Type__c field.
     * @throws AuraHandledException If an error occurs during the update.
     */
    @AuraEnabled
    public static void updateSubDocumentType(Id recordId, String newValue) {
        try {
            // Validate that newValue is not null or empty
            if (String.isBlank(newValue)) {
                return; // Exit if newValue is null or empty
            }

            System.debug('newValue --> ' + newValue);

            // Query the existing Opportunity record to fetch the current Sub_Document_Type__c value
            Opportunity record = [
                SELECT Id, Sub_Document_Type__c 
                FROM Opportunity 
                WHERE Id = :recordId 
                LIMIT 1
            ];

            // If the field is empty, set it to newValue
            if (String.isBlank(record.Sub_Document_Type__c)) {
                record.Sub_Document_Type__c = newValue;
            } 
            // If the field already has a value, append the newValue (if it's not already present)
            else if (!record.Sub_Document_Type__c.contains(newValue)) {
                record.Sub_Document_Type__c += ';' + newValue;
            }

            // Update the Opportunity record with the new value
            update record;

        } catch (Exception ex) {
            // Handle any unexpected errors and log them
            System.debug('Error updating Sub_Document_Type__c: ' + ex.getMessage());
            throw new AuraHandledException('An error occurred while updating the sub-document type: ' + ex.getMessage());
        }
    }

    /**
 * This method checks the size of uploaded files and processes them accordingly.
 * It deletes oversized files and renames valid files based on the Opportunity name.
 *
 * @param jsonInput A JSON string containing file details.
 * @param maxSize The maximum allowed file size in bytes.
 * @param recordId The ID of the Opportunity associated with the files.
 * @param documentType The type of document to be set in the Document_Type__c field.
 * @return A list of file sizes for valid files.
 * @throws AuraHandledException If the input is invalid or an error occurs during processing.
 */
@AuraEnabled
public static List<Long> checkFilesSize(String jsonInput, Integer maxSize, String recordId, String documentType) {
    List<Long> fileSizes = new List<Long>();
    List<ContentDocument> filesToDelete = new List<ContentDocument>();
    List<ContentVersion> filesToUpdate = new List<ContentVersion>();
    String opportunityName = '';
    
    try {
        // Validate input parameters
        if (String.isBlank(jsonInput) || maxSize == null || maxSize <= 0 || String.isBlank(recordId) || String.isBlank(documentType)) {
            throw new AuraHandledException('Invalid input: Ensure JSON input, maxSize, recordId, and documentType are provided correctly.');
        }
        
        // Fetch the Opportunity Name using recordId
        Opportunity opp = [SELECT Name FROM Opportunity WHERE Id = :recordId LIMIT 1];
        if (opp != null) {
            opportunityName = opp.Name;
        }
        
        // Deserialize JSON input
        Map<String, Object> inputMap = (Map<String, Object>) JSON.deserializeUntyped(jsonInput);
        if (!inputMap.containsKey('files') || !(inputMap.get('files') instanceof List<Object>)) {
            throw new AuraHandledException('Invalid JSON structure: Expected "files" as a list.');
        }
        
        List<Object> filesList = (List<Object>) inputMap.get('files');
        List<Map<String, String>> files = new List<Map<String, String>>();
        
        // Convert JSON list to a structured list of maps
        for (Object obj : filesList) {
            if (obj instanceof Map<String, Object>) {
                Map<String, String> fileMap = new Map<String, String>();
                for (String key : ((Map<String, Object>) obj).keySet()) {
                    fileMap.put(key, String.valueOf(((Map<String, Object>) obj).get(key)));
                }
                files.add(fileMap);
            }
        }
        
        // Extract file IDs
        List<String> contentDocumentIds = new List<String>();
        for (Map<String, String> file : files) {
            contentDocumentIds.add(file.get('fileId'));
        }
        
        if (contentDocumentIds.isEmpty()) {
            throw new AuraHandledException('No valid file IDs found in the input.');
        }
        
        // Query file sizes
        List<ContentVersion> contents = [
            SELECT ContentSize, Id, Title, ContentDocumentId FROM ContentVersion 
            WHERE ContentDocumentId IN :contentDocumentIds
        ];
        
        // Categorize files based on size
        for (ContentVersion content : contents) {
            if (content.ContentSize > maxSize) {
                fileSizes.add(0L);
                filesToDelete.add(new ContentDocument(Id = content.ContentDocumentId));
            } else {
                fileSizes.add(content.ContentSize);
                content.Document_Type__c = documentType; // Set the Document_Type__c field
                filesToUpdate.add(content);
            }
        }
        
        // Delete oversized files
        if (!filesToDelete.isEmpty()) {
            delete filesToDelete;
        }
        
        // Proceed with valid files
        if (!filesToUpdate.isEmpty()) {
            String firstFileType = files.isEmpty() ? null : files.get(0).get('fileType');
            Map<String, String> fileTypeMap = new Map<String, String>();
            for (Map<String, String> file : files) {
                fileTypeMap.put(file.get('fileId'), file.get('fileType'));
            }
            
            // Delete old files of the same type
            if (firstFileType != null) {
                List<ContentDocument> oldFiles = [
                    SELECT Id FROM ContentDocument 
                    WHERE Id IN (
                        SELECT ContentDocumentId FROM ContentVersion 
                        WHERE Title LIKE :firstFileType + '__%'
                    )
                ];
                
                if (!oldFiles.isEmpty()) {
                    delete oldFiles;
                }
            }
            
            // Rename and update files
            for (ContentVersion content : filesToUpdate) {
                if (fileTypeMap.containsKey(content.ContentDocumentId)) {
                    content.Title = fileTypeMap.get(content.ContentDocumentId) + '__' + content.Title + '__' + opportunityName;
                }
            }
            
            update filesToUpdate;
        }
        
    } catch (Exception ex) {
        System.debug('Error: ' + ex.getMessage());
        throw new AuraHandledException('An error occurred: ' + ex.getMessage());
    }
    
    return fileSizes;
}
}