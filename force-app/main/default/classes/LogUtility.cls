public class LogUtility {
    @future(callout=true)
    public static void doLog(String requestBody, String responseBody, Integer statusCode) {
        try {
            Integration_Log__c log = new Integration_Log__c();
            log.IsSuccess__c = true;
            log.Request_Body__c = (requestBody != null) ? requestBody : 'No Request Data';
            log.Response_Body__c = (responseBody != null) ? responseBody : 'No Response Data';
            log.Status_Code__c = (statusCode != null) ? statusCode : null;
            insert log;
        } catch (Exception e) {
            System.debug('Error in doLogSuccess(): ' + e.getMessage());
            throw new AuraHandledException('Error in doLogSuccess(): ' + e.getMessage());
        }
    }
    
    @future(callout=true)
    public static void doLogError(String reqJson, String resJson, Integer getStatusCode, String cause, String typeName, String getMessage, String getStackTraceString, String error){
        try{
            system.debug('enter');
            Integration_Log__c log = new Integration_Log__c();
            log.Cause__c = cause!=null?String.valueOf(cause):'';
            log.Status_Code__c = getStatusCode !=null ? getStatusCode:0;
            log.Request_Body__c = reqJson !=null ? reqJson:'';
            log.Response_Body__c = resJson!=null ? resJson:'';
            log.Exception_Type__c = typeName!=null ? typeName:'';
            log.Error_Message__c = getMessage !=null ? getMessage:'';
            log.Stack_Trace__c = getStackTraceString !=null ? getStackTraceString:'';
            log.Error__c=error;
            insert log;
        }catch (Exception e){
             system.debug('enter catch');
            System.debug('Error in doLogError(): ' + e.getMessage());
            throw new AuraHandledException('Error in doLogError(): ' + e.getMessage());
        }
    }
}