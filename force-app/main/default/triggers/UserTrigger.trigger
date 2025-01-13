trigger UserTrigger on User (after update) {
    if(checkRecursion.runOnce()){
        if (Trigger.isAfter && Trigger.isUpdate) {
            UserTriggerHandler.handleStatusChange(Trigger.new, Trigger.oldMap);
        }
    }
}