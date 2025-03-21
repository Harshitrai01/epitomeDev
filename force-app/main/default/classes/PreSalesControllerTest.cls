@isTest
public with sharing class PreSalesControllerTest {
    
    @testSetup
    static void setup() {
        // Insert test data for custom setting
        List<Pre_Sales_Data__c> customSettingsList = new List<Pre_Sales_Data__c>{
            new Pre_Sales_Data__c(Name = 'Minutes', Value__c = '2')
                };
                    
                    // Insert all records in a single DML statement
                    insert customSettingsList;
        
        // Insert test users
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser@example.com.sandbox',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;
    }
    
    @isTest
    static void testGetCustomSetting() {
        Test.startTest();
        String value = PreSalesController.getCustomSetting('Minutes');
        Test.stopTest();
        
    }
    
    @isTest
    static void testUpdateCustomSetting() {
                             

                    
                    
        Test.startTest();
    PreSalesController.updateCustomSetting('Minutes', 'UpdatedValue');
        Test.stopTest();
        
        
    }
    
    @isTest
    static void testUpdateUserStatus() {
        User testUser = [SELECT Id, Status__c FROM User WHERE Email = 'testuser@example.com' LIMIT 1];
        testUser.Status__c = 'Offline';
        
        String userJson = JSON.serialize(new List<User>{testUser});
        Test.startTest();
        PreSalesController.updateUserStatus(userJson);
        Test.stopTest();
        
        
    }
    
    @isTest
    static void testGetPicklistValues() {
        Test.startTest();
        List<String> picklistValues = PreSalesController.getPicklistValues();
        PreSalesController.getLeadSourceValues();
        PreSalesController.deleteScheduledJob();
        PreSalesController.scheduleBatch(null);
        PreSalesController.scheduleBatch(100);
        
        PreSalesController.scheduleBatch(10);
        Test.stopTest();
        
        
    }
    
    @isTest
    static void testscheduleBatch() {
        try{
            Test.startTest();
            
            
            PreSalesController.scheduleBatch(10);
            Test.stopTest();
        }catch (Exception e) {
            system.debug('error');
        }
        
        
        
    }
    @isTest
    static void testGetUsersData() {
        // Create a Queue (Group of type 'Queue')
        Group testQueue = new Group(
            Name = 'Test Queue',
            DeveloperName = 'Test_Queue',
            Type = 'Queue'
        );
        insert testQueue;
        
        // Create Test Users
        User testUser1 = new User(
            FirstName = 'Test',
            LastName = 'User1',
            Email = 'testuser1@example.com',
            Username = 'testuser1aaa@example.com',
            Alias = 'tuser1',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert testUser1;
        
        User testUser2 = new User(
            FirstName = 'Test',
            LastName = 'User2',
            Email = 'testuser2@example.com',
            Username = 'testuser2ssa@example.com',
            Alias = 'tuser2',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert testUser2;
        
        // Add Users to the Queue
        GroupMember gm1 = new GroupMember(GroupId = testQueue.Id, UserOrGroupId = testUser1.Id);
        GroupMember gm2 = new GroupMember(GroupId = testQueue.Id, UserOrGroupId = testUser2.Id);
        insert new List<GroupMember>{gm1, gm2};
            
            // Start Test Execution
            Test.startTest();
        List<PreSalesController.UserWrapper> users = PreSalesController.getUsersData('Test_Queue');
        Test.stopTest();
        
        
    }
}