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

    @AuraEnabled
    public static Long checkFileSize(String contentDocumentId, Integer maxSize, String fileType) {
        System.debug('--->'+fileType);
        ContentVersion content = [SELECT ContentSize, Id, Title  
                                    FROM ContentVersion 
                                    WHERE ContentDocumentId = :contentDocumentId 
                                    ORDER BY CreatedDate DESC 
                                    LIMIT 1
                                ];

        // If file size exceeds maxSize, delete the file
        if (content.ContentSize > maxSize) {
            // Delete the ContentDocument
            ContentDocument docToDelete = [SELECT Id 
                                            FROM ContentDocument 
                                            WHERE Id = :contentDocumentId 
                                            LIMIT 1
                                        ];
            delete docToDelete;
            return 0; // Return 0 to indicate file was deleted
        }

        // Rename the file with the appropriate prefix
        String newFileName = fileType + '__' + content.Title;

        // Update the file name in ContentVersion
        content.Title = newFileName;
        update content;

        return content.ContentSize; // Return file size in bytes
    }

    @AuraEnabled
    public static void uploadFile(String base64Data, String fileName, Id recordId, String documentType) {
        try {
            // Convert base64 data to Blob
            String fileData = base64Data;
            Blob fileBlob = EncodingUtil.base64Decode(fileData);

            // Create ContentVersion record
            ContentVersion contentVersion = new ContentVersion(
                VersionData = fileBlob,
                Title = fileName,
                PathOnClient = fileName,
                FirstPublishLocationId = recordId
            );
            insert contentVersion;

            // Optionally, associate the file with a custom object or process it further
            System.debug('File uploaded successfully: ' + fileName);
        } catch (Exception e) {
            throw new AuraHandledException('Error uploading file: ' + e.getMessage());
        }
    }

    
    @AuraEnabled
    public static void updateOpportunityKYCStatus(Id opportunityId, Id contactId) {
        try {
            System.debug('cn--->'+contactId);
            Opportunity opp = [SELECT Id, Name, KYC_Verification__c FROM Opportunity WHERE Id = :opportunityId];
            opp.KYC_Verification__c = 'In Progress';
            update opp;

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
        } catch (Exception e) {
            throw new AuraHandledException('Error updating KYC Verification status: ' + e.getMessage());
        }
    }
}