public with sharing class sendPaymentLink {
    @AuraEnabled(cacheable=true)
    public static List<Contact> getContactsByOpportunity(Id opportunityId) {
        List<Contact> contacts = new List<Contact>();
        try {
            if (String.isEmpty(opportunityId)) {
                throw new AuraHandledException('Opportunity ID is required.');
            }
            contacts = [
                SELECT Id, Name, Email, Phone FROM Contact 
                WHERE Id IN (
                    SELECT ContactId FROM OpportunityContactRole WHERE OpportunityId = :opportunityId
                )
            ];
            return contacts;
        } catch (Exception ex) {
            throw new AuraHandledException('Error fetching contact details: ' + ex.getMessage());
        }
    }
}