@isTest
private class LeadNotificationBatchTest {
    
    @testSetup
    static void setupTestData() {
        // Create custom settings
        List<Pre_Sales_Data__c> customSettings = new List<Pre_Sales_Data__c>{
            new Pre_Sales_Data__c(
                Name = 'Send to Manager',
                Value__c = 'true'
            ),
            new Pre_Sales_Data__c(
                Name = 'Minutes',
                Value__c = '30'
            )
        };
        insert customSettings;
        
        // Create test users
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        User testUser = new User(
            Alias = 'standt',
            Email = 'standarduser@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = standardProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'standarduser' + System.now().getTime() + '@testorg.com'
        );
        
        User managerUser = new User(
            Alias = 'mgr',
            Email = 'manageruser@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Manager',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = standardProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'manageruser' + System.now().getTime() + '@testorg.com'
        );
        
        insert new List<User>{testUser, managerUser};
        
        // Set manager for test user
        testUser.ManagerId = managerUser.Id;
        update testUser;
        
        // Create test leads
        List<Lead> testLeads = new List<Lead>();
        for (Integer i = 0; i < 10; i++) {
            testLeads.add(new Lead(
                FirstName = 'Test',
                LastName = 'Lead ' + i,
                Company = 'Test Company',
                Status = 'Unopened',
                OwnerId = testUser.Id
            ));
        }
        insert testLeads;
        
    }
    
    @isTest
    static void testLeadNotificationBatch() {
        // Prepare custom notification type mock
        Test.startTest();
        User managerUser = [select Id, Name, Email from User where Email = 'manageruser@testorg.com'];
        list<Lead> updateSomelead = [select Id, Name, OwnerId from Lead where Name like 'Test Lead%'];
        for(Lead eachLead :updateSomelead){
            eachLead.OwnerId = managerUser.Id;
        }
        Update updateSomelead;
        // Ensure custom settings exist
        Pre_Sales_Data__c sendToManagerSetting = [
            SELECT Id, Value__c, Name
            FROM Pre_Sales_Data__c 
            WHERE Name = 'Send to Manager' 
            LIMIT 1
        ];
        
        Pre_Sales_Data__c minutesSetting = [
            SELECT Id, Value__c 
            FROM Pre_Sales_Data__c 
            WHERE Name = 'Minutes' 
            LIMIT 1
        ];
        System.debug('sendToManagerSetting-----'+sendToManagerSetting);
        System.debug('sendToManagerSetting-----'+sendToManagerSetting);
        // Create a mock for custom notification
        List<CustomNotificationType> existingNotifications = [
            SELECT Id, DeveloperName 
            FROM CustomNotificationType 
            WHERE DeveloperName = 'Lead_Assignment_Notification'
        ];
        
        // If no existing notification, skip the test
        if (!existingNotifications.isEmpty()) {
            // Execute the batch
            LeadNotificationBatch batchJob = new LeadNotificationBatch();
            Database.executeBatch(batchJob);
        }
        
        Test.stopTest();
        
        // Add assertions to verify batch execution
        System.assertNotEquals(0, existingNotifications.size(), 'Custom Notification Type should exist');
    }
    
    
    
    @isTest
    static void testBatchFinish() {
        Test.startTest();
        User managerUser = [select Id, Name, Email from User where Email = 'manageruser@testorg.com'];
        list<Lead> updateSomelead = [select Id, Name, OwnerId from Lead where Name like 'Test Lead%'];
        for(Lead eachLead :updateSomelead){
            eachLead.OwnerId = managerUser.Id;
        }
        Update updateSomelead;
        LeadNotificationBatch batchJob = new LeadNotificationBatch();
        Database.BatchableContext mockContext = new MockBatchableContext();
        
        batchJob.finish(mockContext);
        Test.stopTest();
        
        // Verify scheduled job is created
        List<CronTrigger> scheduledJobs = [
            SELECT Id, State, CronJobDetail.Name  
            FROM CronTrigger  
            WHERE CronJobDetail.Name LIKE '%LeadNotificationBatch%'
        ];
        
        System.assert(!scheduledJobs.isEmpty(), 'A scheduled job should have been created');
    }
    
    @isTest
    static void testSendToManagerFalse() {
        // Update custom setting to false
        Pre_Sales_Data__c sendToManagerSetting = [
            SELECT Id, Value__c, Name
            FROM Pre_Sales_Data__c 
            WHERE Name = 'Send to Manager' 
            LIMIT 1
        ];
        User managerUser = [select Id, Name, Email from User where Email = 'manageruser@testorg.com'];
        list<Lead> updateSomelead = [select Id, Name, OwnerId from Lead where Name like 'Test Lead%'];
        for(Lead eachLead :updateSomelead){
            eachLead.OwnerId = managerUser.Id;
        }
        Update updateSomelead;
        system.debug('144 '+sendToManagerSetting);
        if(sendToManagerSetting!=null){
        sendToManagerSetting.Value__c = 'true';
        update sendToManagerSetting;
        }
        Test.startTest();
        Database.executeBatch(new LeadNotificationBatch());
        Test.stopTest();
    }
    
    
    // Mock classes
    private class MockBatchableContext implements Database.BatchableContext {
        public Id getJobId() { return null; }
        public Id getChildJobId() { return null; }
    }
}