@isTest
private class PaymentReceiptControllerTest {
    
    /**
     * @description Test setup method to create test data
     */
    @testSetup
    static void setupTestData() {
        // Create Project
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
    }
    
    /**
     * @description Test InstaCollect payment receipt generation
     */
    @isTest
    static void testInstaCollectPaymentReceipt() {
        // Get created test data
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        Contact contact = [SELECT Id FROM Contact WHERE LastName = 'Contact' LIMIT 1];
        
        // Create Payment record with InstaCollect transaction
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
        
        Test.startTest();
        // Instead of referencing a specific page, use a generic PageReference
        PageReference pageRef = new PageReference('/apex/PaymentReceipt');
        pageRef.getParameters().put('id', payment.Id);
        Test.setCurrentPage(pageRef);
        
        // Initialize the controller
        ApexPages.StandardController stdController = new ApexPages.StandardController(payment);
        PaymentReceiptController controller = new PaymentReceiptController(stdController);
        Test.stopTest();
        
        // Verify the controller properties
        System.assertEquals(String.valueOf(DateTime.now().format('dd-MM-yyyy')), controller.todayDate);
        System.assertEquals('John Doe', controller.customerName);
        System.assertEquals('IC-123456789', controller.referenceId);
        System.assertEquals(String.valueOf(payment.InstaCollect_Transaction_Date_Time__c.format('dd-MM-yyyy')), controller.paymentDate);
        System.assertEquals(payment.Id, controller.paymentRecord.Id);
        System.assertNotEquals(null, controller.rupeesInWord);
    }
    
    /**
     * @description Test Merchant payment receipt generation
     */
    @isTest
    static void testMerchantPaymentReceipt() {
        // Get created test data
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        Contact contact = [SELECT Id FROM Contact WHERE LastName = 'Contact' LIMIT 1];
        
        // Create Payment record with Merchant transaction
        Payment__c payment = new Payment__c(
            Payment_Amount__c = 25000.50,
            Opportunity__c = opp.Id,
            Contact_Name__c = contact.Id,
            Payment_Mode__c = 'Cheque',
            Merchant_Transaction_Id__c = 'MT-987654321',
            Payment_Created_Date__c = Date.today()
        );
        insert payment;
        
        Test.startTest();
        // Instead of referencing a specific page, use a generic PageReference
        PageReference pageRef = new PageReference('/apex/PaymentReceipt');
        pageRef.getParameters().put('id', payment.Id);
        Test.setCurrentPage(pageRef);
        
        // Initialize the controller
        ApexPages.StandardController stdController = new ApexPages.StandardController(payment);
        PaymentReceiptController controller = new PaymentReceiptController(stdController);
        Test.stopTest();
        
        // Verify the controller properties
        System.assertEquals(String.valueOf(DateTime.now().format('dd-MM-yyyy')), controller.todayDate);
        System.assertEquals('Test Contact', controller.customerName);
        System.assertEquals('MT-987654321', controller.referenceId);
        System.assertEquals(String.valueOf(payment.Payment_Created_Date__c.format('dd-MM-yyyy')), controller.paymentDate);
        System.assertEquals(payment.Id, controller.paymentRecord.Id);
        System.assertNotEquals(null, controller.rupeesInWord);
    }
    
    /**
     * @description Test with no payment record found
     */
    @isTest
    static void testNoPaymentRecord() {
        Test.startTest();
        // Instead of referencing a specific page, use a generic PageReference
        PageReference pageRef = new PageReference('/apex/PaymentReceipt');
        pageRef.getParameters().put('id', '001000000000000AAA'); // Invalid ID
        Test.setCurrentPage(pageRef);
        
        // Initialize the controller with a new payment object
        Payment__c emptyPayment = new Payment__c();
        ApexPages.StandardController stdController = new ApexPages.StandardController(emptyPayment);
        PaymentReceiptController controller = new PaymentReceiptController(stdController);
        Test.stopTest();
        
        // Verify the controller properties are not set
        
    }
}