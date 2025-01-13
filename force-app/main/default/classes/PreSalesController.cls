public class PreSalesController {
    @AuraEnabled(cacheable=true)
    public static String getCustomSetting(String name) {
        Pre_Sales_Data__c setting = [SELECT Value__c FROM Pre_Sales_Data__c WHERE Name = :name LIMIT 1];
        return setting.Value__c;
    }

    @AuraEnabled(cacheable=true)
    public static String getUserData(Boolean isLeadOverload) {
        List<Id> queueIds = new List<Id>();
        List<Group> queues = new List<Group>();

        // Fetch queue IDs based on isLeadOverload
        if (!isLeadOverload) {
            queues = [SELECT Id, Name FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Pre_Sales_Queue' LIMIT 1];
        } else {
            queues = [SELECT Id, Name FROM Group WHERE Type = 'Queue' AND 
                      (DeveloperName = 'Pre_Sales_Queue' OR DeveloperName = 'Sales_Queue') LIMIT 2];
        }

        Map<Id, String> queueMap = new Map<Id, String>();
        for (Group grp : queues) {
            queueIds.add(grp.Id);
            queueMap.put(grp.Id, grp.Name); // Map queue IDs to their names
        }

        List<Map<String, Object>> userData = new List<Map<String, Object>>();
        for (GroupMember gm : [
            SELECT UserOrGroupId, GroupId FROM GroupMember WHERE GroupId IN :queueIds
        ]) {
            User user = [
                SELECT Id, Name, Status__c, Capacity__c FROM User WHERE Id = :gm.UserOrGroupId LIMIT 1
            ];
            Map<String, Object> userEntry = new Map<String, Object>();
			userEntry.put('UserId', user.Id);
            userEntry.put('Name', user.Name);
            userEntry.put('Status__c', user.Status__c);
            userEntry.put('Capacity__c', user.Capacity__c);
            userEntry.put('Queue', queueMap.get(gm.GroupId)); // Add the queue name
            userData.add(userEntry);
        }

        // Serialize user data as JSON
        return JSON.serialize(userData);
    }

    @AuraEnabled
    public static void updateUserStatus(List<User> updates) {
        update updates;
    }
}