/*
*********************************************************
Apex Class Name    : EasebuzzInstaCollectService
Created Date       : [Insert Date]
@description       : This class is used to create and manage virtual account details using the Easebuzz API. It handles 
                     the creation of virtual accounts, updates related plot records, and retrieves transaction details.
@author            : Harshit Kumar Rai
Modification Log:
Ver   Date         Author               Modification
1.0   [Insert Date] Harshit Kumar Rai   Initial Version
*********************************************************
*/
public class EasebuzzInstaCollectService {
	public static String API_URL { get; set; }
    public static String RETRIEVE_URL { get; set; }
    public static String MERCHANT_KEY { get; set; }
    public static String MERCHANT_SALT { get; set; }
    /*
    *********************************************************
    @Method Name    : initializeMetadata
    @author         : Harshit Kumar Rai
    @description    : Static initializer to fetch and initialize metadata values for API configuration.
    *********************************************************
    */
    static {
        initializeMetadata();
    }

    private static void initializeMetadata() {
        List<Integration__mdt> integrations = [
            SELECT DeveloperName, InstaCollectKey__c, InstaCollectSalt__c,
                   Easebuzz_Instacollect_Create_VA__c, InstaCollect_Retrieve_Transaction_URL__c
            FROM Integration__mdt 
            WHERE DeveloperName = 'testDashboard' 
            LIMIT 1
        ];
        if (!integrations.isEmpty()) {
            Integration__mdt integration = integrations[0];
            MERCHANT_KEY = integration.InstaCollectKey__c;
            MERCHANT_SALT = integration.InstaCollectSalt__c;
            API_URL = integration.Easebuzz_Instacollect_Create_VA__c;
            RETRIEVE_URL = integration.InstaCollect_Retrieve_Transaction_URL__c;
        }
    }

    /*
    *********************************************************
    @Method Name    : createVirtualAccount
    @author         : Harshit Kumar Rai
    @description    : Creates a virtual account using the Easebuzz API and updates the related plot record with the 
                       virtual account details.
    @param          : plotId - The Id of the plot for which the virtual account is created.
    *********************************************************
    */
    
    public static VirtualAccountDetailWrapper createVirtualAccount(String plotId) {
        String label = plotId;
        String error = '';
        String hashInput = MERCHANT_KEY + '|' + label + '|' + MERCHANT_SALT;
        String hash = generateSHA512Hash(hashInput);

        HttpRequest request = new HttpRequest();
        request.setEndpoint(API_URL);
        request.setMethod('POST');
        request.setHeader('Accept', 'application/json');
        request.setHeader('Authorization', hash);
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('WIRE-API-KEY', MERCHANT_KEY);

        Map<String, Object> requestBody = new Map<String, Object>{
            'key' => MERCHANT_KEY,
            'label' => label,
            'unique_request_number' => plotId
        };
        request.setBody(JSON.serialize(requestBody));

        Http http = new Http();
        HttpResponse response;
        try {
            response = http.send(request);
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            if (response.getStatusCode() == 200 || response.getStatusCode() == 201) {
                Boolean status = (Boolean) responseMap.get('success');
                if (status && responseMap.containsKey('data')) {
                    Map<String, Object> data = (Map<String, Object>) responseMap.get('data');
                    if (data.containsKey('virtual_account')) {
                        Map<String, Object> virtualAccount = (Map<String, Object>) data.get('virtual_account');
                        String virtualAccountId = (String) virtualAccount.get('id');
                        VirtualAccountDetailWrapper wrapper = New VirtualAccountDetailWrapper(plotId,JSON.serialize(virtualAccount));
                        return wrapper;
                        //updateVirtualAccountDetailsOnPlot(plotId, JSON.serialize(virtualAccount));
                    }
                }
            } else {
                if (responseMap.containsKey('additional') && ((Map<String, Object>) responseMap.get('additional')).containsKey('validation') && !((List<Object>) ((Map<String, Object>) responseMap.get('additional')).get('validation')).isEmpty()) {
                    Map<String, Object> validationError = (Map<String, Object>) ((List<Object>) ((Map<String, Object>) responseMap.get('additional')).get('validation'))[0];
                    if (validationError.containsKey('message')) {
                        error = (String) validationError.get('message');
                    }
                }
                System.debug('Error: ' + response.getStatusCode() + ' - ' + error);
                IntegrationLogUtility.doLogError(request.getBody(), response.getBody(), response.getStatusCode(), 'Bad Response', 'Future Method', error, 'Response Error: EasebuzzInstaCollectService', error);
            }
        } catch (Exception ex) {
            IntegrationLogUtility.doLogError(request.getBody(), response.getBody(), response.getStatusCode(), 'Bad Response', 'Future Method', error, 'Response Error: EasebuzzInstaCollectService', error);
        }
        return null;
    }

    /*
    *********************************************************
    @Method Name    : updateVirtualAccountDetailsOnPlot
    @author         : Harshit Kumar Rai
    @description    : Updates the plot record with the virtual account details received from the API response.
    @param          : plotId - The Id of the plot to update.
    @param          : jsonData - JSON string containing virtual account details.
    *********************************************************
    */
    public static void updateVirtualAccountDetailsOnPlot(String plotId, String jsonData) {
        try {
            List<Unit__c> plotList = [
                SELECT Id, Name, Phase__r.Name, Virtual_Account_Name__c, Virtual_Account_Number__c,
                       Virtual_Account_Id__c, Virtual_Account_UPI__c, Virtual_Account_IFSC__c,
                       UPI_QR_Image__c, UPI_QR_PDF__c, Unique_Request_Number__c
                FROM Unit__c 
                WHERE Id = :plotId 
                LIMIT 1
            ];

            Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(jsonData);
            if (plotList != null && !plotList.isEmpty()) {
                if (plotList[0]?.Phase__r?.Name != null) {
                    plotList[0].Virtual_Account_Name__c = plotList[0].Name + ' ' + plotList[0]?.Phase__r?.Name;
                }
                plotList[0].Virtual_Account_Number__c = (String) data.get('virtual_account_number');
                plotList[0].Virtual_Account_Id__c = (String) data.get('id');
                plotList[0].Virtual_Account_UPI__c = (String) data.get('virtual_upi_handle');
                plotList[0].Virtual_Account_IFSC__c = (String) data.get('virtual_ifsc_number');
                plotList[0].UPI_QR_Image__c = (String) data.get('upi_qrcode_remote_file_location');
                plotList[0].UPI_QR_PDF__c = (String) data.get('upi_qrcode_scanner_remote_file_location');
                plotList[0].Unique_Request_Number__c = (String) data.get('unique_request_number');
                update plotList;
            }
        } catch (Exception ex) {
            System.debug('Error In Updating Virtual Account Details : ' + ex.getMessage());
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /*
    *********************************************************
    @Method Name    : retrieveTransactionsList
    @author         : Harshit Kumar Rai
    @description    : Retrieves the list of transactions for a given virtual account ID using the Easebuzz API.
    @param          : virtual_account_id - The ID of the virtual account for which transactions are retrieved.
    @return         : String - JSON string containing the response and integration logs.
    *********************************************************
    */
    public static String retrieveTransactionsList(String virtual_account_id) {
        String requestUrl = RETRIEVE_URL + '?key=' + MERCHANT_KEY;
        if (String.isNotEmpty(virtual_account_id)) {
            requestUrl += '&virtual_account_id=' + EncodingUtil.urlEncode(virtual_account_id, 'UTF-8');
        }
        String hashInput = MERCHANT_KEY + '|' + MERCHANT_SALT;
        String hash = generateSHA512Hash(hashInput);

        HttpRequest request = new HttpRequest();
        request.setEndpoint(requestUrl);
        request.setMethod('GET');
        request.setHeader('Accept', 'application/json');
        request.setHeader('Authorization', hash);
        request.setHeader('WIRE-API-KEY', MERCHANT_KEY);

        Http http = new Http();
        HttpResponse response;

        try {
            response = http.send(request);
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            if (response.getStatusCode() == 200 || response.getStatusCode() == 201) {
                Boolean status = false;
                if (responseMap.containsKey('success')) {
                    status = (Boolean) responseMap.get('success');
                }
                if (status) {
                    Integration_Log__c log = new Integration_Log__c();
                    log.IsSuccess__c = true;
                    log.Request_Body__c = (request.getBody() != null) ? request.getBody() : 'No Request Data';
                    log.Response_Body__c = (response.getBody() != null) ? response.getBody() : 'No Response Data';
                    log.Status_Code__c = (response.getStatusCode() != null) ? response.getStatusCode() : null;
                    ResponseWrapper reponseWrap = new ResponseWrapper(true, null, response.getBody());
                    reponseWrap.integrationLogs = JSON.serialize(log);
                    return JSON.serialize(reponseWrap);
                } else {
                    String error = '';
                    if (responseMap.containsKey('message')) {
                        error = (String) responseMap.get('message');
                    }
                    Integration_Log__c log = new Integration_Log__c();
                    log.Cause__c = error != null ? String.valueOf(error) : '';
                    log.Status_Code__c = response.getStatusCode() != null ? response.getStatusCode() : 0;
                    log.Request_Body__c = request.getBody() != null ? request.getBody() : '';
                    log.Response_Body__c = response.getBody() != null ? response.getBody() : '';
                    log.Exception_Type__c = 'Callout Error';
                    log.Error_Message__c = error != null ? error : '';
                    log.Stack_Trace__c = 'EasebuzzInstaCollectService.retrieveTransactions';
                    log.Error__c = error;
                    ResponseWrapper reponseWrap = new ResponseWrapper(false, error, response.getBody());
                    reponseWrap.integrationLogs = JSON.serialize(log);
                    return JSON.serialize(reponseWrap);
                }
            } else {
                String error = '';
                if (responseMap.containsKey('message')) {
                    error = (String) responseMap.get('message');
                }
                Integration_Log__c log = new Integration_Log__c();
                log.Cause__c = error != null ? String.valueOf(error) : '';
                log.Status_Code__c = response.getStatusCode() != null ? response.getStatusCode() : 0;
                log.Request_Body__c = request.getBody() != null ? request.getBody() : '';
                log.Response_Body__c = response.getBody() != null ? response.getBody() : '';
                log.Exception_Type__c = 'Callout Error';
                log.Error_Message__c = error != null ? error : '';
                log.Stack_Trace__c = 'EasebuzzInstaCollectService.retrieveTransactions';
                log.Error__c = error;
                ResponseWrapper reponseWrap = new ResponseWrapper(false, error, response.getBody());
                reponseWrap.integrationLogs = JSON.serialize(log);
                return JSON.serialize(reponseWrap);
            }
        } catch (Exception ex) {
            ResponseWrapper reponseWrap = new ResponseWrapper(false, ex.getMessage(), response.getBody());
            Integration_Log__c log = new Integration_Log__c();
            log.Cause__c = JSON.serialize(ex.getCause());
            log.Status_Code__c = response.getStatusCode() != null ? response.getStatusCode() : 0;
            log.Request_Body__c = request.getBody() != null ? request.getBody() : '';
            log.Response_Body__c = response.getBody() != null ? response.getBody() : '';
            log.Exception_Type__c = JSON.serialize(ex.getTypeName());
            log.Error_Message__c = JSON.serialize(ex.getMessage()) != null ? JSON.serialize(ex.getMessage()) : '';
            log.Stack_Trace__c = JSON.serialize(ex.getStackTraceString());
            log.Error__c = ex.getMessage();
            reponseWrap.integrationLogs = JSON.serialize(log);
            return JSON.serialize(reponseWrap);
        }
    }

    /*
    *********************************************************
    @Method Name    : generateSHA512Hash
    @author         : Harshit Kumar Rai
    @description    : Generates a SHA-512 hash for the given input string.
    @param          : input - The string to hash.
    @return         : String - The hexadecimal representation of the hash.
    *********************************************************
    */
    private static String generateSHA512Hash(String input) {
        Blob inputBlob = Blob.valueOf(input);
        Blob hashBlob = Crypto.generateDigest('SHA-512', inputBlob);
        return EncodingUtil.convertToHex(hashBlob);
    }

    /*
    *********************************************************
    Apex Class Name    : ResponseWrapper
    @description       : Inner class to wrap response details for API calls or Lightning components.
    @author            : Harshit Kumar Rai
    *********************************************************
    */
    public class ResponseWrapper {
        public Boolean isSuccess;
        public String error;
        public String response;
        public String integrationLogs;

        public ResponseWrapper(Boolean isSuccess, String error, String response) {
            this.isSuccess = isSuccess;
            this.error = error;
            this.response = response;
        }
    }
    
    public class VirtualAccountDetailWrapper {
        public String plotId;
        public String jsonData;

        public VirtualAccountDetailWrapper(String plotId, String jsonData) {
            this.plotId = plotId;
            this.jsonData = jsonData;
        }
    }
}