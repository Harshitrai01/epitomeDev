@isTest
public class BoardOfResolutionControllerTest {
    
    @testSetup
    static void setupTestData() {
        // Create a test Unit record
        Unit__c testUnit = new Unit__c(Name = 'Test Unit');
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
    }
    
    @isTest
    static void testBoardOfResolutionController() {
        // Get the test Opportunity record
        Opportunity testOpportunity = [SELECT Id FROM Opportunity LIMIT 1];
        
        // Set the page parameters
        Test.setCurrentPageReference(new PageReference('/apex/BoardOfResolutionPage'));
        ApexPages.currentPage().getParameters().put('Id', testOpportunity.Id);
        
        // Instantiate the controller
        ApexPages.StandardController stdController = new ApexPages.StandardController(testOpportunity);
        BoardOfResolutionController controller = new BoardOfResolutionController(stdController);
        
        // Assert the values
        System.assertNotEquals(controller.opportunityRecord, null, 'Opportunity record should not be null');
        System.assertEquals(controller.opportunityRecord.Id, testOpportunity.Id, 'Opportunity ID should match');
        System.assertNotEquals(controller.balanceAmountInWords, '-', 'Balance amount in words should not be empty');
    }
}