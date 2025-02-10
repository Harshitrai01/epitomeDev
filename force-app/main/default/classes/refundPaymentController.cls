public class refundPaymentController {
    @AuraEnabled
    public static void getPaymentsByOpportunity(Id opportunityId) {
        List<Payment__c> payments = new List<Payment__c>();
        String error='';
        try {
            if (String.isEmpty(opportunityId)) {
                error='Opportunity ID is required.';
                throw new AuraHandledException(error);
            }
            payments = [
                SELECT Id, Name, Payment_Status__c, Approval_Status__c, Payment_Amount__c, Payment_Easepay_Id__c, Email_Address__c,Is_Refund_Success__c, Phone__c FROM Payment__c 
                WHERE Opportunity__c=:opportunityId AND Payment_Status__c='success' AND Approval_Status__c='Approved' AND Is_Refund_Success__c=false
            ];
            for (Payment__c payment : payments) {
                List<String> missingFields = new List<String>();
                if (String.isBlank(payment.Payment_Easepay_Id__c)) {
                    missingFields.add('Easepay Id');
                }
                if (payment.Payment_Amount__c == null) {
                    missingFields.add('Payment Amount');
                }
                if (String.isBlank(payment.Email_Address__c)) {
                    missingFields.add('Email Address');
                }
                if (String.isBlank(payment.Phone__c)) {
                    missingFields.add('Phone Number');
                }
                if (!missingFields.isEmpty()) {
                    error = 'Payment ' + payment.Name + ' is missing: ' + String.join(missingFields, ', ');
                    throw new AuraHandledException(error);
                }
            }
            
            if (!payments.isEmpty()) {
                PaymentRefundBatch refundBatch = new PaymentRefundBatch(payments);
                Database.executeBatch(refundBatch, 20);
            }
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage()+' : '+error);
        }
    }
    
    @AuraEnabled
    public static void submitForApproval(Id recordId) {
        try {
            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            req.setObjectId(recordId);
            req.setComments('Refund Approval Request');
            req.setNextApproverIds(null);
            req.setProcessDefinitionNameOrId('Opportunity_Refund_Approval_Process');

            Approval.ProcessResult result = Approval.process(req);
            if (result.isSuccess()) {
                System.debug('Approval process successfully triggered for record ID: ' + recordId);
            } else {
                throw new AuraHandledException('Approval process failed to start.');
            }
        } catch (Exception ex) {
            throw new AuraHandledException('Error triggering approval process: ' + ex.getMessage());
        }
    }
}