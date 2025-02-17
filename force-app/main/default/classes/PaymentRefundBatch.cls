/**
* Author: Harshit Kumar Rai
* Description: For Payment Refund Batch
*/
global class PaymentRefundBatch implements Database.Batchable<sObject>, Database.AllowsCallouts  {
    private List<Payment__c> paymentsToRefund;
    
    public PaymentRefundBatch(List<Payment__c> payments) {
        this.paymentsToRefund = payments;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([SELECT Id, Refund_Reason__c, Is_Refund_Success__c, Payment_Easepay_Id__c, Payment_Amount__c, Amount_To_Refund__c, Email_Address__c, Phone__c, Opportunity__c
                                         FROM Payment__c
                                         WHERE Id IN :paymentsToRefund]);
    }
    
    global void execute(Database.BatchableContext BC, List<Payment__c> paymentRecords) {
        
        Map<String, Payment__c> paymentMap = new Map<String, Payment__c>();
        for (Payment__c payment : paymentRecords) {
            paymentMap.put(payment.Payment_Easepay_Id__c, payment);
        }
        
        List<Payment__c> updatedPayments = new List<Payment__c>();
        List<String> oppIds = new List<String>();
        List<Integration_Log__c> integrationLogs = new List<Integration_Log__c>();
        
        for (String txnId : paymentMap.keySet()) {
            Payment__c payment = paymentMap.get(txnId);
            if (payment.Payment_Easepay_Id__c != null) {
                String apiResponse = EasyCollectPayment.initiateRefund(payment.Payment_Easepay_Id__c,payment.Amount_To_Refund__c,payment.Email_Address__c,payment.Phone__c,payment.Id);
                Map<String, Object> responseWrapper = (Map<String, Object>) JSON.deserializeUntyped(apiResponse);
                Boolean isSuccess = (Boolean) responseWrapper.get('isSuccess');
                String errorWrapper = (String) responseWrapper.get('error');
                String response = (String) responseWrapper.get('response');
                String integrationLogsStr = (String) responseWrapper.get('integrationLogs');
                if (isSuccess && String.isNotBlank(response)) {
                    try {
                        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response);
                        Boolean statusOfResponse = (Boolean) responseMap.get('status');
                        if (statusOfResponse ) {
                            String refundReason = (String) responseMap.get('reason');
                            Boolean status = (Boolean) responseMap.get('status');
                            payment.Is_Refund_Success__c=status;
            				payment.Refund_Reason__c=refundReason;
                            updatedPayments.add(payment);
                            oppIds.add(payment.Opportunity__c);
                            Integration_Log__c log = null;
                            if (String.isNotBlank(integrationLogsStr)) {
                                log = (Integration_Log__c) JSON.deserialize(integrationLogsStr, Integration_Log__c.class);
                                // integrationLogs.add(log);
                            }
                        }else{
                            payment.Refund_Reason__c=(String) responseMap.get('reason');
                            updatedPayments.add(payment);
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
        }
        if (!integrationLogs.isEmpty()) {
             insert integrationLogs;
        }
        if (!updatedPayments.isEmpty()) {
            update updatedPayments;
        }
        
        List<Opportunity> oppList = [Select Id,Contact__c,Contact__r.Email,Date_of_Cancellation__c From Opportunity Where ID IN:oppIds];
        for(Opportunity opp : oppList){
            opp.Date_of_Cancellation__c=System.Today();
        }
        if(oppList!=null){
            update oppList;
        }
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        EmailTemplate template = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'Plot_Cancellation_Email' LIMIT 1];
        for(Opportunity opp : oppList){
            	Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            	String recipientEmail = opp.Contact__r.Email;
                email.setToAddresses(new String[]{ recipientEmail });
                email.setTemplateId(template.Id);
                email.setTargetObjectId(opp.Contact__c); 
                email.setWhatId(opp.Id);
                email.setTreatTargetObjectAsRecipient(false);
                emails.add(email);
        }
        
        if (!emails.isEmpty()) {
        	Messaging.sendEmail(emails);
        }
    }
    
    global void finish(Database.BatchableContext BC) {
    }
}