global class PollingWrapperScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        // Call the managed package functionality
        gupshup_crm.PollingIncomingWhatsAppMessageScheduler schedulerInstance =
            new gupshup_crm.PollingIncomingWhatsAppMessageScheduler();
        schedulerInstance.execute(null); 

        // Calculate next run time (1 minute later)
        DateTime nextRun = System.now().addMinutes(1);
        String cronExp = nextRun.second() + ' ' +
                         nextRun.minute() + ' ' +
                         nextRun.hour() + ' ' +
                         nextRun.day() + ' ' +
                         nextRun.month() + ' ? ' +
                         nextRun.year();
        
        System.schedule('incomingMessage ' + nextRun, cronExp, new PollingWrapperScheduler());
    }
}