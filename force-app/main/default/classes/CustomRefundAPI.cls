@RestResource(urlMapping='/CustomRefundAPI')
global with sharing class CustomRefundAPI {
    @HttpPost
    global static String handleRefundRequest(String txnid, Decimal amount, String email, String phone) {
        try {
            EasyCollectPayment.initiateRefund(txnid, amount, email, phone);
            return 'Refund initiated for transaction ID: ' + txnid;
        } catch (Exception ex) {
            throw new AuraHandledException('500 Refund processing failed: ' + ex.getMessage());
        }
    }
}