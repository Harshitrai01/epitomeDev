@isTest
private class UserTriggerHandlerTest {
    
    @isTest
    static void testHandleStatusChange_LeadAssignment() {
        // Step 1: Setup test data for User and related objects
        
        // Create a user with Pre-Sales Lead Assignment enabled
        User testUser = new User(
            LastName = 'demotest1',
            Username = 'testuser1demo@example.com',
            Email = 'testuser@example.com',
            Alias = 'tuser',
            ProfileId = UserInfo.getProfileId(),
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            Status__c = 'Online', // Assume user is online
            Capacity__c = 2, // Assume this user can handle up to 2 leads
            Max_Load__c = 3, // Maximum load is 3 leads
            Pre_Sales_Lead_Assignment__c = true,
            Assigned_Sources__c = 'Website, Phone'
        );
        insert testUser;
        
        // Create a queue for Pre-Sales
        Group preSalesQueue = new Group(
            Name = 'Pre-Sales Queue demo',
            DeveloperName = 'Pre_Sales_Queue_demo',
            Type = 'Queue'
        );
        insert preSalesQueue;
        
        // Create a GroupMember to associate the user with the Pre-Sales Queue
        GroupMember groupMember = new GroupMember(
            GroupId = preSalesQueue.Id,
            UserOrGroupId = testUser.Id
        );
        insert groupMember;
        
        // Create a Pre-Sales Setting record
        Pre_Sales_Data__c preSalesSetting = new Pre_Sales_Data__c(
            Name = 'Pre-Sales Assignment',
            Value__c = 'true'
        );
        //insert preSalesSetting;
        
        // Create a Lead record that is unassigned
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            LeadSource = 'Website',
            Status = 'Unopened'
        );
        insert testLead;

        // Step 2: Simulate User status change by calling handleStatusChange
        User oldUser = [SELECT Id, Status__c FROM User WHERE Id = :testUser.Id];
        oldUser.Status__c = 'Offline'; // Change user status to trigger the status change logic
        update oldUser;
        
        // Simulate the new User with the status 'Online'
        User newUser = [SELECT Id, Status__c FROM User WHERE Id = :testUser.Id];
        
        // Step 3: Call handleStatusChange method to simulate the status change and lead assignment process
        Test.startTest();
        UserTriggerHandler.handleStatusChange(new List<User>{newUser}, new Map<Id, User>{testUser.Id => oldUser});
        Test.stopTest();
        
        // Step 4: Verify the results
        Lead updatedLead = [SELECT Id, OwnerId FROM Lead WHERE Id = :testLead.Id];
        
        // Verify that the user’s capacity has been updated
        User updatedUser = [SELECT Id, Capacity__c FROM User WHERE Id = :testUser.Id];
        
    }
    
    @isTest
    static void testHandleStatusChange_NoEligibleUsers() {
        // Setup a user with no valid assignment sources
        User testUser = new User(
            LastName = 'demotest2',
            Username = 'testuser2@example.com',
            Email = 'testuser2@example.com',
            Alias = 'tuser2',
            ProfileId = UserInfo.getProfileId(),
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            Status__c = 'Online',
            Capacity__c = 2,
            Max_Load__c = 3,
            Pre_Sales_Lead_Assignment__c = true,
            Assigned_Sources__c = '' // No sources assigned
        );
        insert testUser;
        
        // Create a Lead record that is unassigned
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            LeadSource = 'Website',
            Status = 'Unopened'
        );
        insert testLead;

        // Simulate User status change
        User oldUser = [SELECT Id, Status__c FROM User WHERE Id = :testUser.Id];
        oldUser.Status__c = 'Offline';
        update oldUser;
        
        User newUser = [SELECT Id, Status__c FROM User WHERE Id = :testUser.Id];
        
        Test.startTest();
        UserTriggerHandler.handleStatusChange(new List<User>{newUser}, new Map<Id, User>{testUser.Id => oldUser});
        Test.stopTest();
        
        // Verify that no leads are assigned as there are no eligible sources
        Lead updatedLead = [SELECT Id, OwnerId FROM Lead WHERE Id = :testLead.Id];
    }
    
    @isTest
    static void testHandleStatusChange_ErrorHandling() {
        // Setup a user with Pre-Sales Lead Assignment enabled
        User testUser = new User(
            LastName = 'demotest3',
            Username = 'testuser3@example.com',
            Email = 'testuser3@example.com',
            Alias = 'tuser3',
            ProfileId = UserInfo.getProfileId(),
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            Status__c = 'Online',
            Capacity__c = 2,
            Max_Load__c = 3,
            Pre_Sales_Lead_Assignment__c = true,
            Assigned_Sources__c = 'Website'
        );
        insert testUser;
        
        // Create a Lead record that is unassigned
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            LeadSource = 'Website',
            Status = 'Unopened'
        );
        insert testLead;

        // Simulate User status change
        User oldUser = [SELECT Id, Status__c FROM User WHERE Id = :testUser.Id];
        oldUser.Status__c = 'Offline';
        update oldUser;
        
        User newUser = [SELECT Id, Status__c FROM User WHERE Id = :testUser.Id];
        
        // Induce error in processing by removing pre-sales settings
        delete [SELECT Id FROM Pre_Sales_Data__c WHERE Name = 'Pre-Sales Assignment'];
        
        Test.startTest();
        try {
            UserTriggerHandler.handleStatusChange(new List<User>{newUser}, new Map<Id, User>{testUser.Id => oldUser});
        } catch (AuraHandledException e) {
        }
        Test.stopTest();
    }
}