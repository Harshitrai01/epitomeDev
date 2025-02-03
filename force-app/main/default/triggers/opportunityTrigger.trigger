trigger opportunityTrigger on Opportunity (after update) {
	if (Trigger.isAfter && Trigger.isUpdate) {
        OpportunityTriggerHandler.handleAfterInsert(Trigger.New);
    }
}