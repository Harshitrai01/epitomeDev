public with sharing class UserTriggerHandler {
    
    public static void handleStatusChange(List<User> newUsers, Map<Id, User> oldUserMap) {
        for (User newUser : newUsers) {
            User oldUser = oldUserMap.get(newUser.Id);
            if (oldUser != null && newUser.Status__c != oldUser.Status__c) {
                processLeadAssignment();
                break;
            }
        }
    }
    
    public static void processLeadAssignment() {
        try {
            Map<String, Pre_Sales_Data__c> settings = fetchPreSalesSettings();
            Boolean preSalesEnabled = settings.containsKey('Pre-Sales Assignment') && settings.get('Pre-Sales Assignment').Value__c == 'true';
            Boolean salesEnabled = settings.containsKey('Sales Assignment') && settings.get('Sales Assignment').Value__c == 'true';
            
            Set<Id> userIds = fetchEligibleUserIds(preSalesEnabled, salesEnabled);
            if (userIds.isEmpty()) return;
            
            Group preSalesQueue = fetchQueueByName('Pre_Sales_Queue');
            Integer maxCapacity = Integer.valueOf(Label.Lead_Assignment_Capacity);
            List<User> availableUsers = fetchAvailableUsers(userIds, maxCapacity);
            if (availableUsers.isEmpty()) return;
            system.debug('availableUsers--->'+availableUsers);
            List<Lead> unassignedLeads = fetchUnassignedLeads(preSalesQueue.Id);
            if (unassignedLeads.isEmpty()) return;
            system.debug('unassignedLeads--->'+unassignedLeads);
            
            assignLeadsToUsers(unassignedLeads, availableUsers, maxCapacity);
        } catch (Exception e) {
            System.debug('Error in processLeadAssignment: ' + e.getMessage());
            throw new AuraHandledException('An error occurred. Contact support.');
        }
    }
    
    private static Map<String, Pre_Sales_Data__c> fetchPreSalesSettings() {
        Map<String, Pre_Sales_Data__c> settings = new Map<String, Pre_Sales_Data__c>();
        for (Pre_Sales_Data__c setting : [SELECT Name, Value__c FROM Pre_Sales_Data__c WHERE Name IN ('Pre-Sales Assignment', 'Sales Assignment')]) {
            settings.put(setting.Name, setting);
        }
        return settings;
    }
    
    private static Set<Id> fetchEligibleUserIds(Boolean preSalesEnabled, Boolean salesEnabled) {
        Set<Id> userIds = new Set<Id>();
        if (preSalesEnabled) userIds.addAll(getQueueMemberIds('Pre_Sales_Queue'));
        if (salesEnabled) userIds.addAll(getQueueMemberIds('Sales_Queue'));
        return userIds;
    }
    
    private static Group fetchQueueByName(String queueName) {
        return [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = :queueName LIMIT 1];
    }
    
    private static List<User> fetchAvailableUsers(Set<Id> userIds, Integer maxCapacity) {
        List<User> users = [
            SELECT Id, Capacity__c, Pre_Sales_Lead_Assignment__c, Assigned_Sources__c, Max_Load__c
            FROM User 
            WHERE Status__c = 'Online'
            AND Id IN :userIds
            AND Pre_Sales_Lead_Assignment__c = true
        ];
        
        // Step 2: Filter users based on Capacity__c < Max_Load__c using a for loop
        List<User> filteredUsers = new List<User>();
        for (User u : users) {
            if (u.Capacity__c < u.Max_Load__c) {
                filteredUsers.add(u); // Add user to the filtered list if the condition is met
            }
        }
        
        // Step 3: Return the filtered list
        return filteredUsers;
    }
    
    private static List<Lead> fetchUnassignedLeads(Id queueId) {
        return [
            SELECT Id, OwnerId, Status, LeadSource 
            FROM Lead 
            WHERE OwnerId = :queueId 
            AND Status = 'Unopened' 
            ORDER BY CreatedDate DESC
        ];
    }
    
    private static void assignLeadsToUsers(List<Lead> leads, List<User> availableUsers, Integer maxCapacity) {
        Map<Id, Integer> userLeadCounts = initializeUserLeadCounts(availableUsers);
        List<Lead> leadsToUpdate = new List<Lead>();
        List<User> usersToUpdate = new List<User>();
        
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
        
        Map<Id, Decimal> userMaxLoadMap = new Map<Id, Decimal>();
        
        // Iterate through the availableUsers list and populate the map
        for (User u : availableUsers) {
            userMaxLoadMap.put(u.Id, u.Max_Load__c);
        }
        
        system.debug('source '+sourceToUsersMap);
        Map<String, Integer> sourceIndexMap = new Map<String, Integer>();
        
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
                system.debug('candidateUser '+candidateUser);
                Decimal maxLoad = userMaxLoadMap.get(candidateUser.Id);
                
                if (currentCount < maxLoad) {
                    lead.OwnerId = candidateUser.Id;
                    leadsToUpdate.add(lead);
                    userLeadCounts.put(candidateUser.Id, currentCount + 1);
                    if (!usersToUpdate.contains(candidateUser)) {
                        usersToUpdate.add(candidateUser);
                    }
                    sourceIndexMap.put(leadSource, indexToCheck + 1);
                    system.debug('sourceIndexMap '+sourceIndexMap);
                    assigned = true;
                    break;
                }
            }
        }
        
        if (!leadsToUpdate.isEmpty()) update as user leadsToUpdate;
        system.debug('leadsToUpdate-->'+leadsToUpdate);
        if (!usersToUpdate.isEmpty()) {
            for (User u : usersToUpdate) {
                u.Capacity__c = userLeadCounts.get(u.Id);
            }
            update usersToUpdate;
        }
    }
    
    private static Map<Id, Integer> initializeUserLeadCounts(List<User> users) {
        Map<Id, Integer> userLeadCounts = new Map<Id, Integer>();
        for (User user : users) {
            userLeadCounts.put(user.Id, user.Capacity__c != null ? Integer.valueOf(user.Capacity__c) : 0);
        }
        return userLeadCounts;
    }
    
    private static Set<Id> getQueueMemberIds(String queueDeveloperName) {
        Group grp = [SELECT Id FROM Group WHERE DeveloperName = :queueDeveloperName AND Type = 'Queue' LIMIT 1];
        Set<Id> userIds = new Set<Id>();
        for (GroupMember gm : [SELECT UserOrGroupId FROM GroupMember WHERE GroupId = :grp.Id]) {
            userIds.add(gm.UserOrGroupId);
        }
        return userIds;
    }
}