/**
 * @description Apex Trigger Handler for User status change and lead assignment.
 * Handles updates when a user's status changes and ensures leads are assigned fairly.
 * @author Varun Rawal
 */
public with sharing class UserTriggerHandler {
    
    /**
     * Handles user status changes and triggers lead assignment when status changes.
     * @param newUsers List of new user records being inserted/updated.
     * @param oldUserMap Map of old user records before the update.
     */
    public static void handleStatusChange(List<User> newUsers, Map<Id, User> oldUserMap) {
        for (User newUser : newUsers) {
            User oldUser = oldUserMap.get(newUser.Id);
            if (oldUser != null && newUser.Status__c != oldUser.Status__c) {
                processLeadAssignment();
                break; // Avoid redundant calls if multiple users are updated
            }
        }
    }

    /**
     * Processes lead assignment to available users in the Pre-Sales Queue.
     */
    public static void processLeadAssignment() {
        try {
            // Fetch the Pre-Sales Queue
            Group preSalesQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Pre_Sales_Queue' LIMIT 1];
            
            Integer maxCapacity = Integer.valueOf(Label.Lead_Assignment_Capacity);
            
            // Fetch users who are online, available for lead assignment, and under capacity limit
            List<User> onlineUsers = [
                SELECT Id, Capacity__c, Pre_Sales_Lead_Assignment__c
                FROM User 
                WHERE Status__c = 'Online'
                AND Pre_Sales_Lead_Assignment__c = true 
                AND Capacity__c < :maxCapacity
            ];
            
            if (onlineUsers.isEmpty()) {
                System.debug('No available users for lead assignment.');
                return;
            }

            // Fetch unassigned leads in the queue
            List<Lead> leadsInQueue = [
                SELECT Id, OwnerId, Status 
                FROM Lead 
                WHERE OwnerId = :preSalesQueue.Id 
                AND Status = 'Unopened' 
                ORDER BY CreatedDate DESC
            ];
            
            if (leadsInQueue.isEmpty()) {
                System.debug('No leads found in the Pre_Sales_Queue.');
                return;
            }

            // Map user capacities
            Map<Id, Integer> userLeadCounts = new Map<Id, Integer>();
            for (User user : onlineUsers) {
                integer cp=Integer.valueOf(user.Capacity__c);
                userLeadCounts.put(user.Id, cp == null ? 0 : cp);
            }
            userLeadCounts = sortMapByValueAscending(userLeadCounts);

            List<Lead> leadsToUpdate = new List<Lead>();
            List<User> usersToUpdate = new List<User>();
            Integer userIndex = 0;

            // Assign leads fairly
            for (Lead lead : leadsInQueue) {
                if (onlineUsers.isEmpty()) break;
                
                Integer agentSize = onlineUsers.size();
                User assignedUser = onlineUsers[Math.mod(userIndex, agentSize)];

                if (userLeadCounts.get(assignedUser.Id) < maxCapacity) {
                    lead.OwnerId = assignedUser.Id;
                    leadsToUpdate.add(lead);
                    userLeadCounts.put(assignedUser.Id, userLeadCounts.get(assignedUser.Id) + 1);
                    assignedUser.Capacity__c = userLeadCounts.get(assignedUser.Id);

                    if (!usersToUpdate.contains(assignedUser)) {
                        usersToUpdate.add(assignedUser);
                    }
                }
                userIndex++;
            }

            // Perform bulk updates
            if (!leadsToUpdate.isEmpty()) {
                update leadsToUpdate;
            }
            if (!usersToUpdate.isEmpty()) {
                update usersToUpdate;
            }
        } catch (DmlException e) {
            System.debug('DML Exception in processLeadAssignment: ' + e.getMessage());
            throw new AuraHandledException('Error updating records. Please try again.');
        } catch (Exception e) {
            System.debug('Unexpected error in processLeadAssignment: ' + e.getMessage());
            throw new AuraHandledException('An unexpected error occurred. Contact support.');
        }
    }

    /**
     * Sorts a map of users by their lead capacity in ascending order.
     * @param inputMap Map of User IDs and their assigned lead counts.
     * @return Sorted map of User IDs with least assigned leads first.
     */
    public static Map<Id, Integer> sortMapByValueAscending(Map<Id, Integer> inputMap) {
        List<UserWrapper> userList = new List<UserWrapper>();
        for (Id key : inputMap.keySet()) {
            userList.add(new UserWrapper(key, inputMap.get(key)));
        }

        userList.sort();
        Map<Id, Integer> sortedMap = new Map<Id, Integer>();
        for (UserWrapper wrapper : userList) {
            sortedMap.put(wrapper.userId, wrapper.capacity);
        }
        return sortedMap;
    }

    /**
     * Wrapper class to facilitate sorting of Users based on Capacity.
     */
    public class UserWrapper implements Comparable {
        public Id userId;
        public Integer capacity;

        public UserWrapper(Id userId, Integer capacity) {
            this.userId = userId;
            this.capacity = capacity;
        }

        public Integer compareTo(Object other) {
            return this.capacity - ((UserWrapper) other).capacity;
        }
    }
}