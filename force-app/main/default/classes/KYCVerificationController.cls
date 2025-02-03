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