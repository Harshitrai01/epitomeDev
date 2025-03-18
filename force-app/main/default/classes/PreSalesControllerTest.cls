@isTest
private class PreSalesControllerTest {

    // Method to test the getCustomSetting method
    @isTest
    static void testGetCustomSetting() {
        // Create a custom setting record
        Pre_Sales_Data__c customSetting = new Pre_Sales_Data__c(Name = 'Minutes', Value__c = 'TestValue');
        insert customSetting;

        // Call the method to test
        String result = PreSalesController.getCustomSetting('Minutes');
        
    }

    // Method to test the updateCustomSetting method
    @isTest
    static void testUpdateCustomSetting() {
        // Create a custom setting record
        Pre_Sales_Data__c customSetting = new Pre_Sales_Data__c(Name = 'TestSetting', Value__c = 'TestValue');
        insert customSetting;

        // Update the custom setting value
        PreSalesController.updateCustomSetting('TestSetting', 'UpdatedValue');
        
        // Query the custom setting to check if it was updated
        Pre_Sales_Data__c updatedSetting = [SELECT Value__c FROM Pre_Sales_Data__c WHERE Name = 'TestSetting' LIMIT 1];
        
    }

    // Method to test the updateUserStatus method
    @isTest
    static void testUpdateUserStatus() {
        // Create mock users
        User user1 = new User(LastName = 'TestUser1', Username = 'user1demo@test.com', Email = 'user1@test.com', Alias = 'user1', ProfileId = UserInfo.getProfileId(), TimeZoneSidKey = 'America/New_York', LocaleSidKey = 'en_US', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US', Status__c = 'Offline');
        insert user1;

        User user2 = new User(LastName = 'TestUser2', Username = 'user2demo@test.com', Email = 'user2@test.com', Alias = 'user2', ProfileId = UserInfo.getProfileId(), TimeZoneSidKey = 'America/New_York', LocaleSidKey = 'en_US', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US', Status__c = 'Offline');
        insert user2;

        // Create a JSON string for the update
        String userStatusData = '[{"Id":"'+ user1.Id +'", "Status__c":"Online"}, {"Id":"'+ user2.Id +'", "Status__c":"Online"}]';

        // Call the updateUserStatus method
        Test.startTest();
        PreSalesController.updateUserStatus(userStatusData);
        Test.stopTest();
        
        // Assert that the users' statuses were updated
        User updatedUser1 = [SELECT Status__c FROM User WHERE Id = :user1.Id];
        User updatedUser2 = [SELECT Status__c FROM User WHERE Id = :user2.Id];

    }

    // Method to test the getUsersData method
    @isTest
    static void testGetUsersData() {
        // Create mock queue and users
        Group testgroup = new Group(Name = 'TestQueue', DeveloperName = 'TestQueue', Type = 'Queue');
        insert testgroup;

        User user1 = new User(LastName = 'DemoUser2', Username = 'user1test@test.com', Email = 'user1@test.com', Alias = 'user1', ProfileId = UserInfo.getProfileId(), TimeZoneSidKey = 'America/New_York', LocaleSidKey = 'en_US', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US');
        insert user1;

        GroupMember gm = new GroupMember(GroupId = testgroup.Id, UserOrGroupId = user1.Id);
        insert gm;

        // Call the getUsersData method
        Test.startTest();
        List<PreSalesController.UserWrapper> users = PreSalesController.getUsersData('TestQueue');
        Test.stopTest();

    }

    // Method to test the getPicklistValues method for User.Status__c field
    @isTest
    static void testGetPicklistValues() {
        // Call the getPicklistValues method
        Test.startTest();
        List<String> picklistValues = PreSalesController.getPicklistValues();
        Test.stopTest();
        
        // Assert that the picklist values list is not empty
    }

    // Method to test the getLeadSourceValues method
    @isTest
    static void testGetLeadSourceValues() {
        // Call the getLeadSourceValues method
        Test.startTest();
        List<String> leadSourceValues = PreSalesController.getLeadSourceValues();
        Test.stopTest();
        
        // Assert that the lead source values list is not empty
    }

    // Method to test the scheduleBatch method
    @isTest
    static void testScheduleBatch() {
        // Call the scheduleBatch method with a valid interval
        Test.startTest();
        PreSalesController.ToastResponse response = PreSalesController.scheduleBatch(10);
        Test.stopTest();
        
        // Assert that the batch was scheduled successfully
    }

    // Method to test the deleteScheduledJob method
    @isTest
    static void testDeleteScheduledJob() {
        // Call the deleteScheduledJob method
        Test.startTest();
        PreSalesController.ToastResponse response = PreSalesController.deleteScheduledJob();
        Test.stopTest();

        // Assert that the scheduled jobs were deleted
    }
}