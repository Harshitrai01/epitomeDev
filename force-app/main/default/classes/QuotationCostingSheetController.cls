/*
*********************************************************
Apex Class Name    : QuotationCostingSheetController
Created Date       : July 12, 2020
@description       : For generating quotation costing sheet
@author            : Harshit Kumar Rai
*********************************************************
*/
public with sharing class QuotationCostingSheetController {
    /*
    *********************************************************
    @Method Name    : SaveRecord
    @author         : Harshit Kumar Rai
    @description    : Method to save Quote records
    @param          : List<Quote__c> quoteRecords - List of quote records to save
    @return         : List<Quote__c> - List of updated quote records
    *********************************************************
    */

    @AuraEnabled
    public static List<Quote__c> SaveRecord(List<Quote__c> quoteRecords) {
        try {
            if (quoteRecords != null && !quoteRecords.isEmpty()) {
                upsert quoteRecords;
                List<Quote__c> quoteList = [Select Id,Total_Sale_Value__c,Base_Price_Per_Sq_Yard__c From Quote__c Where Id IN: quoteRecords];
                return quoteList;
            }else{
                return null;
            }
        }
        catch(Exception ex) {
            throw new AuraHandledException('Error updating Quote__c records: ' + ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static void SaveOpportunityRecord(List<Opportunity>oppList) {
        try {
            if (oppList != null && !oppList.isEmpty() && !String.isBlank(oppList[0].Id) && oppList[0].Sale_Value_Amount__c!=null) {
                String oppId= (String) oppList[0].Id;
                Opportunity opp = [Select Id,Unit__c From Opportunity Where Id=:oppId];
                String oldPlotId='';
                String newPlotId='';
                if(opp!=null){
                    oldPlotId=opp.Unit__c;
                    newPlotId= (String) oppList[0].Unit__c;
                }
                update oppList;
                if(oldPlotId!='' && newPlotId!='' && oldPlotId!=newPlotId){
                    List<Unit__c> plotToUpdate=[Select Id,Status__c From Unit__c Where ID=:newPlotId OR ID=:oldPlotId Limit 2];
                    List<Unit__c> updatedPlots = New List<Unit__c>();
                    if(plotToUpdate!=null){
                        for(Unit__c plot:plotToUpdate){
                            if(plot.Id==newPlotId){
                                plot.Status__c='Blocked';
                            }else if(plot.Id==oldPlotId){
                                plot.Status__c='Available';
                            }
                            updatedPlots.add(plot);
                        }
                        if(!updatedPlots.isEmpty()){
                            update updatedPlots;
                        }
                    }
                    
                }
            }
        }
        catch(Exception ex) {
            throw new AuraHandledException('Error updating Quote__c records: ' + ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static void savePlot(List<Unit__c> plotRecords) {
        try {	
            if(plotRecords!=null && !plotRecords.isEmpty()){
                update plotRecords;
            }
        } catch (Exception ex) {
            throw new AuraHandledException('Error In Saving Plot Record: ' + ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static void submitForApproval(Id recordId, String userId) {
        try {
            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            req.setObjectId(recordId);
            req.setComments('Quote Approval Request');
            req.setNextApproverIds(null);
            req.setProcessDefinitionNameOrId('Quote_Approval_Process');
            if(userId!=''){
                List<User> userList = [Select Id From User Where ID=:userId Limit 1];
                if(userList!=null && !userList.isEmpty()){
                    req.setSubmitterId(userId);
                }
            }

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
    public static void FinalizeQuote(List<Quote__c> quoteRecord) {
        try {
            if (quoteRecord != null && !quoteRecord.isEmpty()) {
                update quoteRecord;
                String quoteId = (String) quoteRecord[0].Id;
                
                List<Quote__c> quoteRecords = [Select Id,Plot__c,Rate_Per_Sq_Yd__c,Premium_Plots__c,East__c,Registration_Charges__c,
                                               Corpus_Fund_and_Club_House_Payable__c,Other_Corners__c,Legal_And_Documentation_Charges__c,
                                               Price_For_North_East__c,X100_Ft_Road_Plots__c
                                               From Quote__c Where Id=:quoteId];
                // For Updating Additonal Charges
                String plotId ='';
                if(quoteRecords[0].Plot__c!=null){
                    plotId=(String) quoteRecords[0].Plot__c;
                    List<Additional_Charges__c> additonalCharges = new List<Additional_Charges__c>();
                    List<Additional_Charges__c> additonalChargesToUpdate = new List<Additional_Charges__c>();
                    if(plotId!=null && plotId!=''){
                        additonalCharges = [Select Id,Plot__c,Additional_Charges__c,Values__c,Charges__c,Final_Charges__c From Additional_Charges__c
                                            Where Plot__c=:plotId];
                        if(additonalCharges!=null && !additonalCharges.isEmpty()){
                            for(Additional_Charges__c adc : additonalCharges){
                                if(adc.Values__c=='100 Ft Road Plots' && quoteRecords[0].X100_Ft_Road_Plots__c != null){
                                    adc.Final_Charges__c=quoteRecords[0].X100_Ft_Road_Plots__c;
                                }else if(adc.Values__c=='Price For North East' && quoteRecords[0].Price_For_North_East__c != null){
                                    adc.Final_Charges__c=quoteRecords[0].Price_For_North_East__c;
                                }else if(adc.Values__c=='Legal And Documentation Charges' && quoteRecords[0].Legal_And_Documentation_Charges__c != null){
                                    adc.Final_Charges__c=quoteRecords[0].Legal_And_Documentation_Charges__c;
                                }else if(adc.Values__c=='Other Corners' && quoteRecords[0].Other_Corners__c != null){
                                    adc.Final_Charges__c=quoteRecords[0].Other_Corners__c;
                                }else if(adc.Values__c=='Corpus Fund and Club House Payable' && quoteRecords[0].Corpus_Fund_and_Club_House_Payable__c != null){
                                    adc.Final_Charges__c=quoteRecords[0].Corpus_Fund_and_Club_House_Payable__c;
                                }else if(adc.Values__c=='Registration Charges As Applicable On The Day Of Registration' && quoteRecords[0].Registration_Charges__c != null){
                                    adc.Final_Charges__c=quoteRecords[0].Registration_Charges__c;
                                }else if(adc.Values__c=='East' && quoteRecords[0].East__c != null){
                                    adc.Final_Charges__c=quoteRecords[0].East__c;
                                }else if(adc.Values__c=='Premium Plots' && quoteRecords[0].Premium_Plots__c != null){
                                    adc.Final_Charges__c=quoteRecords[0].Premium_Plots__c;
                                }else if(adc.Values__c=='Rate Per Sq. Yd' && quoteRecords[0].Rate_Per_Sq_Yd__c != null){
                                    adc.Final_Charges__c=quoteRecords[0].Rate_Per_Sq_Yd__c;
                                }
                                additonalChargesToUpdate.add(adc);
                            }
                            if(!additonalChargesToUpdate.isEmpty()){
                                update additonalChargesToUpdate;
                            }
                        }
                    }
                }
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
            Blob pdfBlob;
            if(!test.isrunningtest()){
                pdfBlob = pdfPage.getContentAsPDF();
            }
            else{
                pdfBlob= Blob.valueOf('test');
            }
            
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[] { recipientEmail });
            email.setSubject('Quote: ' + name);
            String bodyText = 'Dear Customer,\n\n' +
                          'Please find the attached quote PDF for your reference.\n\n' +
                          'Warm Regards,\n' +
                          'Epitome Projects LLP';
            email.setPlainTextBody(bodyText);
            
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
                IsLocked__c,Approval_Status__c,Lead__r.Email,Is_Final__c,
                Opportunity__r.Contact__r.Name, Opportunity__r.Contact__r.Email, Plot__r.Phase__r.Name, 
                Plot__r.Phase__r.Project__r.Name, Plot__r.Phase__r.Project_Type__c,Plot__r.Plot_Dimension__c,Opportunity__c,Total_Sale_Value__c,
                Final_Base_Price__c,Total_Unit_Cost__c,Time_To_Pay_In_Days__c,Quote_Name__c,Lead__c,Plot__r.Plot_Price__c,Lead__r.OwnerId
                FROM Quote__c where Id =: recordId 
            ];
            
            List<Additional_Charges__c> additonalCharges = new List<Additional_Charges__c>();
            String plotId='';
            plotId=quoteObj.Plot__c;
            if(plotId!=null && plotId!=''){
                additonalCharges = [Select Id,Plot__c,Additional_Charges__c,Values__c,Charges__c,Final_Charges__c From Additional_Charges__c
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
    
    @AuraEnabled
    public static Opportunity getOppDetails(String oppId){
        try{
            List<Opportunity> oppList= [Select Id,Contact__c,Contact__r.Email,Account.Name,Unit__r.Phase__r.Name,
                                        Plot_Name__c, Plot_Size__c,Sale_Value_Amount__c,Collected_Amount__c,OwnerId,
                                        Outstanding_Amount__c,Unit__r.Base_Price_per_Sq_Ft__c,Unit__r.Plot_Price__c
                                        From Opportunity Where Id=:oppId Limit 1];
            if(oppList!=null){
                return oppList[0];
            }else{
                return null;
            }
        }catch(Exception ex){
            throw new AuraHandledException('Error in fetching opportunity: ' + ex.getMessage());
        }
    }
    
    	@AuraEnabled
        public static void sendEmail(String oppId, String oldPlotName, String oldPlotSize, String oldPlotBasePrice, String oldTotalSaleValue, String newPlotPrice) { 
        try {
            List<Opportunity> oppList= [Select Id,Contact__c,Contact__r.Email,Account.Name,Unit__r.Phase__r.Name,
                                        Plot_Name__c, Plot_Size__c,Sale_Value_Amount__c,Collected_Amount__c,
                                        Outstanding_Amount__c,Old_Plot_Details__c,New_Price__c
                                        From Opportunity Where Id=:oppId Limit 1];
            
            if(oppList!=null && oppList[0].Contact__c!=null){
                EmailTemplate template = [SELECT Id, HtmlValue FROM EmailTemplate WHERE DeveloperName = 'Plot_Swapping' LIMIT 1];
                String emailBody = template.HtmlValue;
                
                if (emailBody != null) {
                    emailBody = emailBody
                        		.replace('Opp_Account',oppList[0].Account.Name)
                                .replace('Opp_PhaseName',oppList[0].Unit__r.Phase__r.Name)
                                .replace('Opp_PlotName', oppList[0].Plot_Name__c)
                                .replace('Opp_Old_PlotName', oldPlotName)
                        		.replace('Opp_Old_PlotSize', oldPlotSize)
                        		.replace('Opp_Old_PlotPrice', oldPlotBasePrice)
                        		.replace('Opp_Old_PlotSaleValue', oldTotalSaleValue)
                        		.replace('Opp_New_PlotName', oppList[0].Plot_Name__c)
                        		.replace('Opp_New_PlotSize', String.ValueOf(oppList[0].Plot_Size__c))
                        		.replace('Opp_New_PlotPrice', newPlotPrice)
                        		.replace('Opp_New_PlotSaleValue', String.ValueOf(oppList[0].Sale_Value_Amount__c))
                        		.replace('Opp__Collected_Amount__c', String.ValueOf(oppList[0].Collected_Amount__c))
                        		.replace('Opp__Outstanding_Amount__c', String.ValueOf(oppList[0].Outstanding_Amount__c));
                }
                
                // Build the long text using newline characters
					String textBody = 'Original Unit Details:\n\n' +
                   'Unit Number: '+oldPlotName+'\n\n' +
                   'Unit Size: '+oldPlotSize+'\n\n' +
                   'Unit price per sq. yard: ₹'+oldPlotBasePrice+'\n\n' +
                   'Sale Value: ₹'+oldTotalSaleValue;
                
                oppList[0].Old_Plot_Details__c=textBody;
                oppList[0].New_Price__c=newPlotPrice;
                update oppList;
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(new String[] { oppList[0].Contact__r.Email });
				email.setSubject('Plot Swapping');
                email.setHtmlBody(emailBody);
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
            }
            
        } catch (Exception ex) {
            throw new AuraHandledException('Error in sending email: ' + ex.getMessage());
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