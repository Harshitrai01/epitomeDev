public with sharing class KYCVerificationController {
    @AuraEnabled(cacheable=true)
    public static List<Contact> checkOpportunityContact(Id opportunityId) {
        List<Contact> contacts = new List<Contact>();
        try {
            if (String.isEmpty(opportunityId)) {
                throw new AuraHandledException('Opportunity ID is required.');
            }
            contacts = [
                SELECT Id, Name, Email, Phone FROM Contact 
                WHERE Id IN (
                    SELECT ContactId FROM OpportunityContactRole WHERE OpportunityId = :opportunityId
                )
            ];
            return contacts;
        } catch (Exception ex) {
            throw new AuraHandledException('Error fetching contact details: ' + ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Document_Upload_Specification__c> getConfiguration() {
        return [SELECT File_Size_Limit__c
                    FROM Document_Upload_Specification__c 
                    WHERE Name = 'Specification'];
    }

    // @AuraEnabled
    // public static List<Long> checkFilesSize(String jsonInput, Integer maxSize) {
    //     // List to store file sizes (or 0 if deleted)
    //     List<Long> fileSizes = new List<Long>();
        
    //     // Deserialize JSON into a list of maps
    //     Map<String, Object> inputMap = (Map<String, Object>) JSON.deserializeUntyped(jsonInput);
    //     // List<Map<String, String>> files = (List<Map<String, String>>) inputMap.get('files');

    //     // Ensure 'files' key exists and is a list
    //     if (!inputMap.containsKey('files') || !(inputMap.get('files') instanceof List<Object>)) {
    //         throw new AuraHandledException('Invalid JSON structure: Expected "files" as a list.');
    //     }

    //     // Extract files list and cast each item properly
    //     List<Object> filesList = (List<Object>) inputMap.get('files');
    //     List<Map<String, String>> files = new List<Map<String, String>>();

    //     for (Object obj : filesList) {
    //         if (obj instanceof Map<String, Object>) {
    //             // Convert each map from <String, Object> to <String, String>
    //             Map<String, String> fileMap = new Map<String, String>();
    //             for (String key : ((Map<String, Object>) obj).keySet()) {
    //                 fileMap.put(key, String.valueOf(((Map<String, Object>) obj).get(key)));
    //             }
    //             files.add(fileMap);
    //         }
    //     }

    //     // Get first fileType (index 0) for deletion check
    //     String firstFileType = files.isEmpty() ? null : files.get(0).get('fileType');

    //     // Extract content document IDs and create a fileType map
    //     List<String> contentDocumentIds = new List<String>();
    //     Map<String, String> fileTypeMap = new Map<String, String>();

    //     for (Map<String, String> file : files) {
    //         String fileId = file.get('fileId');
    //         String fileType = file.get('fileType');
    //         contentDocumentIds.add(fileId);
    //         fileTypeMap.put(fileId, fileType);
    //     }

    //     // **Step 1: Delete existing file with the same name as first fileType**
    //     if (firstFileType != null) {
    //         List<ContentDocument> oldFiles = [
    //             SELECT Id FROM ContentDocument 
    //             WHERE Id IN (SELECT ContentDocumentId FROM ContentVersion WHERE Title LIKE :firstFileType + '__%')
    //         ];
    //         if (!oldFiles.isEmpty()) {
    //             delete oldFiles; // Delete existing file
    //         }
    //     }

    //     // Query all uploaded files in bulk
    //     List<ContentVersion> contents = [SELECT ContentSize, Id, Title, ContentDocumentId  
    //                                     FROM ContentVersion 
    //                                     WHERE ContentDocumentId IN :contentDocumentIds 
    //                                     ORDER BY CreatedDate DESC];

    //     // Lists to store files that need to be deleted or updated
    //     List<ContentDocument> filesToDelete = new List<ContentDocument>();
    //     List<ContentVersion> filesToUpdate = new List<ContentVersion>();

    //     // Iterate through the queried files
    //     for (ContentVersion content : contents) {
    //         if (content.ContentSize > maxSize) {
    //             // File exceeds size limit → Mark it for deletion
    //             filesToDelete.add(new ContentDocument(Id = content.ContentDocumentId));
    //             fileSizes.add(0); // Indicate file was deleted
    //         } else {
    //             // Rename the file with the corresponding fileType prefix
    //             String newFileName = fileTypeMap.get(content.ContentDocumentId) + '__' + content.Title;
    //             content.Title = newFileName;
    //             filesToUpdate.add(content);
    //             fileSizes.add(content.ContentSize); // Store valid file size
    //         }
    //     }

    //     // Bulk delete oversized files
    //     if (!filesToDelete.isEmpty()) {
    //         delete filesToDelete;
    //     }

    //     // Bulk update renamed files
    //     if (!filesToUpdate.isEmpty()) {
    //         update filesToUpdate;
    //     }

    //     return fileSizes; // Return file sizes (0 if deleted, actual size if valid)
    // }

    @AuraEnabled
    public static List<Long> checkFilesSize(String jsonInput, Integer maxSize) {
        List<Long> fileSizes = new List<Long>();
        Map<String, Object> inputMap = (Map<String, Object>) JSON.deserializeUntyped(jsonInput);
        
        if (!inputMap.containsKey('files') || !(inputMap.get('files') instanceof List<Object>)) {
            throw new AuraHandledException('Invalid JSON structure: Expected "files" as a list.');
        }
        
        List<Object> filesList = (List<Object>) inputMap.get('files');
        List<Map<String, String>> files = new List<Map<String, String>>();

        for (Object obj : filesList) {
            if (obj instanceof Map<String, Object>) {
                Map<String, String> fileMap = new Map<String, String>();
                for (String key : ((Map<String, Object>) obj).keySet()) {
                    fileMap.put(key, String.valueOf(((Map<String, Object>) obj).get(key)));
                }
                files.add(fileMap);
            }
        }

        List<String> contentDocumentIds = new List<String>();
        for (Map<String, String> file : files) {
            contentDocumentIds.add(file.get('fileId'));
        }

        // Query file sizes first
        List<ContentVersion> contents = [SELECT ContentSize, Id, Title, ContentDocumentId FROM ContentVersion 
                                        WHERE ContentDocumentId IN :contentDocumentIds];
        
        List<ContentDocument> filesToDelete = new List<ContentDocument>();
        List<ContentVersion> filesToUpdate = new List<ContentVersion>();
        
        for (ContentVersion content : contents) {
            if (content.ContentSize > maxSize) {
                fileSizes.add(0L);
                filesToDelete.add(new ContentDocument(Id = content.ContentDocumentId));
            } else {
                fileSizes.add(content.ContentSize);
                filesToUpdate.add(content);
            }
        }
        
        // Delete files that exceed size limit
        if (!filesToDelete.isEmpty()) {
            delete filesToDelete;
        }
        
        // Proceed with further processing for valid files
        if (!filesToUpdate.isEmpty()) {
            String firstFileType = files.isEmpty() ? null : files.get(0).get('fileType');
            Map<String, String> fileTypeMap = new Map<String, String>();
            for (Map<String, String> file : files) {
                fileTypeMap.put(file.get('fileId'), file.get('fileType'));
            }
            
            if (firstFileType != null) {
                List<ContentDocument> oldFiles = [SELECT Id FROM ContentDocument 
                                                WHERE Id IN (SELECT ContentDocumentId FROM ContentVersion WHERE Title LIKE :firstFileType + '__%')];
                if (!oldFiles.isEmpty()) {
                    delete oldFiles;
                }
            }
            
            for (ContentVersion content : filesToUpdate) {
                String newFileName = fileTypeMap.get(content.ContentDocumentId) + '__' + content.Title;
                content.Title = newFileName;
            }
            
            update filesToUpdate;
        }
        
        return fileSizes;
    }
    
    @AuraEnabled
    public static void updateOpportunityKYCStatus(Id opportunityId, Id contactId, String fileType) {
        try {
            System.debug('cn--->'+contactId);
            Opportunity opp = [SELECT Id, Name, KYC_Verification__c FROM Opportunity WHERE Id = :opportunityId];
            opp.KYC_Verification__c = 'In Progress';
            update opp;

            if (fileType == 'Booked(KYC Verification)') {
                // Fetch the Task recordtype KYC ID 
                Id kycRecordTypeID = Schema.SObjectType.Task.getRecordTypeInfosByName().get('KYC Document').getRecordTypeId();
                // Fetch the Queue ID
                Group queue = [SELECT Id FROM Group WHERE Name = 'MIS Team' AND Type = 'Queue' LIMIT 1];
                
                // Create a Task assigned to the queue
                Task newTask = new Task(
                    Subject = 'KYC Verification',
                    Description = 'Please verify KYC for Opportunity ' + opp.Name,
                    WhatId = opportunityId,
                    WhoId = contactId,
                    OwnerId = queue.Id,
                    Status = 'Not Started',
                    Priority = 'High',
                    RecordTypeId = kycRecordTypeID
                );
                insert newTask;

                List<GroupMember> queueMembers = [SELECT UserOrGroupId FROM GroupMember WHERE GroupId = :queue.Id];
                // Send Notification to Queue
                CustomNotificationType cnType = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'Lead_Assignment_Notification' LIMIT 1];
                // Prepare the notification
                Messaging.CustomNotification customNotificationObj = new Messaging.CustomNotification();
                customNotificationObj.setBody('Please verify KYC for Opportunity: ' + opp.Name);
                customNotificationObj.setTitle('New KYC Verification Task');
                customNotificationObj.setNotificationTypeId(cnType.id);
                customNotificationObj.setTargetId(newTask.Id); // Set the target record ID
            
                // Send the notification to each queue member
                for (GroupMember member : queueMembers) {
                    try {
                        customNotificationObj.send(new Set<String> { member.UserOrGroupId });
                    } catch (Exception e) {
                        System.debug('Error sending notification to user: ' + member.UserOrGroupId + ' - ' + e.getMessage());
                    }
                }
            } else if (fileType == 'Loan Process') {
                Id loanRecordTypeID = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Loan').getRecordTypeId();
                // Query the user with the profile name "Documentation Manager"
                User docManager = [SELECT Id FROM User WHERE Profile.Name = 'Documentation Manager' LIMIT 1];

                // Create a Task assigned to the DM
                Task newTask = new Task(
                    Subject = 'Loan Verification',
                    Description = 'Please verify Loan Document for Opportunity ' + opp.Name,
                    WhatId = opportunityId,
                    WhoId = contactId,
                    OwnerId = docManager.Id,
                    // Status = 'Document Submitted',
                    Priority = 'High',
                    RecordTypeId = loanRecordTypeID
                );
                insert newTask;
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error updating KYC Verification status: ' + e.getMessage());
        }
    }
}