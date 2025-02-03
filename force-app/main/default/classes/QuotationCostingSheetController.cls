public with sharing class QuotationCostingSheetController {

    @AuraEnabled
    public static void SaveRecord(List<Quote__c> quoteRecords) {
        try {
            if (quoteRecords != null && !quoteRecords.isEmpty()) {
                update quoteRecords;
                if(!quoteRecords[0].IsSample__c){
                    submitForApproval(quoteRecords[0].Id);
				}
            }
        }
        catch(Exception ex) {
            throw new AuraHandledException('Error updating Quote__c records: ' + ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static void submitForApproval(Id recordId) {
        try {
            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            req.setObjectId(recordId);
            req.setComments('Quote Approval Request.');
            req.setNextApproverIds(null);
            req.setProcessDefinitionNameOrId('Quote_Approval_Process');

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
    
    @AuraEnabled
    public static void FinalizeQuote(List<Quote__c> quoteRecords) {
        try {
            if (quoteRecords != null && !quoteRecords.isEmpty()) {
                update quoteRecords;
            }
        }
        catch(Exception ex) {
            throw new AuraHandledException('Error updating Quote__c records: ' + ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static void sendQuoteEmail(Id quoteId, String recipientEmail, String name) {
        try {
            
            PageReference pdfPage = Page.QuotePdf;
            pdfPage.getParameters().put('id', quoteId);
            Blob pdfBlob = pdfPage.getContentAsPDF();
            
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[] { recipientEmail });
            email.setSubject('Quote: ' + name);
            email.setPlainTextBody('Please find the attached quote PDF for your reference.');
            
            // Attach the PDF
            Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
            attachment.setFileName('Quote_' + name + '.pdf');
            attachment.setBody(pdfBlob);
            attachment.setContentType('application/pdf');
            email.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });
            
            // Send the email
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
            System.debug('Email sent successfully with the PDF attachment.');
        } catch (Exception ex) {
            throw new AuraHandledException('Error sending quote email: ' + ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=false)
    public static lightningResponseWrapper getQuote(String recordId) {
        try {
            String unitId;
            String queryString;
            String phaseId;
            String projectId;
            Quote__c quoteObj = [
                SELECT Id,Name,IsQuoteGenerated__c,Plot__c,Phase__c,Project__c,IsSample__c,CreatedDate,Lead__r.Name,
                Lead__r.Phase__r.Name,Plot__r.Name,Plot__r.Plot_Facing__c,Plot__r.Plot_Size__c,Plot__r.Flat_Number__c,
                Plot__r.Floor_Number__c,Plot__r.Unit_Code__c,Lead__r.Project__r.Project_Type__c,Plot__r.Base_Price_per_Sq_Ft__c,
                Plot_Dimension__c,Total_Basic_Cost__c,Total_Gst_For_Charge__c,Total_Charge_Amount__c,AgreementValueWithGst__c,
                Base_Price_Per_Sq_Yard__c,Price_For_North_East__c,Other_Corners__c,East__c,X100_Ft_Road_Plots__c,Premium_Plots__c,
                Rate_Per_Sq_Yd__c,Corpus_Fund_and_Club_House_Payable__c,Legal_And_Documentation_Charges__c,Registration_Charges__c,
                IsLocked__c,Approval_Status__c,Lead__r.Email
                FROM Quote__c where Id =: recordId 
            ];
            
            List<Additional_Charges__c> additonalCharges = new List<Additional_Charges__c>();
            String plotId='';
            plotId=quoteObj.Plot__c;
            if(plotId!=null && plotId!=''){
                additonalCharges = [Select Id,Plot__c,Additional_Charges__c,Values__c,Charges__c From Additional_Charges__c
									Where Plot__c=:plotId];
            }
            
            if(quoteObj!= null) {
                if(quoteObj.IsQuoteGenerated__c){
                    lightningResponseWrapper quoteWrapObj = new lightningResponseWrapper();
                    quoteWrapObj.isSuccess = true;
                    quoteWrapObj.quoteObj = quoteObj;
                    quoteWrapObj.additonalCharges=additonalCharges;
                    return quoteWrapObj;
                }else{
                    unitId = quoteObj.Plot__c;
                    phaseId = quoteObj.Phase__c;
                    projectId = quoteObj.Project__c;
                    lightningResponseWrapper quoteWrapObj = new lightningResponseWrapper();
                    quoteWrapObj.isSuccess = true;
                    quoteWrapObj.quoteObj = quoteObj;
                    quoteWrapObj.additonalCharges=additonalCharges;
                    return quoteWrapObj;
                }
            }
            return null;
        }
        catch(Exception Error) {
            lightningResponseWrapper quoteWrapObj = new lightningResponseWrapper();
            quoteWrapObj.isSuccess = false;
            quoteWrapObj.message = Error.getMessage();
            return quoteWrapObj;
        }
    }
    
    public class lightningResponseWrapper {
        @AuraEnabled
        public  Boolean isSuccess {get;set;}
        @AuraEnabled
        public  String message {get;set;}
        @AuraEnabled
        public Quote__c quoteObj {get; set;}
        @AuraEnabled
        public List<Additional_Charges__c> additonalCharges {get; set;}
    }


}