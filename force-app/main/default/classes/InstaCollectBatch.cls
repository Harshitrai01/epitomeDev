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
            for (Unit__c plot : plotRecords) {
                EasebuzzInstaCollectService.createVirtualAccount(plot.Id);
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