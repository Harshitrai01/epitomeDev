/**********
Apex Class Name : PreSalesController
Apex Test Class Name: 
Created Date: January 17, 2025
@description : This class handles Pre-Sales functionalities, including user updates, queue management, custom settings retrieval and updates, batch scheduling, and picklist value fetching.
@author : Varun Rawal
Modify By : 
Modify Date: 
**********/

public with sharing class PreSalesController {

    /*
    **********
    Method Name : getCustomSetting
    author: Varun Rawal
    description: Fetches the value of a custom setting by its name.
    @params: 
        - name: The name of the custom setting.
    @return: The value of the custom setting.
    **********
    */
    @AuraEnabled(cacheable=true)
    public static String getCustomSetting(String name) {
        try {
            // Query the custom setting by name
            Pre_Sales_Data__c customSetting = [
                SELECT Value__c 
                FROM Pre_Sales_Data__c 
                WHERE Name = :name 
                LIMIT 1
            ];
            system.debug(name + ' value:- ' + customSetting.Value__c);
            return customSetting.Value__c;
        } catch (Exception e) {
            // Log and throw an exception if the custom setting is not found or an error occurs
            System.debug('Error retrieving custom setting: ' + e.getMessage());
            throw new AuraHandledException('Failed to retrieve custom setting.');
        }
    }

    /*
    **********
    Method Name : updateUserStatus
    author: Varun Rawal
    description: Updates the status of multiple users based on the provided JSON data. While updating or inserting, use as user.
    @params: 
        - userStatusData: JSON string containing a list of User records to update.
    @return: None
    **********
    */
    @AuraEnabled
    public static void updateUserStatus(String userStatusData) {
        try {
            system.debug('userStatusData-->' + userStatusData);
            // Null check: Ensure the input string is not empty
            if (String.isEmpty(userStatusData)) {
                throw new AuraHandledException('Input string is empty.');
            }

            // Deserialize the JSON string into a list of User records
            List<User> userList = (List<User>) JSON.deserialize(userStatusData, List<User>.class);
            system.debug('userList-->' + userList);

            // Update the User records if the list is not empty
            if (!userList.isEmpty()) {
                update userList; // Update as the current user
                UserTriggerHandler.processLeadAssignment(); // Trigger lead assignment logic
            }
        } catch (Exception e) {
            // Log and throw an exception if an error occurs during the update
            System.debug('Error updating user status: ' + e.getMessage());
            throw new AuraHandledException('Failed to update user status.');
        }
    }

    /*
    **********
    Method Name : updateCustomSetting
    author: Varun Rawal
    description: Updates the value of a custom setting. While updating or inserting, use as user.
    @params: 
        - name: The name of the custom setting.
        - value: The new value to set.
    @return: None
    **********
    */
    @AuraEnabled
    public static void updateCustomSetting(String name, String value) {
        try {
            // Query the custom setting by name
            Pre_Sales_Data__c customSetting = [
                SELECT Id, Value__c
                FROM Pre_Sales_Data__c
                WHERE Name = :name
                LIMIT 1
            ];

            // Update the custom setting's value
            customSetting.Value__c = value;
            update customSetting; // Update as the current user
        } catch (Exception e) {
            // Log and throw an exception if the custom setting is not found or an error occurs
            System.debug('Error updating custom setting: ' + e.getMessage());
            throw new AuraHandledException('Failed to update custom setting.');
        }
    }

    /*
    **********
    Method Name : getUsersData
    author: Varun Rawal
    description: Fetches user data for a specific queue.
    @params: 
        - queueName: The name of the queue.
    @return: A list of UserWrapper objects containing user details.
    **********
    */
    @AuraEnabled
    public static List<UserWrapper> getUsersData(String queueName) {
        try {
            // Null check: Ensure the queue name is not empty
            if (String.isBlank(queueName)) {
                throw new AuraHandledException('Queue name cannot be empty.');
            }

            // Query the queue by its DeveloperName
            Group grp = [
                SELECT Id 
                FROM Group 
                WHERE DeveloperName = :queueName 
                AND Type = 'Queue' 
                LIMIT 1
            ];

            // Query the group members (users) in the queue
            List<GroupMember> groupMembers = [
                SELECT UserOrGroupId 
                FROM GroupMember 
                WHERE GroupId = :grp.Id
            ];

            // Extract user IDs from the group members
            Set<Id> userIds = new Set<Id>();
            for (GroupMember gm : groupMembers) {
                userIds.add(gm.UserOrGroupId);
            }

            // Query user details for the extracted user IDs
            List<User> users = [
                SELECT Id, Name, Email, Status__c, Capacity__c, Pre_Sales_Lead_Assignment__c, Username, Assigned_Sources__c, Max_Load__c
                FROM User 
                WHERE Id IN :userIds 
                ORDER BY Name
            ];

            // Wrap the user data into UserWrapper objects
            List<UserWrapper> wrappedUsers = new List<UserWrapper>();
            for (User user : users) {
                List<String> userSources = new List<String>();
                if (String.isNotBlank(user.Assigned_Sources__c)) {
                    userSources = user.Assigned_Sources__c.split(',');
                }

                Decimal capMax = 0;
                Decimal currentCap = 0;
                if (user.Max_Load__c != null) {
                    capMax = user.Max_Load__c;
                }
                if (user.Capacity__c != null) {
                    currentCap = user.Capacity__c;
                }

                wrappedUsers.add(new UserWrapper(
                    user.Id,
                    user.Name,
                    user.Username,
                    user.Email,
                    user.Status__c,
                    capMax,
                    false,
                    user.Pre_Sales_Lead_Assignment__c,
                    userSources,
                    currentCap
                ));
            }

            system.debug('wrappedUsers-->' + wrappedUsers);
            return wrappedUsers;
        } catch (Exception e) {
            // Log and throw an exception if an error occurs during the query
            System.debug('Error retrieving user data: ' + e.getMessage());
            throw new AuraHandledException('Failed to fetch users.');
        }
    }

    /*
    **********
    Method Name : getPicklistValues
    author: Varun Rawal
    description: Fetches the picklist values for the User.Status__c field.
    @return: A list of picklist values.
    **********
    */
    @AuraEnabled(cacheable=true)
    public static List<String> getPicklistValues() {
        try {
            List<String> statusValues = new List<String>();
            // Describe the User.Status__c field to get its picklist values
            Schema.DescribeFieldResult fieldResult = User.Status__c.getDescribe();
            for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
                statusValues.add(entry.getLabel());
            }
            return statusValues;
        } catch (Exception e) {
            // Log and throw an exception if an error occurs
            System.debug('Error fetching picklist values: ' + e.getMessage());
            throw new AuraHandledException('Failed to retrieve picklist values.');
        }
    }

    /*
    **********
    Method Name : scheduleBatch
    author: Varun Rawal
    description: Schedules a batch job to run at a specified minute interval.
    @params: 
        - minuteInterval: The interval in minutes at which the batch job should run.
    @return: A ToastResponse object indicating success or failure.
    **********
    */
    @AuraEnabled
    public static ToastResponse scheduleBatch(Integer minuteInterval) {
        try {
            // Null and range check: Ensure the minute interval is valid
            if (minuteInterval == null || minuteInterval <= 0 || minuteInterval > 59) {
                return new ToastResponse(false, 'Invalid minute interval. Please provide a value between 1 and 59.');
            }

            // Generate a unique job name and schedule the batch job
            String jobName = 'LeadNotificationBatch_' + System.now().getTime();
            String hour = String.valueOf(Datetime.now().hour());
            String min = String.valueOf(Datetime.now().addMinutes(minuteInterval).minute()); 
            String ss = String.valueOf(Datetime.now().second());
            String day = String.valueOf(Datetime.now().day());
            String month = String.valueOf(Datetime.now().month());
            String nextFireTime = ss + ' ' + min + ' ' + hour + ' ' + day + ' ' + month + ' ?';
            System.schedule(jobName, nextFireTime, new LeadNotificationBatch());

            return new ToastResponse(true, 'Scheduled job "' + jobName + '" to run every ' + minuteInterval + ' minute(s).');
        } catch (Exception e) {
            // Return a failure response if an error occurs
            return new ToastResponse(false, 'Failed to schedule job: ' + e.getMessage());
        }
    }

    /*
    **********
    Method Name : deleteScheduledJob
    author: Varun Rawal
    description: Deletes all scheduled jobs for the LeadNotificationBatch.
    @return: A ToastResponse object indicating success or failure.
    **********
    */
    @AuraEnabled
    public static ToastResponse deleteScheduledJob() {
        try {
            // Query all scheduled jobs for LeadNotificationBatch
            List<CronTrigger> scheduledJobs = [
                SELECT Id, State, CronJobDetail.Name  
                FROM CronTrigger  
                WHERE CronJobDetail.Name LIKE '%LeadNotificationBatch%'
            ];

            // Abort the jobs if they exist
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
            // Return a failure response if an error occurs
            return new ToastResponse(false, 'Failed to delete the scheduled job: ' + e.getMessage());
        }
    }

    /*
    **********
    Method Name : getLeadSourceValues
    author: Varun Rawal
    description: Fetches the picklist values for the Lead.LeadSource field.
    @return: A list of picklist values.
    **********
    */
    @AuraEnabled(cacheable=true)
    public static List<String> getLeadSourceValues() {
        List<String> leadSourceValues = new List<String>();
        // Describe the Lead.LeadSource field to get its picklist values
        Schema.DescribeFieldResult fieldResult = Lead.LeadSource.getDescribe();
        for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
            leadSourceValues.add(entry.getLabel());
        }
        return leadSourceValues;
    }

    /*
    **********
    Class Name : UserWrapper
    author: Varun Rawal
    description: Wrapper class to structure user data for LWC/Aura components.
    **********
    */
    public class UserWrapper {
        @AuraEnabled public String userId;
        @AuraEnabled public String name;
        @AuraEnabled public String userName;
        @AuraEnabled public String email;
        @AuraEnabled public String status;
        @AuraEnabled public Decimal capacity;
        @AuraEnabled public Boolean userChange;
        @AuraEnabled public Boolean leadAssignment;
        @AuraEnabled public List<String> userSources;
        @AuraEnabled public Decimal currentCapacity;

        public UserWrapper(String userId, String name, String userName, String email, String status, Decimal capacity, boolean userChange, boolean leadAssignment, List<String> userSources, Decimal currentCapacity) {
            this.userId = userId;
            this.name = name;
            this.userName = userName;
            this.email = email;
            this.status = status;
            this.capacity = capacity;
            this.userChange = userChange;
            this.leadAssignment = leadAssignment;
            this.userSources = userSources;
            this.currentCapacity = currentCapacity;
        }
    }

    /*
    **********
    Class Name : ToastResponse
    author: Varun Rawal
    description: Wrapper class to structure toast responses for LWC/Aura components.
    **********
    */
    public class ToastResponse {
        @AuraEnabled public Boolean isSuccess;
        @AuraEnabled public String message;

        public ToastResponse(Boolean isSuccess, String message) {
            this.isSuccess = isSuccess;
            this.message = message;
        }
    }
}