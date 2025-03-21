/**********
Apex Class Name : UserStatusController
Apex Test Class Name: 
Created Date: January 21, 2025
@description : This class is a controller for managing user status in a Lightning Component. It provides methods to retrieve the current user's status, fetch available status picklist values, and update the user's status.
@author : Varun Rawal
Modify By : 
Modify Date: 
**********/

public with sharing class UserStatusController {
    
    /*
    **********
    Method Name : getCurrentUserStatus
    author: Varun Rawal
    description: Retrieves the current user's status. Uses caching for better performance.
    @return: User's status or 'Offline' if null.
    **********
    */
    @AuraEnabled(cacheable=true)
    public static String getCurrentUserStatus() {
        try {
            // Query current user's status field
            User currentUser = [SELECT Status__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

            // Return status if available, otherwise default to 'Offline'
            return String.isNotBlank(currentUser.Status__c) ? currentUser.Status__c : 'Offline';
        } catch (Exception e) {
            System.debug('Error in getCurrentUserStatus: ' + e.getMessage());
            throw new AuraHandledException('Failed to retrieve user status. Please try again.');
        }
    }

    /*
    **********
    Method Name : getStatusPicklistValues
    author: Varun Rawal
    description: Fetches available picklist values for the Status__c field on the User object. Uses caching for better performance.
    @return: List of active status values.
    **********
    */
    @AuraEnabled(cacheable=true)
    public static List<String> getStatusPicklistValues() {
        List<String> picklistValues = new List<String>();

        try {
            // Describe field and fetch active picklist values
            Schema.DescribeFieldResult fieldResult = User.Status__c.getDescribe();
            for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
                if (entry.isActive()) {
                    picklistValues.add(entry.getValue());
                }
            }
        } catch (Exception e) {
            System.debug('Error in getStatusPicklistValues: ' + e.getMessage());
            throw new AuraHandledException('Failed to retrieve status picklist values.');
        }

        return picklistValues;
    }

    /*
    **********
    Method Name : updateUserStatus
    author: Varun Rawal
    description: Updates the current user's status. While updating or inserting, use as user.
    @params: 
        - newStatus: The new status to be set.
    @return: Success message if updated successfully.
    **********
    */
    @AuraEnabled
    public static String updateUserStatus(String newStatus) {
        if (String.isBlank(newStatus)) {
            throw new AuraHandledException('Invalid status. Please provide a valid value.');
        }

        try {
            // Fetch current user
            User currentUser = [SELECT Id, Status__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

            // Update status only if it's different to avoid unnecessary DML operations
            if (currentUser.Status__c != newStatus) {
                currentUser.Status__c = newStatus;
                update currentUser; // Update as the current user
            }

            return 'Status updated successfully to ' + newStatus;
        } catch (DmlException e) {
            System.debug('DML Error in updateUserStatus: ' + e.getMessage());
            throw new AuraHandledException('Failed to update user status. Please try again.');
        } catch (Exception e) {
            System.debug('Unexpected Error in updateUserStatus: ' + e.getMessage());
            throw new AuraHandledException('An unexpected error occurred. Contact support.');
        }
    }
}