/*
*********************************************************
Apex Class Name    : EasebuzzWebhookHandler
Created Date       : 18th March 2025
@description       : This class is used to handle incoming webhook requests from Easebuzz. It processes transaction 
                     responses and updates the corresponding payment records in Salesforce.
@author            : Harshit Rai
Modification Log:
Ver   Date         Author               Modification
1.0   [Insert Date] Harshit Rai         Initial Version
*********************************************************
*/
@RestResource(urlMapping='/EasebuzzWebhook')
global class EasebuzzWebhookHandler {

    /*
    *********************************************************
    @Method Name    : handleTransactionResponse
    @author         : Harshit Rai
    @description    : Handles incoming POST requests from the Easebuzz webhook. It processes transaction data and updates 
                       the corresponding payment record with the transaction status, mode, easepay ID, and error message.
    *********************************************************
    */
    //@HttpPost
    global static void handleTransactionResponse() {
        // Get the request and response objects
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
		/*
        // Extract transaction data from the request parameters
        Map<String, String> transactionData = req.params;
        String txnId = (String) transactionData.get('txnid');
        String mode = (String) transactionData.get('mode');
        String status = (String) transactionData.get('status');
        String error = (String) transactionData.get('error');
        String easepayId = (String) transactionData.get('easepayid');
        String errorMessage = (String) transactionData.get('error_Message');
		*/
        try {
            // Query the payment record using the transaction ID
            /*
            List<Payment__c> paymentList = [
                SELECT Payment_Status__c, Payment_Mode__c, Id, Payment_Easepay_Id__c, 
                       Is_Webhook__c, Error_Message__c, Merchant_Transaction_Id__c 
                FROM Payment__c 
                WHERE Merchant_Transaction_Id__c = :txnId 
                LIMIT 1
            ];*/

            // Update the payment record with the transaction details
            /*
            if (paymentList != null && !paymentList.isEmpty()) {
                paymentList[0].Payment_Status__c = status;
                paymentList[0].Payment_Mode__c = mode;
                paymentList[0].Payment_Easepay_Id__c = easepayId;
                paymentList[0].Is_Webhook__c = true;
                paymentList[0].Error_Message__c = errorMessage;
                update paymentList;
            }*/
        } catch (Exception e) {
            // Log the error and return a 500 status code
            System.debug('🚨 Error updating payment record: ' + e.getMessage());
            RestContext.response.statusCode = 500;
            return;
        }

        // Return a 200 status code for successful processing
        RestContext.response.statusCode = 200;
    }
}