@isTest
private class IdbiJuSbiAosControllerTest {
    @testSetup
    static void setupTestData() {
        // Create an Account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        // Create a Contact
        Contact testContact = new Contact(FirstName = 'Test', LastName = 'User',
                                          AccountId = testAccount.Id,
                                          Aadhaar_Card__c = '123456781234',
                                          Date_Of_Birth__c = Date.newInstance(1990, 1, 1));
        insert testContact;
        
        // Create an Opportunity
        Opportunity testOpportunity = new Opportunity(Name = 'Test Opportunity',
                                                      StageName = 'Prospecting',
                                                      CloseDate = Date.today().addMonths(1),
                                                      AccountId = testAccount.Id,
                                                      Contact__c = testContact.id,
                                                      Sale_Value_Amount__c = 100000);
        insert testOpportunity;
        
        // Create an OpportunityContactRole
        OpportunityContactRole oppContactRole = new OpportunityContactRole(OpportunityId = testOpportunity.Id, ContactId = testContact.Id, Role = 'Decision Maker');
        insert oppContactRole;
        
        // Create a Payment record
        Payment__c testPayment = new Payment__c(Opportunity__c = testOpportunity.Id,
                                                 Payment_Amount__c = 25000,
                                                 Approval_Status__c = 'Approved',
                                                 Payment_Created_Date__c = Date.today());
        insert testPayment;
    }
    
    @isTest
    static void testControllerInitialization() {
        Test.startTest();
        // Mock page reference
        PageReference pageRef = new PageReference('/apex/IdbiJuSbiAosPage');
        pageRef.getParameters().put('Id', [SELECT Id FROM Opportunity LIMIT 1].Id);
        Test.setCurrentPage(pageRef);
        
        // Instantiate controller
        ApexPages.StandardController stdController = new ApexPages.StandardController([SELECT Id FROM Opportunity LIMIT 1]);
        IdbiJuSbiAosController controller = new IdbiJuSbiAosController(stdController);
        Test.stopTest();
        
        // Assertions
       }
    
    @isTest
    static void testMaskAadhaarNumber() {
        IdbiJuSbiAosController controller = new IdbiJuSbiAosController(new ApexPages.StandardController(new Opportunity()));
        String maskedAadhaar = controller.maskAadhaarNumber('123456781234');
              controller.convertPlotSizeToSqM(10.8);

    }
    
    @isTest
    static void testCalculateAge() {
        IdbiJuSbiAosController controller = new IdbiJuSbiAosController(new ApexPages.StandardController(new Opportunity()));
        Integer age = controller.calculateAge(Date.newInstance(2000, 1, 1));
    }
}