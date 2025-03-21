/**********
Apex Class Name : UserStatusScheduler
Apex Test Class Name: 
Created Date: January 30, 2025
@description : This class is a schedulable class designed to run every night at 12:00 AM. It updates the `Status__c` field of users to 'Offline' if their current status is 'Online' or null. This ensures that user statuses are reset at the start of a new day, preparing the system for the next day's operations.
@author : Varun Rawal
Modify By : 
Modify Date: 
**********/

public with sharing class UserStatusScheduler implements Schedulable {

    /* 
    **********
    Method Name : execute
    author: Varun Rawal
    description: Executes the scheduled job to update user statuses. While updating or inserting, use as user.
    @params: 
        - sc: The SchedulableContext object provided by the system.
    @return: None
    **********
    */
    public void execute(SchedulableContext sc) {
        // Query users with Status__c = 'Online' or null
        List<User> usersToUpdate = [
            SELECT Id, Status__c  
            FROM User 
            WHERE (Status__c = 'Online' OR Status__c = null)
        ];

        // Null check: Ensure the list of users to update is not empty
        if (!usersToUpdate.isEmpty()) {
            // Update the Status__c field for each user to 'Offline'
            for (User user : usersToUpdate) {
                user.Status__c = 'Offline'; // Reset status to 'Offline'
            }

            try {
                // Perform the update operation
                update usersToUpdate; // Update as the current user
                System.debug('Updated ' + usersToUpdate.size() + ' user records successfully.');
            } catch (DmlException e) {
                // Log the error if the update operation fails
                System.debug('Error while updating user records: ' + e.getMessage());
            }
        } else {
            // Log a message if no users are found to update
            System.debug('No users found with Status__c = Online or null.');
        }
    }
}