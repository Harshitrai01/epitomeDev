/*
*********************************************************
Apex Class Name    : IntegrationLogUtility
Created Date       : March 18, 2025
@description       : Utility class to handle integration logging
@author            : Harshit Rai
Modification Log:
Ver   Date         Author            Modification
1.0   03-18-2025   Harshit Rai       Initial Version
*********************************************************
*/

public class IntegrationLogUtility {

    /*
    *********************************************************
    @Method Name    : doLog
    @author         : Harshit Rai
    @description    : Logs integration details including request and response bodies with status codes.
    @param requestBody   : Request data in string format
    @param responseBody  : Response data in string format
    @param statusCode    : HTTP status code from the integration call
    @return         : None
    *********************************************************
    */
    public static void doLog(String requestBody, String responseBody, Integer statusCode) {
        try {
            Integration_Log__c log = new Integration_Log__c();
            log.IsSuccess__c = true; // Marking log as success
            log.Request_Body__c = (requestBody != null) ? requestBody : 'No Request Data';
            log.Response_Body__c = (responseBody != null) ? responseBody : 'No Response Data';
            log.Status_Code__c = (statusCode != null) ? statusCode : null; // Assign status code if available
            insert log;
        } catch (Exception e) {
            System.debug('Error in doLogSuccess(): ' + e.getMessage());
            throw new AuraHandledException('Error in doLogSuccess(): ' + e.getMessage());
        }
    }

    /*
    *********************************************************
    @Method Name    : doLogError
    @author         : Harshit Rai
    @description    : Logs error details including cause, type, message, and stack trace for integration failures.
    @param reqJson            : Request JSON data
    @param resJson            : Response JSON data
    @param getStatusCode      : HTTP status code from the integration call
    @param cause              : Cause of the error
    @param typeName           : Exception type name
    @param getMessage         : Error message string
    @param getStackTraceString: Stack trace details in string format
    @param error              : General error description
    @return                   : None
    *********************************************************
    */
    public static void doLogError(String reqJson, String resJson, Integer getStatusCode, String cause, String typeName, String getMessage, String getStackTraceString, String error){
        try {
            Integration_Log__c log = new Integration_Log__c();
            log.Cause__c = cause != null ? String.valueOf(cause) : '';
            log.Status_Code__c = getStatusCode != null ? getStatusCode : 0;
            log.Request_Body__c = reqJson != null ? reqJson : '';
            log.Response_Body__c = resJson != null ? resJson : '';
            log.Exception_Type__c = typeName != null ? typeName : '';
            log.Error_Message__c = getMessage != null ? getMessage : '';
            log.Stack_Trace__c = getStackTraceString != null ? getStackTraceString : '';
            log.Error__c = error;
            insert log;
        } catch (Exception e) {
            System.debug('Error in doLogError(): ' + e.getMessage());
            throw new AuraHandledException('Error in doLogError(): ' + e.getMessage());
        }
    }
}