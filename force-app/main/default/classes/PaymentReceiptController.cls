/*
*********************************************************
Apex Class Name    : PaymentReceiptController
Created Date       : 18th March 2024
@description       : For Payment Reciept Generation
@author            : Harshit Kumar Rai
*********************************************************
*/
public with sharing class PaymentReceiptController{
    
    public String todayDate { get; set; }
    public String customerName { get; set; }
    public String referenceId { get; set; }
    public String rupeesInWord { get ; set; }
    public Payment__c paymentRecord { get; set; }
    public String paymentDate { get; set; }
    
     /*
    *********************************************************
    @Constructor Name  : PaymentReceiptController
    @author            : Harshit Kumar Rai
    @description       : Initializes class and retrieves payment recieved details
    @param             : ApexPages.StandardController stdController - Standard controller for Payment__c
    ****
	*/
    
    public PaymentReceiptController(ApexPages.StandardController stdController) {
        String paymentId= Apexpages.currentPage().getParameters().get('id');
        List<Payment__c> paymentRecordList = [SELECT Id, Payment_Amount__c, Opportunity__r.Name, Contact_Name__r.Name, 
                                              Remitter_Full_Name__c, Opportunity__r.Plot_Name__c,
                                              Opportunity__r.Unit__r.Project__r.Name, Opportunity__r.Unit__r.Phase__r.Name, 
                                              Payment_Mode__c, InstaCollect_Transaction_Id__c, 
                                              Merchant_Transaction_Id__c, Payment_Created_Date__c, 
                                              InstaCollect_Transaction_Date_Time__c 
                                              FROM Payment__c Where Id=:paymentId];
        
        if(paymentRecordList!=null && !paymentRecordList.isEmpty()){
            paymentRecord=paymentRecordList[0];
            todayDate=String.ValueOf(DateTime.now().format('dd-MM-yyyy'));
            rupeesInWord=NumberToCharacter.getNumberTOWordConvertion(paymentRecord.Payment_Amount__c);
            if(paymentRecord.InstaCollect_Transaction_Id__c!=null){
                customerName=paymentRecord.Remitter_Full_Name__c;
                referenceId=paymentRecord.InstaCollect_Transaction_Id__c;
                paymentDate=String.ValueOf(paymentRecord.InstaCollect_Transaction_Date_Time__c.format('dd-MM-yyyy'));
            }else if(paymentRecord.Merchant_Transaction_Id__c!=null){
                customerName=paymentRecord.Contact_Name__r.Name;
                referenceId=paymentRecord.Merchant_Transaction_Id__c;
                paymentDate=String.ValueOf(paymentRecord.Payment_Created_Date__c.format('dd-MM-yyyy'));
            }
        }
        
    }
    
}