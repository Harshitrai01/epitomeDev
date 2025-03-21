@isTest
private class IntegrationLogUtilityTest {
    @testSetup
    static void setupTestData() {
        // No setup data needed as logs are independent records
    }
    
    @isTest
    static void testDoLog() {
        Test.startTest();
        
        String requestBody = '{"key":"value"}';
        String responseBody = '{"status":"success"}';
        Integer statusCode = 200;
        
        IntegrationLogUtility.doLog(requestBody, responseBody, statusCode);
        
        Test.stopTest();
        
        
    }
   @isTest
static void testDoLogWithException() {
    Test.startTest();
    
    try {
        // Pass data that causes an insert failure (e.g., a too-long string for a text field)
        String longRequestBody = 'A'.repeat(1391000); // Exceeding the field limit (Max 131072 for Long Text)
        String responseBody = 'Test Response';
        Integer statusCode = -70;

        IntegrationLogUtility.doLog(longRequestBody, responseBody, statusCode); // Call method

    } catch (Exception ex) {
        System.debug('Caught expected exception: ' + ex.getMessage());
    }

    Test.stopTest();
}
    
    @isTest
    static void testDoLogError() {
        Test.startTest();
        
        String reqJson = '{"request":"test"}';
        String resJson = '{"response":"error"}';
        Integer statusCode = 500;
        String cause = 'Null Pointer Exception';
        String typeName = 'System.NullPointerException';
        String getMessage = 'Attempt to de-reference a null object';
        String getStackTraceString = 'Class.IntegrationLogUtility.doLogError: line 10, column 1';
        String error = 'Critical';
        
        IntegrationLogUtility.doLogError(reqJson, resJson, statusCode, cause, typeName, getMessage, getStackTraceString, error);
        
        Test.stopTest();
        
       
    }
}