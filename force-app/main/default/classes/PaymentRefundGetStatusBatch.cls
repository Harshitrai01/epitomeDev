/**
* Author: Harshit Kumar Rai
* Description: For Payment Refund Get Status Batch
*/
global class PaymentRefundGetStatusBatch implements Database.Batchable<sObject>, Schedulable, Database.AllowsCallouts, Database.Stateful{
    private Decimal timeForRun = 2;
    global Database.QueryLocator start(Database.BatchableContext BC) {
        List<BatchClassTime__mdt> batchTime = [SELECT DeveloperName, Time_In_Minutes__c
                                               FROM BatchClassTime__mdt 
                                               WHERE DeveloperName = 'testBatchClassTime' LIMIT 1];
        if (!batchTime.isEmpty()) {
            BatchClassTime__mdt batch = batchTime[0];
            timeForRun = batch.Time_In_Minutes__c;
        }
        
        return Database.getQueryLocator([
            SELECT Id, Payment_Easepay_Id__c FROM Payment__c 
            WHERE Is_Refund_Success__c=true AND Payment_Easepay_Id__c!=null AND Payment_Status__c='success'
            AND Refund_Status__c!='refunded'
        ]);
    }
    
    global void execute(Database.BatchableContext BC, List<Payment__c> paymentRecords) {
        Map<String, Payment__c> paymentMap = new Map<String, Payment__c>();
        for (Payment__c payment : paymentRecords) {
            paymentMap.put(payment.Payment_Easepay_Id__c, payment);
        }
        
        List<Payment__c> updatedPayments = new List<Payment__c>();
        List<Integration_Log__c> integrationLogs = new List<Integration_Log__c>();
        
        for (String txnId : paymentMap.keySet()) {
            Payment__c paymentRecord = paymentMap.get(txnId);
            
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
                        
                            paymentRecord.Refund_Status__c = refundStatus;
                            paymentRecord.Refund_Date__c = merchantRefundDate;
                            paymentRecord.Refund_Settled_Date__c = refundSettledDate;
                            updatedPayments.add(paymentRecord);
                            Integration_Log__c log = null;
                            if (String.isNotBlank(integrationLogsStr)) {
                                log = (Integration_Log__c) JSON.deserialize(integrationLogsStr, Integration_Log__c.class);
                                //integrationLogs.add(log);
                            }
                        }else{
                            Integration_Log__c log = null;
                            if (String.isNotBlank(integrationLogsStr)) {
                                log = (Integration_Log__c) JSON.deserialize(integrationLogsStr, Integration_Log__c.class);
                                integrationLogs.add(log);
                            }
                        }
                    }else{
                        Integration_Log__c log = null;
                        if (String.isNotBlank(integrationLogsStr)) {
                            log = (Integration_Log__c) JSON.deserialize(integrationLogsStr, Integration_Log__c.class);
                            integrationLogs.add(log);
                        }
                    }
                } catch (Exception e) {
                    Integration_Log__c log = null;
                        if (String.isNotBlank(integrationLogsStr)) {
                            log = (Integration_Log__c) JSON.deserialize(integrationLogsStr, Integration_Log__c.class);
                            integrationLogs.add(log);
                        }
                }
            }else if(!isSuccess){
                Integration_Log__c log = null;
                if (String.isNotBlank(integrationLogsStr)) {
                    log = (Integration_Log__c) JSON.deserialize(integrationLogsStr, Integration_Log__c.class);
                    integrationLogs.add(log);
                }
            }else{
                Integration_Log__c log = null;
                if (String.isNotBlank(integrationLogsStr)) {
                    log = (Integration_Log__c) JSON.deserialize(integrationLogsStr, Integration_Log__c.class);
                    integrationLogs.add(log);
                }
            }
        }
        
        if (!integrationLogs.isEmpty()) {
            insert integrationLogs;
        }
        if (!updatedPayments.isEmpty()) {
            update updatedPayments;
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        DateTime nextRun = System.now().addMinutes(Integer.ValueOf(timeForRun));
        String cronExp = nextRun.second() + ' ' +
            nextRun.minute() + ' ' +
            nextRun.hour() + ' ' +
            nextRun.day() + ' ' +
            nextRun.month() + ' ? ' +
            nextRun.year();
            System.schedule('Payment Refund Details Fetch '+ String.valueOf(Datetime.now()), cronExp, new PaymentRefundGetStatusBatch());
    }
    
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new PaymentRefundGetStatusBatch(), 20);
        System.abortJob(sc.getTriggerId());
    }
}