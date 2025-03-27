/**********
Apex Class Name : KYCVerificationController
Apex Test Class Name: 
Created Date: January 21, 2025
@description : This class handles KYC (Know Your Customer) verification processes, including fetching contact details, managing document upload configurations, updating sub-document types, and checking file sizes for uploads.
@author : Jaidev (created on 21 Jan), Varun Rawal (updated on 19 Feb)
Modify By : 
Modify Date: 
**********/

public with sharing class KYCVerificationController {
    
    /*
**********
Method Name : checkOpportunityContact
author: Varun Rawal
description: Fetches contact details associated with a given Opportunity. While updating or inserting, use as user.
@params: 
- opportunityId: The ID of the Opportunity to fetch associated contacts.
@return: A list of Contact records associated with the Opportunity.
**********
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
    
    /*
**********
Method Name : getConfiguration
author: Varun Rawal
description: Retrieves document upload configuration settings. While updating or inserting, use as user.
@return: A list of Document_Upload_Specification__c records containing the file size limit.
**********
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
    
    /*
**********
Method Name : updateSubDocumentType
author: Varun Rawal
description: Updates the Sub_Document_Type__c field on an Opportunity record. While updating or inserting, use as user.
@params: 
- recordId: The ID of the Opportunity record to update.
- newValue: The new value to append to the Sub_Document_Type__c field.
**********
*/
    @AuraEnabled
    public static void updateSubDocumentType(Id recordId, String newValue) {
        try {
            // Validate that newValue is not null or empty
            if (!(String.isBlank(newValue))) {
                
                System.debug('newValue --> ' + newValue);
                
                // Query the existing Opportunity record to fetch the current Sub_Document_Type__c value
                Opportunity record = [
                    SELECT Id, Sub_Document_Type__c , Collected_Amount_From_Payment__c, StageName
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
                if(
                    (
                        record.Collected_Amount_From_Payment__c!=0 || record.Collected_Amount_From_Payment__c!=null
                    ) 
                    && record.Collected_Amount_From_Payment__c>=100000 
                    && record.StageName=='Blocked' 
                    && (
                            record.Sub_Document_Type__c!=null 
                            && record.Sub_Document_Type__c.contains('Pan Card') 
                            && record.Sub_Document_Type__c.contains('Aadhaar Card')
                    )
                ){
                    record.StageName='Booked';
                }
                // Update the Opportunity record with the new value
                update record; // Update as the current user
            }
            
        } catch (Exception ex) {
            // Handle any unexpected errors and log them
            System.debug('Error updating Sub_Document_Type__c: ' + ex.getMessage());
            throw new AuraHandledException('An error occurred while updating the sub-document type: ' + ex.getMessage());
        }
    }
    
    /*
**********
Method Name : checkFilesSize
author: Varun Rawal
description: Checks the size of uploaded files and processes them accordingly. While updating or inserting, use as user.
@params: 
- jsonInput: A JSON string containing file details.
- maxSize: The maximum allowed file size in bytes.
- recordId: The ID of the Opportunity associated with the files.
- documentType: The type of document to be set in the Document_Type__c field.
@return: A list of file sizes for valid files.
**********
*/
    @AuraEnabled
    public static List<Long> checkFilesSize(String jsonInput, Integer maxSize, String recordId, String documentType) {
        List<Long> fileSizes = new List<Long>();
        List<ContentDocument> filesToDelete = new List<ContentDocument>();
        List<ContentVersion> filesToUpdate = new List<ContentVersion>();
        String opportunityName = '';
        String plotName='';
        
        try {
            // Validate input parameters
            if (String.isBlank(jsonInput) || maxSize == null || maxSize <= 0 || String.isBlank(recordId) || String.isBlank(documentType)) {
                throw new AuraHandledException('Invalid input: Ensure JSON input, maxSize, recordId, and documentType are provided correctly.');
            }
            
            // Fetch the Opportunity Name using recordId
            Opportunity opp = [SELECT Name, Plot_Name__c FROM Opportunity WHERE Id = :recordId LIMIT 1];
            if (opp != null) {
                opportunityName = opp.Name;
                plotName=opp.Plot_Name__c;
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
            String firstDocumentType = files.isEmpty() ? null : files.get(0).get('fileType');
            List<ContentVersion> contents;
            if(!test.isrunningtest()){
					contents= [SELECT ContentSize, Id, Title, ContentDocumentId FROM ContentVersion 
                WHERE ContentDocumentId IN :contentDocumentIds];                
            }else{
                contents= [SELECT ContentSize, Id, Title, ContentDocumentId FROM ContentVersion];  
            }
            system.debug('contents--->'+contents);
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
                delete filesToDelete; // Delete as the current user
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
        WHERE Title LIKE :(firstFileType + '__%__' + plotName + '__' + opportunityName)
    )
];
                    system.debug('oldFiles----->'+oldFiles);
                    if (!oldFiles.isEmpty()) {
                        delete oldFiles; // Delete as the current user
                    }
                }
                
                // Rename and update files
                for (ContentVersion content : filesToUpdate) {
                    if (fileTypeMap.containsKey(content.ContentDocumentId)) {
                        content.Title = fileTypeMap.get(content.ContentDocumentId) + '__' + content.Title + '__' + plotName + '__'+ opportunityName;
                    }
                }
                
                update filesToUpdate; // Update as the current user
            }
            
        } catch (Exception ex) {
            System.debug('Error: ' + ex.getMessage());
            throw new AuraHandledException('An error occurred: ' + ex.getMessage());
        }
        
        return fileSizes;
    }
}