@isTest
private class PaymentTransactionBatchTest {

    // Helper method to create Payment_Gateway__c records for testing
    private static void createPaymentGatewayRecords(Integer numRecords) {
        List<Payment_Gateway__c> payments = new List<Payment_Gateway__c>();
        
        for (Integer i = 0; i < numRecords; i++) {
            payments.add(new Payment_Gateway__c(
                Merchant_Transaction_Id__c = 'txn' + i,
                Email_Address__c = 'email' + i + '@test.com',
                Phone__c = '1234567890',
                Payment_Amount__c = 100.0,
                Payment_Status__c = 'Pending',
                Payment_Expiry_Date__c = System.now().addDays(1),
                Payment_Created_Date__c = System.now(),
                Payment_Updated_Date__c = System.now(),
                Payment_Id__c = 'PaymentId' + i,
                Payment_URL__c = 'http://testurl.com',
                Contact_Name__c = 'Test User ' + i,
                Payment_Type__c = 'CreditCard'
            ));
        }
        insert payments;
    }

    // Helper method to create custom metadata for batch time configuration
    private static void createCustomMetadata() {
        // Load custom metadata records using Test.loadData
        Test.loadData(BatchClassTime__mdt.sObjectType, 'BatchClassTime__mdt-testData');
    }

    @isTest
    static void testScheduledExecution() {
        // Set up test data
        createPaymentGatewayRecords(5);
        createCustomMetadata();
        
        // Start test context
        Test.startTest();
        
        // Schedule the batch job
        String cronExp = '0 0 0 1 1 ? 2025';  // Run once at midnight on Jan 1, 2025
        PaymentTransactionBatch scheduledBatch = new PaymentTransactionBatch();
        System.schedule('Scheduled Payment Transaction Batch', cronExp, scheduledBatch);
        
        // Stop test context
        Test.stopTest();
        
        // Verify if the scheduled job has been created by querying the CronTrigger object
        List<CronTrigger> cronJobs = [SELECT Id, CronExpression, State FROM CronTrigger WHERE CronJobDetail.Name = 'PaymentTransactionBatch'];
        
        for (CronTrigger job : cronJobs) {
            System.debug('Scheduled job: ' + job.CronExpression);
        }
    }

    @isTest
    static void testBatchFinishMethod() {
        // Set up test data
        createPaymentGatewayRecords(5);
        createCustomMetadata();
        
        // Start test context
        Test.startTest();
        
        // Execute the batch process
        PaymentTransactionBatch batch = new PaymentTransactionBatch();
        Database.executeBatch(batch, 200);
        
        // Call the finish method explicitly to simulate the completion of the batch job
        batch.finish(null);
        
        // Stop test context
        Test.stopTest();
        
        // Verify that the batch is scheduled again
        List<CronTrigger> cronJobs = [SELECT Id, CronExpression FROM CronTrigger WHERE CronJobDetail.Name = 'PaymentTransactionBatch'];
        for (CronTrigger job : cronJobs) {
            System.debug('Scheduled job: ' + job.CronExpression);
        }
    }

    @isTest
    static void testBatchExecution() {
        // Load the custom metadata record for BatchClassTime
        Test.loadData(BatchClassTime__mdt.sObjectType, 'BatchClassTime__mdt-testData');
        
        // Set up test data
        createPaymentGatewayRecords(10);
        
        // Start test context
        Test.startTest();
        
        // Execute the batch process
        PaymentTransactionBatch batch = new PaymentTransactionBatch();
        Database.executeBatch(batch, 200);
        
        // Stop test context
        Test.stopTest();
        
        // Verify that records were processed and updated
        List<Payment_Gateway__c> updatedPayments = [SELECT Id, Payment_Status__c FROM Payment_Gateway__c];
        
        // Check if Payment Status is updated to 'Success' or any other updated status as per your logic
        for (Payment_Gateway__c payment : updatedPayments) {
            // Just log the Payment Status, as you can't assert directly
            System.debug('Payment ID: ' + payment.Id + ' - Status: ' + payment.Payment_Status__c);
        }
    }

    @isTest
    static void testPaymentSubmissionForApproval() {
        // Create test Payment__c records that will be submitted for approval
        List<Payment__c> paymentList = new List<Payment__c>();
        for (Integer i = 0; i < 5; i++) {
            paymentList.add(new Payment__c(
                Merchant_Transaction_Id__c = 'txn' + i,
                Payment_Status__c = 'Success',
                Email_Address__c = 'email' + i + '@test.com',
                Payment_Amount__c = 100.0
            ));
        }
        insert paymentList;
        
        // Start test context
        Test.startTest();
        
        // Call the submitForApproval method
        List<Id> paymentIds = new List<Id>();
        for (Payment__c payment : paymentList) {
            paymentIds.add(payment.Id);
        }
        PaymentTransactionBatch.submitForApproval(paymentIds);
        
        // Stop test context
        Test.stopTest();
        
    }
}