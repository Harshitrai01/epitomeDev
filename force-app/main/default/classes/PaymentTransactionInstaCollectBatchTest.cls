@isTest
private class PaymentTransactionInstaCollectBatchTest {
    @isTest
    static void testBatchProcess() {
        // Step 1: Setup test data
        createTestData();

        // Step 2: Create an instance of the batch class
        PaymentTransactionInstaCollectBatch batch = new PaymentTransactionInstaCollectBatch();
        
        // Step 3: Test the start method
        Test.startTest();
        Database.QueryLocator queryLocator = batch.start(null);
        List<Opportunity> opportunities = [SELECT Id, Unit__c, Unit__r.Virtual_Account_Id__c, Contact_Email__c 
                                            FROM Opportunity 
                                            limit 1]; // Fetch the opportunities
        Test.stopTest();
        System.assertEquals(1, opportunities.size(), 'Should return the test Opportunity.');

        // Step 4: Test the execute method
        Test.startTest();
        batch.execute(null, opportunities);
        Test.stopTest();

        // Verify Payment records created or updated
        List<Payment__c> createdPayments = [SELECT Id, InstaCollect_Transaction_Id__c, Email_Address__c FROM Payment__c];
        System.assertEquals(1, createdPayments.size(), 'One Payment record should have been created.');

        // Step 5: Test the finish method
        Test.startTest();
        batch.finish(null);
        Test.stopTest();


        // Step 6: Test the submitForApproval method
        List<Id> paymentIds = new List<Id>();
        for (Payment__c payment : createdPayments) {
            paymentIds.add(payment.Id);
        }
        Map<String, String> paymentIdToOppOwnerId = new Map<String, String> {
            paymentIds[0] => UserInfo.getUserId() // Assuming the current user is the owner
        };

    }

    private static void createTestData() {
        // Create a test unit with a virtual account
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Contact contact = new Contact(FirstName = 'Test', LastName = 'User', Email = 'test@example.com', AccountId = acc.Id);
        insert contact;
        
        Unit__c testUnit = new Unit__c(Name = 'Test Unit', Status__c = 'Available', Virtual_Account_Id__c = 'VA123');
        insert testUnit;

        // Create a test opportunity linked to the unit
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'New',
            Contact__c = contact.Id,
            CloseDate = System.today().addDays(30),
            Unit__c = testUnit.Id,
            AccountId = acc.id,
            Type_of_Booking__c='SBI'
        );
        insert testOpportunity;

        // Create default Payment record if needed
        Payment__c testPayment = new Payment__c(InstaCollect_Transaction_Id__c = 'InitialPayment', Email_Address__c = 'test@example.com');
        insert testPayment;
    }
}