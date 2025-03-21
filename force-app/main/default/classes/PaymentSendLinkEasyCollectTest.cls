@isTest
private class PaymentSendLinkEasyCollectTest {
    
    @testSetup
    static void setupTestData() {
        // Create test Contact
        Contact testContact = new Contact(FirstName = 'Test', LastName = 'User', Email = 'test@example.com', Phone = '1234567890');
        insert testContact;
        
        // Create test Opportunity
        Opportunity testOpp = new Opportunity(Name = 'Test Opportunity', StageName = 'Prospecting', CloseDate = Date.today().addDays(10), Contact__c = testContact.Id, First_Booking_Amount__c = 5000);
        insert testOpp;
        
        
    }
    
    @isTest
    static void testBatchExecution() {
        // Fetch test Opportunity
        List<Opportunity> opps = [SELECT Id FROM Opportunity];
        
        Test.startTest();
        PaymentSendLinkEasyCollect batchJob = new PaymentSendLinkEasyCollect(opps);
        Database.executeBatch(batchJob);
        Test.stopTest();
        
    }
    
    @isTest
    static void testBatchWithNoOpportunities() {
        Test.startTest();
        PaymentSendLinkEasyCollect batchJob = new PaymentSendLinkEasyCollect(new List<Opportunity>());
        Database.executeBatch(batchJob);
        Test.stopTest();
       
    }
    
    @isTest
    static void testExceptionHandling() {
        // Create an Opportunity with missing required fields
        Opportunity badOpp = new Opportunity(Name = 'Bad Opportunity', StageName = 'Prospecting', CloseDate = Date.today().addDays(10));
        insert badOpp;
        
        List<Opportunity> opps = [SELECT Id FROM Opportunity WHERE Id = :badOpp.Id];
        
        Test.startTest();
        PaymentSendLinkEasyCollect batchJob = new PaymentSendLinkEasyCollect(opps);
        try {
            Database.executeBatch(batchJob);
        } catch (Exception e) {
            System.debug('Expected Exception: ' + e.getMessage());
        }
        Test.stopTest();
    }
}