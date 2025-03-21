/*
*********************************************************
Apex Class Name    : InstaCollectBatch
Created Date       : 18th March 2025
@description       : This class is used to create virtual account details by processing Opportunity and Unit__c records.
It implements the Database.Batchable interface to handle bulk processing and allows callouts.
@author            : Harshit Kumar Rai
Modification Log:
Ver   Date         Author               Modification
1.0   [18th March 2025] Harshit Kumar Rai   Initial Version
*********************************************************
*/
global class InstaCollectBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {
    
    private List<Opportunity> oppList;
    private Set<Id> plotIds;
    
    /*
*********************************************************
@Method Name    : InstaCollectBatch
@author         : Harshit Kumar Rai
@description    : Constructor to initialize the batch class with a list of Opportunities and a set of Unit__c Ids.
@param          : opp - List of Opportunity records to process.
@param          : listOfPlotIds - Set of Plot Ids to process.
*********************************************************
*/
    public InstaCollectBatch(List<Opportunity> opp, Set<Id> listOfPlotIds) {
        this.oppList = opp;
        this.plotIds = listOfPlotIds;
    }
    /*
*********************************************************
@Method Name    : start
@author         : Harshit Kumar Rai
@description    : Start method of the batch class. Returns a QueryLocator to fetch Unit__c records based on the provided plotIds.
@param          : BC - Database.BatchableContext object.
@return         : Database.QueryLocator - QueryLocator for Unit__c records.
*********************************************************
*/
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(
            [SELECT Id FROM Unit__c WHERE Id IN :plotIds]
        );
    }
    
    /*
*********************************************************
@Method Name    : execute
@author         : Harshit Kumar Rai
@description    : Execute method of the batch class. Processes each Unit__c record and calls the EasebuzzInstaCollectService 
to create a virtual account.
@param          : BC - Database.BatchableContext object.
@param          : plotRecords - List of Unit__c records to process.
*********************************************************
*/
    global void execute(Database.BatchableContext BC, List<Unit__c> plotRecords) {
        if (plotRecords != null && !plotRecords.isEmpty()) {
            List<String> plotIdList = New List<String>();
            Map<String,String> plotIdToJsonData = New Map<String,String>();
            
            for (Unit__c plot : plotRecords) {
                String res = JSON.serialize(EasebuzzInstaCollectService.createVirtualAccount(plot.Id));
                if(res!='null'){
                    Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res);
                    String plotId = (String) responseMap.get('plotId');
                    String jsonData = (String) responseMap.get('jsonData');
                    plotIdList.add(plotId);
                    plotIdToJsonData.put(plotId,jsonData);
                }else{
                    
                }
            }
            
            if(!plotIdList.isEmpty() && !plotIdToJsonData.isEmpty()){
                List<Unit__c> plotList = [
                    SELECT Id, Name, Phase__r.Name, Virtual_Account_Name__c, Virtual_Account_Number__c,
                    Virtual_Account_Id__c, Virtual_Account_UPI__c, Virtual_Account_IFSC__c,
                    UPI_QR_Image__c, UPI_QR_PDF__c, Unique_Request_Number__c
                    FROM Unit__c 
                    WHERE Id IN :plotIdList
                ];
                
                List<Unit__c> plotListToUpdate = new List<Unit__c>();
                for(Unit__c plot :plotList){
                    if(plotIdToJsonData.ContainsKey(plot.Id)){
                        String jsonData = plotIdToJsonData.get(plot.Id);
                        Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(jsonData);
                        if (plot?.Phase__r?.Name != null) {
                            plot.Virtual_Account_Name__c = plot.Name + ' ' + plot?.Phase__r?.Name;
                        }
                        plot.Virtual_Account_Number__c = (String) data.get('virtual_account_number');
                        plot.Virtual_Account_Id__c = (String) data.get('id');
                        plot.Virtual_Account_UPI__c = (String) data.get('virtual_upi_handle');
                        plot.Virtual_Account_IFSC__c = (String) data.get('virtual_ifsc_number');
                        plot.UPI_QR_Image__c = (String) data.get('upi_qrcode_remote_file_location');
                        plot.UPI_QR_PDF__c = (String) data.get('upi_qrcode_scanner_remote_file_location');
                        plot.Unique_Request_Number__c = (String) data.get('unique_request_number');
                        plotListToUpdate.add(plot);
                    }
                    
                }
                if(plotListToUpdate!=null && !plotListToUpdate.isEmpty()){
                    update plotListToUpdate;
                }
            }
        }
    }
    
    /*
*********************************************************
@Method Name    : finish
@author         : Harshit Kumar Rai
@description    : Finish method of the batch class. Executes the next batch (PaymentSendLinkEasyCollect) with the provided Opportunity list.
@param          : BC - Database.BatchableContext object.
*********************************************************
*/
    global void finish(Database.BatchableContext BC) {
        Database.executeBatch(new PaymentSendLinkEasyCollect(oppList), 50);
    }
    
    /*
*********************************************************
Apex Class Name    : ResponseWrapper
@description       : Inner class to wrap response details for API calls or Lightning components.
@author            : Harshit Kumar Rai
*********************************************************
*/
    public class ResponseWrapper {
        @AuraEnabled
        public Boolean isSuccess;
        @AuraEnabled
        public String error;
        @AuraEnabled
        public String response;
        public String integrationLogs;
    }
    
}