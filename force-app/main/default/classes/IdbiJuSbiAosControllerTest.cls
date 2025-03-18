@isTest
private class IdbiJuSbiAosControllerTest {
    @testSetup
    static void setupTestData() {
        // Create an Account
        Account acc = new Account(Name = 'Test Account', BillingStreet = '123 Test St',
                                  BillingCity = 'Test City', BillingState = 'Test State',
                                  BillingCountry = 'Test Country', BillingPostalCode = '123456');
        insert acc;

        // Create a Contact
        Contact con = new Contact(FirstName = 'John', LastName = 'Doe',
                                  Aadhaar_Card__c = '123412341234', Date_Of_Birth__c = Date.newInstance(1990, 1, 1),
                                  AccountId = acc.Id);
        insert con;

        // Create an Opportunity
        Opportunity opp = new Opportunity(Name = 'Test Opportunity',
                                          StageName = 'Prospecting', CloseDate = Date.today(),
                                          AccountId = acc.Id, Contact__c = con.Id,
                                          Sale_Value_Amount__c = 100000);
        insert opp;

        // Create an OpportunityContactRole
        OpportunityContactRole oppConRole = new OpportunityContactRole(OpportunityId = opp.Id, ContactId = con.Id, Role = 'Decision Maker', IsPrimary = true);
        insert oppConRole;
    }

    @isTest
    static void testControllerMethods() {
        Test.startTest();
        
        // Simulate Visualforce page request with Opportunity Id
        ApexPages.StandardController stdController = new ApexPages.StandardController([SELECT Id FROM Opportunity LIMIT 1]);
        IdbiJuSbiAosController controller = new IdbiJuSbiAosController(stdController);

        Test.stopTest();
    }
}