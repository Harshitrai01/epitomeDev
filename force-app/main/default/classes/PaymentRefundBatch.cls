global class PaymentRefundBatch implements Database.Batchable<sObject> {
    private List<Payment__c> paymentsToRefund;

    public PaymentRefundBatch(List<Payment__c> payments) {
        this.paymentsToRefund = payments;
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([SELECT Id, Payment_Easepay_Id__c, Payment_Amount__c, Email_Address__c, Phone__c 
                                         FROM Payment__c
                                         WHERE Id IN :paymentsToRefund]);
    }

    global void execute(Database.BatchableContext BC, List<Payment__c> paymentRecords) {
        for (Payment__c payment : paymentRecords) {
            if (payment.Payment_Easepay_Id__c != null) {
                EasyCollectPayment.initiateRefund(payment.Payment_Easepay_Id__c, 
                                                  payment.Payment_Amount__c, 
                                                  payment.Email_Address__c, 
                                                  payment.Phone__c, 
                                                  payment.Id);
            }
        }
    }

    global void finish(Database.BatchableContext BC) {
        System.debug('Batch process completed.');
    }
}