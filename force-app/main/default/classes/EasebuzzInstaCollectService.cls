/**
* Author: Harshit Kumar Rai
* Description: For Creation Of Virtual Account Details
*/

public class EasebuzzInstaCollectService {
    private static String API_URL;
    private static String MERCHANT_KEY;
    private static String MERCHANT_SALT;
    
    static {
        initializeMetadata();
    }
    
    private static void initializeMetadata() {
        List<Integration__mdt> integrations = [SELECT DeveloperName, InstaCollectKey__c, InstaCollectSalt__c,
                                               Easebuzz_Instacollect_Create_VA__c
                                               FROM Integration__mdt 
                                               WHERE DeveloperName = 'testDashboard' LIMIT 1];
        if (!integrations.isEmpty()) {
            Integration__mdt integration = integrations[0];
            MERCHANT_KEY = integration.InstaCollectKey__c;
            MERCHANT_SALT = integration.InstaCollectSalt__c;
            API_URL = integration.Easebuzz_Instacollect_Create_VA__c;
        }
    }
    
    @future (callout=true)
    public static void createVirtualAccount(String plotId) {
        
            String label = plotId;
        	String error='';
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
                'unique_request_number'=>plotId
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
                            //IntegrationLogUtility.doLog(request.getBody(), response.getBody(), response.getStatusCode());
                            updateVirtualAccountDetailsOnPlot(plotId,JSON.serialize(virtualAccount));
                        }
                    }
                }else {
                    if (responseMap.containsKey('additional') && ((Map<String, Object>) responseMap.get('additional')).containsKey('validation') && !((List<Object>) ((Map<String, Object>) responseMap.get('additional')).get('validation')).isEmpty()) {
                        Map<String, Object> validationError = (Map<String, Object>) ((List<Object>) ((Map<String, Object>) responseMap.get('additional')).get('validation'))[0];
                        if (validationError.containsKey('message')) {
                            error = (String) validationError.get('message');
                        }
                    }
                    System.debug('Error: ' + response.getStatusCode() + ' - ' + error);
                    IntegrationLogUtility.doLogError(request.getBody(), response.getBody(), response.getStatusCode(), 'Bad Response', 'Future Method', error, 'Response Error: EasebuzzInstaCollectService', error);
                    
                }
        }catch (Exception ex) {
            IntegrationLogUtility.doLogError(request.getBody(), response.getBody(), response.getStatusCode(), 'Bad Response', 'Future Method', error, 'Response Error: EasebuzzInstaCollectService', error);
        }
    }
    
    public static void updateVirtualAccountDetailsOnPlot(String plotId, String jsonData){
        try{
            List<Unit__c> plotList = [Select Id,Name,Phase__r.Name, Virtual_Account_Name__c, Virtual_Account_Number__c,
                                      Virtual_Account_Id__c, Virtual_Account_UPI__c, Virtual_Account_IFSC__c,
                                      UPI_QR_Image__c, UPI_QR_PDF__c, Unique_Request_Number__c
                                      From Unit__c Where Id=:plotId Limit 1];
            
            Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(jsonData);
            if(plotList!=null && !plotList.isEmpty()){
                if(plotList[0]?.Phase__r?.Name!=null){
                    plotList[0].Virtual_Account_Name__c= plotList[0].Name + ' '+ plotList[0]?.Phase__r?.Name;
                }
                plotList[0].Virtual_Account_Number__c=(String) data.get('virtual_account_number');
                plotList[0].Virtual_Account_Id__c=(String) data.get('id');
                plotList[0].Virtual_Account_UPI__c=(String) data.get('virtual_upi_handle');
                plotList[0].Virtual_Account_IFSC__c=(String) data.get('virtual_ifsc_number');
                plotList[0].UPI_QR_Image__c=(String) data.get('upi_qrcode_remote_file_location');
                plotList[0].UPI_QR_PDF__c=(String) data.get('upi_qrcode_scanner_remote_file_location');
                plotList[0].Unique_Request_Number__c=(String) data.get('unique_request_number');
                update plotList;
            }
        }catch(Exception ex){
            System.Debug('Error In Updating Virtual Account Details : '+ ex.getMessage());
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    @future (callout=true)
    public static void retrieveTransactionsList() {
        // String createdAt, String createdAtStart, String createdAtEnd, String currentPage, String pageSize, String status
        String requestUrl = 'https://wire.easebuzz.in/api/v2/insta-collect/transactions/?key=' + MERCHANT_KEY;
        /*
        if (String.isNotEmpty(createdAt)) {
            requestUrl += '&created_at=' + EncodingUtil.urlEncode(createdAt, 'UTF-8');
        } else {
            if (String.isNotEmpty(createdAtStart)) {
                requestUrl += '&created_at_start=' + EncodingUtil.urlEncode(createdAtStart, 'UTF-8');
            }
            if (String.isNotEmpty(createdAtEnd)) {
                requestUrl += '&created_at_end=' + EncodingUtil.urlEncode(createdAtEnd, 'UTF-8');
            }
        }
        if (String.isNotEmpty(currentPage)) {
            requestUrl += '&current=' + EncodingUtil.urlEncode(currentPage, 'UTF-8');
        }
        if (String.isNotEmpty(pageSize)) {
            requestUrl += '&pageSize=' + EncodingUtil.urlEncode(pageSize, 'UTF-8');
        }
        if (String.isNotEmpty(status)) {
            requestUrl += '&status=' + EncodingUtil.urlEncode(status, 'UTF-8');
        }
        */
        String createdAt='';
        // String createdAtStart='2025-02-13 04:01:53 PM';
        String createdAtStart='2025-01-13';
        String createdAtEnd=String.valueOf(System.now().dateGmt());
        if (String.isNotEmpty(createdAt)) {
            requestUrl += '&created_at=' + EncodingUtil.urlEncode(createdAt, 'UTF-8');
        } else {
            if (String.isNotEmpty(createdAtStart)) {
                requestUrl += '&created_at_start=' + EncodingUtil.urlEncode(createdAtStart, 'UTF-8');
            }
            if (String.isNotEmpty(createdAtEnd)) {
                requestUrl += '&created_at_end=' + EncodingUtil.urlEncode(createdAtEnd, 'UTF-8');
            }
        }
        
        String virtual_account_id='cvae9575838c4e8a8b8fa985132b9860';
        if (String.isNotEmpty(virtual_account_id)) {
            requestUrl += '&virtual_account_id=' + EncodingUtil.urlEncode(virtual_account_id, 'UTF-8');
        }
        
        /*
        String unique_transaction_reference='9839977941';
        if (String.isNotEmpty(unique_transaction_reference)) {
            requestUrl += '&unique_transaction_reference=' + EncodingUtil.urlEncode(unique_transaction_reference, 'UTF-8');
        }*/
        
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
            if (response.getStatusCode() == 200) {
                System.debug('Transaction List Response: ' + response.getBody());
                        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        
                        if (responseMap.containsKey('success') && (Boolean) responseMap.get('success')) {
                            Map<String, Object> data = (Map<String, Object>) responseMap.get('data');
                            
                            if (data.containsKey('results')) {
                                List<Object> results = (List<Object>) data.get('results');
                                
                                for (Object resultObj : results) {
                                    Map<String, Object> transactions = (Map<String, Object>) resultObj;
                                    
                                    // Extracting values
                                    String id = (String) transactions.get('id');
                                    String status = (String) transactions.get('status');
                                    String uniqueTransactionReference = (String) transactions.get('unique_transaction_reference');
                                    String transactionDate = (String) transactions.get('transaction_date');
                                    String remitterAccountNumber = (String) transactions.get('remitter_account_number');
                                    String remitterAccountIfsc = (String) transactions.get('remitter_account_ifsc');
                                    String remitterUpiHandle = (String) transactions.get('remitter_upi_handle');
                                    String remitterFullName = (String) transactions.get('remitter_full_name');
                                    String remitterPhoneNumber = (String) transactions.get('remitter_phone_number');
                                    Integer transactionOrder = (Integer) transactions.get('transaction_order');
                                    String narration = (String) transactions.get('narration');
                                    
                                    String virtualAccountNumber = null;
                                    if (transactions.containsKey('virtual_account')) {
                                        Map<String, Object> virtualAccount = (Map<String, Object>) transactions.get('virtual_account');
                                        virtualAccountNumber = (String) virtualAccount.get('virtual_account_number');
                                    }
                
                                    // Logging values
                                    System.debug('Transaction Details:');
                                    System.debug('ID: ' + id);
                                    System.debug('Status: ' + status);
                                    System.debug('Unique Transaction Reference: ' + uniqueTransactionReference);
                                    System.debug('Transaction Date: ' + transactionDate);
                                    System.debug('Remitter Account Number: ' + remitterAccountNumber);
                                    System.debug('Remitter Account IFSC: ' + remitterAccountIfsc);
                                    System.debug('Remitter UPI Handle: ' + remitterUpiHandle);
                                    System.debug('Remitter Full Name: ' + remitterFullName);
                                    System.debug('Remitter Phone Number: ' + remitterPhoneNumber);
                                    System.debug('Transaction Order: ' + transactionOrder);
                                    System.debug('Narration: ' + narration);
                                    System.debug('Virtual Account Number: ' + virtualAccountNumber);
                                    System.debug('------------------------------------');
                                }
                            }
                        }
            } else {
                System.debug('Error: ' + response.getStatusCode() + ' - ' + response.getBody());
            }
        } catch (Exception ex) {
            System.debug('Exception in retrieving transactions: ' + ex.getMessage());
        }
    }
    
        public static void sendCollectRequest() {
        try {
            String virtualAccountId='cvae9575838c4e8a8b8fa985132b9860';
            String key = MERCHANT_KEY;
            String wireApiKey = key;
            String email='harshitrai.as@gmail.com';
            String phone = '7380515333';
           	Decimal amount = 20;
            String purpose='Payment Collection';
            // Define the endpoint
            String endpoint = 'https://wire.easebuzz.in/api/v1/insta-collect/virtual_accounts/' + virtualAccountId + '/collect_request/';

            // Generate SHA-512 hash for Authorization header
            String salt = MERCHANT_SALT; // Replace with actual salt
            String rawString = key + '|' + virtualAccountId + '|' + salt;
            String authorizationHash = EncodingUtil.convertToHex(Crypto.generateDigest('SHA-512', Blob.valueOf(rawString)));
            List<String> collectRequestType = new List<String>{'account_details', 'upi_handle'};
            String upiHandle = 'harshitrai484@ybl'; // Static UPI Handle

            // Prepare request body
            Map<String, Object> requestBody = new Map<String, Object>();
            requestBody.put('key', key);
            requestBody.put('email', email);
            requestBody.put('phone', phone);
            requestBody.put('collect_request_type', new List<String>{'account_details', 'upi_handle'});
            requestBody.put('amount', amount);
            requestBody.put('purpose', purpose);
            requestBody.put('collect_request_type', collectRequestType);
            requestBody.put('upi_handle', upiHandle);

            // Convert request body to JSON
            String jsonBody = JSON.serialize(requestBody);

            // Set up HTTP request
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Accept', 'application/json');
            req.setHeader('Authorization', authorizationHash);
            req.setHeader('WIRE-API-KEY', wireApiKey);
            req.setBody(jsonBody);

            // Send request
            Http http = new Http();
            HTTPResponse res = http.send(req);

            // Log response
            System.debug('Response Status: ' + res.getStatusCode());
            System.debug('Response Body: ' + res.getBody());
        } catch (Exception e) {
            System.debug('Error in sending collect request: ' + e.getMessage());
        }
    }
    
    private static String generateSHA512Hash(String input) {
        Blob inputBlob = Blob.valueOf(input);
        Blob hashBlob = Crypto.generateDigest('SHA-512', inputBlob);
        return EncodingUtil.convertToHex(hashBlob);
    }
    
}