public class UserTriggerHandler {
    
    // Main method to handle status change and process lead assignment
    public static void handleStatusChange(List<User> newUsers, Map<Id, User> oldUserMap) {
        for (User newUser : newUsers) {
            User oldUser = oldUserMap.get(newUser.Id);
            if (newUser.Status__c != oldUser.Status__c) {
                processLeadAssignment();
            }
        }
    }

    // Method to process the lead assignment to users
    public static void processLeadAssignment() {
        Group preSalesQueue = fetchPreSalesQueue();

        if (preSalesQueue == null) {
            return;
        }

        List<User> onlineUsers = fetchOnlineUsers(preSalesQueue.Id);

        if (onlineUsers.isEmpty()) {
            return;
        }

        Integer maxCapacity = Integer.valueOf(Label.Lead_Assignment_Capacity);

        List<Lead> leadsInQueue = fetchLeadsInQueue(preSalesQueue.Id);

        if (leadsInQueue.isEmpty()) {
            return;
        }

        Map<Id, Integer> userLeadCounts = initializeUserLeadCounts(onlineUsers);

        List<Lead> leadsToUpdate = new List<Lead>();
        Integer userIndex = 0;

        for (Lead lead : leadsInQueue) {
            User assignedUser = assignLeadToUser(userIndex, onlineUsers, userLeadCounts, maxCapacity);
            if (assignedUser != null) {
                lead.OwnerId = assignedUser.Id;
                leadsToUpdate.add(lead);
                userLeadCounts.put(assignedUser.Id, userLeadCounts.get(assignedUser.Id) + 1);
            }
            userIndex++;

            if (userLeadCounts.get(assignedUser.Id) >= maxCapacity) {
                break;
            }
        }

        updateLeads(leadsToUpdate);
        updateUserCapacities(onlineUsers, userLeadCounts);
    }

    // Method to fetch the Pre_Sales_Queue
    private static Group fetchPreSalesQueue() {
        Group preSalesQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Pre_Sales_Queue' LIMIT 1];
        if (preSalesQueue == null) {
            System.debug('Error: Queue "Pre_Sales_Queue" not found.');
        } else {
            System.debug('Queue data:- ' + preSalesQueue);
        }
        return preSalesQueue;
    }

    // Method to fetch users under the Pre_Sales_Queue with Status__c = 'Online'
    private static List<User> fetchOnlineUsers(Id queueId) {
        List<User> onlineUsers = [SELECT Id, Capacity__c 
                                  FROM User 
                                  WHERE Id IN (SELECT UserOrGroupId FROM GroupMember WHERE GroupId = :queueId)
                                    AND Status__c = 'Online'];
        if (onlineUsers.isEmpty()) {
            System.debug('Error: No users found in the queue with Status__c = "Online".');
        } else {
            System.debug('User data:- ' + onlineUsers);
        }
        return onlineUsers;
    }

    // Method to fetch leads assigned to the Pre_Sales_Queue
    private static List<Lead> fetchLeadsInQueue(Id queueId) {
        List<Lead> leadsInQueue = [SELECT Id, OwnerId FROM Lead WHERE OwnerId = :queueId ORDER BY CreatedDate DESC];
        if (leadsInQueue.isEmpty()) {
            System.debug('No leads found in the Pre_Sales_Queue.');
        }
        return leadsInQueue;
    }

    // Method to initialize user lead counts
    private static Map<Id, Integer> initializeUserLeadCounts(List<User> onlineUsers) {
        Map<Id, Integer> userLeadCounts = new Map<Id, Integer>();
        for (User user : onlineUsers) {
            Integer count = user.Capacity__c == null ? 0 : user.Capacity__c.intValue();
            userLeadCounts.put(user.Id, count); 
        }
        userLeadCounts=sortMapByValueAscending(userLeadCounts);
        return userLeadCounts;
    }

    // Method to assign a lead to a user using round-robin
    private static User assignLeadToUser(Integer userIndex, List<User> onlineUsers, Map<Id, Integer> userLeadCounts, Integer maxCapacity) {
        Integer agentSize = onlineUsers.size();
        Integer recordNumber = userIndex;  // The record index for round-robin logic
        User assignedUser = onlineUsers[Math.mod(recordNumber, agentSize)];

        if (userLeadCounts.get(assignedUser.Id) < maxCapacity) {
            return assignedUser;
        }
        return null; // Return null if the user has reached their capacity
    }

    // Method to update the leads after assignment
    private static void updateLeads(List<Lead> leadsToUpdate) {
        if (!leadsToUpdate.isEmpty()) {
            update leadsToUpdate;
        }
    }

    // Method to update the user capacities
    private static void updateUserCapacities(List<User> onlineUsers, Map<Id, Integer> userLeadCounts) {
        List<User> usersToUpdate = new List<User>();
        for (User user : onlineUsers) {
            user.Capacity__c = userLeadCounts.get(user.Id);
            usersToUpdate.add(user);
        }

        if (!usersToUpdate.isEmpty()) {
            update usersToUpdate;
        }
    }
    
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