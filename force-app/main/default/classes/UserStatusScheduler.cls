// Scheduler Class to run every night at 12:00 AM
public class UserStatusScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        // Query users with Status__c = 'Online' and from Pre_Sales_Queue
        Group preSalesQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Pre_Sales_Queue' LIMIT 1];
        
        List<User> usersToUpdate = [SELECT 
                                    Id, Status__c  
                                    FROM User 
                                  	WHERE Id IN (SELECT UserOrGroupId FROM GroupMember WHERE GroupId = :preSalesQueue.Id)
                                    AND (Status__c = 'Online' or Status__c=null)
        ];

        // Update Status__c field for users
        if (!usersToUpdate.isEmpty()) {
            for (User user : usersToUpdate) {
                user.Status__c = 'Offline'; // Assuming you are toggling it to 'Offline'
            }

            try {
                update usersToUpdate;
                System.debug('Updated ' + usersToUpdate.size() + ' user records successfully.');
            } catch (DmlException e) {
                System.debug('Error while updating user records: ' + e.getMessage());
            }
        } else {
            System.debug('No users found with Status__c = Online in Pre_Sales_Queue.');
        }
    }
}