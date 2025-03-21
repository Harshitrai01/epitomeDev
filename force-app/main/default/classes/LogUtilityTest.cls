@isTest
public class LogUtilityTest {
    
    @isTest
    static void testDoLog() {
        Test.startTest();
        
        // Call the future method
        LogUtility.doLog('{"request":"test"}', '{"response":"success"}', 200);
        Test.stopTest();
    }
    
    @isTest
    static void testDoLogError() {
        Test.startTest();
        
        // Call the future method
        LogUtility.doLogError(
            '{"request":"errorTest"}',
            '{"response":"error"}',
            500,
            'NullPointerException',
            'System.NullPointerException',
            'Attempt to de-reference a null object',
            'stack trace here',
            'Custom error message'
        );
        Test.stopTest();
    }
    

}