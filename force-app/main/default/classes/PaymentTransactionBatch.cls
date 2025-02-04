global class PaymentTransactionBatch implements Database.Batchable<sObject>, Schedulable, Database.AllowsCallouts {
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id, Merchant_Transaction_Id__c, Email_Address__c, Phone__c, Payment_Amount__c, 
            			Payment_Status__c,Payment_Mode__c, Payment_Easepay_Id__c,Is_Webhook__c,
                        Error_Message__c FROM Payment__c 
            			WHERE Merchant_Transaction_Id__c != null AND Email_Address__c!=null AND 
            			Phone__c!=null AND Payment_Amount__c!=null
        ]);
    }

    global void execute(Database.BatchableContext BC, List<Payment__c> paymentRecords) {
        Map<String, Payment__c> paymentMap = new Map<String, Payment__c>();
        for (Payment__c payment : paymentRecords) {
            paymentMap.put(payment.Merchant_Transaction_Id__c, payment);
        }
        List<Payment__c> updatedPayments = new List<Payment__c>();
        List<Integration_Log__c> integrationLogs = new List<Integration_Log__c>();
        
        for (String txnId : paymentMap.keySet()) {
            Payment__c paymentRecord = paymentMap.get(txnId);

            String apiResponse = EasyCollectPayment.getTransactionDetails(paymentRecord.Merchant_Transaction_Id__c, paymentRecord.Payment_Amount__c, paymentRecord.Email_Address__c,paymentRecord.Phone__c);
            Map<String, Object> responseWrapper = (Map<String, Object>) JSON.deserializeUntyped(apiResponse);
            Boolean isSuccess = (Boolean) responseWrapper.get('isSuccess');
            String errorWrapper = (String) responseWrapper.get('error');
            String response = (String) responseWrapper.get('response');
            String integrationLogsStr = (String) responseWrapper.get('integrationLogs');
            if (isSuccess && String.isNotBlank(response)) {
                try {
                    Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response);
                    Boolean statusOfResponse = (Boolean) responseMap.get('status');
                    if (statusOfResponse && responseMap.containsKey('msg')) {
                        Map<String, Object> transactionData = (Map<String, Object>) responseMap.get('msg');
                        String mode = (String) transactionData.get('mode');
                        String status = (String) transactionData.get('status');
                        String error = (String) transactionData.get('error');
                        String easepayId = (String) transactionData.get('easepayid');
                        String errorMessage = (String) transactionData.get('error_Message');

                        paymentRecord.Payment_Status__c = status;
                        paymentRecord.Payment_Mode__c = mode;
                        paymentRecord.Payment_Easepay_Id__c = easepayId;
                        paymentRecord.Is_Webhook__c = true;
                        paymentRecord.Error_Message__c = errorMessage;
                        updatedPayments.add(paymentRecord);
                        Integration_Log__c log = null;
                        if (String.isNotBlank(integrationLogsStr)) {
                            log = (Integration_Log__c) JSON.deserialize(integrationLogsStr, Integration_Log__c.class);
                            integrationLogs.add(log);
                        }
                    }else{
                        String message= (String) responseMap.get('msg');
                        paymentRecord.Error_Message__c = message;
                        updatedPayments.add(paymentRecord);
                        Integration_Log__c log = null;
                        if (String.isNotBlank(integrationLogsStr)) {
                            log = (Integration_Log__c) JSON.deserialize(integrationLogsStr, Integration_Log__c.class);
                            integrationLogs.add(log);
                        }
                    }
                } catch (Exception e) {
                    System.debug('Error parsing response: ' + e.getMessage());
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
        /*String hour = String.valueOf(Datetime.now().hour());
        String min = String.valueOf(Datetime.now().addMinutes(2).minute());
        String ss = String.valueOf(Datetime.now().second());
        String nextFireTime = ss + ' ' + min + ' ' + hour + ' * * ?';*/
        DateTime nextRun = System.now().addMinutes(2);
        String cronExp = nextRun.second() + ' ' +
                         nextRun.minute() + ' ' +
                         nextRun.hour() + ' ' +
                         nextRun.day() + ' ' +
                         nextRun.month() + ' ? ' +
                         nextRun.year();
        System.schedule('Payment Details Fetch '+ String.valueOf(Datetime.now()), cronExp, new PaymentTransactionBatch());
    }

    global void execute(SchedulableContext sc) {
        Database.executeBatch(new PaymentTransactionBatch(), 10);
        System.abortJob(sc.getTriggerId());
    }
}