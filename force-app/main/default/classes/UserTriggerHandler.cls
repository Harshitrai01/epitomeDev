/**
 *  * @author Varun Rawal

 * This class, `UserTriggerHandler`, is designed to handle lead assignment logic when a user's status changes.
 * It ensures that leads are assigned to users based on their capacity, availability, and assigned lead sources.
 * The class also manages user capacity and updates lead ownership dynamically.
 *
 * Key Features:
 * - Handles lead assignment when a user's status changes.
 * - Fetches and processes pre-sales and sales settings.
 * - Assigns leads to users based on their capacity and assigned lead sources.
 * - Updates user capacity after lead assignment.
 * - Includes null checks and ensures robust execution.
 */

public with sharing class UserTriggerHandler {

    /**
     * Handles the logic when a user's status changes.
     * Triggers lead assignment if the user's status has changed.
     *
     * @param newUsers The list of updated User records.
     * @param oldUserMap A map of old User records by their IDs.
     */
    public static void handleStatusChange(List<User> newUsers, Map<Id, User> oldUserMap) {
        for (User newUser : newUsers) {
            User oldUser = oldUserMap.get(newUser.Id);
            // Check if the user's status has changed
            if (oldUser != null && newUser.Status__c != oldUser.Status__c) {
                processLeadAssignment(); // Trigger lead assignment logic
                break; // Exit the loop after processing the first status change
            }
        }
    }

    /**
     * Processes lead assignment based on pre-sales and sales settings.
     * Fetches eligible users and unassigned leads, then assigns leads to users.
     */
    public static void processLeadAssignment() {
        try {
            // Fetch pre-sales and sales settings
            Map<String, Pre_Sales_Data__c> settings = fetchPreSalesSettings();
            Boolean preSalesEnabled = settings.containsKey('Pre-Sales Assignment') && settings.get('Pre-Sales Assignment').Value__c == 'true';
            Boolean salesEnabled = settings.containsKey('Sales Assignment') && settings.get('Sales Assignment').Value__c == 'true';

            // Fetch eligible user IDs based on settings
            Set<Id> userIds = fetchEligibleUserIds(preSalesEnabled, salesEnabled);
            if (userIds.isEmpty()) return; // Exit if no eligible users are found

            // Fetch the pre-sales queue
            Group preSalesQueue = fetchQueueByName('Pre_Sales_Queue');
            Integer maxCapacity = Integer.valueOf(Label.Lead_Assignment_Capacity);

            // Fetch available users with capacity less than their max load
            List<User> availableUsers = fetchAvailableUsers(userIds, maxCapacity);
            if (availableUsers.isEmpty()) return; // Exit if no available users are found
            system.debug('availableUsers--->' + availableUsers);

            // Fetch unassigned leads from the pre-sales queue
            List<Lead> unassignedLeads = fetchUnassignedLeads(preSalesQueue.Id);
            if (unassignedLeads.isEmpty()) return; // Exit if no unassigned leads are found
            system.debug('unassignedLeads--->' + unassignedLeads);

            // Assign leads to users based on their capacity and lead sources
            assignLeadsToUsers(unassignedLeads, availableUsers, maxCapacity);
        } catch (Exception e) {
            // Log and throw an exception if an error occurs
            System.debug('Error in processLeadAssignment: ' + e.getMessage());
            throw new AuraHandledException('An error occurred. Contact support.');
        }
    }

    /**
     * Fetches pre-sales and sales settings from custom settings.
     *
     * @return A map of pre-sales and sales settings by their names.
     */
    private static Map<String, Pre_Sales_Data__c> fetchPreSalesSettings() {
        Map<String, Pre_Sales_Data__c> settings = new Map<String, Pre_Sales_Data__c>();
        for (Pre_Sales_Data__c setting : [SELECT Name, Value__c FROM Pre_Sales_Data__c WHERE Name IN ('Pre-Sales Assignment', 'Sales Assignment')]) {
            settings.put(setting.Name, setting);
        }
        return settings;
    }

    /**
     * Fetches eligible user IDs based on pre-sales and sales settings.
     *
     * @param preSalesEnabled Whether pre-sales assignment is enabled.
     * @param salesEnabled Whether sales assignment is enabled.
     * @return A set of eligible user IDs.
     */
    private static Set<Id> fetchEligibleUserIds(Boolean preSalesEnabled, Boolean salesEnabled) {
        Set<Id> userIds = new Set<Id>();
        if (preSalesEnabled) userIds.addAll(getQueueMemberIds('Pre_Sales_Queue'));
        if (salesEnabled) userIds.addAll(getQueueMemberIds('Sales_Queue'));
        return userIds;
    }

    /**
     * Fetches a queue by its developer name.
     *
     * @param queueName The developer name of the queue.
     * @return The Group record representing the queue.
     */
    private static Group fetchQueueByName(String queueName) {
        return [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = :queueName LIMIT 1];
    }

    /**
     * Fetches available users with capacity less than their max load.
     *
     * @param userIds The set of eligible user IDs.
     * @param maxCapacity The maximum capacity for lead assignment.
     * @return A list of available users.
     */
    private static List<User> fetchAvailableUsers(Set<Id> userIds, Integer maxCapacity) {
        List<User> users = [
            SELECT Id, Capacity__c, Pre_Sales_Lead_Assignment__c, Assigned_Sources__c, Max_Load__c
            FROM User 
            WHERE Status__c = 'Online'
            AND Id IN :userIds
            AND Pre_Sales_Lead_Assignment__c = true
        ];

        // Filter users based on Capacity__c < Max_Load__c
        List<User> filteredUsers = new List<User>();
        for (User u : users) {
            if (u.Capacity__c < u.Max_Load__c) {
                filteredUsers.add(u); // Add user to the filtered list if the condition is met
            }
        }

        return filteredUsers;
    }

    /**
     * Fetches unassigned leads from a specific queue.
     *
     * @param queueId The ID of the queue.
     * @return A list of unassigned leads.
     */
    private static List<Lead> fetchUnassignedLeads(Id queueId) {
        return [
            SELECT Id, OwnerId, Status, LeadSource 
            FROM Lead 
            WHERE OwnerId = :queueId 
            AND Status = 'Unopened' 
            ORDER BY CreatedDate DESC
        ];
    }

    /**
     * Assigns leads to users based on their capacity and assigned lead sources.
     *
     * @param leads The list of unassigned leads.
     * @param availableUsers The list of available users.
     * @param maxCapacity The maximum capacity for lead assignment.
     */
    private static void assignLeadsToUsers(List<Lead> leads, List<User> availableUsers, Integer maxCapacity) {
        Map<Id, Integer> userLeadCounts = initializeUserLeadCounts(availableUsers);
        List<Lead> leadsToUpdate = new List<Lead>();
        List<User> usersToUpdate = new List<User>();

        // Map lead sources to users
        Map<String, List<User>> sourceToUsersMap = new Map<String, List<User>>();
        for (User u : availableUsers) {
            if (u.Assigned_Sources__c != null) {
                List<String> userSources = u.Assigned_Sources__c.split(',');
                for (String source : userSources) {
                    source = source.trim();
                    if (!sourceToUsersMap.containsKey(source)) {
                        sourceToUsersMap.put(source, new List<User>());
                    }
                    sourceToUsersMap.get(source).add(u);
                }
            }
        }

        // Map user IDs to their max load
        Map<Id, Decimal> userMaxLoadMap = new Map<Id, Decimal>();
        for (User u : availableUsers) {
            userMaxLoadMap.put(u.Id, u.Max_Load__c);
        }

        system.debug('source ' + sourceToUsersMap);
        Map<String, Integer> sourceIndexMap = new Map<String, Integer>();

        // Assign leads to users based on lead source and capacity
        for (Lead lead : leads) {
            String leadSource = lead.LeadSource;
            if (String.isBlank(leadSource)) continue;

            List<User> sourceUsers = sourceToUsersMap.get(leadSource);
            if (sourceUsers == null || sourceUsers.isEmpty()) continue;

            Integer currentIndex = sourceIndexMap.get(leadSource) != null ? sourceIndexMap.get(leadSource) : 0;
            Integer numUsers = sourceUsers.size();
            Boolean assigned = false;

            for (Integer i = 0; i < numUsers; i++) {
                Integer sum = currentIndex + i;
                Integer indexToCheck = sum - ((sum / numUsers) * numUsers);
                User candidateUser = sourceUsers[indexToCheck];
                Integer currentCount = userLeadCounts.get(candidateUser.Id);
                system.debug('candidateUser ' + candidateUser);
                Decimal maxLoad = userMaxLoadMap.get(candidateUser.Id);

                if (currentCount < maxLoad) {
                    lead.OwnerId = candidateUser.Id;
                    leadsToUpdate.add(lead);
                    userLeadCounts.put(candidateUser.Id, currentCount + 1);
                    if (!usersToUpdate.contains(candidateUser)) {
                        usersToUpdate.add(candidateUser);
                    }
                    sourceIndexMap.put(leadSource, indexToCheck + 1);
                    system.debug('sourceIndexMap ' + sourceIndexMap);
                    assigned = true;
                    break;
                }
            }
        }

        // Update leads and users
        if (!leadsToUpdate.isEmpty()) update as user leadsToUpdate;
        system.debug('leadsToUpdate-->' + leadsToUpdate);
        if (!usersToUpdate.isEmpty()) {
            for (User u : usersToUpdate) {
                u.Capacity__c = userLeadCounts.get(u.Id);
            }
            update usersToUpdate;
        }
    }

    /**
     * Initializes a map of user IDs to their current lead counts.
     *
     * @param users The list of available users.
     * @return A map of user IDs to their current lead counts.
     */
    private static Map<Id, Integer> initializeUserLeadCounts(List<User> users) {
        Map<Id, Integer> userLeadCounts = new Map<Id, Integer>();
        for (User user : users) {
            userLeadCounts.put(user.Id, user.Capacity__c != null ? Integer.valueOf(user.Capacity__c) : 0);
        }
        return userLeadCounts;
    }

    /**
     * Fetches the member IDs of a queue by its developer name.
     *
     * @param queueDeveloperName The developer name of the queue.
     * @return A set of user IDs in the queue.
     */
    private static Set<Id> getQueueMemberIds(String queueDeveloperName) {
        Group grp = [SELECT Id FROM Group WHERE DeveloperName = :queueDeveloperName AND Type = 'Queue' LIMIT 1];
        Set<Id> userIds = new Set<Id>();
        for (GroupMember gm : [SELECT UserOrGroupId FROM GroupMember WHERE GroupId = :grp.Id]) {
            userIds.add(gm.UserOrGroupId);
        }
        return userIds;
    }
}