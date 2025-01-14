public with sharing class PreSalesController {

    /**
     * Retrieves the value of a custom setting by its name.
     * @param name The name of the custom setting.
     * @return The value of the custom setting as a string.
     */
    @AuraEnabled(cacheable=true)
    public static String getCustomSetting(String name) {
        try {
            Pre_Sales_Data__c customSetting = [
                SELECT Value__c 
                FROM Pre_Sales_Data__c 
                WHERE Name = :name 
                LIMIT 1
            ];
            return customSetting.Value__c;
        } catch (Exception e) {
            System.debug('Error retrieving custom setting: ' + e.getMessage());
            throw new AuraHandledException('Failed to retrieve custom setting.');
        }
    }

    /**
     * Retrieves user data based on the provided queue name.
     * @param queueName The name of the queue to fetch users for.
     * @return A JSON string containing the user data.
     */
    @AuraEnabled(cacheable=true)
    public static String getUserData(String queueName) {
        try {
            // Retrieve the group (queue) ID based on the queue name
            Group grp = [
                SELECT Id 
                FROM Group 
                WHERE DeveloperName = :queueName 
                AND Type = 'Queue' 
                LIMIT 1
            ];

            // Fetch all GroupMember entries for the group
            List<GroupMember> groupMembers = [
                SELECT UserOrGroupId 
                FROM GroupMember 
                WHERE GroupId = :grp.Id
            ];

            // Collect all User IDs
            Set<Id> userIds = new Set<Id>();
            for (GroupMember gm : groupMembers) {
                userIds.add(gm.UserOrGroupId);
            }

            // Fetch user data for the collected IDs
            List<User> users = [
                SELECT Id, Name, Status__c 
                FROM User 
                WHERE Id IN :userIds 
                ORDER BY Name
            ];

            return JSON.serialize(users);
        } catch (Exception e) {
            System.debug('Error retrieving user data: ' + e.getMessage());
            throw new AuraHandledException('Failed to retrieve user data.');
        }
    }

       /**
     * Updates the status of users based on a string containing user data.
     * The input string should be in the format: "UserId1:Status1,UserId2:Status2"
     * @param userStatusData A string containing user IDs and their corresponding statuses.
     */
    @AuraEnabled
    public static void updateUserStatus(String userStatusData) {
        try {
            // Validate input
            system.debug('userStatusData-->'+userStatusData);
            if (String.isEmpty(userStatusData)) {
                throw new AuraHandledException('Input string is empty.');
            }
            
            // Split the input string into individual user-status pairs
            List<String> userStatusPairs = userStatusData.split(',');
            List<User> userList = (List<User>) JSON.deserialize(userStatusData, List<User>.class);
            system.debug('userList-->'+userList);


            // Prepare a list of users to update
            List<User> usersToUpdate = new List<User>();
            for (String pair : userStatusPairs) {
                // Split each pair into user ID and status
                List<String> userAndStatus = pair.split(':');
                if (userAndStatus.size() == 2) {
                    String userId = userAndStatus[0];
                    String status = userAndStatus[1];

                    // Add the user to the list with the new status
                    usersToUpdate.add(new User(Id = userId, Status__c = status));
                } else {
                    throw new AuraHandledException('Invalid format for user-status pair: ' + pair);
                }
            }

            // Perform update if the list is not empty
            if (!usersToUpdate.isEmpty()) {
                update usersToUpdate;
            }
        } catch (Exception e) {
            System.debug('Error updating user status: ' + e.getMessage());
            throw new AuraHandledException('Failed to update user status.');
        }
    }

    /**
 * Updates the value of a custom setting.
 * @param name The name of the custom setting to update.
 * @param value The new value for the custom setting.
 */
@AuraEnabled
public static void updateCustomSetting(String name, String value) {
    try {
        Pre_Sales_Data__c customSetting = [
            SELECT Id, Value__c
            FROM Pre_Sales_Data__c
            WHERE Name = :name
            LIMIT 1
        ];
        customSetting.Value__c = value;
        update customSetting;
    } catch (Exception e) {
        System.debug('Error updating custom setting: ' + e.getMessage());
        throw new AuraHandledException('Failed to update custom setting.');
    }
}



}