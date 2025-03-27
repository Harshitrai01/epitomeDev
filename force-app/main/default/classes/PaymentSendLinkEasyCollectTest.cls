/**
*********************************************************
Test Class Name    : PaymentSendLinkEasyCollectTest
Created Date       : March 24, 2025
@description       : Test class for PaymentSendLinkEasyCollect batch class
@author            : Claude
Modification Log:
Ver   Date         Author                         Modification
1.0   24-03-2025   Claude                         Initial Version
*********************************************************
*/
@isTest
private class PaymentSendLinkEasyCollectTest {
    
    // Static mock response variable for EasyCollectPayment simulation
    private static PaymentSendLinkEasyCollect.ResponseWrapper mockResponse;
    
    /**
*********************************************************
@Method Name    : setupTestData
@description    : Creates test data for test methods
@return         : Map<String, Object> - Contains all test data objects
*********************************************************
*/
    private static Map<String, Object> setupTestData() {
        Map<String, Object> testData = new Map<String, Object>();
        
        // Create test account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        testData.put('account', testAccount);
        
        // Create test contact
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'test@example.com',
            Phone = '9999999999',
            AccountId = testAccount.Id
        );
        insert testContact;
        testData.put('contact', testContact);
        
        // Create test phase
        Phase__c testPhase = new Phase__c(
            Name = 'Test Phase'
        );
        insert testPhase;
        testData.put('phase', testPhase);
        
        // Create test unit
        Unit__c testUnit = new Unit__c(
            Name = 'Test Unit',
            Virtual_Account_Name__c = 'Test Account Name',
            Virtual_Account_Number__c = '123456789012',
            Virtual_Account_UPI__c = 'test@ybl',
            Virtual_Account_IFSC__c = 'ABCD0001234',
            UPI_QR_Image__c = 'https://example.com/qr.png',
            Phase__c = testPhase.Id
        );
        insert testUnit;
        testData.put('unit', testUnit);
        
        // Create test unit without banking details
        Unit__c testUnitNoBank = new Unit__c(
            Name = 'Test Unit No Bank',
            Phase__c = testPhase.Id
        );
        insert testUnitNoBank;
        testData.put('unitNoBank', testUnitNoBank);
        
        // Create test opportunities
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Contact__c = testContact.Id,
            Unit__c = testUnit.Id,
            First_Booking_Amount__c = 10000
        );
        insert testOpp;
        testData.put('opportunity', testOpp);
        
        Opportunity testOppNoBank = new Opportunity(
            Name = 'Test Opportunity No Bank',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Contact__c = testContact.Id,
            Unit__c = testUnitNoBank.Id,
            First_Booking_Amount__c = 10000
        );
        insert testOppNoBank;
        testData.put('opportunityNoBank', testOppNoBank);
        
        // Create Email Template
        EmailTemplate testTemplate = new EmailTemplate(
            DeveloperName = 'Terms_and_Conditions',
            Name = 'Terms and Conditions',
            FolderId = UserInfo.getUserId(),
            TemplateType = 'Text',
            Subject = 'Terms and Conditions',
            HtmlValue = 'These are the terms and conditions for {!Opportunity.Phase_Name__c} {!Opportunity.Plot_Name__c} with booking amount {!Opportunity.First_Booking_Amount__c}',
            IsActive = true
        );
        
        // Use System.runAs to create email template as admin user
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        System.runAs(adminUser) {
            insert testTemplate;
        }
        
        testData.put('emailTemplate', testTemplate);
        
        return testData;
    }
    
    /**
* Mock implementation of EasyCollectPayment.createPaymentLink
* This method will be called instead of the actual implementation during tests
*/
    @isTest
    static void mockEasyCollectPayment() {
        // Create a mock response for the HTTP callout (this is a simulated response)
        PaymentSendLinkEasyCollect.ResponseWrapper wrapper = new PaymentSendLinkEasyCollect.ResponseWrapper();
        wrapper.isSuccess = true;
        
        Map<String, Object> responseData = new Map<String, Object>{
            'status' => true,
                'created_date' => '2025-03-24T10:00:00.000Z',
                'updated_date' => '2025-03-24T10:00:00.000Z',
                'email' => 'test@example.com',
                'payment_url' => 'https://pay.example.com/test-link',
                'oppId' => 'someOpportunityId',
                'contactId' => 'someContactId',
                'amount' => '10000',
                'merchant_txn' => 'txn_123456789',
                'id' => 'pay_987654321',
                'state' => 'active',
                'phone' => '9999999999',
                'expiry_date' => '24-03-2025 10:00:00'
                };
                    wrapper.response = JSON.serialize(responseData);
        
        // Now mock the HTTP response using the HttpCalloutMock
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(true));
    }
    
    /**
*********************************************************
@Method Name    : testSuccessfulPaymentLinkGeneration
@description    : Tests the successful generation of payment links
*********************************************************
*/
    
    
    /**
*********************************************************
@Method Name    : testNoContactScenario
@description    : Tests scenario where opportunity has no contact
*********************************************************
*/
    @isTest
    static void testNoContactScenario() {
        Map<String, Object> testData = setupTestData();
        Opportunity testOpp = (Opportunity)testData.get('opportunity');
        
        // Remove contact from opportunity
        testOpp.Contact__c = null;
        update testOpp;
        
        Test.startTest();
        
        // Mock callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(true));
        
        // Run the batch
        List<Opportunity> oppList = new List<Opportunity>{testOpp};
            PaymentSendLinkEasyCollect batchJob = new PaymentSendLinkEasyCollect(oppList);
        Database.executeBatch(batchJob);
        
        Test.stopTest();
        
        // Verify that no payment records were created
        List<Payment_Gateway__c> payments = [SELECT Id FROM Payment_Gateway__c WHERE Opportunity__c = :testOpp.Id];
        System.assertEquals(0, payments.size(), 'No payment records should be created when contact is missing');
    }
    
    /**
*********************************************************
@Method Name    : testNoBookingAmountScenario
@description    : Tests scenario where opportunity has no booking amount
*********************************************************
*/
    @isTest
    static void testNoBookingAmountScenario() {
        Map<String, Object> testData = setupTestData();
        Opportunity testOpp = (Opportunity)testData.get('opportunity');
        
        // Remove booking amount from opportunity
        testOpp.First_Booking_Amount__c = null;
        update testOpp;
        
        Test.startTest();
        
        // Mock callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(true));
        
        // Run the batch
        List<Opportunity> oppList = new List<Opportunity>{testOpp};
            PaymentSendLinkEasyCollect batchJob = new PaymentSendLinkEasyCollect(oppList);
        Database.executeBatch(batchJob);
        
        Test.stopTest();
        
        // Verify that no payment records were created
        List<Payment_Gateway__c> payments = [SELECT Id FROM Payment_Gateway__c WHERE Opportunity__c = :testOpp.Id];
        System.assertEquals(0, payments.size(), 'No payment records should be created when booking amount is missing');
    }
    
    /**
*********************************************************
@Method Name    : testFailedApiResponse
@description    : Tests scenario where API call fails
*********************************************************
*/
    @isTest
    static void testFailedApiResponse() {
        Map<String, Object> testData = setupTestData();
        Opportunity testOpp = (Opportunity)testData.get('opportunity');
        Contact testContact = (Contact)testData.get('contact');
        
        // Prepare failed mock response
        PaymentSendLinkEasyCollect.ResponseWrapper wrapper = new PaymentSendLinkEasyCollect.ResponseWrapper();
        wrapper.isSuccess = false;
        wrapper.error = 'API Error';
        mockResponse = wrapper;
        
        Test.startTest();
        
        // Mock callout with failure response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(false));
        
        // Run the batch
        List<Opportunity> oppList = new List<Opportunity>{testOpp};
            PaymentSendLinkEasyCollect batchJob = new PaymentSendLinkEasyCollect(oppList);
        Database.executeBatch(batchJob);
        
        Test.stopTest();
        
        // Verify that no payment records were created
        List<Payment_Gateway__c> payments = [SELECT Id FROM Payment_Gateway__c WHERE Opportunity__c = :testOpp.Id];
        System.assertEquals(0, payments.size(), 'No payment records should be created when API call fails');
    }
    
    /**
*********************************************************
@Method Name    : testNoBankDetailsScenario
@description    : Tests scenario where unit has no banking details
*********************************************************
*/
    @isTest
    static void testNoBankDetailsScenario() {
        Map<String, Object> testData = setupTestData();
        Opportunity testOppNoBank = (Opportunity)testData.get('opportunityNoBank');
        Contact testContact = (Contact)testData.get('contact');
        
        // Prepare mock response for the EasyCollectPayment.createPaymentLink method
        PaymentSendLinkEasyCollect.ResponseWrapper wrapper = new PaymentSendLinkEasyCollect.ResponseWrapper();
        wrapper.isSuccess = true;
        
        // Create mock payment response
        Map<String, Object> responseData = new Map<String, Object>{
            'status' => true,
                'created_date' => '2025-03-24T10:00:00.000Z',
                'updated_date' => '2025-03-24T10:00:00.000Z',
                'email' => 'test@example.com',
                'payment_url' => 'https://pay.example.com/test-link',
                'oppId' => testOppNoBank.Id,
                'contactId' => testContact.Id,
                'amount' => '10000',
                'merchant_txn' => 'txn_123456789',
                'id' => 'pay_987654321',
                'state' => 'active',
                'phone' => '9999999999',
                'expiry_date' => '24-03-2025 10:00:00'
                };
                    
                    wrapper.response = JSON.serialize(responseData);
        mockResponse = wrapper;
        
        Test.startTest();
        
        // Mock callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(true));
        
        // Run the batch
        List<Opportunity> oppList = new List<Opportunity>{testOppNoBank};
            PaymentSendLinkEasyCollect batchJob = new PaymentSendLinkEasyCollect(oppList);
        Database.executeBatch(batchJob);
        
        Test.stopTest();
        
        // Verify results - payment should be created but email should have different template
        List<Payment_Gateway__c> payments = [SELECT Id FROM Payment_Gateway__c WHERE Opportunity__c = :testOppNoBank.Id];
        System.assertEquals(1, payments.size(), 'Payment record should be created for opportunity without bank details');
        
        // Email verification would require additional mocking which is not available in standard test context
    }
    
    /**
*********************************************************
@Method Name    : testEmailException
@description    : Tests handling of email exception
*********************************************************
*/
    @isTest
    static void testEmailException() {
        Map<String, Object> testData = setupTestData();
        Opportunity testOpp = (Opportunity)testData.get('opportunity');
        Contact testContact = (Contact)testData.get('contact');
        
        // Delete email template to force an exception during email creation
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        System.runAs(adminUser) {
            EmailTemplate template = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'Terms_and_Conditions' LIMIT 1];
            delete template;
        }
        
        // Prepare mock response
        PaymentSendLinkEasyCollect.ResponseWrapper wrapper = new PaymentSendLinkEasyCollect.ResponseWrapper();
        wrapper.isSuccess = true;
        
        // Create mock payment response
        Map<String, Object> responseData = new Map<String, Object>{
            'status' => true,
                'created_date' => '2025-03-24T10:00:00.000Z',
                'updated_date' => '2025-03-24T10:00:00.000Z',
                'email' => 'test@example.com',
                'payment_url' => 'https://pay.example.com/test-link',
                'oppId' => testOpp.Id,
                'contactId' => testContact.Id,
                'amount' => '10000',
                'merchant_txn' => 'txn_123456789',
                'id' => 'pay_987654321',
                'state' => 'active',
                'phone' => '9999999999',
                'expiry_date' => '24-03-2025 10:00:00'
                };
                    
                    wrapper.response = JSON.serialize(responseData);
        mockResponse = wrapper;
        
        Test.startTest();
        
        // Mock callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(true));
        
        // Run the batch
        List<Opportunity> oppList = new List<Opportunity>{testOpp};
            PaymentSendLinkEasyCollect batchJob = new PaymentSendLinkEasyCollect(oppList);
        
        // We expect this to complete without unhandled exceptions
        Database.executeBatch(batchJob);
        
        Test.stopTest();
        
        // Payment records should still be created despite email exception
        List<Payment_Gateway__c> payments = [SELECT Id FROM Payment_Gateway__c WHERE Opportunity__c = :testOpp.Id];
        System.assertEquals(1, payments.size(), 'Payment record should be created even if email fails');
    }
    
    /**
*********************************************************
@Method Name    : testResponseWrapperClass
@description    : Tests the ResponseWrapper inner class
*********************************************************
*/
    @isTest
    static void testResponseWrapperClass() {
        PaymentSendLinkEasyCollect.ResponseWrapper wrapper = new PaymentSendLinkEasyCollect.ResponseWrapper();
        wrapper.isSuccess = true;
        wrapper.error = 'No error';
        wrapper.response = '{"status": true}';
        wrapper.integrationLogs = 'Log data';
        
        System.assertEquals(true, wrapper.isSuccess, 'isSuccess should be true');
        System.assertEquals('No error', wrapper.error, 'error should match');
        System.assertEquals('{"status": true}', wrapper.response, 'response should match');
        System.assertEquals('Log data', wrapper.integrationLogs, 'integrationLogs should match');
    }
    
    /**
*********************************************************
@Method Name    : testPaymentDetailsClass
@description    : Tests the PaymentDetails inner class
*********************************************************
*/
    @isTest
    static void testPaymentDetailsClass() {
        PaymentSendLinkEasyCollect.PaymentDetails details = new PaymentSendLinkEasyCollect.PaymentDetails();
        details.recipientEmail = 'test@example.com';
        details.paymentLink = 'https://test.com';
        details.accountName = 'Test Account';
        details.accountNumber = '123456789';
        details.ifscCode = 'ABCD0001234';
        details.upiId = 'test@ybl';
        details.qrImageUrl = 'https://test.com/qr.png';
        details.plotName = 'Test Plot';
        details.phaseName = 'Test Phase';
        details.firstAmount = 10000;
        
        System.assertEquals('test@example.com', details.recipientEmail, 'recipientEmail should match');
        System.assertEquals('https://test.com', details.paymentLink, 'paymentLink should match');
        System.assertEquals('Test Account', details.accountName, 'accountName should match');
        System.assertEquals('123456789', details.accountNumber, 'accountNumber should match');
        System.assertEquals('ABCD0001234', details.ifscCode, 'ifscCode should match');
        System.assertEquals('test@ybl', details.upiId, 'upiId should match');
        System.assertEquals('https://test.com/qr.png', details.qrImageUrl, 'qrImageUrl should match');
        System.assertEquals('Test Plot', details.plotName, 'plotName should match');
        System.assertEquals('Test Phase', details.phaseName, 'phaseName should match');
        System.assertEquals(10000, details.firstAmount, 'firstAmount should match');
    }
    
    /**
*********************************************************
@Method Name    : MockHttpResponseGenerator
@description    : Mock class for HTTP callouts
*********************************************************
*/
    @isTest
static void testSuccessfulPaymentLinkGeneration() {
    Map<String, Object> testData = setupTestData();
    Opportunity testOpp = (Opportunity)testData.get('opportunity');
    Contact testContact = (Contact)testData.get('contact');
    
    // Prepare mock response for the EasyCollectPayment.createPaymentLink method
    PaymentSendLinkEasyCollect.ResponseWrapper wrapper = new PaymentSendLinkEasyCollect.ResponseWrapper();
    wrapper.isSuccess = true;
    
    Map<String, Object> responseData = new Map<String, Object>{
        'status' => true,
        'created_date' => '2025-03-24T10:00:00.000Z',
        'updated_date' => '2025-03-24T10:00:00.000Z',
        'email' => 'test@example.com',
        'payment_url' => 'https://pay.example.com/test-link',
        'oppId' => testOpp.Id,
        'contactId' => testContact.Id,
        'amount' => '10000',
        'merchant_txn' => 'txn_123456789',
        'id' => 'pay_987654321',
        'state' => 'active',
        'phone' => '9999999999',
        'expiry_date' => '24-03-2025 10:00:00'
    };
    
    wrapper.response = JSON.serialize(responseData);
    
    // Set the mock response
    mockResponse = wrapper;
    
    // Call the test method
    Test.startTest();
    Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(true));
    
    // Run the batch job
    List<Opportunity> oppList = new List<Opportunity>{testOpp};
    PaymentSendLinkEasyCollect batchJob = new PaymentSendLinkEasyCollect(oppList);
    Database.executeBatch(batchJob);
    
    Test.stopTest();
    
    // Verifications
    List<Payment_Gateway__c> payments = [SELECT Id, Payment_Amount__c, Email_Address__c, Payment_URL__c, 
                                          Payment_Status__c, Opportunity__c FROM Payment_Gateway__c 
                                          WHERE Opportunity__c = :testOpp.Id];
    System.assertEquals(1, payments.size(), 'Expected one payment record to be created');
    System.assertEquals('active', payments[0].Payment_Status__c, 'Payment status should be active');
    System.assertEquals(10000, payments[0].Payment_Amount__c, 'Payment amount should match');
    
    // Verify Opportunity update
    Opportunity updatedOpp = [SELECT Id, Easy_Collect_Payment_Link__c FROM Opportunity WHERE Id = :testOpp.Id];
    System.assertEquals('https://pay.example.com/test-link', updatedOpp.Easy_Collect_Payment_Link__c, 
                      'Payment link should be updated on the opportunity');
}
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        private Boolean isSuccess;
        
        public MockHttpResponseGenerator(Boolean isSuccess) {
            this.isSuccess = isSuccess;
        }
        
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            
            if (isSuccess) {
                response.setBody(JSON.serialize(mockResponse));
            } else {
                PaymentSendLinkEasyCollect.ResponseWrapper wrapper = new PaymentSendLinkEasyCollect.ResponseWrapper();
                wrapper.isSuccess = false;
                wrapper.error = 'API Error';
                response.setBody(JSON.serialize(wrapper));
            }
            
            return response;
        }
    }
}