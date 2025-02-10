trigger opportunityTrigger on Opportunity (after insert, after update) {
    if (Trigger.isAfter && Trigger.isInsert) {
        OpportunityTriggerHandler.handleAfterInsert(Trigger.New);
    }
    if (Trigger.isAfter && Trigger.isUpdate) {
        List<Id> opportunityIds = new List<Id>();
        for (Opportunity opp : Trigger.new) {
            Opportunity oldOpp = Trigger.oldMap.get(opp.Id);
            if (oldOpp.Refund_Status__c != opp.Refund_Status__c && opp.Refund_Status__c == 'Initiate') {
                try {
                    refundPaymentController.getPaymentsByOpportunity(opp.Id);
                } catch (Exception ex) {
                    throw new AuraHandledException(ex.getMessage());
                }
            }
        }
    }
}