public class UserStatusController {

    @AuraEnabled(cacheable=true)
    public static String getCurrentUserStatus() {
        try {
            User currentUser = [SELECT Status__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            
            return currentUser.Status__c != null ? currentUser.Status__c : 'Offline';
        } catch (Exception e) {
            System.debug('Error in getCurrentUserStatus: ' + e.getMessage());
            throw new AuraHandledException('Error retrieving user status');
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getStatusPicklistValues() {
        List<String> picklistValues = new List<String>();
        try {
            Schema.DescribeFieldResult fieldResult = User.Status__c.getDescribe();
            List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();
            
            for (Schema.PicklistEntry entry : picklistEntries) {
                if (entry.isActive()) {
                    picklistValues.add(entry.getValue());
                }
            }
        } catch (Exception e) {
            System.debug('Error in getStatusPicklistValues: ' + e.getMessage());
            throw new AuraHandledException('Error retrieving status picklist values');
        }
        
        return picklistValues;
    }

    @AuraEnabled
    public static String updateUserStatus(String newStatus) {
        try {
            User currentUser = [SELECT Id, Status__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            
            currentUser.Status__c = newStatus;
            update currentUser;
            
            return 'Status updated to ' + newStatus;
        } catch (Exception e) {
            System.debug('Error in updateUserStatus: ' + e.getMessage());
            throw new AuraHandledException('Error updating user status');
        }
    }
}