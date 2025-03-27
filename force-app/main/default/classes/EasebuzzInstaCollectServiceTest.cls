@isTest
public class EasebuzzInstaCollectServiceTest {
    
    static void setupMockIntegration() {
        // Simulating the configuration variables directly without multiple test contexts
        EasebuzzInstaCollectService.API_URL = 'https://api.easebuzz.in/createVA';
        EasebuzzInstaCollectService.RETRIEVE_URL = 'https://api.easebuzz.in/retrieveTransactions';
        EasebuzzInstaCollectService.MERCHANT_KEY = 'testKey';
        EasebuzzInstaCollectService.MERCHANT_SALT = 'testSalt';
    }

    @isTest
    static void testCreateVirtualAccount() {
        setupMockIntegration();
        
        // Mock HTTP response for success
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setStatusCode(200);
        mockResponse.setBody('{"success": true, "data": {"virtual_account": {"id": "VA123", "virtual_account_number": "1234567890", "virtual_upi_handle": "test@upi", "virtual_ifsc_number": "IFSCTEST", "upi_qrcode_remote_file_location": "http://test.com/qr.png", "upi_qrcode_scanner_remote_file_location": "http://test.com/qrcode.pdf"}, "unique_request_number": "REQ123"}}');
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));
        
        // Call the method to test
        Test.startTest();
        String plotId = 'TestPlotId';
        EasebuzzInstaCollectService.VirtualAccountDetailWrapper result = EasebuzzInstaCollectService.createVirtualAccount(plotId);
        Test.stopTest();
        
        // Assert results
        System.assertNotEquals(null, result);
        System.assertEquals('TestPlotId', result.plotId);
        Map<String, Object> virtualAccountDetails = (Map<String, Object>) JSON.deserializeUntyped(result.jsonData);
        System.assertEquals('VA123', virtualAccountDetails.get('id'));
    }

    @isTest
    static void testUpdateVirtualAccountDetailsOnPlot() {
        setupMockIntegration();

        // Prepare test data
        Phase__c phase = new Phase__c(
        	Name = 'Test Phase'
        );
        insert phase;
        // Prepare test data
        Unit__c plot = new Unit__c(
            Name = 'Test Plot',
            Phase__c = phase.id
        );
        insert plot;

        // Mock JSON data for update
        String jsonData = '{"id": "VA123", "virtual_account_number": "1234567890", "virtual_upi_handle": "test@upi", "virtual_ifsc_number": "IFSCTEST", "upi_qrcode_remote_file_location": "http://test.com/qr.png", "upi_qrcode_scanner_remote_file_location": "http://test.com/qrcode.pdf", "unique_request_number": "REQ123"}';
        
        // Start a test context for the update method
        Test.startTest();
        EasebuzzInstaCollectService.updateVirtualAccountDetailsOnPlot(plot.Id, jsonData);
        Test.stopTest();

        // Verify the Unit__c object was updated
        plot = [SELECT Id, Virtual_Account_Number__c, Virtual_Account_Id__c FROM Unit__c WHERE Id = :plot.Id LIMIT 1];
        System.assertEquals('1234567890', plot.Virtual_Account_Number__c);
        System.assertEquals('VA123', plot.Virtual_Account_Id__c);
    }

    @isTest
    static void testRetrieveTransactionsList() {
        setupMockIntegration();

        // Mock HTTP response for transaction retrieval
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setStatusCode(200);
        mockResponse.setBody('{"success": true, "data": {"transactions": []}}');
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));

        // Call the retrieve method inside a test context
        Test.startTest();
        String result = EasebuzzInstaCollectService.retrieveTransactionsList('VA123');
        Test.stopTest();

    }

    @isTest
    static void testErrorHandlingCreateVirtualAccount() {
        setupMockIntegration();

        // Mock HTTP response for error scenario
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setStatusCode(400);
        mockResponse.setBody('{"success": false, "message": "Bad Request"}');
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));

        // Call the createVirtualAccount method in a test context
        Test.startTest();
        String plotId = 'TestPlotId';
        EasebuzzInstaCollectService.VirtualAccountDetailWrapper result = EasebuzzInstaCollectService.createVirtualAccount(plotId);
        Test.stopTest();

        // Assert that the result is null due to the error
        System.assertEquals(null, result);
    }

    @isTest
    static void testErrorHandlingRetrieveTransactionsList() {
        setupMockIntegration();

        // Mock HTTP response for error scenario
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setStatusCode(500);
        mockResponse.setBody('{"success": false, "message": "Internal Server Error"}');
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));

        // Call the retrieve method in a test context
        Test.startTest();
        String result = EasebuzzInstaCollectService.retrieveTransactionsList('VA123');
        Test.stopTest();

    }

    class MockHttpResponseGenerator implements HttpCalloutMock {
        HttpResponse mockResponse;

        public MockHttpResponseGenerator(HttpResponse response) {
            this.mockResponse = response;
        }

        public HttpResponse respond(HttpRequest request) {
            return mockResponse;
        }
    }
}