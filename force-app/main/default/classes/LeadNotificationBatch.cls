/**********
Apex Class Name : LeadNotificationBatch
Apex Test Class Name: 
Created Date: February 10, 2025
@description : This class is a batch and schedulable class designed to handle notifications for unopened leads. It sends notifications to lead owners and optionally their managers based on a custom setting configuration. The class also reschedules itself to run at a specified interval defined in a custom setting.
@author : Varun Rawal
Modify By : 
Modify Date: 
**********/

public with sharing class LeadNotificationBatch implements Database.Batchable<SObject>, Schedulable {
    
    /*
**********
Method Name : start
author: Varun Rawal
description: The start method of the batch class, which defines the query to fetch unopened leads.
@params: 
- bc: The BatchableContext object provided by the system.
@return: A QueryLocator object containing the unopened leads.
**********
*/
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, OwnerId, Status, Name
            FROM Lead 
            WHERE Status = 'Unopened'
        ]);
    }
    
    /*
**********
Method Name : execute
author: Varun Rawal
description: The execute method of the batch class, which processes the fetched leads and sends notifications.
@params: 
- bc: The BatchableContext object provided by the system.
- scope: The list of leads to process.
@return: None
**********
*/
    public void execute(Database.BatchableContext bc, List<Lead> scope) {
        // Fetch the custom setting to determine if notifications should be sent to managers
        Pre_Sales_Data__c customSetting = [
            SELECT Value__c 
            FROM Pre_Sales_Data__c 
            WHERE Name = 'Send to Manager' 
            LIMIT 1
        ];
        
        // Check if the custom setting is null or empty
        if (customSetting == null || String.isEmpty(customSetting.Value__c)) {
            System.debug('Custom setting "Send to Manager" not found or is empty.');
        }else{
            
            // Determine if notifications should be sent to managers
            Boolean sendToManager = customSetting.Value__c.equalsIgnoreCase('true');
            System.debug('Send to Manager: ' + sendToManager);
            
            // Fetch the custom notification type
            CustomNotificationType notificationType = [
                SELECT Id, DeveloperName 
                FROM CustomNotificationType 
                WHERE DeveloperName = 'Lead_Assignment_Notification'
            ];
            
            // Initialize collections to store user IDs and leads
            Set<String> ids = new Set<String>();
            Map<String, String> userToManager = new Map<String, String>();
            List<Lead> userLeads = new List<Lead>();
            
            // Iterate through the leads and collect user IDs
            for (Lead l : scope) {
                system.debug('User.SObjectType --------'+User.SObjectType);
                system.debug('l.OwnerId.getSObjectType()-------'+l.OwnerId.getSObjectType());
                if (l.OwnerId.getSObjectType() == User.SObjectType) {
                    ids.add(l.OwnerId);
                    userLeads.add(l);
                }
            }
            
            // If notifications should be sent to managers, fetch manager IDs
            if (sendToManager) {
                List<User> users = [SELECT Id, ManagerId FROM User WHERE Id IN :ids];
                for (User usr : users) {
                    userToManager.put(usr.Id, usr.ManagerId);
                }
            }
            
            System.debug('Map user to Manager: ' + userToManager);
            
            // If no user leads are found, exit the method
            if (userLeads.isEmpty()) {
                System.debug('No User Leads Found');
            }else{
                
                // Send notifications to lead owners and optionally their managers
                for (Lead l : scope) {
                    if (l.OwnerId.getSObjectType() == User.SObjectType) {
                        Set<String> userIds = new Set<String>();
                        userIds.add(l.OwnerId);
                        System.debug('Owner ID: ' + l.OwnerId);
                        
                        // Add the manager's ID if applicable
                        if (sendToManager && userToManager.containsKey(l.OwnerId) && userToManager.get(l.OwnerId) != null) {
                            userIds.add(userToManager.get(l.OwnerId));
                            System.debug('Owner Manager ID: ' + userToManager.get(l.OwnerId));
                        }
                        
                        // Create and send the custom notification
                        Messaging.CustomNotification notification = new Messaging.CustomNotification();
                        notification.setTitle('Unopenned Lead ALERT');
                        notification.setBody('You have an Unopenned Lead.');
                        notification.setNotificationTypeId(notificationType.Id);
                        notification.setTargetId(l.Id);
                        
                        try {
                            notification.send(userIds);	
                        } catch (Exception e) {
                            System.debug('Problem sending notification: ' + e.getMessage());
                        }
                    }
                }
            }
        }
    }
    
    /*
**********
Method Name : finish
author: Varun Rawal
description: The finish method of the batch class, which reschedules the batch job.
@params: 
- bc: The BatchableContext object provided by the system.
@return: None
**********
*/
    public void finish(Database.BatchableContext bc) {
        // Fetch the custom setting to determine the interval for rescheduling
        Pre_Sales_Data__c customSetting = [
            SELECT Value__c 
            FROM Pre_Sales_Data__c 
            WHERE Name = 'Minutes' 
            LIMIT 1
        ];
        
        // Fetch any existing scheduled jobs with the same name
        List<CronTrigger> scheduledJobs = [
            SELECT Id, State, CronJobDetail.Name  
            FROM CronTrigger  
            WHERE CronJobDetail.Name LIKE '%LeadNotificationBatch%'  
            ORDER BY CreatedDate DESC 
        ];
        
        // Abort any existing scheduled jobs to avoid duplicates
        if (!scheduledJobs.isEmpty()) {
            for (CronTrigger job : scheduledJobs) {
                system.debug('job-->'+job);
                if (job.State != 'DELETED') {
                    System.abortJob(job.Id);
                    system.debug('job aborted');
                }
            }
        }
        
        // Calculate the next fire time based on the custom setting
        Integer minutesToAdd = Integer.valueOf(customSetting.Value__c);
        
        String jobName = 'LeadNotificationBatch_' + System.now().getTime();
        String hour = String.valueOf(Datetime.now().hour());
        String min = String.valueOf(Datetime.now().addMinutes(minutesToAdd).minute()); 
        String ss = String.valueOf(Datetime.now().second());
        String day = String.valueOf(Datetime.now().day());
        String month = String.valueOf(Datetime.now().month());
        String nextFireTime = ss + ' ' + min + ' ' + hour + ' ' + day + ' ' + month + ' ?';
        
        // Reschedule the batch job
        try {
            System.schedule(jobName, nextFireTime, new LeadNotificationBatch());
        } catch (Exception e) {
            throw new AuraHandledException('Failed to schedule job: ' + e.getMessage());
        }
        
        System.debug('Batch Process Complete');
    }
    
    /*
**********
Method Name : execute (Schedulable)
author: Varun Rawal
description: The execute method of the Schedulable interface, which starts the batch job.
@params: 
- sc: The SchedulableContext object provided by the system.
@return: None
**********
*/
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new LeadNotificationBatch());
    }
}