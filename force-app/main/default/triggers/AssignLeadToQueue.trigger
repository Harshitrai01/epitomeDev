trigger AssignLeadToQueue on Lead (after insert) {
    // Map to hold leads to be updated
    List<Lead> leadsToUpdate = new List<Lead>();

    // Replace with the Developer Name of your queue
    String queueDeveloperName = 'Pre_Sales_Queue'; 

    // Query to get the GroupId of the queue
    Group queue = [SELECT Id,DeveloperName FROM Group WHERE DeveloperName = :queueDeveloperName LIMIT 1];

    for (Lead lead : Trigger.new) {
        // Assign the queue's GroupId to the OwnerId field of the lead
        //lead.OwnerId = queue.Id;
        leadsToUpdate.add(lead);
    }

    // Update the leads with the new OwnerId
    if (!leadsToUpdate.isEmpty()) {
      //  update leadsToUpdate;
    }
}