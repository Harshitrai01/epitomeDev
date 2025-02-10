/**
 * @description Batch and Scheduled Apex class to send notifications for Unopened Leads
 * @author Varun Rawal
 */
global with sharing class LeadNotificationBatch implements Database.Batchable<SObject>, Schedulable {
    
    // QueryLocator for fetching unopened Leads
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, OwnerId, Status, Name
            FROM Lead 
            WHERE Status = 'Unopened'
        ]);
    }
    
    global void execute(Database.BatchableContext bc, List<Lead> scope) {
        try {
            // Fetch custom setting value
            Pre_Sales_Data__c customSetting = [
                SELECT Value__c 
                FROM Pre_Sales_Data__c 
                WHERE Name = 'Send to Manager' 
                LIMIT 1
            ];
            
            Boolean sendToManager = (customSetting != null && !String.isEmpty(customSetting.Value__c)) 
                                   ? customSetting.Value__c.equalsIgnoreCase('true') : false;
            
            System.debug('Send to Manager: ' + sendToManager);
            
            // Fetch Notification Type
            CustomNotificationType notificationType;
            try {
                notificationType = [
                    SELECT Id, DeveloperName 
                    FROM CustomNotificationType 
                    WHERE DeveloperName = 'Lead_Assignment_Notification'
                    LIMIT 1
                ];
            } catch (Exception e) {
                System.debug('Error fetching notification type: ' + e.getMessage());
                return;
            }
            
            Set<String> userIds = new Set<String>();
            Map<String, String> userToManager = new Map<String, String>();
            List<Lead> userLeads = new List<Lead>();
            
            // Collect Lead owners
            for (Lead l : scope) {
                if (l.OwnerId.getSObjectType() == User.SObjectType) {
                    userIds.add(l.OwnerId);
                    userLeads.add(l);
                }
            }
            
            // Fetch Manager IDs if required
            if (sendToManager && !userIds.isEmpty()) {
                List<User> users = [SELECT Id, ManagerId FROM User WHERE Id IN :userIds];
                for (User usr : users) {
                    userToManager.put(usr.Id, usr.ManagerId);
                }
            }
            
            // Send Notifications
            if (!userLeads.isEmpty()) {
                for (Lead l : userLeads) {
                    Set<String> recipients = new Set<String>{ l.OwnerId };
                    
                    if (sendToManager && userToManager.containsKey(l.OwnerId) && userToManager.get(l.OwnerId) != null) {
                        recipients.add(userToManager.get(l.OwnerId));
                    }
                    
                    Messaging.CustomNotification notification = new Messaging.CustomNotification();
                    notification.setTitle('Lead Notification');
                    notification.setBody('A new Lead has been assigned: ' + l.Name);
                    notification.setNotificationTypeId(notificationType.Id);
                    notification.setTargetId(l.Id);
                    
                    try {
                        notification.send(recipients);
                    } catch (Exception e) {
                        System.debug('Error sending notification: ' + e.getMessage());
                    }
                }
            } else {
                System.debug('No leads found for notification.');
            }
        } catch (Exception e) {
            System.debug('Error in execute method: ' + e.getMessage());
        }
    }
    
    global void finish(Database.BatchableContext bc) {
        try {
            // Fetch custom setting for rescheduling interval
            Pre_Sales_Data__c customSetting = [
                SELECT Value__c 
                FROM Pre_Sales_Data__c 
                WHERE Name = 'Minutes' 
                LIMIT 1
            ];
            
            Integer minutesToAdd = (customSetting != null && !String.isEmpty(customSetting.Value__c))
                                   ? Integer.valueOf(customSetting.Value__c) : 15;
            
            // Abort existing scheduled jobs
            List<CronTrigger> scheduledJobs = [
                SELECT Id, State, CronJobDetail.Name  
                FROM CronTrigger  
                WHERE CronJobDetail.Name LIKE '%LeadNotificationBatch%'  
                ORDER BY CreatedDate DESC 
            ];
            
            for (CronTrigger job : scheduledJobs) {
                if (job.State != 'DELETED') {
                    System.abortJob(job.Id);
                }
            }
            
            // Schedule new job
            String jobName = 'LeadNotificationBatch_' + System.now().getTime();
            Datetime nextRun = Datetime.now().addMinutes(minutesToAdd);
            String cronExpression = String.format('{0} {1} {2} {3} {4} ?',
                new String[]{
                    String.valueOf(nextRun.second()),
                    String.valueOf(nextRun.minute()),
                    String.valueOf(nextRun.hour()),
                    String.valueOf(nextRun.day()),
                    String.valueOf(nextRun.month())
                }
            );
            
            System.schedule(jobName, cronExpression, new LeadNotificationBatch());
            System.debug('Batch Process Complete, rescheduled for ' + minutesToAdd + ' minutes.');
        } catch (Exception e) {
            System.debug('Error in finish method: ' + e.getMessage());
        }
    }
    
    // Scheduled Execution
    global void execute(SchedulableContext sc) {
        try {
            Database.executeBatch(new LeadNotificationBatch());
        } catch (Exception e) {
            System.debug('Error executing batch: ' + e.getMessage());
        }
    }
}