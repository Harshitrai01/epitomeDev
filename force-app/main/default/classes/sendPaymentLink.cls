/*
*********************************************************
Apex Class Name    : sendPaymentLink
Created Date       : 18th March 2025
@description       : This class is used to fetch contact details associated with a specific opportunity. 
                     It provides an Aura-enabled method to retrieve contacts linked to an opportunity 
                     via OpportunityContactRole.
@author            : Harshit Kumar Rai
Modification Log:
Ver   Date             Author                               Modification
1.0   18th March 2025  Harshit Kumar Rai              Initial Version
*********************************************************
*/
public with sharing class sendPaymentLink {

    /*
    *********************************************************
    @Method Name    : getContactsByOpportunity
    @author         : Harshit Kumar Rai
    @description    : This method retrieves a list of contacts associated with a specific opportunity 
                       using the OpportunityContactRole relationship. It is Aura-enabled and cacheable.
    @param          : Id opportunityId - The ID of the opportunity for which contacts are to be fetched.
    @return         : List<Contact> - A list of contacts associated with the opportunity.
    @throws         : AuraHandledException - If the opportunity ID is empty or an error occurs while fetching contacts.
    ********************************************************
    */
    @AuraEnabled(cacheable=true)
    public static List<Contact> getContactsByOpportunity(Id opportunityId) {
        List<Contact> contacts = new List<Contact>();
        try {
            // Validate the opportunity ID
            if (String.isEmpty(opportunityId)) {
                throw new AuraHandledException('Opportunity ID is required.');
            }
            
            // Query contacts associated with the opportunity via OpportunityContactRole
            contacts = [
                SELECT Id, Name, Email, Phone 
                FROM Contact 
                WHERE Id IN (
                    SELECT ContactId 
                    FROM OpportunityContactRole 
                    WHERE OpportunityId = :opportunityId
                )
            ];
            return contacts;
        } catch (Exception ex) {
            // Handle exceptions and throw an AuraHandledException
            throw new AuraHandledException('Error fetching contact details: ' + ex.getMessage());
        }
    }
}