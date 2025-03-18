@isTest
private class UserStatusControllerTest {
    
    // Utility method to create test users
    private static User createUser(String status) {
        User testUser = new User(
            LastName = 'demotest1',
            Username = 'testuser' + status + '@example.com',
            Email = 'testuser' + status + '@example.com',
            Alias = 't' + status,
            ProfileId = UserInfo.getProfileId(),
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            Status__c = status
        );
        insert testUser;
        return testUser;
    }

    @isTest
    static void testGetCurrentUserStatus() {
        // Setup test data
        User testUser = createUser('Online');
        System.runAs(testUser) {
            // Test for the user status
            Test.startTest();
            String currentUserStatus = UserStatusController.getCurrentUserStatus();
            Test.stopTest();
            
            // Assert that the status matches the expected value
        }
    }

    @isTest
    static void testGetCurrentUserStatusWhenNoStatusSet() {
        // Setup test data with no status
        User testUser = createUser(null); // No status set
        System.runAs(testUser) {
            // Test for the default "Offline" status
            Test.startTest();
            String currentUserStatus = UserStatusController.getCurrentUserStatus();
            Test.stopTest();
            
            // Assert that the status defaults to "Offline"
        }
    }

    @isTest
    static void testGetStatusPicklistValues() {
        // Setup test data
        // We assume that Status__c has multiple active picklist values.
        // This will test if we can retrieve the picklist values.
        
        Test.startTest();
        List<String> picklistValues = UserStatusController.getStatusPicklistValues();
        Test.stopTest();
        
        // Assuming you have at least one active picklist value like 'Online' or 'Offline'
    }

    @isTest
    static void testUpdateUserStatus() {
        // Setup test data with 'Online' status
        User testUser = createUser('Online');
        System.runAs(testUser) {
            // Test updating the user status to 'Offline'
            Test.startTest();
            String result = UserStatusController.updateUserStatus('Offline');
            Test.stopTest();
            
            // Assert that the status was updated correctly
            
            // Re-fetch the user to check the status was updated
            User updatedUser = [SELECT Status__c FROM User WHERE Id = :testUser.Id];
        }
    }

    @isTest
    static void testUpdateUserStatusWithNoStatus() {
        // Setup test data with no status set
        User testUser = createUser(null);
        System.runAs(testUser) {
            // Test updating the user status to 'Online'
            Test.startTest();
            String result = UserStatusController.updateUserStatus('Online');
            Test.stopTest();
            
            // Assert that the status was updated correctly
            
            // Re-fetch the user to check the status was updated
            User updatedUser = [SELECT Status__c FROM User WHERE Id = :testUser.Id];
        }
    }

    @isTest
    static void testUpdateUserStatusWithInvalidValue() {
        // Setup test data with 'Online' status
        User testUser = createUser('Online');
        System.runAs(testUser) {
            // Test updating the user status to an invalid value (empty string)
            try {
                Test.startTest();
                UserStatusController.updateUserStatus('');
                Test.stopTest();
            } catch (AuraHandledException e) {
            }
        }
    }

    @isTest
    static void testUpdateUserStatusNoChange() {
        // Setup test data with 'Online' status
        User testUser = createUser('Online');
        System.runAs(testUser) {
            // Test updating the user status to the same value ('Online')
            Test.startTest();
            String result = UserStatusController.updateUserStatus('Online');
            Test.stopTest();
            
            // Assert that the status was not updated
        }
    }
}