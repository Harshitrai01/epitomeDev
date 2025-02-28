/**
* Author: Harshit Kumar Rai
* Description: For InstaCollect Payment Transaction Get Status Batch
*/
global class PaymentTransactionInstaCollectBatch implements Database.Batchable<sObject>, Schedulable, Database.AllowsCallouts, Database.Stateful {
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
            // More Filter Conditions Are Required For Optimization
            Select Id, Unit__c, Unit__r.Virtual_Account_Id__c 
            From Opportunity Where Unit__c!=null AND Unit__r.Virtual_Account_Id__c!=null 
            AND Unit__r.Virtual_Account_Id__c!='' AND Unit__r.Status__c!='Available'
            AND Unit__r.Status__c!='Sold'
        ]);
    }

    global void execute(Database.BatchableContext BC, List<Opportunity> oppRecords) {
        List<String> virtualAccountIdList = New List<String>();
        List<Payment__c> updatedPayments = new List<Payment__c>();
        List<Integration_Log__c> integrationLogs = new List<Integration_Log__c>();
        for (Opportunity opp:oppRecords) {
            String apiResponse = EasebuzzInstaCollectService.retrieveTransactionsList(opp.Unit__r.Virtual_Account_Id__c);
            Map<String, Object> responseWrapper = (Map<String, Object>) JSON.deserializeUntyped(apiResponse);
            Boolean isSuccess = (Boolean) responseWrapper.get('isSuccess');
            String errorWrapper = (String) responseWrapper.get('error');
            String response = (String) responseWrapper.get('response');
            String integrationLogsStr = (String) responseWrapper.get('integrationLogs');
            if (isSuccess && String.isNotBlank(response)) {
                try {
                    Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response);
                    Map<String, Object> data = (Map<String, Object>) responseMap.get('data');
                    if(data.containsKey('results')){
                        List<Object> results = (List<Object>) data.get('results');
                                for (Object resultObj : results) {
                                    Map<String, Object> transactions = (Map<String, Object>) resultObj;
                                    String id = (String) transactions.get('id');
                                    String status1 = (String) transactions.get('status');
                                    String createdDate = (String) transactions.get('created_at');
                                    String paymentMode = (String) transactions.get('payment_mode');
                                    Decimal amount = (Decimal) transactions.get('amount');
                                    String transactionDateTime = (String) transactions.get('transaction_date');
                                    String uniqueTransactionReference = (String) transactions.get('unique_transaction_reference');
                                    String remitterAccountNumber = (String) transactions.get('remitter_account_number');
                                    String remitterAccountIfsc = (String) transactions.get('remitter_account_ifsc');
                                    String remitterUpiHandle = (String) transactions.get('remitter_upi_handle');
                                    String remitterFullName = (String) transactions.get('remitter_full_name');
                                    String remitterPhoneNumber = (String) transactions.get('remitter_phone_number');
                                    String settlementDate = (String) transactions.get('settlement_date');
                                    Boolean is_settled_by_bank = (Boolean) transactions.get('is_settled_by_bank');
                                    String bankSettlementDate = (String) transactions.get('bank_settlement_date');
                                    String narration = (String) transactions.get('narration');
                                    
                                    String virtualAccountNumber = null;
                                    if (transactions.containsKey('virtual_account')){
                                        Map<String, Object> virtualAccount = (Map<String, Object>) transactions.get('virtual_account');
                                        virtualAccountNumber = (String) virtualAccount.get('virtual_account_number');
                                    }
                                    Payment__c payment = new Payment__c();
                                    payment.InstaCollect_Transaction_Id__c=id;
                                    if(status1!=null)
                                    payment.InstaCollect_Status__c=status1.substring(0,1).toUpperCase() + status1.substring(1);
                                    if(createdDate!=null)
                                    payment.Payment_Created_Date__c = Datetime.valueOf(createdDate.substring(0, 19).replace('T', ' '));
                                    payment.Payment_Updated_Date__c = System.now();
                                    payment.Payment_Mode__c = paymentMode;
                                    payment.Payment_Amount__c = amount;
                                    if(transactionDateTime!=null)
                                    payment.InstaCollect_Transaction_Date_Time__c = Datetime.valueOf(transactionDateTime.substring(0, 19).replace('T', ' '));
                                    payment.Opportunity__c = opp.Id;
                                    payment.InstaCollect_Transaction_Reference__c = uniqueTransactionReference;
                                    payment.Remitter_Account_Number__c = remitterAccountNumber;
                                    payment.Remitter_Account_IFSC__c = remitterAccountIfsc;
                                    payment.Remitter_UPI_Handle__c = remitterUpiHandle;
                                    payment.Remitter_Full_Name__c = remitterFullName;
                                    payment.Remitter_Phone_Number__c = remitterPhoneNumber;
                                    if(bankSettlementDate!=null)
                                    payment.InstaCollect_Bank_Settlement_Date__c = Date.valueOf(bankSettlementDate);
                                    if(settlementDate!=null)
                                    payment.InstaCollect_Settlement_Date__c = Datetime.valueOf(settlementDate.substring(0, 19).replace('T', ' '));
                                    payment.InstaCollect_Settled_By_Bank__c = is_settled_by_bank;
                                    payment.InstaCollect_Narration__c = narration;
                                    payment.Payment_Type__c = 'InstaCollect';
                                    payment.Percent_Of_Amount_To_Refund__c=100;
                                    updatedPayments.add(payment);
                                    virtualAccountIdList.add(id);
                                    Integration_Log__c log = null;
                                    if (String.isNotBlank(integrationLogsStr)) {
                                        log = (Integration_Log__c) JSON.deserialize(integrationLogsStr, Integration_Log__c.class);
                                        integrationLogs.add(log);
                                    }
                                }
                    }
                } catch (Exception e) {
                    System.debug('Error parsing response: ' + e.getMessage());
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
            //insert integrationLogs;
        }
        if (!updatedPayments.isEmpty()) {
            List<Payment__c> updatedPaymentList = New List<Payment__c>();
            List<Payment__c> paymentList = [Select Id,InstaCollect_Transaction_Id__c From Payment__c 
                                            Where InstaCollect_Transaction_Id__c IN: virtualAccountIdList];
            Map<String, String> transactionIdMap = new Map<String, String>();
            for(Payment__c payment:paymentList){
                transactionIdMap.put(payment.InstaCollect_Transaction_Id__c,payment.Id);
            }
            for(Payment__c payment:updatedPayments){
                if(transactionIdMap.ContainsKey(payment.InstaCollect_Transaction_Id__c)){
                    payment.Id=transactionIdMap.get(payment.InstaCollect_Transaction_Id__c);
                }
                updatedPaymentList.add(payment);
            }
            if (!updatedPaymentList.isEmpty()) {
                upsert updatedPaymentList;
            }
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
        System.schedule('PaymentTransactionInstaCollect '+ String.valueOf(Datetime.now()), cronExp, new PaymentTransactionInstaCollectBatch());
    }

    global void execute(SchedulableContext sc) {
        Database.executeBatch(new PaymentTransactionInstaCollectBatch(), 10);
        System.abortJob(sc.getTriggerId());
    }
    
}