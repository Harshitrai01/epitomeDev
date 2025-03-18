@isTest
public class DemandLetterPdfControllerTest {
    
    @testSetup
    static void setupTestData() {
        // Create a test Unit record
        Unit__c testUnit = new Unit__c(Name = 'Test Unit', Bank_Name__c = 'Test Bank', Virtual_Account_IFSC__c = 'TEST0001234', Virtual_Account_Number__c = '1234567890');
        insert testUnit;
        
        // Create a test Opportunity record
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Unit__c = testUnit.Id,
            Sale_Value_Amount__c = 100000
        );
        insert testOpportunity;
        
        // Create a test Contact record
        Contact testContact = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'johndoe@example.com',
            Phone = '1234567890',
            Permanent_Address__City__s = 'Test City',
            Permanent_Address__CountryCode__s = 'US',
            Permanent_Address__StateCode__s = 'CA',
            Permanent_Address__PostalCode__s = '12345',
            Permanent_Address__Street__s = '123 Test Street'
        );
        insert testContact;
        
        // Create a test OpportunityContactRole record
        OpportunityContactRole testOCR = new OpportunityContactRole(
            OpportunityId = testOpportunity.Id,
            ContactId = testContact.Id,
            IsPrimary = true
        );
        insert testOCR;
    }
    
    @isTest
    static void testDemandLetterPdfController() {
        // Get the test Opportunity record
        Opportunity testOpportunity = [SELECT Id FROM Opportunity LIMIT 1];
        
        // Set the page parameters
        Test.setCurrentPageReference(new PageReference('/apex/DemandLetterPdfPage'));
        ApexPages.currentPage().getParameters().put('Id', testOpportunity.Id);
        
        // Instantiate the controller
        ApexPages.StandardController stdController = new ApexPages.StandardController(testOpportunity);
        demandLetterPdfController controller = new demandLetterPdfController(stdController);
        
        // Assert the values
        System.assertNotEquals(controller.opportunityRecord, null, 'Opportunity record should not be null');
        System.assertEquals(controller.opportunityRecord.Id, testOpportunity.Id, 'Opportunity ID should match');
        System.assertNotEquals(controller.balanceAmountInWords, '-', 'Balance amount in words should not be empty');
        
        // Verify OpportunityContactRolesRecord
        System.assertNotEquals(controller.OpportunityContactRolesRecord, null, 'Opportunity Contact Role record should not be null');
        System.assertEquals(controller.OpportunityContactRolesRecord.OpportunityId, testOpportunity.Id, 'OpportunityContactRole should belong to the Opportunity');
    }
}