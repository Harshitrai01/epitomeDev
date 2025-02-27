/**
* Author: Harshit Kumar Rai
* Description: Trigger Handler For Opportunity
*/
public class OpportunityTriggerHandler {
    
	public static void handleAfterInsert(List<Opportunity> newOpportunities) {
        try{
            List<String> opportunityIds = new List<String>();
            for (Opportunity opp : newOpportunities) {
                opportunityIds.add(opp.Id);
            }
            List<Opportunity> oppList = [Select Id, Unit__c, Unit__r.Name, Unit__r.Virtual_Account_Id__c, Unit__r.Phase__c,
                                         ContactId
                                         From Opportunity Where ID IN: opportunityIds];
            List<String> responseList = new List<String>();
            
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
                Database.executeBatch(new PaymentSendLinkEasyCollect(oppList),10);
            }
            
        }catch (Exception ex){
            throw New AuraHandledException(ex.getMessage());
        }
    }
    
    public static void handleAfterUpdate(List<Opportunity> newOpportunities){
        
    }
    
    public static void sendPlotCancellationEmail(List<Id> oppIds){
        List<Opportunity> oppList = [Select Id,Contact__c,Contact__r.Email,Date_of_Cancellation__c From Opportunity Where ID IN:oppIds];
        for(Opportunity opp : oppList){
            opp.Date_of_Cancellation__c=System.Today();
        }
        if(oppList!=null){
            update oppList;
        }
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        EmailTemplate template = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'Plot_Cancellation_Email' LIMIT 1];
        for(Opportunity opp : oppList){
            	Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            	String recipientEmail = opp.Contact__r.Email;
                email.setToAddresses(new String[]{ recipientEmail });
                email.setTemplateId(template.Id);
                email.setTargetObjectId(opp.Contact__c); 
                email.setWhatId(opp.Id);
                email.setTreatTargetObjectAsRecipient(false);
                emails.add(email);
        }
        if (!emails.isEmpty()) {
        	Messaging.sendEmail(emails);
        }
    }
}