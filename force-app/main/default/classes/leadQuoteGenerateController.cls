/**
* Author: Harshit Kumar Rai
* Description: For Plot Select and generation quote on lead
*/
public with sharing class leadQuoteGenerateController {
    @AuraEnabled(cacheable=true)
    public static List<Lead> getLeadDetails(Id leadId) {
        try {	
            List<Lead> lsitOfLead = [ SELECT Id, Project__r.Name, Phase__r.Name 
                                     FROM Lead WHERE Id = :leadId LIMIT 1];
            return lsitOfLead;
        } catch (Exception ex) {
            throw new AuraHandledException('Error fetching Lead details: ' + ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static void sendEmail(String oppId) {
        try {
            List<Opportunity> oppList= [Select Id,Contact__c,Contact__r.Email From Opportunity Where Id=:oppId Limit 1];
            if(oppList!=null && oppList[0].Contact__c!=null){
                String recipientEmail = oppList[0].Contact__r.Email;
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(new String[]{ recipientEmail });
                EmailTemplate template = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'Plot_Swapping' LIMIT 1];
                email.setTemplateId(template.Id);
                email.setTargetObjectId(oppList[0].Contact__c); 
                email.setWhatId(oppId);
                email.setTreatTargetObjectAsRecipient(false);
                Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
                if (!results[0].isSuccess()) {
                    System.debug('Email failed to send: ' + results[0].getErrors()[0].getMessage());
                    throw new AuraHandledException(results[0].getErrors()[0].getMessage());
                } else {
                    System.debug('Email sent successfully to ' + recipientEmail);
                }
            }
        } catch (Exception ex) {
            throw new AuraHandledException('Error in sending email: ' + ex.getMessage());
        }
    }
    
    /**
* Searches records on the specified object based on a search key.
*
* @param searchKey The string to search for within the Name field.
* @param objectApiName The API name of the object to search (e.g., 'Unit__c').
* @return A list of sObjects that match the search criteria.
*/
    @AuraEnabled
    public static List<sObject> searchRecords(String searchKey, String objectApiName) {
        // Ensure searchKey is not null to avoid errors
        if (searchKey == null) {
            return new List<sObject>();
        }
        
        // Escape single quotes to prevent SOQL injection
        String escapedSearchKey = String.escapeSingleQuotes(searchKey);
        
        // Construct the dynamic SOQL query
        // NOTE: The field 'Name' is assumed to be present on the searched object.
        String query = 'SELECT Id, Name FROM ' + objectApiName +
            ' WHERE Status__c=\'Available\' AND Name LIKE \'%' + escapedSearchKey + '%\' LIMIT 10';
        
        system.debug(query);
        // Execute the query and return the results
        List<sObject> records = Database.query(query);
        return records;
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getUnitAndLeadDetails(Id unitId) {
        if (unitId == null) {
            return null;
        }
        
        try {
            // Query Unit__c record along with its related Lead__c
            Unit__c unitRecord = [
                SELECT Id, Name, Unit_Code__c, Plot_Facing__c, Plot_Size__c, 
                Status__c, Base_Price_per_Sq_Ft__c, 
                (SELECT Id, FirstName, LastName, Email FROM Leads__r LIMIT 1) 
                FROM Unit__c 
                WHERE Id = :unitId
                LIMIT 1
            ];
            
            Map<String, Object> response = new Map<String, Object>();
            response.put('unit', unitRecord);
            
            // If a related lead exists, include it in the response
            if (unitRecord.Leads__r != null && !unitRecord.Leads__r.isEmpty()) {
                response.put('lead', unitRecord.Leads__r[0]);
            } else {
                response.put('lead', null);
            }
            
            return response;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching Unit and Lead details: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static void saveLeadPlotRecords(List<Lead_Plot__c> leadPlotRecords, List<Quote__c> quoteRecords) {
        try {
            if (leadPlotRecords != null && !leadPlotRecords.isEmpty()) {
                insert leadPlotRecords;
            }
            if (quoteRecords != null && !quoteRecords.isEmpty()) {
                insert quoteRecords;
            }
        } catch (Exception ex) {
            throw new AuraHandledException('Error creating Lead_Plot__c records: ' + ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static List<Quote__c> saveLeadQuoteRecords(List<Quote__c> quoteRecords) {
        try {
            if (quoteRecords != null && !quoteRecords.isEmpty()) {
                insert quoteRecords;
                Set<Id> quoteIds = new Set<Id>();
                for (Quote__c quote : quoteRecords) {
                    quoteIds.add(quote.Id);
                }
                return [SELECT Id, Name, Quote_Name__c, Plot__r.Name, Plot__r.Plot_Size__c  
                        FROM Quote__c WHERE Id IN :quoteIds];
            }
            return null;
        } catch (Exception ex) {
            throw new AuraHandledException('Error creating Quote__c records: ' + ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static List<Opportunity> saveOpportunity(List<Opportunity> oppRecords) {
        try {
            if (oppRecords != null && !oppRecords.isEmpty()) {
                update oppRecords;
                return oppRecords;
            }
            return null;
        } catch (Exception ex) {
            throw new AuraHandledException('Error in updating opportunity plot details: ' + ex.getMessage());
        }
    }
}