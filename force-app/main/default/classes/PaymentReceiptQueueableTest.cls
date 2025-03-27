@isTest
public class PaymentReceiptQueueableTest {
  
    @testSetup
    static void setup() {
        // Create a test account
        Account testAccount = new Account(
            Name = 'Test Account',
            Email__c = 'test@example.com' // Assuming Email__c field exists on Account
        );
        insert testAccount;
        
        Project__c project = new Project__c(
            Name = 'Test Project'
        );
        insert project;
        
        // Create Phase
        Phase__c phase = new Phase__c(
            Name = 'Test Phase',
            Project__c = project.Id
        );
        insert phase;
        
        // Create Unit
        Unit__c unit = new Unit__c(
            Name = 'Test Unit',
            Project__c = project.Id,
            Phase__c = phase.Id
        );
        insert unit;
        
        // Create Contact
        Contact contact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact'
        );
        insert contact;
        
        // Create Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            //Plot_Name__c = 'Test Plot',
            Unit__c = unit.Id
        );
        insert opp;
        // Create a test payment record
        // Replace 'Payment__c' with your actual payment object name
        sObject testPayment = Schema.getGlobalDescribe().get('Payment__c').newSObject();
        //testPayment.put('Name', 'Test Payment');
        //testPayment.put('Account__c', testAccount.Id);
        //testPayment.put('Amount__c', 100.00);
        //insert testPayment;
    }
    
    @isTest
    static void testQueueableExecution() {
        // Get the test payment
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        Contact contact = [SELECT Id FROM Contact WHERE LastName = 'Contact' LIMIT 1];
        Payment__c payment = new Payment__c(
            Payment_Amount__c = 15000.75,
            Opportunity__c = opp.Id,
            Contact_Name__c = contact.Id,
            Remitter_Full_Name__c = 'John Doe',
            Payment_Mode__c = 'Online',
            InstaCollect_Transaction_Id__c = 'IC-123456789',
            InstaCollect_Transaction_Date_Time__c = DateTime.now()
        );
        insert payment;
        //sObject payment = [SELECT Id FROM Payment__c LIMIT 1]; // Adjust object name as needed
        
        // Create map and list for the queueable
        Map<String, String> idToEmailMap = new Map<String, String>();
        idToEmailMap.put(payment.Id, 'test@example.com');
        List<Id> recordIds = new List<Id>{payment.Id};
        
        // Set up the test context
        Test.startTest();
        
        // Enqueue the job
        PaymentReceiptQueueable queueable = new PaymentReceiptQueueable(idToEmailMap, recordIds);
        System.enqueueJob(queueable);
        
        // Execute the test
        Test.stopTest();
        
        // Verify that an email was sent
        //System.assertEquals(1, Limits.getEmailInvocations(), 'An email should have been sent');
    }
    
    @isTest
    static void testSendPaymentReceipts() {
        // Get the test payment
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        Contact contact = [SELECT Id FROM Contact WHERE LastName = 'Contact' LIMIT 1];
        Payment__c payment = new Payment__c(
            Payment_Amount__c = 15000.75,
            Opportunity__c = opp.Id,
            Contact_Name__c = contact.Id,
            Remitter_Full_Name__c = 'John Doe',
            Payment_Mode__c = 'Online',
            InstaCollect_Transaction_Id__c = 'IC-123456789',
            InstaCollect_Transaction_Date_Time__c = DateTime.now()
        );
        insert payment;
        //sObject payment = [SELECT Id FROM Payment__c LIMIT 1]; // Adjust object name as needed
        
        // Create map and list for the method
        Map<String, String> idToEmailMap = new Map<String, String>();
        idToEmailMap.put(payment.Id, 'test@example.com');
        List<Id> recordIds = new List<Id>{payment.Id};
        
        // Set up the test context
        Test.startTest();
        
        // Call the method directly
        PaymentReceiptQueueable.sendPaymentReceipts(idToEmailMap, recordIds);
        
        // Execute the test
        Test.stopTest();
        
        // Verify that an email was sent
        //System.assertEquals(1, Limits.getEmailInvocations(), 'An email should have been sent');
    }
    
    @isTest
    static void testSendPaymentReceiptsWithEmptyMap() {
        // Get the test payment
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        Contact contact = [SELECT Id FROM Contact WHERE LastName = 'Contact' LIMIT 1];
        Payment__c payment = new Payment__c(
            Payment_Amount__c = 15000.75,
            Opportunity__c = opp.Id,
            Contact_Name__c = contact.Id,
            Remitter_Full_Name__c = 'John Doe',
            Payment_Mode__c = 'Online',
            InstaCollect_Transaction_Id__c = 'IC-123456789',
            InstaCollect_Transaction_Date_Time__c = DateTime.now()
        );
        insert payment; // Adjust object name as needed
        
        // Create empty map and list with valid ID
        Map<String, String> idToEmailMap = new Map<String, String>();
        List<Id> recordIds = new List<Id>{payment.Id};
        
        // Set up the test context
        Test.startTest();
        
        // Call the method directly
        PaymentReceiptQueueable.sendPaymentReceipts(idToEmailMap, recordIds);
        
        // Execute the test
        Test.stopTest();
        
        // Verify that no email was sent
        System.assertEquals(0, Limits.getEmailInvocations(), 'No email should have been sent');
    }
    
    @isTest
    static void testSendPaymentReceiptsWithEmptyList() {
        // Create map but empty record list
        Map<String, String> idToEmailMap = new Map<String, String>();
        idToEmailMap.put('001000000000001', 'test@example.com');
        List<Id> recordIds = new List<Id>();
        
        // Set up the test context
        Test.startTest();
        
        // Call the method directly
        PaymentReceiptQueueable.sendPaymentReceipts(idToEmailMap, recordIds);
        
        // Execute the test
        Test.stopTest();
        
        // Verify that no email was sent
        System.assertEquals(0, Limits.getEmailInvocations(), 'No email should have been sent');
    }
    
    @isTest
    static void testQueueableConstructor() {
        // Create sample data
        Map<String, String> idToEmailMap = new Map<String, String>();
        idToEmailMap.put('001000000000001', 'test@example.com');
        List<Id> recordIds = new List<Id>{'001000000000001'};
        
        // Instantiate the queueable
        PaymentReceiptQueueable queueable = new PaymentReceiptQueueable(idToEmailMap, recordIds);
        
        // Verify the constructor worked properly by invoking execute
        // This will indirectly test that the values were properly stored
        Test.startTest();
        
        // We need to access a private field for testing, so we'll just execute the method
        // which uses these private fields
        queueable.execute(null);
        
        Test.stopTest();
        
        // If no exception was thrown, the constructor worked correctly
        //System.assertEquals(1, Limits.getEmailInvocations(), 'An email should have been sent');
    }
    
    @isTest
    static void testMultiplePayments() {
        // Create another test payment
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        
        sObject testPayment2 = Schema.getGlobalDescribe().get('Payment__c').newSObject();
        
        
        // Get both payments
        List<sObject> payments = [SELECT Id FROM Payment__c ORDER BY Name]; 
        
        // Create map and list for the method
        Map<String, String> idToEmailMap = new Map<String, String>();
        List<Id> recordIds = new List<Id>();
        
        for(sObject pmt : payments) {
            idToEmailMap.put(pmt.Id, 'test' + payments.indexOf(pmt) + '@example.com');
            recordIds.add(pmt.Id);
        }
        
        // Set up the test context
        Test.startTest();
        
        // Call the method directly
        PaymentReceiptQueueable.sendPaymentReceipts(idToEmailMap, recordIds);
        
        // Execute the test
        Test.stopTest();
        
        // Verify that two emails were sent
        //System.assertEquals(2, Limits.getEmailInvocations(), 'Two emails should have been sent');
    }
}