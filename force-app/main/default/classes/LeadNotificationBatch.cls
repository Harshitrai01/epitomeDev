global class LeadNotificationBatch implements Database.Batchable<SObject>, Schedulable {
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, OwnerId, Status, Name
            FROM Lead 
            WHERE Status = 'Unopened'
        ]);
    }
    
    global void execute(Database.BatchableContext bc, List<Lead> scope) {
        Pre_Sales_Data__c customSetting = [
            SELECT Value__c 
            FROM Pre_Sales_Data__c 
            WHERE Name = 'Send to Manager' 
            LIMIT 1
        ];
        
        if (customSetting == null || String.isEmpty(customSetting.Value__c)) {
            System.debug('Custom setting "Send to Manager" not found or is empty.');
            return;
        }
        
        Boolean sendToManager = customSetting.Value__c.equalsIgnoreCase('true');
        System.debug('Send to Manager: ' + sendToManager);
        
        CustomNotificationType notificationType = [
            SELECT Id, DeveloperName 
            FROM CustomNotificationType 
            WHERE DeveloperName = 'Lead_Assignment_Notification'
        ];
        
        Set<String> ids = new Set<String>();
        Map<String, String> userToManager = new Map<String, String>();
        List<Lead> userLeads = new List<Lead>();
        for (Lead l : scope) {
            if (l.OwnerId.getSObjectType() == User.SObjectType) {
                ids.add(l.OwnerId);
                userLeads.add(l);
            }
        }
        
        if (sendToManager) {
            List<User> users = [SELECT Id, ManagerId FROM User WHERE Id IN :ids];
            for (User usr : users) {
                userToManager.put(usr.Id, usr.ManagerId);
            }
        }
        
        System.debug('Map user to Manager: ' + userToManager);
        if (userLeads.isEmpty()) {
            System.debug('No User Leads Found');
            return;
        }
        
        for (Lead l : scope) {
            if (l.OwnerId.getSObjectType() == User.SObjectType) {
                Set<String> userIds = new Set<String>();
                userIds.add(l.OwnerId);
                System.debug('Owner ID: ' + l.OwnerId);
                if (sendToManager && userToManager.containsKey(l.OwnerId) && userToManager.get(l.OwnerId) != null) {
                    userIds.add(userToManager.get(l.OwnerId));
                    System.debug('Owner Manager ID: ' + userToManager.get(l.OwnerId));
                }
                
                Messaging.CustomNotification notification = new Messaging.CustomNotification();
                notification.setTitle('Apex Custom Notification');
                notification.setBody('The notifications are coming from INSIDE the Apex!');
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
    
    global void finish(Database.BatchableContext bc) {
        Pre_Sales_Data__c customSetting = [
            SELECT Value__c 
            FROM Pre_Sales_Data__c 
            WHERE Name = 'Minutes' 
            LIMIT 1
        ];
        
        List<CronTrigger> scheduledJobs = [
            SELECT Id, State, CronJobDetail.Name  
            FROM CronTrigger  
            WHERE CronJobDetail.Name LIKE '%LeadNotificationBatch%'  
            ORDER BY CreatedDate DESC 
        ];
        
        if (!scheduledJobs.isEmpty()) {
            for (CronTrigger job : scheduledJobs) {
                system.debug('job-->'+job);
                if (job.State != 'DELETED') {
                    System.abortJob(job.Id);
                    system.debug('job aborted');
                }
            }
        }
        
        Integer minutesToAdd = Integer.valueOf(customSetting.Value__c);
        
        String jobName = 'LeadNotificationBatch_' + System.now().getTime();
        String hour = String.valueOf(Datetime.now().addMinutes(minutesToAdd).hour());
        String min = String.valueOf(Datetime.now().addMinutes(minutesToAdd).minute()); 
        String ss = String.valueOf(Datetime.now().addMinutes(minutesToAdd).second());
        String day = String.valueOf(Datetime.now().addMinutes(minutesToAdd).day());
        String month = String.valueOf(Datetime.now().addMinutes(minutesToAdd).month());
        String nextFireTime = ss + ' ' + min + ' ' + hour + ' ' + day + ' ' + month + ' ?';
        
        try {
            System.schedule(jobName, nextFireTime, new LeadNotificationBatch());
        } catch (Exception e) {
            throw new AuraHandledException('Failed to schedule job: ' + e.getMessage());
        }
        
        System.debug('Batch Process Complete');
    }
    
    // Implement the Schedulable interface
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new LeadNotificationBatch());
    }
}