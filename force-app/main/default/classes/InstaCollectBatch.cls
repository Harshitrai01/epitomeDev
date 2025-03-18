/*
* Author: Harshit Kumar Rai
* Description: For Creating Virtual Account Details
*/
global class InstaCollectBatch implements Database.Batchable<sObject>, Database.AllowsCallouts{
    
    private List<Opportunity> oppList;
    private Set<Id> plotIds;
    public InstaCollectBatch(List<Opportunity> opp, Set<Id> listOfPlotIds) {
        this.oppList=opp;
        this.plotIds=listOfPlotIds;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(
            [Select Id From Unit__c Where Id IN :plotIds]);
    }
    
    global void execute(Database.BatchableContext BC, List<Unit__c> plotRecords){
        if(plotRecords!=null && !plotRecords.isEmpty()){
            for(Unit__c plot:plotRecords){
                EasebuzzInstaCollectService.createVirtualAccount(plot.Id);
            }
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        Database.executeBatch(new PaymentSendLinkEasyCollect(oppList), 50);
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
    
}