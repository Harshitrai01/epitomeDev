/*
*********************************************************
Apex Class Name    : EasyCollectPayment
Created Date       : [Insert Date]
@description       : This class is used for payment integration with Easebuzz. It handles creating payment links, 
                     initiating refunds, retrieving transaction details, and managing refund statuses.
@author            : Harshit Rai
Modification Log:
Ver   Date         Author               Modification
1.0   [Insert Date] Harshit Rai         Initial Version
*********************************************************
*/
public with sharing class EasyCollectPayment {
    
    public static String key;
    public static String salt;
    public static String refundStatus;
    public static String initiateRefund;
    public static String transactinDetails;
    public static String createPaymentLink;
    
    // Static initializer to fetch and initialize metadata values
    static {
        initializeMetadata();
    }
    /*
    *********************************************************
    @Method Name    : initializeMetadata
    @author         : Harshit Rai
    @description    : Fetches and initializes metadata values for API configuration from custom metadata.
    *********************************************************
    */
    private static void initializeMetadata() {
        List<Integration__mdt> integrations = [SELECT DeveloperName, EasyCollectKey__c, EasyCollectSalt__c,Easebuzz_Refund_Status_Url__c,
                                               Easebuzz_Initiate_Refund_Url__c,Easebuzz_Get_Transaction_Details_Url__c,
                                               Easebuzz_Create_Payment_Link_Url__c
                                               FROM Integration__mdt 
                                               WHERE DeveloperName = 'testDashboard' LIMIT 1];
        
        if (!integrations.isEmpty()) {
            Integration__mdt integration = integrations[0];
            key = integration.EasyCollectKey__c;
            salt = integration.EasyCollectSalt__c;
            refundStatus = integration.Easebuzz_Refund_Status_Url__c;
            initiateRefund = integration.Easebuzz_Initiate_Refund_Url__c;
            transactinDetails = integration.Easebuzz_Get_Transaction_Details_Url__c;
            createPaymentLink = integration.Easebuzz_Create_Payment_Link_Url__c;
            
        }
    }
    
     /*
    *********************************************************
    @Method Name    : createPaymentLink
    @author         : Harshit Rai
    @description    : Creates a payment link using the Easebuzz API.
    @param          : name - Name of the payer.
    @param          : amount - Amount to be paid.
    @param          : phone - Phone number of the payer.
    @param          : email - Email of the payer.
    @param          : expiryTime - Expiry time for the payment link.
    @param          : oppId - Opportunity ID associated with the payment.
    @param          : contactId - Contact ID associated with the payment.
    @return         : ResponseWrapper - Wrapper containing the response and integration logs.
    *********************************************************
    */
    @AuraEnabled
    public static ResponseWrapper createPaymentLink(String name, String amount, String phone, String email, String expiryTime, String oppId, String contactId) {
        
        String url = createPaymentLink;
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
                    //LogUtility.doLog(request.getBody(), response.getBody(), response.getStatusCode());
                    ResponseWrapper responseWrapper= New ResponseWrapper(true,null,JSON.serialize(data));
                    return responseWrapper;
                } else {
                    error='Error: Status Code: ' + response.getStatusCode() + ', ' + responseMap.get('error');
                    LogUtility.doLogError(request.getBody(), response.getBody(), response.getStatusCode(), error, error, error, error, error);
                    throw new AuraHandledException(error);
                }
            } else {
                error='HTTP Error: Status Code: ' + response.getStatusCode() + ', ' + responseMap.get('error');
                LogUtility.doLogError(request.getBody(), response.getBody(), response.getStatusCode(), error, error, error, error, error);
                throw new AuraHandledException(error);
            }
        } catch (Exception ex) {
            LogUtility.doLogError(request.getBody(), response.getBody(), response.getStatusCode(), JSON.serialize(ex.getCause()), JSON.serialize(ex.getTypeName()), JSON.serialize(ex.getMessage()), JSON.serialize(ex.getStackTraceString()), error);
            ResponseWrapper responseWrapper= New ResponseWrapper(false,error,null);
            return responseWrapper;
        }
    }
    
    /*
    *********************************************************
    @Method Name    : insertPaymentRecord
    @author         : Harshit Rai
    @description    : Inserts a payment record based on the provided JSON data.
    @param          : jsonData - JSON string containing payment details.
    *********************************************************
    */
    @AuraEnabled
    public static void insertPaymentRecord(String jsonData) {
        try {
            Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(jsonData);
            Boolean status = (Boolean) data.get('status');
            if(status){
                System.Debug('Expiry Date-->>'+(String) data.get('expiry_date'));
                String createdDate = (String) data.get('created_date');
            	String updatedDate = (String) data.get('updated_date');
            	String email = (String) data.get('email');
            	String paymentUrl = (String) data.get('payment_url');
            	String oppId = (String) data.get('oppId');
                String amount = (String) data.get('amount');
                String expiry_date = (String) data.get('expiry_date');
                List<String> parts = expiry_date.split(' ');
                List<String> dateParts = parts[0].split('-'); // [day, month, year]
                String reformatted = dateParts[2] + '-' + dateParts[1] + '-' + dateParts[0] + ' ' + parts[1];
                //Percent_Of_Amount_To_Refund__c=100,
            	Payment_Gateway__c payment = new Payment_Gateway__c(
                Payment_Amount__c = Decimal.valueOf((String) data.get('amount')),
                Email_Address__c = email,
                Merchant_Transaction_Id__c = (String) data.get('merchant_txn'),
                Opportunity__c = (String) data.get('oppId'),
                Payment_Created_Date__c = Datetime.valueOf(createdDate.substring(0, 19).replace('T', ' ')),
                Payment_Updated_Date__c = Datetime.valueOf(updatedDate.substring(0, 19).replace('T', ' ')),
                Payment_Expiry_Date__c = Datetime.valueOf(reformatted),
                Payment_Id__c = String.ValueOf(data.get('id')),
                Payment_Status__c = (String) data.get('state'),
                Payment_URL__c = paymentUrl,
                Contact_Name__c = (String) data.get('contactId'),
                Payment_Type__c = 'EasyCollect',
                Phone__c=(String) data.get('phone')
            );
            insert payment;
            
            List<Opportunity> oppList = [Select Id, Name, Unit__r.Virtual_Account_Name__c, Unit__r.Virtual_Account_Number__c,
                                         Unit__r.Virtual_Account_UPI__c, Unit__r.Virtual_Account_IFSC__c,Easy_Collect_Payment_Link__c,
                                         Unit__r.UPI_QR_Image__c,Unit__r.Name,First_Booking_Amount__c,Unit__r.Phase__r.Name
                                         From Opportunity Where Id=:oppId Limit 1];
                if(oppList!=null && !oppList.isEmpty()){
                    oppList[0].Easy_Collect_Payment_Link__c=paymentUrl;
                    update oppList;
                }
            sendPaymentLinkEmail(email,paymentUrl,oppList[0].Unit__r.Virtual_Account_Name__c,oppList[0].Unit__r.Virtual_Account_Number__c,oppList[0].Unit__r.Virtual_Account_IFSC__c,oppList[0].Unit__r.Virtual_Account_UPI__c,oppList[0].Unit__r.UPI_QR_Image__c,oppList[0].Unit__r.Name,oppList[0].Unit__r.Phase__r.Name,String.ValueOf(oppList[0].First_Booking_Amount__c));
           }
        } catch (Exception e) {
            System.debug('Error inserting payment record: ' + e.getMessage());
            throw new AuraHandledException('Failed to insert payment record: ' + e.getMessage());
        }
    }
    
        /*
    *********************************************************
    @Method Name    : sendPaymentLinkEmail
    @author         : Harshit Rai
    @description    : Sends an email with the payment link and virtual account details.
    @param          : recipientEmail - Email address of the recipient.
    @param          : paymentLink - Payment link to be sent.
    @param          : accountName - Name of the virtual account.
    @param          : accountNumber - Number of the virtual account.
    @param          : ifscCode - IFSC code of the virtual account.
    @param          : upiId - UPI ID of the virtual account.
    @param          : qrImageUrl - URL of the UPI QR code image.
    @param          : plotName - Name of the plot.
    @param          : phaseName - Name of the phase.
    @param          : amount - Amount to be paid.
    *********************************************************
    */
    
    public static void sendPaymentLinkEmail(String recipientEmail, String paymentLink, String accountName, String accountNumber, String ifscCode, String upiId, String qrImageUrl, String plotName, String phaseName, String amount) {
        try {
            EmailTemplate template = [SELECT HtmlValue FROM EmailTemplate WHERE DeveloperName = 'Terms_and_Conditions' LIMIT 1];
            String termsAndConditions = template.HtmlValue;
            if(phaseName==null){
                phaseName='';
            }
            if(plotName==null){
                plotName='';
            }
            if (termsAndConditions != null) {
            	termsAndConditions = termsAndConditions
                            .replace('{!Opportunity.Phase_Name__c}', phaseName)
                            .replace('{!Opportunity.Plot_Name__c}', plotName)
                            .replace('{!Opportunity.First_Booking_Amount__c}', amount);
            }
            
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
    
     /*
    *********************************************************
    @Method Name    : initiateRefund
    @author         : Harshit Rai
    @description    : Initiates a refund for a given transaction.
    @param          : txnid - Transaction ID.
    @param          : amount - Amount to be refunded.
    @param          : email - Email of the payer.
    @param          : phone - Phone number of the payer.
    @param          : paymentId - Payment ID.
    @return         : String - JSON string containing the response and integration logs.
    *********************************************************
    */
    public static String initiateRefund(String txnid, Decimal amount, String email, String phone, String paymentId) {
        
        String url = initiateRefund;
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
    
    /*
    *********************************************************
    @Method Name    : getRefundStatus
    @author         : Harshit Rai
    @description    : Retrieves the refund status for a given Easebuzz transaction ID. It makes an API call to the Easebuzz 
                       refund status endpoint and processes the response. If successful, it returns the refund details; 
                       otherwise, it logs the error and returns an error response.
    @param          : easebuzzId - The Easebuzz transaction ID for which the refund status is to be retrieved.
    @return         : String - JSON string containing the response and integration logs.
    *********************************************************
    */
    public static String getRefundStatus(String easebuzzId) {
        
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(refundStatus);
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
        req.setEndpoint(transactinDetails);
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
            System.debug('--------++++');
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