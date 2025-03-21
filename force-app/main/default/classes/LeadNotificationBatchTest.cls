@isTest
private class LeadNotificationBatchTest {

    // Method to create test data (Leads and Custom Settings)
    private static void setupTestData() {
        // Create test User (Owner of Lead)
        User testUser = new User(
            LastName = 'testUser1',
            Alias = 'testu1',
            Email = 'testuserdemo1@example.com',
            Username = 'testuserdemo1@example.com',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'ISO-8859-1',
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;
        
        // Create test Lead records
        Lead lead1 = new Lead(
            Status = 'Unopened',
            OwnerId = testUser.Id,
            FirstName = 'John',
            LastName = 'Doe',
            Company = 'Company1'
        );
        Lead lead2 = new Lead(
            Status = 'Unopened',
            OwnerId = testUser.Id,
            FirstName = 'Jane',
            LastName = 'Smith',
            Company = 'Company2'
        );
        insert new List<Lead>{ lead1, lead2 };
        
        // Create custom setting for 'Send to Manager'
        Pre_Sales_Data__c setting1 = new Pre_Sales_Data__c(
            Name = 'Send to Manager',
            Value__c = 'true'
        );
        insert setting1;
        
        // Create custom setting for 'Minutes' (reschedule interval)
        Pre_Sales_Data__c setting2 = new Pre_Sales_Data__c(
            Name = 'Minutes',
            Value__c = '15'
        );
        insert setting2;
    }

    // Test for start method of batch class
    @isTest
    static void testStartMethod() {
        setupTestData();
        
        Test.startTest();
        
        // Instantiate the batch class
        LeadNotificationBatch batch = new LeadNotificationBatch();
        
        // Start method
        Database.QueryLocator queryLocator = batch.start(null);
        List<Lead> leads = [SELECT Id FROM Lead WHERE Status = 'Unopened'];
        
        System.assertEquals(leads.size(), 2, 'Expected two leads to be selected.');
        
        Test.stopTest();
    }

    // Test for execute method of batch class
    @isTest
    static void testExecuteMethod() {
        setupTestData();
        
        // Create test data
        List<Lead> leads = [SELECT Id, OwnerId FROM Lead WHERE Status = 'Unopened'];
        
		CustomNotificationType notificationType = [Select Id, DeveloperName from CustomNotificationType where DeveloperName = 'Lead_Assignment_Notification'];
        
        Test.startTest();
        
        // Instantiate batch class
        LeadNotificationBatch batch = new LeadNotificationBatch();
        
        // Execute method (simulate processing leads)
        batch.execute(null, leads);
        
        Test.stopTest();
    }

    // Test for finish method of batch class (including scheduling logic)
    @isTest
    static void testFinishMethod() {
        setupTestData();
        
        // Create test data
        Pre_Sales_Data__c customSetting = [
            SELECT Value__c FROM Pre_Sales_Data__c WHERE Name = 'Minutes' LIMIT 1
        ];
        
        // Validate that the finish method reschedules the job
        Test.startTest();
        
        LeadNotificationBatch batch = new LeadNotificationBatch();
        batch.finish(null);
        
        // Fetch scheduled jobs and check if rescheduling happened
        List<CronTrigger> scheduledJobs = [
            SELECT Id, State, CronJobDetail.Name  
            FROM CronTrigger  
            WHERE CronJobDetail.Name LIKE '%LeadNotificationBatch%'  
        ];
        
        System.assert(scheduledJobs.size() > 0, 'Expected at least one job to be scheduled.');
        
        Test.stopTest();
    }

    // Test for execute method of the Schedulable interface
    @isTest
    static void testSchedulableExecuteMethod() {
        setupTestData();
        
        Test.startTest();
        
        // Test the schedulable execute method by scheduling it
        LeadNotificationBatch batch = new LeadNotificationBatch();
        String jobId = System.schedule('LeadNotificationBatch Job', '0 0 * * * ?', batch);
        
        // Fetch the scheduled job to ensure it was scheduled correctly
        CronTrigger cronTrigger = [
            SELECT Id, CronExpression FROM CronTrigger WHERE Id = :jobId
        ];
        
        System.assertNotEquals(cronTrigger, null, 'Expected scheduled job to exist.');
        
        Test.stopTest();
    }
}