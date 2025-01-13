trigger LeadTrigger on Lead (before insert, after insert) {
    // Call the handler method to assign leads to the queue
    if (Trigger.isBefore) {
        LeadTriggerHandler.assignLeadsToQueue(Trigger.new);
    } else if (Trigger.isAfter) {
        LeadTriggerHandler.checkAssignment(Trigger.new);
    }
}