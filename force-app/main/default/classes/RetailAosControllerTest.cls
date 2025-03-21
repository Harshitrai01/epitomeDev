@isTest
public class RetailAosControllerTest {

    // Helper method to create test data
    public static void setupTestData() {
        // Create test Account
        Account acc = new Account(Name = 'Test Account', BillingStreet = 'Street', BillingCity = 'City', BillingState = 'State', BillingCountry = 'Country', BillingPostalCode = '12345');
        insert acc;

        // Create test Contact
        Contact con = new Contact(FirstName = 'John', LastName = 'Doe', Date_Of_Birth__c = Date.newInstance(1990, 5, 20), Aadhaar_Card__c = '123456789012');
        insert con;

        // Create test Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity', 
            StageName = 'Prospecting', 
            CloseDate = Date.today(), 
            AccountId = acc.Id, 
            Contact__c = con.Id, 
            Sale_Value_Amount__c = 1000000.00
        );
        insert opp;

        // Create related Payment records
        Payment__c payment = new Payment__c(
            Opportunity__c = opp.Id,
            Payment_Amount__c = 200000.00,
            Payment_Created_Date__c = Date.today(),
            Payment_Mode__c = 'Bank Transfer',
            Merchant_Transaction_Id__c = '123ABC',
            Approval_Status__c = 'Approved'
        );
        insert payment;

        // Create OpportunityContactRole
        OpportunityContactRole oppConRole = new OpportunityContactRole(OpportunityId = opp.Id, ContactId = con.Id, Role = 'Decision Maker');
        insert oppConRole;
    }

    @isTest
    static void testRetailAosController() {
        // Setup test data
        setupTestData();

        // Retrieve an Opportunity record
        Opportunity testOpportunity = [SELECT Id FROM Opportunity LIMIT 1];

        // Set the page parameters
        Test.setCurrentPageReference(new PageReference('/apex/YourPageName'));  // Use your actual Visualforce page name
        ApexPages.currentPage().getParameters().put('Id', testOpportunity.Id);

        // Create a StandardController for the Opportunity
        ApexPages.StandardController stdController = new ApexPages.StandardController(testOpportunity);

        // Instantiate the controller
        RetailAosController controller = new RetailAosController(stdController);

        // Assert the values
        System.assertNotEquals(controller.opportunityRecord, null, 'Opportunity record should not be null');
        System.assertEquals(controller.opportunityRecord.Id, testOpportunity.Id, 'Opportunity ID should match');
        System.assertNotEquals(controller.saleAmountInWords, '-', 'Sale amount in words should not be empty');
        System.assertNotEquals(controller.balanceAmountInWords, '-', 'Balance amount in words should not be empty');
        System.assertNotEquals(controller.paidAmountInWords, '-', 'Paid amount in words should not be empty');
        
        // Assert Contact Details
        System.assertNotEquals(controller.contactDetailsList, null, 'Contact details list should not be null');
      
    }

    @isTest
    static void testControllerWithoutOpportunityId() {
        // Create a StandardController without Opportunity
        ApexPages.StandardController stdController = new ApexPages.StandardController(new Opportunity());
        
        // Instantiate the controller
        RetailAosController controller = new RetailAosController(stdController);
controller.convertPlotSizeToSqM(12.0);
        // Verify that no data is retrieved if there is no OpportunityId
        System.assertEquals(null, controller.opportunityRecord, 'Opportunity record should be null if no OpportunityId is provided');
    }
     
}