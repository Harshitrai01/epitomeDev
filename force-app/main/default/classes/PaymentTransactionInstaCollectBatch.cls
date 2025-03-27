/*
*********************************************************
Apex Class Name    : PaymentTransactionInstaCollectBatch
Created Date       : [Insert Date]
@description       : This batch class is responsible for fetching and updating the status of InstaCollect payment 
                     transactions by making callouts to the Easebuzz InstaCollect API. It processes opportunities 
                     linked to units with virtual accounts and updates payment records with transaction details. 
                     The class implements Database.Batchable, Schedulable, and allows callouts.
@author            : Harshit Kumar Rai
Modification Log:
Ver   Date         Author                               Modification
1.0   [Insert Date] Harshit Kumar Rai                   Initial Version
*********************************************************
*/
global class PaymentTransactionInstaCollectBatch implements Database.Batchable<sObject>, Schedulable, Database.AllowsCallouts, Database.Stateful {
    private Decimal timeForRun = 2; // Default time interval for scheduling the next batch run

    /*
    *********************************************************
    @Method Name    : start
    @author         : Harshit Kumar Rai
    @description    : This method is the starting point of the batch process. It queries the custom metadata 
                       to determine the time interval for the next batch run and returns a QueryLocator for 
                       opportunities linked to units with virtual accounts.
    @param          : Database.BatchableContext BC - The context of the batch job.
    @return         : Database.QueryLocator - A query locator for opportunities to process.
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
        
        // Query opportunities linked to units with virtual accounts
        return Database.getQueryLocator([
            // More Filter Conditions Are Required For Optimization
            SELECT Id, Unit__c, Unit__r.Virtual_Account_Id__c,Contact_Email__c
            FROM Opportunity 
            WHERE Unit__c != null AND Unit__r.Virtual_Account_Id__c != null 
            AND Unit__r.Virtual_Account_Id__c != '' AND Unit__r.Status__c != 'Available'
            AND Unit__r.Status__c != 'Sold'
        ]);
    }

    /*
    *********************************************************
    @Method Name    : execute
    @author         : Harshit Kumar Rai
    @description    : This method processes a batch of opportunities, makes callouts to the Easebuzz InstaCollect API 
                       to fetch transaction details, and updates payment records and integration logs accordingly.
    @param          : Database.BatchableContext BC - The context of the batch job.
    @param          : List<Opportunity> oppRecords - The list of opportunities to process.
    ********************************************************
    */
    global void execute(Database.BatchableContext BC, List<Opportunity> oppRecords) {
        List<String> virtualAccountIdList = new List<String>();
        List<Payment__c> updatedPayments = new List<Payment__c>();
        List<Integration_Log__c> integrationLogs = new List<Integration_Log__c>();
        
        for (Opportunity opp : oppRecords) {
            // Call the Easebuzz InstaCollect API to fetch transaction details
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
                    
                    if (data.containsKey('results')) {
                        List<Object> results = (List<Object>) data.get('results');
                        for (Object resultObj : results) {
                            Map<String, Object> transactions = (Map<String, Object>) resultObj;
                            
                            // Extract transaction details
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
                            if (transactions.containsKey('virtual_account')) {
                                Map<String, Object> virtualAccount = (Map<String, Object>) transactions.get('virtual_account');
                                virtualAccountNumber = (String) virtualAccount.get('virtual_account_number');
                            }
                            
                            // Create or update payment record with transaction details
                            Payment__c payment = new Payment__c();
                            payment.InstaCollect_Transaction_Id__c = id;
                            if (status1 != null) {
                                payment.InstaCollect_Status__c = status1.substring(0, 1).toUpperCase() + status1.substring(1);
                            }
                            if (createdDate != null) {
                                payment.Payment_Created_Date__c = Datetime.valueOf(createdDate.substring(0, 19).replace('T', ' '));
                            }
                            payment.Payment_Updated_Date__c = System.now();
                            payment.Payment_Mode__c = paymentMode;
                            payment.Payment_Amount__c = amount;
                            if (transactionDateTime != null) {
                                payment.InstaCollect_Transaction_Date_Time__c = Datetime.valueOf(transactionDateTime.substring(0, 19).replace('T', ' '));
                            }
                            payment.Opportunity__c = opp.Id;
                            payment.InstaCollect_Transaction_Reference__c = uniqueTransactionReference;
                            payment.Remitter_Account_Number__c = remitterAccountNumber;
                            payment.Remitter_Account_IFSC__c = remitterAccountIfsc;
                            payment.Remitter_UPI_Handle__c = remitterUpiHandle;
                            payment.Remitter_Full_Name__c = remitterFullName;
                            payment.Remitter_Phone_Number__c = remitterPhoneNumber;
                            if (bankSettlementDate != null) {
                                payment.InstaCollect_Bank_Settlement_Date__c = Date.valueOf(bankSettlementDate);
                            }
                            if (settlementDate != null) {
                                payment.InstaCollect_Settlement_Date__c = Datetime.valueOf(settlementDate.substring(0, 19).replace('T', ' '));
                            }
                            payment.InstaCollect_Settled_By_Bank__c = is_settled_by_bank;
                            payment.InstaCollect_Narration__c = narration;
                            payment.Payment_Type__c = 'InstaCollect';
                            payment.Percent_Of_Amount_To_Refund__c = 100;
                            payment.Email_Address__c=opp.Contact_Email__c;
                            updatedPayments.add(payment);
                            virtualAccountIdList.add(id);
                            
                            // Log integration details if available
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
            } else {
                // Log integration details if the API call is unsuccessful
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
            List<Payment__c> paymentList = [SELECT Id, InstaCollect_Transaction_Id__c FROM Payment__c 
                                            WHERE InstaCollect_Transaction_Id__c IN :virtualAccountIdList];
            Map<String, String> transactionIdMap = new Map<String, String>();
            Map<String, String> idToEmailMap = new Map<String, String>();
            for (Payment__c payment : paymentList) {
                transactionIdMap.put(payment.InstaCollect_Transaction_Id__c, payment.Id);
            }
            for (Payment__c payment : updatedPayments) {
                if (transactionIdMap.containsKey(payment.InstaCollect_Transaction_Id__c)) {
                    payment.Id = transactionIdMap.get(payment.InstaCollect_Transaction_Id__c);
                }
                updatedPaymentList.add(payment);
            }
            if (!updatedPaymentList.isEmpty()) {
                upsert updatedPaymentList;
                List<Id> recordIds = new List<Id>();
                for (Payment__c p : updatedPaymentList) {
                    if (p.InstaCollect_Status__c == 'Received') {
                        recordIds.add(p.Id);
                        idToEmailMap.put(p.Id, p.Email_Address__c);
                    }
                }
                if (!recordIds.isEmpty()) {
                    List<Payment__c> pList = [Select Id,Opportunity__r.OwnerId From Payment__c Where Id IN:recordIds];
                    Map<String,String> paymentIdToOppOwnerId = New Map<String,String>();
                    if(pList!=null){
                        for(Payment__c p:pList){
                            paymentIdToOppOwnerId.put(p.Id,p.Opportunity__r.OwnerId);
                        }
                    }
                    submitForApproval(recordIds,paymentIdToOppOwnerId);
                    if(!idToEmailMap.isEmpty()){
                        System.enqueueJob(new PaymentReceiptQueueable(idToEmailMap, recordIds));
                    }
                }
            }
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
        System.schedule('PaymentTransactionInstaCollect ' + String.valueOf(Datetime.now()), cronExp, new PaymentTransactionInstaCollectBatch());
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
        Database.executeBatch(new PaymentTransactionInstaCollectBatch(), 10);
        System.abortJob(sc.getTriggerId());
    }

    /*
    *********************************************************
    @Method Name    : submitForApproval
    @author         : Harshit Kumar Rai
    @description    : This method submits payment records for approval if their status is 'Received'.
    @param          : List<Id> recordIds - The list of payment record IDs to submit for approval.
    ********************************************************
    */
    public static void submitForApproval(List<Id> recordIds, Map<String,String> paymentIdToOppOwnerId) {
        try {
            List<Approval.ProcessSubmitRequest> submitRequests = new List<Approval.ProcessSubmitRequest>();
            
            for (Id recordId : recordIds) {
                String userId='';
                if(paymentIdToOppOwnerId.ContainsKey(recordId)){
                    userId=paymentIdToOppOwnerId.get(recordId);
                }
                Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
                req.setObjectId(recordId);
                req.setComments('Approval Request For Payment');
                req.setNextApproverIds(null);
                req.setProcessDefinitionNameOrId('Payment_Approval_Process');
                if(userId!=''){
                    req.setSubmitterId(userId);
                }
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