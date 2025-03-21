/**
*********************************************************
Apex Class Name    : LogUtility
Created Date       : March 18, 2025
@description       : Utility class for logging integration data and errors.
                     Uses @future annotation to handle callouts asynchronously.
@author            : Harshit Rai
Modification Log:
Ver   Date         Author                         Modification
1.0   18-03-2025   Harshit Rai                    Initial Version
*********************************************************
*/
public class LogUtility {

    /**
    *********************************************************
    @Method Name    : doLog
    @description    : Logs successful integration request and response data asynchronously.
                      Uses @future(callout=true) for callout support in future methods.
    @param          : requestBody - Request payload as a JSON string.
    @param          : responseBody - Response payload as a JSON string.
    @param          : statusCode - HTTP status code of the integration response.
    @return         : None
    *********************************************************
    */
    @future(callout=true)
    public static void doLog(String requestBody, String responseBody, Integer statusCode) {
        try {
            Integration_Log__c log = new Integration_Log__c();
            log.IsSuccess__c = true;
            log.Request_Body__c = (requestBody != null) ? requestBody : 'No Request Data';
            log.Response_Body__c = (responseBody != null) ? responseBody : 'No Response Data';
            log.Status_Code__c = (statusCode != null) ? statusCode : null;
            
            // Insert log record
            insert log;
        } catch (Exception e) {
            System.debug('Error in doLogSuccess(): ' + e.getMessage());
            throw new AuraHandledException('Error in doLogSuccess(): ' + e.getMessage());
        }
    }

    /**
    *********************************************************
    @Method Name    : doLogError
    @description    : Logs integration errors asynchronously with detailed information.
                      Uses @future(callout=true) for callout support in future methods.
    @param          : reqJson - Request payload as a JSON string.
    @param          : resJson - Response payload as a JSON string.
    @param          : getStatusCode - HTTP status code of the response.
    @param          : cause - Root cause of the error.
    @param          : typeName - Exception type name.
    @param          : getMessage - Exception message.
    @param          : getStackTraceString - Stack trace details.
    @param          : error - Custom error description.
    @return         : None
    *********************************************************
    */
    @future(callout=true)
    public static void doLogError(
        String reqJson, 
        String resJson, 
        Integer getStatusCode, 
        String cause, 
        String typeName, 
        String getMessage, 
        String getStackTraceString, 
        String error
    ) {
        try {
            system.debug('enter');
            
            // Create Integration Log record
            Integration_Log__c log = new Integration_Log__c();
            log.Cause__c = cause != null ? String.valueOf(cause) : '';
            log.Status_Code__c = getStatusCode != null ? getStatusCode : 0;
            log.Request_Body__c = reqJson != null ? reqJson : '';
            log.Response_Body__c = resJson != null ? resJson : '';
            log.Exception_Type__c = typeName != null ? typeName : '';
            log.Error_Message__c = getMessage != null ? getMessage : '';
            log.Stack_Trace__c = getStackTraceString != null ? getStackTraceString : '';
            log.Error__c = error;

            // Insert log record
            insert log;
        } catch (Exception e) {
            system.debug('enter catch');
            System.debug('Error in doLogError(): ' + e.getMessage());
            throw new AuraHandledException('Error in doLogError(): ' + e.getMessage());
        }
    }
}