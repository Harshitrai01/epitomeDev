public class LeadTriggerHandler {
    
    public static void assignLeadsToQueue(List<Lead> newLeads) {
        
        Group preSalesQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Pre_Sales_Queue' LIMIT 1];
        
        if (preSalesQueue == null) {
            System.debug('Error: Pre-Sales Queue not found.');
            return;
        }
        
        for (Lead lead : newLeads) {
            lead.OwnerId = preSalesQueue.Id;
        }
    }
    
    public static void checkAssignment(List<Lead> newLeads) {
        
        Group preSalesQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Pre_Sales_Queue' LIMIT 1];
        
        if (preSalesQueue != null) {
            Boolean leadsAssignedToPreSalesQueue = false;
            
            for (Lead lead : newLeads) {
                if (lead.OwnerId == preSalesQueue.Id) {
                    leadsAssignedToPreSalesQueue = true;
                    break;
                }
            }
            
            if (leadsAssignedToPreSalesQueue) {
                UserTriggerHandler.processLeadAssignment();
            }
        }
    }
}