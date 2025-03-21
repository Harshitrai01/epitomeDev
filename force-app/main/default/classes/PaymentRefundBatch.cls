/**
*********************************************************
Apex Class Name    : PaymentRefundBatch
Created Date       : March 18, 2025
@description       : Batch class to process payment refunds.
                     - Uses EasyCollectPayment API to initiate refunds.
                     - Updates payment records and logs integration details.
                     - Sends email notifications for cancellations.
@author            : Harshit Kumar Rai
Modification Log:
Ver   Date         Author                         Modification
1.0   18-03-2025   Harshit Kumar Rai             Initial Version
*********************************************************
*/
global class PaymentRefundBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {
    
    // List to store payments that need to be refunded
    private List<Payment__c> paymentsToRefund;
    
    /**
    *********************************************************
    @Method Name    : Constructor
    @description    : Initializes the batch class with a list of Payment records.
    @param          : payments - List of Payment__c records to be processed.
    *********************************************************
    */
    public PaymentRefundBatch(List<Payment__c> payments) {
        this.paymentsToRefund = payments;
    }
    
    /**
    *********************************************************
    @Method Name    : start
    @description    : QueryLocator method that retrieves Payment records
                      from the provided list for batch processing.
    @param          : Database.BatchableContext BC
    @return         : Database.QueryLocator
    *********************************************************
    */
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id, Refund_Reason__c, Is_Refund_Success__c, 
                   Payment_Easepay_Id__c, Payment_Amount__c, 
                   Amount_To_Refund__c, Email_Address__c, 
                   Phone__c, Opportunity__c
            FROM Payment__c
            WHERE Id IN :paymentsToRefund
        ]);
    }
    
    /**
    *********************************************************
    @Method Name    : execute
    @description    : Processes each batch of Payment records.
                      - Initiates refund requests.
                      - Updates Payment records with refund details.
                      - Logs integration data.
                      - Sends email notifications for cancellations.
    @param          : Database.BatchableContext BC
                      paymentRecords - List of Payment__c records.
    @return         : None
    *********************************************************
    */
    global void execute(Database.BatchableContext BC, List<Payment__c> paymentRecords) {
        
        // Map to store Payment records by their Easepay ID
        Map<String, Payment__c> paymentMap = new Map<String, Payment__c>();
        for (Payment__c payment : paymentRecords) {
            paymentMap.put(payment.Payment_Easepay_Id__c, payment);
        }
        
        List<Payment__c> updatedPayments = new List<Payment__c>();
        List<String> oppIds = new List<String>();
        List<Integration_Log__c> integrationLogs = new List<Integration_Log__c>();
        
        // Iterate through payments to process refunds
        for (String txnId : paymentMap.keySet()) {
            Payment__c payment = paymentMap.get(txnId);
            
            // Ensure Easepay ID is present before processing
            if (payment.Payment_Easepay_Id__c != null) {
                // Call EasyCollectPayment API for refund processing
                String apiResponse = EasyCollectPayment.initiateRefund(
                    payment.Payment_Easepay_Id__c, 
                    payment.Amount_To_Refund__c, 
                    payment.Email_Address__c, 
                    payment.Phone__c, 
                    payment.Id
                );
                
                // Deserialize API response into a map
                Map<String, Object> responseWrapper = 
                    (Map<String, Object>) JSON.deserializeUntyped(apiResponse);
                Boolean isSuccess = (Boolean) responseWrapper.get('isSuccess');
                String errorWrapper = (String) responseWrapper.get('error');
                String response = (String) responseWrapper.get('response');
                String integrationLogsStr = (String) responseWrapper.get('integrationLogs');
                
                // Process successful refunds
                if (isSuccess && String.isNotBlank(response)) {
                    try {
                        Map<String, Object> responseMap = 
                            (Map<String, Object>) JSON.deserializeUntyped(response);
                        Boolean statusOfResponse = (Boolean) responseMap.get('status');
                        
                        if (statusOfResponse) {
                            // Successful refund details
                            String refundReason = (String) responseMap.get('reason');
                            Boolean status = (Boolean) responseMap.get('status');
                            payment.Is_Refund_Success__c = status;
                            payment.Refund_Reason__c = refundReason;
                            updatedPayments.add(payment);
                            oppIds.add(payment.Opportunity__c);
                            
                            // Handle integration logs
                            if (String.isNotBlank(integrationLogsStr)) {
                                Integration_Log__c log = 
                                    (Integration_Log__c) JSON.deserialize(integrationLogsStr, Integration_Log__c.class);
                            }
                        } else {
                            // Handle unsuccessful refunds
                            payment.Refund_Reason__c = (String) responseMap.get('reason');
                            updatedPayments.add(payment);
                            
                            // Handle integration logs
                            if (String.isNotBlank(integrationLogsStr)) {
                                Integration_Log__c log = 
                                    (Integration_Log__c) JSON.deserialize(integrationLogsStr, Integration_Log__c.class);
                                integrationLogs.add(log);
                            }
                        }
                    } catch (Exception e) {
                        System.debug('Error parsing response: ' + e.getMessage());
                    }
                } else {
                    // Handle unsuccessful API responses
                    if (String.isNotBlank(integrationLogsStr)) {
                        Integration_Log__c log = 
                            (Integration_Log__c) JSON.deserialize(integrationLogsStr, Integration_Log__c.class);
                        integrationLogs.add(log);
                    }
                }
            }
        }

        // Insert Integration Logs if present
        if (!integrationLogs.isEmpty()) {
            insert integrationLogs;
        }

        // Update Payment records if changes were made
        if (!updatedPayments.isEmpty()) {
            update updatedPayments;
        }
        
        // Process related Opportunities for cancellation updates
        List<Opportunity> oppList = [
            SELECT Id, Contact__c, Contact__r.Email, Date_of_Cancellation__c 
            FROM Opportunity 
            WHERE ID IN :oppIds
        ];

        for (Opportunity opp : oppList) {
            opp.Date_of_Cancellation__c = System.Today();
        }

        if (oppList != null) {
            update oppList;
        }

        // Prepare and send email notifications for cancellations
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        EmailTemplate template = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'Plot_Cancellation_Email' LIMIT 1];
        
        for (Opportunity opp : oppList) {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            String recipientEmail = opp.Contact__r.Email;
            email.setToAddresses(new String[]{ recipientEmail });
            email.setTemplateId(template.Id);
            email.setTargetObjectId(opp.Contact__c);
            email.setWhatId(opp.Id);
            email.setTreatTargetObjectAsRecipient(false);
            emails.add(email);
        }
        
        // Send prepared emails
        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
    }

    /**
    *********************************************************
    @Method Name    : finish
    @description    : Final method in the batch lifecycle.
                      Used for logging, cleanup, or post-processing.
    @param          : Database.BatchableContext BC
    @return         : None
    *********************************************************
    */
    global void finish(Database.BatchableContext BC) {
        // Add any completion logic here if needed
    }
}