/*
*********************************************************
Apex Class Name    : PaymentRefundGetStatusBatch
Created Date       : [Insert Date]
@description       : This batch class is responsible for fetching and updating the refund status of payments 
                     by making callouts to an external API (Easepay). It processes payments that are marked 
                     as successful but have not yet been refunded. The class implements Database.Batchable, 
                     Schedulable, and allows callouts.
@author            : Harshit Kumar Rai
Modification Log:
Ver   Date         Author                               Modification
1.0   [Insert Date] Harshit Kumar Rai                   Initial Version
*********************************************************
*/
global class PaymentRefundGetStatusBatch implements Database.Batchable<sObject>, Schedulable, Database.AllowsCallouts, Database.Stateful {
    private Decimal timeForRun = 2; // Default time interval for scheduling the next batch run

    /*
    *********************************************************
    @Method Name    : start
    @author         : Harshit Kumar Rai
    @description    : This method is the starting point of the batch process. It queries the custom metadata 
                       to determine the time interval for the next batch run and returns a QueryLocator for 
                       payments that are eligible for refund status checks.
    @param          : Database.BatchableContext BC - The context of the batch job.
    @return         : Database.QueryLocator - A query locator for payments that need refund status updates.
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
        
        // Query payments that are eligible for refund status checks
        return Database.getQueryLocator([
            SELECT Id, Payment_Easepay_Id__c FROM Payment__c 
            WHERE Is_Refund_Success__c = true AND Payment_Easepay_Id__c != null 
            AND Payment_Status__c = 'success' AND Refund_Status__c != 'refunded'
        ]);
    }

    /*
    *********************************************************
    @Method Name    : execute
    @author         : Harshit Kumar Rai
    @description    : This method processes a batch of payment records, makes callouts to the Easepay API 
                       to fetch refund status, and updates the payment records and integration logs accordingly.
    @param          : Database.BatchableContext BC - The context of the batch job.
    @param          : List<Payment__c> paymentRecords - The list of payment records to process.
    ********************************************************
    */
    global void execute(Database.BatchableContext BC, List<Payment__c> paymentRecords) {
        Map<String, Payment__c> paymentMap = new Map<String, Payment__c>();
        for (Payment__c payment : paymentRecords) {
            paymentMap.put(payment.Payment_Easepay_Id__c, payment);
        }
        
        List<Payment__c> updatedPayments = new List<Payment__c>();
        List<Integration_Log__c> integrationLogs = new List<Integration_Log__c>();
        
        for (String txnId : paymentMap.keySet()) {
            Payment__c paymentRecord = paymentMap.get(txnId);
            
            // Call the Easepay API to fetch refund status
            String apiResponse = EasyCollectPayment.getRefundStatus(paymentRecord.Payment_Easepay_Id__c);
            Map<String, Object> responseWrapper = (Map<String, Object>) JSON.deserializeUntyped(apiResponse);
            Boolean isSuccess = (Boolean) responseWrapper.get('isSuccess');
            String errorWrapper = (String) responseWrapper.get('error');
            String response = (String) responseWrapper.get('response');
            String integrationLogsStr = (String) responseWrapper.get('integrationLogs');
            
            if (isSuccess && String.isNotBlank(response)) {
                try {
                    Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response);
                    Boolean statusOfResponse = (Boolean) responseMap.get('status');
                    if (statusOfResponse && responseMap.containsKey('refunds')) {
                        List<Object> refundsList = (List<Object>) responseMap.get('refunds');
                        if (!refundsList.isEmpty()) {
                            Map<String, Object> transactionData = (Map<String, Object>) refundsList[0];
                            String refundStatus = (String) transactionData.get('refund_status');
                            String merchantRefundDate = (String) transactionData.get('merchant_refund_date');
                            String refundSettledDate = (String) transactionData.get('refund_settled_date');
                            String refundId = (String) transactionData.get('refund_id');
                        
                            // Update payment record with refund details
                            paymentRecord.Refund_Status__c = refundStatus;
                            paymentRecord.Refund_Date__c = merchantRefundDate;
                            paymentRecord.Refund_Settled_Date__c = refundSettledDate;
                            updatedPayments.add(paymentRecord);
                            
                            // Log integration details if available
                            Integration_Log__c log = null;
                            if (String.isNotBlank(integrationLogsStr)) {
                                log = (Integration_Log__c) JSON.deserialize(integrationLogsStr, Integration_Log__c.class);
                                //integrationLogs.add(log); // Uncomment if logs need to be added
                            }
                        } else {
                            // Log integration details if no refunds are found
                            Integration_Log__c log = null;
                            if (String.isNotBlank(integrationLogsStr)) {
                                log = (Integration_Log__c) JSON.deserialize(integrationLogsStr, Integration_Log__c.class);
                                integrationLogs.add(log);
                            }
                        }
                    } else {
                        // Log integration details if the response status is false
                        Integration_Log__c log = null;
                        if (String.isNotBlank(integrationLogsStr)) {
                            log = (Integration_Log__c) JSON.deserialize(integrationLogsStr, Integration_Log__c.class);
                            integrationLogs.add(log);
                        }
                    }
                } catch (Exception e) {
                    // Log integration details in case of exceptions
                    Integration_Log__c log = null;
                    if (String.isNotBlank(integrationLogsStr)) {
                        log = (Integration_Log__c) JSON.deserialize(integrationLogsStr, Integration_Log__c.class);
                        integrationLogs.add(log);
                    }
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
            insert integrationLogs;
        }
        if (!updatedPayments.isEmpty()) {
            update updatedPayments;
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
        System.schedule('Payment Refund Details Fetch ' + String.valueOf(Datetime.now()), cronExp, new PaymentRefundGetStatusBatch());
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
        Database.executeBatch(new PaymentRefundGetStatusBatch(), 20);
        System.abortJob(sc.getTriggerId());
    }
}