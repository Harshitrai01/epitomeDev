@isTest
private class UserStatusSchedulerTest {
    
    @isTest
    static void testUserStatusScheduler() {
        
        // Step 1: Setup necessary test data
        
        Group preSalesQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Pre_Sales_Queue' LIMIT 1];


        // Create a User with Status__c = 'Online'
        User testUser1 = new User(
            LastName = 'demotest1',
            Username = 'testuser1demo@example.com',
            Email = 'testuser1demo@example.com',
            Alias = 'tuser1',
            ProfileId = UserInfo.getProfileId(),
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            Status__c = '',
            Capacity__c = 2,
            Max_Load__c = 3
        );
        insert testUser1;

        // Create another User with Status__c = 'Online'
        User testUser2 = new User(
            LastName = 'demotest2',
            Username = 'testuser2demo@example.com',
            Email = 'testuser2demo@example.com',
            Alias = 'tuser2',
            ProfileId = UserInfo.getProfileId(),
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            Status__c = 'Online',
            Capacity__c = 2,
            Max_Load__c = 3
        );
        insert testUser2;

        // Create GroupMember to associate users with Pre-Sales Queue
        GroupMember groupMember1 = new GroupMember(
            GroupId = preSalesQueue.Id,
            UserOrGroupId = testUser1.Id
        );
        insert groupMember1;

        GroupMember groupMember2 = new GroupMember(
            GroupId = preSalesQueue.Id,
            UserOrGroupId = testUser2.Id
        );
        insert groupMember2;
        
        // Step 2: Schedule the job for testing
        Test.startTest();
        
        // Schedule the job to run immediately (for testing purposes)
        String cronExpression = '0 0 0 1 1 ?'; // This would be for scheduling the job every night at 12:00 AM
        String jobName = 'UserStatusSchedulerTestJob';
        UserStatusScheduler scheduler = new UserStatusScheduler();
        System.schedule(jobName, cronExpression, scheduler);
        
        Test.stopTest(); // This will execute the scheduled job immediately in test context
        
        // Step 3: Verify the expected outcomes
        
        // Re-query the users to check if their Status__c has been updated
        testUser1 = [SELECT Id, Status__c FROM User WHERE Id = :testUser1.Id];
        testUser2 = [SELECT Id, Status__c FROM User WHERE Id = :testUser2.Id];
        
    }
}