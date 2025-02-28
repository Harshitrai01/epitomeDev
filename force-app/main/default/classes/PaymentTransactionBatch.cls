/**
* Author: Harshit Kumar Rai
* Description: For Payment Transaction Get Status Batch
*/
global class PaymentTransactionBatch implements Database.Batchable<sObject>, Schedulable, Database.AllowsCallouts, Database.Stateful {
    private Decimal timeForRun = 2;
    global Database.QueryLocator start(Database.BatchableContext BC) {
        List<BatchClassTime__mdt> batchTime = [SELECT DeveloperName, Time_In_Minutes__c
                                               FROM BatchClassTime__mdt 
                                               WHERE DeveloperName = 'testBatchClassTime' LIMIT 1];
        if (!batchTime.isEmpty()) {
            BatchClassTime__mdt batch = batchTime[0];
            timeForRun = batch.Time_In_Minutes__c;
        }
        
        DateTime currentDateTime = System.Now();
        return Database.getQueryLocator([
            SELECT Id, Merchant_Transaction_Id__c, Email_Address__c, Phone__c, Payment_Amount__c, 
            			Payment_Status__c, Opportunity__c, Payment_Type__c, Contact_Name__c,
						Payment_URL__c, Payment_Id__c, Payment_Expiry_Date__c, Payment_Updated_Date__c,
						Payment_Created_Date__c
            			FROM Payment_Gateway__c 
            			WHERE Merchant_Transaction_Id__c != null AND Email_Address__c!=null AND 
            			Phone__c!=null AND Payment_Amount__c!=null AND Payment_Status__c!='Success'
						AND Payment_Status__c!='UserCancelled' AND Payment_Expiry_Date__c>=:currentDateTime
        ]);
    }

    global void execute(Database.BatchableContext BC, List<Payment_Gateway__c> paymentRecords) {
        Map<String, Payment_Gateway__c> paymentMap = new Map<String, Payment_Gateway__c>();
        for (Payment_Gateway__c payment : paymentRecords) {
            paymentMap.put(payment.Merchant_Transaction_Id__c, payment);
        }
        List<String> merchantIdList = New List<String>();
        List<Payment__c> updatedPayments = new List<Payment__c>();
        List<Payment_Gateway__c> paymentGateWayToUpdate = new List<Payment_Gateway__c>();
        List<Integration_Log__c> integrationLogs = new List<Integration_Log__c>();
        
        for (String txnId : paymentMap.keySet()) {
            Payment_Gateway__c paymentRecord = paymentMap.get(txnId);
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
                    Payment__c payment = new Payment__c();
                    payment.Payment_Amount__c = paymentRecord.Payment_Amount__c;
                    payment.Email_Address__c = paymentRecord.Email_Address__c;
                    payment.Merchant_Transaction_Id__c = paymentRecord.Merchant_Transaction_Id__c;
                    payment.Opportunity__c = paymentRecord.Opportunity__c;
                    payment.Payment_Created_Date__c = paymentRecord.Payment_Created_Date__c;
                    // To Be Checked Updated Date
                    payment.Payment_Updated_Date__c = System.now();
                    payment.Payment_Expiry_Date__c = paymentRecord.Payment_Expiry_Date__c;
                    payment.Payment_Id__c = paymentRecord.Payment_Id__c;
                    payment.Payment_Status__c = paymentRecord.Payment_Status__c;
                    payment.Payment_URL__c = paymentRecord.Payment_URL__c;
                    payment.Contact_Name__c = paymentRecord.Contact_Name__c;
                    payment.Payment_Type__c = paymentRecord.Payment_Type__c;
                    payment.Phone__c=paymentRecord.Phone__c;
                    payment.Payment_Gateway__c = paymentRecord.Id;
                    payment.Percent_Of_Amount_To_Refund__c=100;
                    if (statusOfResponse && responseMap.containsKey('msg')) {
                        Map<String, Object> transactionData = (Map<String, Object>) responseMap.get('msg');
                        String mode = (String) transactionData.get('mode');
                        String status = (String) transactionData.get('status');
                        String error = (String) transactionData.get('error');
                        String easepayId = (String) transactionData.get('easepayid');
                        String errorMessage = (String) transactionData.get('error_Message');
                        payment.Payment_Status__c = status;
                        payment.Payment_Mode__c = mode;
                        payment.Payment_Easepay_Id__c = easepayId;
                        payment.Is_Webhook__c = true;
                        payment.Error_Message__c = errorMessage;
                        paymentRecord.Payment_Status__c=status;
                        updatedPayments.add(payment);
                        paymentGateWayToUpdate.add(paymentRecord);
                        Integration_Log__c log = null;
                        if (String.isNotBlank(integrationLogsStr)) {
                            log = (Integration_Log__c) JSON.deserialize(integrationLogsStr, Integration_Log__c.class);
                            //integrationLogs.add(log);
                        }
                    }else{
                        String message= (String) responseMap.get('msg');
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
            // insert integrationLogs;
        }
        if (!updatedPayments.isEmpty()) {
            List<Payment__c> updatedPaymentList = New List<Payment__c>();
            List<Payment__c> paymentList = [Select Id,Merchant_Transaction_Id__c From Payment__c 
                                            Where Merchant_Transaction_Id__c IN: merchantIdList];
            Map<String, String> merchantIdMap = new Map<String, String>();
            for(Payment__c payment:paymentList){
                merchantIdMap.put(payment.Merchant_Transaction_Id__c,payment.Id);
            }
            for(Payment__c payment:updatedPayments){
                if(merchantIdMap.ContainsKey(payment.Merchant_Transaction_Id__c)){
                    payment.Id=merchantIdMap.get(payment.Merchant_Transaction_Id__c);
                }
                updatedPaymentList.add(payment);
            }
            if (!updatedPaymentList.isEmpty()) {
                upsert updatedPaymentList;
            }
        }
        if (!paymentGateWayToUpdate.isEmpty()) {
            update paymentGateWayToUpdate;
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
        System.schedule('PaymentTransactionBatch '+ String.valueOf(Datetime.now()), cronExp, new PaymentTransactionBatch());
    }

    global void execute(SchedulableContext sc) {
        Database.executeBatch(new PaymentTransactionBatch(), 10);
        System.abortJob(sc.getTriggerId());
    }
}