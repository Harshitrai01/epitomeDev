/*
*********************************************************
Apex Class Name    : PaymentTransactionBatch
Created Date       : [Insert Date]
@description       : This batch class is responsible for fetching and updating the status of payment transactions 
                     by making callouts to an external API (Easepay). It processes payment gateway records that 
                     are not marked as 'Success' or 'UserCancelled' and have not expired. The class implements 
                     Database.Batchable, Schedulable, and allows callouts.
@author            : Harshit Kumar Rai
Modification Log:
Ver   Date         Author                               Modification
1.0   [Insert Date] Harshit Kumar Rai                   Initial Version
*********************************************************
*/
global class PaymentTransactionBatch implements Database.Batchable<sObject>, Schedulable, Database.AllowsCallouts, Database.Stateful {
    private Decimal timeForRun = 2; // Default time interval for scheduling the next batch run

    /*
    *********************************************************
    @Method Name    : start
    @author         : Harshit Kumar Rai
    @description    : This method is the starting point of the batch process. It queries the custom metadata 
                       to determine the time interval for the next batch run and returns a QueryLocator for 
                       payment gateway records that are eligible for transaction status checks.
    @param          : Database.BatchableContext BC - The context of the batch job.
    @return         : Database.QueryLocator - A query locator for payment gateway records that need status updates.
    ********************************************************
    */
    global Database.QueryLocator start(Database.BatchableContext BC) {
        // Fetch the time interval for the next batch run from custom metadata
        List<BatchClassTime__mdt> batchTime = [SELECT DeveloperName, Time_In_Minutes__c
                                               FROM BatchClassTime__mdt 
                                               WHERE DeveloperName = 'testBatchClassTime' LIMIT 1];
        if (!batchTime.isEmpty()) {
            BatchClassTime__mdt batch = batchTime[0];
            timeForRun = batch.Time_In_Minutes__c;
        }
        
        // Query payment gateway records that are eligible for transaction status checks
        DateTime currentDateTime = System.Now();
        return Database.getQueryLocator([
            SELECT Id, Merchant_Transaction_Id__c, Email_Address__c, Phone__c, Payment_Amount__c, 
                   Payment_Status__c, Opportunity__c, Payment_Type__c, Contact_Name__c,
                   Payment_URL__c, Payment_Id__c, Payment_Expiry_Date__c, Payment_Updated_Date__c,
                   Payment_Created_Date__c
            FROM Payment_Gateway__c 
            WHERE Merchant_Transaction_Id__c != null AND Email_Address__c != null AND 
                  Phone__c != null AND Payment_Amount__c != null AND Payment_Status__c != 'Success'
                  AND Payment_Status__c != 'UserCancelled' AND Payment_Expiry_Date__c >= :currentDateTime
        ]);
    }

    /*
    *********************************************************
    @Method Name    : execute
    @author         : Harshit Kumar Rai
    @description    : This method processes a batch of payment gateway records, makes callouts to the Easepay API 
                       to fetch transaction details, and updates the payment records and integration logs accordingly.
    @param          : Database.BatchableContext BC - The context of the batch job.
    @param          : List<Payment_Gateway__c> paymentRecords - The list of payment gateway records to process.
    ********************************************************
    */
    global void execute(Database.BatchableContext BC, List<Payment_Gateway__c> paymentRecords) {
        Map<String, Payment_Gateway__c> paymentMap = new Map<String, Payment_Gateway__c>();
        for (Payment_Gateway__c payment : paymentRecords) {
            paymentMap.put(payment.Merchant_Transaction_Id__c, payment);
        }
        
        List<String> merchantIdList = new List<String>();
        List<Payment__c> updatedPayments = new List<Payment__c>();
        List<Payment_Gateway__c> paymentGateWayToUpdate = new List<Payment_Gateway__c>();
        List<Integration_Log__c> integrationLogs = new List<Integration_Log__c>();
        
        for (String txnId : paymentMap.keySet()) {
            Payment_Gateway__c paymentRecord = paymentMap.get(txnId);
            
            // Call the Easepay API to fetch transaction details
            String apiResponse = EasyCollectPayment.getTransactionDetails(paymentRecord.Merchant_Transaction_Id__c, 
                                                                         paymentRecord.Payment_Amount__c, 
                                                                         paymentRecord.Email_Address__c, 
                                                                         paymentRecord.Phone__c);
            Map<String, Object> responseWrapper = (Map<String, Object>) JSON.deserializeUntyped(apiResponse);
            Boolean isSuccess = (Boolean) responseWrapper.get('isSuccess');
            String errorWrapper = (String) responseWrapper.get('error');
            String response = (String) responseWrapper.get('response');
            String integrationLogsStr = (String) responseWrapper.get('integrationLogs');
            
            if (isSuccess && String.isNotBlank(response)) {
                try {
                    Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response);
                    Boolean statusOfResponse = (Boolean) responseMap.get('status');
                    
                    // Create a new Payment record
                    Payment__c payment = new Payment__c();
                    payment.Payment_Amount__c = paymentRecord.Payment_Amount__c;
                    payment.Email_Address__c = paymentRecord.Email_Address__c;
                    payment.Merchant_Transaction_Id__c = paymentRecord.Merchant_Transaction_Id__c;
                    payment.Opportunity__c = paymentRecord.Opportunity__c;
                    payment.Payment_Created_Date__c = paymentRecord.Payment_Created_Date__c;
                    payment.Payment_Updated_Date__c = System.now();
                    payment.Payment_Expiry_Date__c = paymentRecord.Payment_Expiry_Date__c;
                    payment.Payment_Id__c = paymentRecord.Payment_Id__c;
                    payment.Payment_Status__c = paymentRecord.Payment_Status__c;
                    payment.Payment_URL__c = paymentRecord.Payment_URL__c;
                    payment.Contact_Name__c = paymentRecord.Contact_Name__c;
                    payment.Payment_Type__c = paymentRecord.Payment_Type__c;
                    payment.Phone__c = paymentRecord.Phone__c;
                    payment.Payment_Gateway__c = paymentRecord.Id;
                    payment.Percent_Of_Amount_To_Refund__c = 100;
                    
                    if (statusOfResponse && responseMap.containsKey('msg')) {
                        Map<String, Object> transactionData = (Map<String, Object>) responseMap.get('msg');
                        String mode = (String) transactionData.get('mode');
                        String status = (String) transactionData.get('status');
                        String error = (String) transactionData.get('error');
                        String easepayId = (String) transactionData.get('easepayid');
                        String errorMessage = (String) transactionData.get('error_Message');
                        
                        // Update payment and payment gateway records with transaction details
                        payment.Payment_Status__c = status;
                        payment.Payment_Mode__c = mode;
                        payment.Payment_Easepay_Id__c = easepayId;
                        payment.Is_Webhook__c = true;
                        payment.Error_Message__c = errorMessage;
                        paymentRecord.Payment_Status__c = status;
                        
                        updatedPayments.add(payment);
                        paymentGateWayToUpdate.add(paymentRecord);
                        
                        // Log integration details if available
                        Integration_Log__c log = null;
                        if (String.isNotBlank(integrationLogsStr)) {
                            log = (Integration_Log__c) JSON.deserialize(integrationLogsStr, Integration_Log__c.class);
                            //integrationLogs.add(log); // Uncomment if logs need to be added
                        }
                    } else {
                        // Log integration details if the response status is false
                        String message = (String) responseMap.get('msg');
                        payment.Error_Message__c = message;
                        updatedPayments.add(payment);
                        
                        Integration_Log__c log = null;
                        if (String.isNotBlank(integrationLogsStr)) {
                            log = (Integration_Log__c) JSON.deserialize(integrationLogsStr, Integration_Log__c.class);
                            integrationLogs.add(log);
                        }
                    }
                    merchantIdList.add(paymentRecord.Merchant_Transaction_Id__c);
                } catch (Exception e) {
                    System.debug('Error parsing response: ' + e.getMessage());
                }
            } else if (!isSuccess) {
                // Log integration details if the API call is unsuccessful
                Integration_Log__c log = null;
                if (String.isNotBlank(integrationLogsStr)) {
                    log = (Integration_Log__c) JSON.deserialize(integrationLogsStr, Integration_Log__c.class);
                    integrationLogs.add(log);
                }
            } else {
                // Log integration details for other scenarios
                Integration_Log__c log = null;
                if (String.isNotBlank(integrationLogsStr)) {
                    log = (Integration_Log__c) JSON.deserialize(integrationLogsStr, Integration_Log__c.class);
                    integrationLogs.add(log);
                }
            }
        }
        
        // Insert integration logs and update payment records
        if (!integrationLogs.isEmpty()) {
            // insert integrationLogs; // Uncomment if logs need to be inserted
        }
        if (!updatedPayments.isEmpty()) {
            List<Payment__c> updatedPaymentList = new List<Payment__c>();
            List<Payment__c> paymentList = [SELECT Id, Merchant_Transaction_Id__c,Email_Address__c FROM Payment__c 
                                            WHERE Merchant_Transaction_Id__c IN :merchantIdList];
            Map<String, String> merchantIdMap = new Map<String, String>();
            Map<String, String> idToEmailMap = new Map<String, String>();
            for (Payment__c payment : paymentList) {
                merchantIdMap.put(payment.Merchant_Transaction_Id__c, payment.Id);
            }
            for (Payment__c payment : updatedPayments) {
                if (merchantIdMap.containsKey(payment.Merchant_Transaction_Id__c)) {
                    payment.Id = merchantIdMap.get(payment.Merchant_Transaction_Id__c);
                }
                updatedPaymentList.add(payment);
            }
            if (!updatedPaymentList.isEmpty()) {
                upsert updatedPaymentList;
                List<Id> recordIds = new List<Id>();
                for (Payment__c p : updatedPaymentList) {
                    if (p.Payment_Status__c == 'success') {
                        recordIds.add(p.Id);
                        idToEmailMap.put(p.Id, p.Email_Address__c);
                    }
                }
                if (!recordIds.isEmpty()) {
                    submitForApproval(recordIds);
                    if(!idToEmailMap.isEmpty()){
                        System.enqueueJob(new PaymentReceiptQueueable(idToEmailMap, recordIds));
                    }
                }
            }
        }
        
        if (!paymentGateWayToUpdate.isEmpty()) {
            update paymentGateWayToUpdate;
        }
    }

    /*
    *********************************************************
    @Method Name    : finish
    @author         : Harshit Kumar Rai
    @description    : This method is called when the batch job finishes. It schedules the next run of the 
                       batch job based on the configured time interval.
    @param          : Database.BatchableContext BC - The context of the batch job.
    ********************************************************
    */
    global void finish(Database.BatchableContext BC) {
        DateTime nextRun = System.now().addMinutes(Integer.ValueOf(timeForRun));
        String cronExp = nextRun.second() + ' ' +
                         nextRun.minute() + ' ' +
                         nextRun.hour() + ' ' +
                         nextRun.day() + ' ' +
                         nextRun.month() + ' ? ' +
                         nextRun.year();
        System.schedule('PaymentTransactionBatch ' + String.valueOf(Datetime.now()), cronExp, new PaymentTransactionBatch());
    }

    /*
    *********************************************************
    @Method Name    : execute (Schedulable)
    @author         : Harshit Kumar Rai
    @description    : This method is called when the class is executed as a scheduled job. It starts the 
                       batch process and aborts the current scheduled job.
    @param          : SchedulableContext sc - The context of the scheduled job.
    ********************************************************
    */
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new PaymentTransactionBatch(), 10);
        System.abortJob(sc.getTriggerId());
    }

    /*
    *********************************************************
    @Method Name    : submitForApproval
    @author         : Harshit Kumar Rai
    @description    : This method submits payment records for approval if their status is 'success'.
    @param          : List<Id> recordIds - The list of payment record IDs to submit for approval.
    ********************************************************
    */
    public static void submitForApproval(List<Id> recordIds) {
        try {
            List<Approval.ProcessSubmitRequest> submitRequests = new List<Approval.ProcessSubmitRequest>();
            
            for (Id recordId : recordIds) {
                Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
                req.setObjectId(recordId);
                req.setComments('Refund Approval Request.');
                req.setNextApproverIds(null);
                req.setProcessDefinitionNameOrId('Payment_Approval_Process');
                submitRequests.add(req);
            }
            
            // Submit all requests in bulk
            List<Approval.ProcessResult> results = Approval.process(submitRequests);
            
            // Validate that each approval submission was successful
            for (Approval.ProcessResult result : results) {
                if (!result.isSuccess()) {
                    System.debug('Approval process failed for one or more records.');
                }
            }
        } catch (Exception ex) {
            System.debug('Error triggering approval process: ' + ex.getMessage());
        }
    }    
}