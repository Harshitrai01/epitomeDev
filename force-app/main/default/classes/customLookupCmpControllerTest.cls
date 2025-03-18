@isTest
private class customLookupCmpControllerTest {
    
    @testSetup
    static void setupTestData() {
        // Create a test Phase record
        Phase__c testPhase = new Phase__c(Name = 'Test Phase');
        insert testPhase;
        
        // Insert a single test Unit record
        Unit__c testUnit = new Unit__c(
            Name = 'Plot A1', 
            Status__c = 'Available', 
            Plot_Facing__c = 'North', 
            Phase__c = testPhase.Id
        );
        insert testUnit;
    }
    
    @isTest
    static void testSearchPlots() {
        Phase__c testPhase = [SELECT Id FROM Phase__c LIMIT 1];

        Test.startTest();
        customLookupCmpController.searchPlots('Plot A', testPhase.Id);
        Test.stopTest();
    }
    
    @isTest
    static void testSearchPlotsWithInvalidId() {
        Test.startTest();
        try {
            customLookupCmpController.searchPlots('Plot A', 'InvalidPhaseId123');
        } catch (AuraHandledException e) {
            // Exception expected
        }
        Test.stopTest();
    }

    @isTest
    static void testSearchLookupRecords() {
        Contact testContact = new Contact(FirstName = 'Test', LastName = 'User');
        insert testContact;

        Test.startTest();
        customLookupCmpController.searchLookupRecords('Test', new List<String>(), 'Contact', 'FirstName', 'LastName', 10);
        Test.stopTest();
    }

    @isTest
    static void testSearchLookupRecordsWithInvalidObject() {
        Test.startTest();
        try {
            customLookupCmpController.searchLookupRecords('Test', new List<String>(), 'InvalidObject', 'Name', 'LastName', 10);
        } catch (Exception e) {
            // Exception expected
        }
        Test.stopTest();
    }

    @isTest
    static void testGetRecentlyCreatedRecord() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Test.startTest();
        customLookupCmpController.getRecentlyCreatedRecord('Account', testAccount.Id, 'Name', '');
        Test.stopTest();
    }

    @isTest
    static void testGetRecentlyCreatedRecordWithInvalidId() {
        Test.startTest();
        try {
            customLookupCmpController.getRecentlyCreatedRecord('Account', 'InvalidId123', 'Name', '');
        } catch (Exception e) {
            // Exception expected
        }
        Test.stopTest();
    }
}