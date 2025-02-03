public class OpportunityTriggerHandler {
    
	public static void handleAfterInsert(List<Opportunity> newOpportunities) {
        try{
            List<String> opportunityIds = new List<String>();
            for (Opportunity opp : newOpportunities) {
                opportunityIds.add(opp.Id);
            }
            List<Opportunity> oppList = [Select Id, Unit__c, Unit__r.Name, Unit__r.Virtual_Account_Id__c, Unit__r.Phase__c
                                         From Opportunity Where ID IN: opportunityIds];
            
            if(oppList!=null){
                for (Opportunity opp : oppList) {
                    if(opp.Unit__c!=null){
                        if(opp?.Unit__r?.Virtual_Account_Id__c == null){
                        	EasebuzzInstaCollectService.createVirtualAccount(opp.Unit__c);
                        }else{
                            System.Debug('Virtual Account Details Already Present');
                        }
                    }else{
                        System.Debug('Plot is not present');
                    }
                }
            }
            
        }catch (Exception ex){
            throw New AuraHandledException(ex.getMessage());
        }
    }
}