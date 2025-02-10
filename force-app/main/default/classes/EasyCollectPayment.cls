public class EasyCollectPayment {
    
    public static String key;
    public static String salt;
    static {
        initializeMetadata();
    }
    
    private static void initializeMetadata() {
        List<Integration__mdt> integrations = [SELECT DeveloperName, EasyCollectKey__c, EasyCollectSalt__c
                                               FROM Integration__mdt 
                                               WHERE DeveloperName = 'testDashboard' LIMIT 1];
        
        if (!integrations.isEmpty()) {
            Integration__mdt integration = integrations[0];
            key = integration.EasyCollectKey__c;
            salt = integration.EasyCollectSalt__c;
        }
    }
    
    @AuraEnabled
    public static ResponseWrapper createPaymentLink(String name, String amount, String phone, String email, String expiryTime, String oppId, String contactId) {
        
        String url = 'https://testdashboard.easebuzz.in/easycollect/v1/create';
        PaymentRequest paymentRequest = new PaymentRequest();
        paymentRequest.key = key;
        paymentRequest.name = name;
        paymentRequest.amount = amount;
        paymentRequest.phone = phone;
        
        paymentRequest.merchant_txn = '';
        paymentRequest.email = email;
        
        paymentRequest.udf1 = '';
        paymentRequest.udf2 = '';
        paymentRequest.udf3 = '';
        paymentRequest.udf4 = '';
        paymentRequest.udf5 = '';
        Datetime currentDateTime = Datetime.now();
        Datetime expiryDateTime = currentDateTime.addMinutes(Integer.valueOf(expiryTime));
        String formattedExpiryDate = expiryDateTime.format('dd-MM-yyyy hh:mm:ss a');
        paymentRequest.expiry_date = formattedExpiryDate;
        paymentRequest.message = 'Please pay the mentioned amount.';
        
        Operation smsOperation = new Operation();
        smsOperation.type = 'sms';
        smsOperation.template = 'Default sms template';
        
        Operation emailOperation = new Operation();
        emailOperation.type = 'email';
        emailOperation.template = 'Default email template';
        
        Operation whatsappOperation = new Operation();
        whatsappOperation.type = 'whatsapp';
        whatsappOperation.template = 'Default whatsapp template';
        
        paymentRequest.operation = new List<Operation>{smsOperation, emailOperation, whatsappOperation};
            
            String error='';
        String hashString = paymentRequest.key + '|' + paymentRequest.merchant_txn + '|' + paymentRequest.name + '|' +
            paymentRequest.email + '|' + paymentRequest.phone + '|' + paymentRequest.amount + '|' +
            paymentRequest.udf1 + '|' + paymentRequest.udf2 + '|' + paymentRequest.udf3 + '|' +
            paymentRequest.udf4 + '|' + paymentRequest.udf5 + '|' + paymentRequest.message + '|' + salt;
        paymentRequest.hash = generateSHA512Hash(hashString);
        String requestBody = JSON.serialize(paymentRequest);
        
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(url);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Accept', 'application/json');
        request.setBody(requestBody);
        HttpResponse response;
        try {
            response = http.send(request);
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            if (response.getStatusCode() == 200 || response.getStatusCode() == 201) {
                Boolean status = (Boolean) responseMap.get('status');
                if (status) {
                    Map<String, Object> data = (Map<String, Object>) responseMap.get('data');
                    String paymentUrl = (String) data.get('payment_url');
                    data.put('oppId', oppId);
                    data.put('contactId', contactId);
                    data.put('status',status);
                    // LogUtility.doLog(request.getBody(), response.getBody(), response.getStatusCode());
                    ResponseWrapper responseWrapper= New ResponseWrapper(true,null,JSON.serialize(data));
                    return responseWrapper;
                } else {
                    error='Error: Status Code: ' + response.getStatusCode() + ', ' + responseMap.get('error');
                    throw new AuraHandledException(error);
                }
            } else {
                error='HTTP Error: Status Code: ' + response.getStatusCode() + ', ' + responseMap.get('error');
                throw new AuraHandledException(error);
            }
        } catch (Exception ex) {
            LogUtility.doLogError(request.getBody(), response.getBody(), response.getStatusCode(), JSON.serialize(ex.getCause()), JSON.serialize(ex.getTypeName()), JSON.serialize(ex.getMessage()), JSON.serialize(ex.getStackTraceString()), error);
            ResponseWrapper responseWrapper= New ResponseWrapper(false,error,null);
            return responseWrapper;
        }
    }
    
    @AuraEnabled
    public static void insertPaymentRecord(String jsonData) {
        try {
            Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(jsonData);
            Boolean status = (Boolean) data.get('status');
            if(status){
                String createdDate = (String) data.get('created_date');
            	String updatedDate = (String) data.get('updated_date');
            	String email = (String) data.get('email');
            	String paymentUrl = (String) data.get('payment_url');
            	String oppId = (String) data.get('oppId');
            	Payment__c payment = new Payment__c(
                Payment_Amount__c = Decimal.valueOf((String) data.get('amount')),
                Email_Address__c = email,
                Merchant_Transaction_Id__c = (String) data.get('merchant_txn'),
                Opportunity__c = (String) data.get('oppId'),
                Payment_Created_Date__c = Datetime.valueOfGmt(createdDate.substring(0, 19).replace('T', ' ')),
                Payment_Updated_Date__c = Datetime.valueOfGmt(updatedDate.substring(0, 19).replace('T', ' ')),
                Payment_Expiry_Date__c = (String) data.get('expiry_date'),
                Payment_Id__c = String.ValueOf(data.get('id')),
                Payment_Status__c = (String) data.get('state'),
                Payment_URL__c = paymentUrl,
                Contact_Name__c = (String) data.get('contactId'),
                Payment_Type__c = 'Online',
                Phone__c=(String) data.get('phone')
            );
            insert payment;
            
            List<Opportunity> oppList = [Select Id, Name, Unit__r.Virtual_Account_Name__c, Unit__r.Virtual_Account_Number__c,
                                         Unit__r.Virtual_Account_UPI__c, Unit__r.Virtual_Account_IFSC__c,
                                         Unit__r.UPI_QR_Image__c
                                         From Opportunity Where Id=:oppId Limit 1];
            
            sendPaymentLinkEmail(email,paymentUrl,oppList[0].Unit__r.Virtual_Account_Name__c,oppList[0].Unit__r.Virtual_Account_Number__c,oppList[0].Unit__r.Virtual_Account_IFSC__c,oppList[0].Unit__r.Virtual_Account_UPI__c,oppList[0].Unit__r.UPI_QR_Image__c);
           }
        } catch (Exception e) {
            System.debug('Error inserting payment record: ' + e.getMessage());
            throw new AuraHandledException('Failed to insert payment record: ' + e.getMessage());
        }
    }
    
    public static void sendPaymentLinkEmail(String recipientEmail, String paymentLink, String accountName, String accountNumber, String ifscCode, String upiId, String qrImageUrl) {
        try {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[] { recipientEmail });
            email.setSubject('Payment Link - Epitome Projects LLP');
            String htmlBody;
            if(accountNumber!=null){
                htmlBody = '<html>'
                    + '<body style="font-family: Arial, sans-serif; font-size: 16px; color: #333; background-color: #f9f9f9; padding: 20px;">'
                    
                    + '<div style="max-width: 500px; margin: auto; background: #fff; padding: 20px; border-radius: 8px; box-shadow: 0px 0px 10px rgba(0, 0, 0, 0.1);">'
                    
                    + '<p style="font-size: 18px; font-weight: bold;">Dear Customer,</p>'
                    + '<p style="color: #555;">Please find below your payment details:</p>'
                    
                    + '<div style="padding: 15px; background: #f3f3f3; border-radius: 8px;">'
                    + '<p><strong>📌 Account Name:</strong> ' + accountName + '</p>'
                    + '<p><strong>🏦 Account Number:</strong> ' + accountNumber + '</p>'
                    + '<p><strong>🏷️ IFSC Code:</strong> ' + ifscCode + '</p>'
                    + '<p><strong>💳 UPI ID:</strong> ' + upiId + '</p>'
                    + '</div>'
                    
                    + '<div style="text-align: center; margin: 20px 0;">'
                    + '<p><strong>Scan to Pay:</strong></p>'
                    + '<img src="' + qrImageUrl + '" alt="QR Code" width="180" height="180" style="border-radius: 8px;">'
                    + '</div>'
                    
                    + '<div style="text-align: center;">'
                    + '<a href="' + paymentLink + '" style="display: inline-block; padding: 12px 20px; background-color: #28a745; color: #fff; text-decoration: none; border-radius: 5px; font-size: 16px; font-weight: bold;">🔗 Click to Pay</a>'
                    + '</div>'
                    
                    + '<p style="margin-top: 20px;"><strong>Warm Regards,</strong><br/>Epitome Projects LLP</p>'
                    
                    + '</div>'
                    + '</body></html>';
            }else{
                htmlBody = '<html>'
                    + '<body style="font-family: Arial, sans-serif; font-size: 16px; color: #333; background-color: #f9f9f9; padding: 20px;">'
                    + '<p style="font-size: 18px; font-weight: bold;">Dear Customer,</p>'
                    + '<div style="text-align: left;">'
                    + '<p style="color: #555;">Please click here to complete your transaction:</p>'
                    + '<a href="' + paymentLink + '" style="display: inline-block; padding: 12px 20px; background-color: #28a745; color: #fff; text-decoration: none; border-radius: 5px; font-size: 16px; font-weight: bold;">🔗 Click to Pay</a>'
                    + '</div>'
                    
                    + '<p style="margin-top: 20px;"><strong>Warm Regards,</strong><br/>Epitome Projects LLP</p>'
                    
                    + '</div>'
                    + '</body></html>';
                
            }
            
            email.setHtmlBody(htmlBody);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
        } catch (Exception ex) {
            throw new AuraHandledException('Error in sending email: ' + ex.getMessage());
        }
    }
    
    public static String initiateRefund(String txnid, Decimal amount, String email, String phone, String paymentId) {
        
        String url = 'https://testdashboard.easebuzz.in/transaction/v1/refund';
        String error='';
        Decimal refundAmount= amount;
        if (String.valueOf(refundAmount).endsWith('.00')) {
            refundAmount = refundAmount.setScale(1, System.RoundingMode.DOWN);
            amount=refundAmount;
        }
        String hashString = key + '|' + txnid + '|' + amount + '|' + refundAmount + '|' + email + '|' + phone + '|' + salt;
        String hash = generateSHA512Hash(hashString);
        
        Map<String, Object> payload = new Map<String, Object>{
            'key' => key,
                'txnid' => txnid,
                'refund_amount' => refundAmount,
                'phone' => phone,
                'email' => email,
                'amount' => amount,
                'hash' => hash
                };
                    
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(url);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Accept', 'application/json');
        request.setBody(JSON.serialize(payload));
        HttpResponse response;
        try {
            response = http.send(request);
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            if (response.getStatusCode() == 200 || response.getStatusCode() == 201) {
                Boolean status = (Boolean) responseMap.get('status');
                if (status) {
                    System.debug('Refund Response: ' + responseMap);
                    System.debug('Refund Status: ' + responseMap.get('status'));
                    System.debug('Refund Amount: ' + responseMap.get('refund_amount'));
                    System.debug('Reason: ' + responseMap.get('reason'));
                    System.debug('Refund ID: ' + responseMap.get('refund_id'));
                    Integration_Log__c log = new Integration_Log__c();
                    log.IsSuccess__c = true;
                    log.Request_Body__c = (request.getBody() != null) ? request.getBody() : 'No Request Data';
                    log.Response_Body__c = (response.getBody() != null) ? response.getBody() : 'No Response Data';
                    log.Status_Code__c = (response.getStatusCode() != null) ? response.getStatusCode() : null;
                    ResponseWrapper reponseWrap = New ResponseWrapper(true,null,response.getBody());
                    reponseWrap.integrationLogs=JSON.serialize(log);
                    return JSON.serialize(reponseWrap);
                } else {
                    error = 'Status: '+status +', Reason: '+ (String) responseMap.get('reason');
                    String msg = (String) responseMap.get('msg');
                    Integration_Log__c log = new Integration_Log__c();
                    log.Cause__c = msg!=null?String.valueOf(msg):'';
                    log.Status_Code__c = response.getStatusCode() !=null ? response.getStatusCode():0;
                    log.Request_Body__c = request.getBody() !=null ? request.getBody():'';
                    log.Response_Body__c = response.getBody()!=null ? response.getBody():'';
                    log.Exception_Type__c ='Callout Error';
                    log.Error_Message__c = error!=null ? error:'';
                    log.Stack_Trace__c ='EasyCollectPayment.initiateRefund';
                    log.Error__c=error;
                    ResponseWrapper reponseWrap = New ResponseWrapper(true,error,response.getBody());
                    reponseWrap.integrationLogs=JSON.serialize(log);
                    return JSON.serialize(reponseWrap);
                }
            } else {
                error='Failed to initiate refund.';
                ResponseWrapper reponseWrap = New ResponseWrapper(false,error,response.getBody());
                Integration_Log__c log = new Integration_Log__c();
                log.Cause__c = error;
                log.Status_Code__c = response.getStatusCode() !=null ? response.getStatusCode():0;
                log.Request_Body__c = request.getBody() !=null ? request.getBody():'';
                log.Response_Body__c = response.getBody()!=null ? response.getBody():'';
                log.Exception_Type__c ='Callout Error';
                log.Error_Message__c = error!=null ? error:'';
                log.Stack_Trace__c ='EasyCollectPayment.getTransactionDetails';
                log.Error__c=error;
                reponseWrap.integrationLogs=JSON.serialize(log);
                return JSON.serialize(reponseWrap);
            }
        } catch (Exception ex) {
            ResponseWrapper reponseWrap = New ResponseWrapper(false,error,response.getBody());
            Integration_Log__c log = new Integration_Log__c();
            log.Cause__c = JSON.serialize(ex.getCause());
            log.Status_Code__c = response.getStatusCode() !=null ? response.getStatusCode():0;
            log.Request_Body__c = request.getBody() !=null ? request.getBody():'';
            log.Response_Body__c = response.getBody()!=null ? response.getBody():'';
            log.Exception_Type__c =JSON.serialize(ex.getTypeName());
            log.Error_Message__c = JSON.serialize(ex.getMessage())!=null ? JSON.serialize(ex.getMessage()):'';
            log.Stack_Trace__c =JSON.serialize(ex.getStackTraceString());
            log.Error__c=error;
            reponseWrap.integrationLogs=JSON.serialize(log);
            return JSON.serialize(reponseWrap);
        }
    }
    
    public static String getRefundStatus(String easebuzzId) {
        
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://testdashboard.easebuzz.in/refund/v1/retrieve');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Accept', 'application/json');
        String hash=generateSHA512Hash(key + '|' + easebuzzId + '|' + salt);
        Map<String, Object> requestBody = new Map<String, Object>{
            'key' => key,
                'easebuzz_id' => easebuzzId,
                'hash' => hash
                };
        String error='';
        request.setBody(JSON.serialize(requestBody));
        HttpResponse response;
        try {
            response = http.send(request);
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            if (response.getStatusCode() == 200 || response.getStatusCode() == 201) {
                Boolean status = (Boolean) responseMap.get('status');
                if (status && responseMap.containsKey('refunds')) {
                    List<Object> refundsList = (List<Object>) responseMap.get('refunds');
                    if (!refundsList.isEmpty()) {
                        Map<String, Object> refundDetails = (Map<String, Object>) refundsList[0];
                        String refundStatus = (String) refundDetails.get('refund_status');
                        String merchantRefundDate = (String) refundDetails.get('merchant_refund_date');
                        String refundSettledDate = (String) refundDetails.get('refund_settled_date');
                        String refundId = (String) refundDetails.get('refund_id');
                        Integration_Log__c log = new Integration_Log__c();
                        log.IsSuccess__c = true;
                        log.Request_Body__c = (request.getBody() != null) ? request.getBody() : 'No Request Data';
                        log.Response_Body__c = (response.getBody() != null) ? response.getBody() : 'No Response Data';
                        log.Status_Code__c = (response.getStatusCode() != null) ? response.getStatusCode() : null;
                        ResponseWrapper reponseWrap = New ResponseWrapper(true,null,response.getBody());
                        reponseWrap.integrationLogs=JSON.serialize(log);
                        return JSON.serialize(reponseWrap);
                    }else{
                        Integration_Log__c log = new Integration_Log__c();
                        log.Cause__c = ''!=null?String.valueOf(''):'';
                        log.Status_Code__c = response.getStatusCode() !=null ? response.getStatusCode():0;
                        log.Request_Body__c = request.getBody() !=null ? request.getBody():'';
                        log.Response_Body__c = response.getBody()!=null ? response.getBody():'';
                        log.Exception_Type__c ='Callout Error';
                        log.Error_Message__c = error!=null ? error:'';
                        log.Stack_Trace__c ='EasyCollectPayment.initiateRefund';
                        log.Error__c=error;
                        ResponseWrapper reponseWrap = New ResponseWrapper(true,error,response.getBody());
                        reponseWrap.integrationLogs=JSON.serialize(log);
                        return JSON.serialize(reponseWrap);
                    }
                }else{
                    Integration_Log__c log = new Integration_Log__c();
                    log.Cause__c = ''!=null?String.valueOf(''):'';
                    log.Status_Code__c = response.getStatusCode() !=null ? response.getStatusCode():0;
                    log.Request_Body__c = request.getBody() !=null ? request.getBody():'';
                    log.Response_Body__c = response.getBody()!=null ? response.getBody():'';
                    log.Exception_Type__c ='Callout Error';
                    log.Error_Message__c = error!=null ? error:'';
                    log.Stack_Trace__c ='EasyCollectPayment.initiateRefund';
                    log.Error__c=error;
                    ResponseWrapper reponseWrap = New ResponseWrapper(true,error,response.getBody());
                    reponseWrap.integrationLogs=JSON.serialize(log);
                    return JSON.serialize(reponseWrap);
				}
            } else {
                if (responseMap.containsKey('error_desc')) {
                    error = (String) responseMap.get('error_desc');
                }
                ResponseWrapper reponseWrap = New ResponseWrapper(false,error,response.getBody());
                Integration_Log__c log = new Integration_Log__c();
                log.Cause__c = error;
                log.Status_Code__c = response.getStatusCode() !=null ? response.getStatusCode():0;
                log.Request_Body__c = request.getBody() !=null ? request.getBody():'';
                log.Response_Body__c = response.getBody()!=null ? response.getBody():'';
                log.Exception_Type__c ='Callout Error';
                log.Error_Message__c = error!=null ? error:'';
                log.Stack_Trace__c ='EasyCollectPayment.getRefundStatus';
                log.Error__c=error;
                reponseWrap.integrationLogs=JSON.serialize(log);
                return JSON.serialize(reponseWrap);
            }
        } catch (Exception ex) {
            ResponseWrapper reponseWrap = New ResponseWrapper(false,error,response.getBody());
            Integration_Log__c log = new Integration_Log__c();
            log.Cause__c = JSON.serialize(ex.getCause());
            log.Status_Code__c = response.getStatusCode() !=null ? response.getStatusCode():0;
            log.Request_Body__c = request.getBody() !=null ? request.getBody():'';
            log.Response_Body__c = response.getBody()!=null ? response.getBody():'';
            log.Exception_Type__c =JSON.serialize(ex.getTypeName());
            log.Error_Message__c = JSON.serialize(ex.getMessage())!=null ? JSON.serialize(ex.getMessage()):'';
            log.Stack_Trace__c =JSON.serialize(ex.getStackTraceString());
            log.Error__c=error;
            reponseWrap.integrationLogs=JSON.serialize(log);
            return JSON.serialize(reponseWrap);
        }
    }
    
    public static String getTransactionDetails(String txnid, Decimal amount, String email, String phone) {
        if (amount!=null && String.valueOf(amount).endsWith('.00')) {
            amount = amount.setScale(1, System.RoundingMode.DOWN);
        }
        String inputString = key + '|' + txnid + '|' + amount + '|' + email + '|' + phone + '|' + SALT;
        String hash = generateSHA512Hash(inputString);
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://testdashboard.easebuzz.in/transaction/v1/retrieve');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setHeader('Accept', 'application/json');
        
        String requestBody = 'txnid=' + EncodingUtil.urlEncode(txnid, 'UTF-8') +
            '&key=' + EncodingUtil.urlEncode(key, 'UTF-8') +
            '&amount=' + EncodingUtil.urlEncode(String.valueOf(amount), 'UTF-8') +
            '&email=' + EncodingUtil.urlEncode(email, 'UTF-8') +
            '&phone=' + EncodingUtil.urlEncode(phone, 'UTF-8') +
            '&hash=' + EncodingUtil.urlEncode(hash, 'UTF-8');
        
        req.setBody(requestBody);
        Http http = new Http();
        HttpResponse res;
        String error='';
        try {
            res = http.send(req);
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
                Boolean status = (Boolean) responseMap.get('status');
                if (status) {
                    Integration_Log__c log = new Integration_Log__c();
                    log.IsSuccess__c = true;
                    log.Request_Body__c = (req.getBody() != null) ? req.getBody() : 'No Request Data';
                    log.Response_Body__c = (res.getBody() != null) ? res.getBody() : 'No Response Data';
                    log.Status_Code__c = (res.getStatusCode() != null) ? res.getStatusCode() : null;
                    ResponseWrapper reponseWrap = New ResponseWrapper(true,null,res.getBody());
                    reponseWrap.integrationLogs=JSON.serialize(log);
                    return JSON.serialize(reponseWrap);
                } else {
                    error = 'Status: '+status +', Reason: '+ (String) responseMap.get('msg');
                    String msg = (String) responseMap.get('msg');
                    Integration_Log__c log = new Integration_Log__c();
                    log.Cause__c = msg!=null?String.valueOf(msg):'';
                    log.Status_Code__c = res.getStatusCode() !=null ? res.getStatusCode():0;
                    log.Request_Body__c = req.getBody() !=null ? req.getBody():'';
                    log.Response_Body__c = res.getBody()!=null ? res.getBody():'';
                    log.Exception_Type__c ='Callout Error';
                    log.Error_Message__c = error!=null ? error:'';
                    log.Stack_Trace__c ='EasyCollectPayment.getTransactionDetails';
                    log.Error__c=error;
                    ResponseWrapper reponseWrap = New ResponseWrapper(true,error,res.getBody());
                    reponseWrap.integrationLogs=JSON.serialize(log);
                    return JSON.serialize(reponseWrap);
                }
            } else {
                ResponseWrapper reponseWrap = New ResponseWrapper(false,error,res.getBody());
                Integration_Log__c log = new Integration_Log__c();
                log.Cause__c = error;
                log.Status_Code__c = res.getStatusCode() !=null ? res.getStatusCode():0;
                log.Request_Body__c = req.getBody() !=null ? req.getBody():'';
                log.Response_Body__c = res.getBody()!=null ? res.getBody():'';
                log.Exception_Type__c ='Callout Error';
                log.Error_Message__c = error!=null ? error:'';
                log.Stack_Trace__c ='EasyCollectPayment.getTransactionDetails';
                log.Error__c=error;
                reponseWrap.integrationLogs=JSON.serialize(log);
                return JSON.serialize(reponseWrap);
            }
        } catch (Exception ex) {
            ResponseWrapper reponseWrap = New ResponseWrapper(false,error,res.getBody());
            Integration_Log__c log = new Integration_Log__c();
            log.Cause__c = JSON.serialize(ex.getCause());
            log.Status_Code__c = res.getStatusCode() !=null ? res.getStatusCode():0;
            log.Request_Body__c = req.getBody() !=null ? req.getBody():'';
            log.Response_Body__c = res.getBody()!=null ? res.getBody():'';
            log.Exception_Type__c =JSON.serialize(ex.getTypeName());
            log.Error_Message__c = JSON.serialize(ex.getMessage())!=null ? JSON.serialize(ex.getMessage()):'';
            log.Stack_Trace__c =JSON.serialize(ex.getStackTraceString());
            log.Error__c=error;
            reponseWrap.integrationLogs=JSON.serialize(log);
            return JSON.serialize(reponseWrap);
        }
    }
    
    private static String generateSHA512Hash(String input) {
        Blob inputBlob = Blob.valueOf(input);
        Blob hashBlob = Crypto.generateDigest('SHA-512', inputBlob);
        return EncodingUtil.convertToHex(hashBlob);
    }
    
    public class ResponseWrapper {
        @AuraEnabled
        public Boolean isSuccess;
        @AuraEnabled
        public String error;
        @AuraEnabled
        public String response;
        public String integrationLogs;
        public ResponseWrapper(Boolean isSuccess, String error, String response) {
            this.isSuccess = isSuccess;
            this.error = error;
            this.response = response;
        }
    }
    
    public class Operation {
        public String type;
        public String template;
    }
    
    public class PaymentRequest {
        public String merchant_txn;
        public String key;
        public String email;
        public String name;
        public String amount;
        public String phone;
        public String udf1;
        public String udf2;
        public String udf3;
        public String udf4;
        public String udf5;
        public String message;
        public String expiry_date;
        public List<Operation> operation;
        public String hash;
    }
}