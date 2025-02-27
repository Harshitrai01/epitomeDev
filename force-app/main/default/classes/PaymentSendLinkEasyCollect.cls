/**
* Author: Harshit Kumar Rai
* Description: For Payment Send Link In Batches
*/
global class PaymentSendLinkEasyCollect implements Database.Batchable<sObject>, Database.AllowsCallouts{
    
    private List<Opportunity> oppList;
    public PaymentSendLinkEasyCollect(List<Opportunity> opp) {
        this.oppList=opp;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(
            [Select Id, Contact__c, Contact__r.Name, Contact__r.Email, Contact__r.Phone,
             First_Booking_Amount__c From Opportunity 
             Where Id IN :oppList AND Contact__c!=null AND First_Booking_Amount__c!=null]);
    }
    
    global void execute(Database.BatchableContext BC, List<Opportunity> oppRecords) {
        List<String>reponses = New List<String>();
        for(Opportunity opp: oppRecords){
            if(opp.Contact__c!=null && opp.Contact__r.Name!=null && opp.Contact__r.Email!=null && opp.Contact__r.Phone!=null){
                String res = JSON.serialize(EasyCollectPayment.createPaymentLink(opp.Contact__r.Name,String.ValueOf(opp.First_Booking_Amount__c),opp.Contact__r.Phone,opp.Contact__r.Email,'30', opp.Id, opp.Contact__c));
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res);
                Boolean status = (Boolean) responseMap.get('isSuccess');
                if(status){
                    String responseValue = (String) responseMap.get('response');
                    reponses.add(responseValue);
                }
            }
        }
        
        List<Id> oppListId = New List<Id>();
        Map<String,String> oppToEmail = New Map<String,String>();
        Map<String,String> oppToUrl = New Map<String,String>();
        List<Payment_Gateway__c> paymentListToInsert = New List<Payment_Gateway__c>();
        for(String res:reponses){
            try {
                Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(res);
                Boolean status = (Boolean) data.get('status');
                if(status){
                    String createdDate = (String) data.get('created_date');
                    String updatedDate = (String) data.get('updated_date');
                    String email = (String) data.get('email');
                    String paymentUrl = (String) data.get('payment_url');
                    String oppId = (String) data.get('oppId');
                    oppListId.add(oppId);
                    oppToUrl.put(oppId,paymentUrl);
                    oppToEmail.put(oppId,email);
                    //Percent_Of_Amount_To_Refund__c=100,
                    Payment_Gateway__c payment = new Payment_Gateway__c(
                        Payment_Amount__c = Decimal.valueOf((String) data.get('amount')),
                        Email_Address__c = email,
                        Merchant_Transaction_Id__c = (String) data.get('merchant_txn'),
                        Opportunity__c = (String) data.get('oppId'),
                        Payment_Created_Date__c = Datetime.valueOf(createdDate.substring(0, 19).replace('T', ' ')),
                        Payment_Updated_Date__c = Datetime.valueOf(updatedDate.substring(0, 19).replace('T', ' ')),
                        Payment_Expiry_Date__c = (String) data.get('expiry_date'),
                        Payment_Id__c = String.ValueOf(data.get('id')),
                        Payment_Status__c = (String) data.get('state'),
                        Payment_URL__c = paymentUrl,
                        Contact_Name__c = (String) data.get('contactId'),
                        Payment_Type__c = 'EasyCollect',
                        Phone__c=(String) data.get('phone')
                    );
                    paymentListToInsert.add(payment);
                }
            } catch (Exception e) {
                System.debug('Error inserting payment record: ' + e.getMessage());
                throw new AuraHandledException('Failed to insert payment record: ' + e.getMessage());
            }
        }
        
        List<Opportunity> oppListForSendingMail = [Select Id, Name, Unit__r.Virtual_Account_Name__c, Unit__r.Virtual_Account_Number__c,
                                                   Unit__r.Virtual_Account_UPI__c, Unit__r.Virtual_Account_IFSC__c,
                                                   Unit__r.UPI_QR_Image__c,Unit__r.Name,First_Booking_Amount__c,Unit__r.Phase__r.Name
                                                   From Opportunity Where Id IN :oppListId];
        
        List<PaymentDetails> paymentDetailsList = New List<PaymentDetails>();
        for(Opportunity opp:oppListForSendingMail){
            String email = oppToEmail.get(opp.Id);
            String paymentUrl = oppToUrl.get(opp.Id);
            PaymentDetails pd = New PaymentDetails();
            pd.recipientEmail=email;
            pd.paymentLink=paymentUrl;
            pd.accountName=opp.Unit__r.Virtual_Account_Name__c;
            pd.accountNumber=opp.Unit__r.Virtual_Account_Number__c;
            pd.ifscCode=opp.Unit__r.Virtual_Account_IFSC__c;
            pd.upiId=opp.Unit__r.Virtual_Account_UPI__c;
            pd.qrImageUrl=opp.Unit__r.UPI_QR_Image__c;
            pd.plotName=opp.Unit__r.Name;
            pd.phaseName=opp.Unit__r.Phase__r.Name;
            pd.firstAmount=opp.First_Booking_Amount__c;
            paymentDetailsList.add(pd);
        }
        
        if(!paymentListToInsert.isEmpty()){
            insert paymentListToInsert;
            
            List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
            
            for (PaymentDetails details : paymentDetailsList) {
                try {
                    EmailTemplate template = [SELECT HtmlValue FROM EmailTemplate WHERE DeveloperName = 'Terms_and_Conditions' LIMIT 1];
                    String termsAndConditions = template.HtmlValue;
                    if(details.phaseName==null){
                        details.phaseName='';
                    }
                    if(details.plotName==null){
                        details.plotName='';
                    }
                    if (termsAndConditions != null) {
                        termsAndConditions = termsAndConditions
                            .replace('{!Opportunity.Phase_Name__c}', details.phaseName)
                            .replace('{!Opportunity.Plot_Name__c}', details.plotName)
                            .replace('{!Opportunity.First_Booking_Amount__c}', String.ValueOf(details.firstAmount));
                    }
                    
                    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                    email.setToAddresses(new String[]{details.recipientEmail});
                    email.setSubject('Payment Link - Epitome Projects LLP');
                    
                    String htmlBody;
                    if (details.accountNumber != null) {
                        htmlBody = '<html>'
                            + '<body style="font-family: Arial, sans-serif; font-size: 16px; color: #333; background-color: #f9f9f9; padding: 20px;">'
                            + '<div style="max-width: 500px; margin: auto; background: #fff; padding: 20px; border-radius: 8px; box-shadow: 0px 0px 10px rgba(0, 0, 0, 0.1);">'
                            + '<p style="font-size: 18px; font-weight: bold;">Dear Customer,</p>'
                            + '<p style="color: #555;">Please find below your payment details:</p>'
                            + '<div style="padding: 15px; background: #f3f3f3; border-radius: 8px;">'
                            + '<p><strong>📌 Account Name:</strong> ' + details.accountName + '</p>'
                            + '<p><strong>🏦 Account Number:</strong> ' + details.accountNumber + '</p>'
                            + '<p><strong>🏷️ IFSC Code:</strong> ' + details.ifscCode + '</p>'
                            + '<p><strong>💳 UPI ID:</strong> ' + details.upiId + '</p>'
                            + '</div>'
                            + '<div style="text-align: center; margin: 20px 0;">'
                            + '<p><strong>Scan to Pay:</strong></p>'
                            + '<img src="' + details.qrImageUrl + '" alt="QR Code" width="180" height="180" style="border-radius: 8px;">'
                            + '</div>'
                            + '<div style="text-align: center;">'
                            + '<a href="' + details.paymentLink + '" style="display: inline-block; padding: 12px 20px; background-color: #28a745; color: #fff; text-decoration: none; border-radius: 5px; font-size: 16px; font-weight: bold;">🔗 Click to Pay</a>'
                            + '</div>'
                            + '<p style="margin-top: 20px;"><strong>Warm Regards,</strong><br/>Epitome Projects LLP</p>'
                            + '</div>'
                            + '<hr style="margin: 20px 0; border: 0; border-top: 1px solid #ddd;">'
        					+ '<div style="font-size: 14px; color: #777;">' + termsAndConditions + '</div>'
                            + '</body></html>';
                    } else {
                        htmlBody = '<html>'
                            + '<body style="font-family: Arial, sans-serif; font-size: 16px; color: #333; background-color: #f9f9f9; padding: 20px;">'
                            + '<p style="font-size: 18px; font-weight: bold;">Dear Customer,</p>'
                            + '<div style="text-align: left;">'
                            + '<p style="color: #555;">Please click here to complete your transaction:</p>'
                            + '<a href="' + details.paymentLink + '" style="display: inline-block; padding: 12px 20px; background-color: #28a745; color: #fff; text-decoration: none; border-radius: 5px; font-size: 16px; font-weight: bold;">🔗 Click to Pay</a>'
                            + '</div>'
                            + '<p style="margin-top: 20px;"><strong>Warm Regards,</strong><br/>Epitome Projects LLP</p>'
                            + '</div>'
                            + '<hr style="margin: 20px 0; border: 0; border-top: 1px solid #ddd;">'
        					+ '<div style="font-size: 14px; color: #777;">' + termsAndConditions + '</div>'
                            + '</body></html>';
                    }
                    email.setHtmlBody(htmlBody);
                    emails.add(email);
                } catch (Exception ex) {
                    System.debug('Error in preparing email: ' + ex.getMessage());
                }
            }
            
            if (!emails.isEmpty()) {
                Messaging.sendEmail(emails);
            }
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        
    }
    
    public class ResponseWrapper {
        @AuraEnabled
        public Boolean isSuccess;
        @AuraEnabled
        public String error;
        @AuraEnabled
        public String response;
        public String integrationLogs;
    }
    
    public class PaymentDetails {
        public String recipientEmail;
        public String paymentLink;
        public String accountName;
        public String accountNumber;
        public String ifscCode;
        public String upiId;
        public String qrImageUrl;
        public String plotName;
        public String phaseName;
        public Decimal firstAmount;
    }
    
}