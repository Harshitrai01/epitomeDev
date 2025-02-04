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
                SELECT Id, Name, Payment_Status__c, Approval_Status__c, Payment_Amount__c, Payment_Easepay_Id__c, Email_Address__c, Phone__c FROM Payment__c 
                WHERE Opportunity__c=:opportunityId AND Payment_Status__c='success' AND Approval_Status__c='Approved'
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
                Database.executeBatch(refundBatch, 10);
            }
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage()+' : '+error);
        }
    }
    
    @AuraEnabled
    public static String processBulkRefund(List<Payment__c> paymentList) {
        if (paymentList == null || paymentList.isEmpty()) {
            throw new AuraHandledException('No payments to process for refund.');
        }
        
        List<Map<String, Object>> requests = new List<Map<String, Object>>();
        Integer requestId = 1;
        
        for (Payment__c payment : paymentList) {
            Map<String, Object> req = new Map<String, Object>{
                'method' => 'POST',
                    'url' => '/services/apexrest/CustomRefundAPI',
                    'referenceId' => 'refund' + requestId,
                    'body' => new Map<String, Object>{
                        'txnid' => payment.Payment_Easepay_Id__c,
                            'amount' => 120.0,
                            'refund_amount' => 120.0,
                            'email' => payment.Email_Address__c,
                            'phone' => payment.Phone__c
                            }
            };
            requests.add(req);
            requestId++;
        }
        
        Map<String, Object> compositeRequest = new Map<String, Object>{ 'allOrNone' => false, 'compositeRequest' => requests };
            
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(System.Url.getOrgDomainUrl().toExternalForm() + '/services/data/v60.0/composite');
        request.setMethod('POST');
        request.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
        request.setHeader('Content-Type', 'application/json');
        request.setBody(JSON.serialize(compositeRequest));
        System.debug('Composite Reques-->>'+JSON.serialize(compositeRequest));
        HttpResponse response = http.send(request);
        
        if (response.getStatusCode() == 200) {
            return 'Success';
        } else {
            throw new AuraHandledException('Failed to process refunds: ' + response.getBody());
        }
    }
}