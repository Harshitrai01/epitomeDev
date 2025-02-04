//@RestResource(urlMapping='/EasebuzzWebhook')
global class EasebuzzWebhookHandler {
    //@HttpPost
    global static void handleTransactionResponse() {
        
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        
        Map<String, String> transactionData = req.params;
        String txnId = (String) transactionData.get('txnid');
        String mode = (String) transactionData.get('mode');
        String status = (String) transactionData.get('status');
        String error = (String) transactionData.get('error');
        String easepayId = (String) transactionData.get('easepayid');
        String errorMessage = (String) transactionData.get('error_Message');
        
        try{
            List<Payment__c> paymentList = new List<Payment__c>();
            paymentList = [Select Payment_Status__c,Payment_Mode__c,Id,Payment_Easepay_Id__c,Is_Webhook__c,
                           Error_Message__c, Merchant_Transaction_Id__c From Payment__c
                           Where Merchant_Transaction_Id__c=:txnId Limit 1
                          ];
            if(paymentList!=null && !paymentList.isEmpty()){
                paymentList[0].Payment_Status__c=status;
                paymentList[0].Payment_Mode__c=mode;
                paymentList[0].Payment_Easepay_Id__c=easepayId;
                paymentList[0].Is_Webhook__c=true;
                paymentList[0].Error_Message__c=errorMessage;
                update paymentList;
            }
        }catch(Exception e){
            System.debug('🚨 Error updating payment record: ' + e.getMessage());
            RestContext.response.statusCode = 500; 
            return;
        }
        
        RestContext.response.statusCode = 200;
    }
}