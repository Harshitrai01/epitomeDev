/**
 *  * @author Varun Rawal

 * This class, `UserStatusScheduler`, is a schedulable class designed to run every night at 12:00 AM.
 * It updates the `Status__c` field of users to 'Offline' if their current status is 'Online' or null.
 * This ensures that user statuses are reset at the start of a new day, preparing the system for the next day's operations.
 *
 * Key Features:
 * - Runs as a scheduled job to reset user statuses.
 * - Queries users with a status of 'Online' or null.
 * - Updates their status to 'Offline'.
 * - Includes null checks and ensures robust execution.
 */

public class UserStatusScheduler implements Schedulable {

    /**
     * Executes the scheduled job to update user statuses.
     *
     * @param sc The SchedulableContext object provided by the system.
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
                update usersToUpdate;
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