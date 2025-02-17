/**
* Author: Varun Rawal
* Description: Apex Controller for handling Pre-Sales functionalities, including user updates, queue management,
* custom settings retrieval and updates, batch scheduling, and picklist value fetching.
*/
public with sharing class PreSalesController {
    @AuraEnabled(cacheable=true)
    public static String getCustomSetting(String name) {
        try {
            Pre_Sales_Data__c customSetting = [
                SELECT Value__c 
                FROM Pre_Sales_Data__c 
                WHERE Name = :name 
                LIMIT 1
            ];
            system.debug(name+' value:- '+customSetting.Value__c);
            return customSetting.Value__c;
        } catch (Exception e) {
            System.debug('Error retrieving custom setting: ' + e.getMessage());
            throw new AuraHandledException('Failed to retrieve custom setting.');
        }
    }
    
    @AuraEnabled
    public static void updateUserStatus(String userStatusData) {
        try {
            system.debug('userStatusData-->'+userStatusData);
            if (String.isEmpty(userStatusData)) {
                throw new AuraHandledException('Input string is empty.');
            }
            List<User> userList = (List<User>) JSON.deserialize(userStatusData, List<User>.class);
            system.debug('userList-->'+userList);
            if (!userList.isEmpty()) {
                update userList;
            }
        } catch (Exception e) {
            System.debug('Error updating user status: ' + e.getMessage());
            throw new AuraHandledException('Failed to update user status.');
        }
    }
    
    @AuraEnabled
    public static void updateCustomSetting(String name, String value) {
        try {
            Pre_Sales_Data__c customSetting = [
                SELECT Id, Value__c
                FROM Pre_Sales_Data__c
                WHERE Name = :name
                LIMIT 1
            ];
            customSetting.Value__c = value;
            update customSetting;
        } catch (Exception e) {
            System.debug('Error updating custom setting: ' + e.getMessage());
            throw new AuraHandledException('Failed to update custom setting.');
        }
    }
    
    @AuraEnabled
    public static List<UserWrapper> getUsersData(String queueName) {
        try {
            if (String.isBlank(queueName)) {
                throw new AuraHandledException('Queue name cannot be empty.');
            }
            Group grp = [
                SELECT Id 
                FROM Group 
                WHERE DeveloperName = :queueName 
                AND Type = 'Queue' 
                LIMIT 1
            ];
            List<GroupMember> groupMembers = [
                SELECT UserOrGroupId 
                FROM GroupMember 
                WHERE GroupId = :grp.Id
            ];
            Set<Id> userIds = new Set<Id>();
            for (GroupMember gm : groupMembers) {
                userIds.add(gm.UserOrGroupId);
            }
            List<User> users = [
                SELECT Id, Name, Email, Status__c, Capacity__c, Pre_Sales_Lead_Assignment__c, Username
                FROM User 
                WHERE Id IN :userIds 
                ORDER BY Name
            ];
            List<UserWrapper> wrappedUsers = new List<UserWrapper>();
            for (User user : users) {
                wrappedUsers.add(new UserWrapper(
                    user.Id,
                    user.Name,
                    user.Username,
                    user.Email,
                    user.Status__c,
                    user.Capacity__c,
                    false,
                    user.Pre_Sales_Lead_Assignment__c
                ));
            }
            return wrappedUsers;
        } catch (Exception e) {
            System.debug('Error retrieving user data: ' + e.getMessage());
            throw new AuraHandledException('Failed to fetch users.');
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<String> getPicklistValues() {
        try {
            List<String> statusValues = new List<String>();
            Schema.DescribeFieldResult fieldResult = User.Status__c.getDescribe();
            for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
                statusValues.add(entry.getLabel());
            }
            return statusValues;
        } catch (Exception e) {
            System.debug('Error fetching picklist values: ' + e.getMessage());
            throw new AuraHandledException('Failed to retrieve picklist values.');
        }
    }
    
    public class UserWrapper {
        @AuraEnabled public Id userId;
        @AuraEnabled public String name;
        @AuraEnabled public String userName;
        @AuraEnabled public String email;
        @AuraEnabled public String status;
        @AuraEnabled public Decimal capacity;
        @AuraEnabled public Boolean userChange;
        @AuraEnabled public Boolean leadAssignment;
        public UserWrapper(Id userId, String name, String userName, String email, String status, Decimal capacity, boolean userChange, boolean leadAssignment) {
            this.userId = userId;
            this.name = name;
            this.userName = userName;
            this.email = email;
            this.status = status;
            this.capacity = capacity;
            this.userChange = userChange;
            this.leadAssignment = leadAssignment;
        }
    }
    
    public class ToastResponse {
        @AuraEnabled public Boolean isSuccess;
        @AuraEnabled public String message;
        public ToastResponse(Boolean isSuccess, String message) {
            this.isSuccess = isSuccess;
            this.message = message;
        }
    }
    
    @AuraEnabled
    public static ToastResponse scheduleBatch(Integer minuteInterval) {
        try {
            if (minuteInterval == null || minuteInterval <= 0 || minuteInterval > 59) {
                return new ToastResponse(false, 'Invalid minute interval. Please provide a value between 1 and 59.');
            }
            //String jobName = 'LeadNotificationBatch_' + System.now().getTime();
            String jobName = 'LeadNotificationBatch_' + System.now().getTime();
            String hour = String.valueOf(Datetime.now().hour());
            String min = String.valueOf(Datetime.now().addMinutes(minuteInterval).minute()); 
            String ss = String.valueOf(Datetime.now().second());
            String day = String.valueOf(Datetime.now().day());
            String month = String.valueOf(Datetime.now().month());
            String nextFireTime = ss + ' ' + min + ' ' + hour + ' ' + day + ' ' + month + ' ?';
            // String nextFireTime = '0 ' + minuteInterval + ' * * * ?';
            System.schedule(jobName, nextFireTime, new LeadNotificationBatch());
            return new ToastResponse(true, 'Scheduled job "' + jobName + '" to run every ' + minuteInterval + ' minute(s).');
        } catch (Exception e) {
            return new ToastResponse(false, 'Failed to schedule job: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static ToastResponse deleteScheduledJob() {
        try {
            List<CronTrigger> scheduledJobs = [
                SELECT Id, State, CronJobDetail.Name  
                FROM CronTrigger  
                WHERE CronJobDetail.Name LIKE '%LeadNotificationBatch%'
            ];
            if (!scheduledJobs.isEmpty()) {
                for (CronTrigger job : scheduledJobs) {
                    if (job.State != 'DELETED') {
                        System.abortJob(job.Id);
                    }
                }
                return new ToastResponse(true, 'Scheduled jobs for LeadNotificationBatch deleted.');
            }
            return new ToastResponse(false, 'No scheduled jobs found.');
        } catch (Exception e) {
            return new ToastResponse(false, 'Failed to delete the scheduled job: ' + e.getMessage());
        }
    }
}