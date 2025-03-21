/**
*********************************************************
Apex Class Name    : leadQuoteGenerateController
Created Date       : March 18, 2025
@description       : For Plot Select and generation quote on lead.
@author            : Harshit Kumar Rai
Modification Log:
Ver   Date         Author                         Modification
1.0   18-03-2025   Harshit Kumar Rai              Initial Version
*********************************************************
*/
public with sharing class leadQuoteGenerateController {

    /*
    *********************************************************
    @Method Name    : getLeadDetails
    @description    : Fetches Lead details for the given Lead Id.
    @param          : leadId - The Id of the Lead record.
    @return         : List of Lead records with related Project and Phase details.
    *********************************************************
    */
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

    /*
    *********************************************************
    @Method Name    : getOppDetails
    @description    : Fetches Opportunity details for the given Opportunity Id.
    @param          : oppId - The Id of the Opportunity record.
    @return         : Opportunity record with related Unit and Lead details.
    *********************************************************
    */
    @AuraEnabled(cacheable=true)
    public static Opportunity getOppDetails(Id oppId) {
        try {	
            Opportunity opp = [SELECT Id, Unit__c, Unit__r.Base_Price_per_Sq_Ft__c, Lead__c 
                               FROM Opportunity WHERE Id = :oppId LIMIT 1];
            return opp;
        } catch (Exception ex) {
            throw new AuraHandledException('Error fetching opp details: ' + ex.getMessage());
        }
    }

    /*
    *********************************************************
    @Method Name    : getLeadQuote
    @description    : Fetches the latest Quote for the given Opportunity Id.
    @param          : oppId - The Id of the Opportunity record.
    @return         : The latest Quote__c record.
    *********************************************************
    */
    @AuraEnabled
    public static Quote__c getLeadQuote(Id oppId) {
        try {	
            Quote__c quote = [SELECT Id FROM Quote__c 
                              WHERE Opportunity__c = :oppId ORDER BY CreatedDate DESC LIMIT 1];
            return quote;
        } catch (Exception ex) {
            throw new AuraHandledException('Error fetching opp details: ' + ex.getMessage());
        }
    }

    /*
    *********************************************************
    @Method Name    : sendEmail
    @description    : Sends an email notification using a predefined email template.
    @param          : oppId - The Id of the Opportunity record.
    @return         : None
    *********************************************************
    */
    @AuraEnabled
    public static void sendEmail(String oppId) {
        try {
            List<Opportunity> oppList = [SELECT Id, Contact__c, Contact__r.Email 
                                         FROM Opportunity WHERE Id = :oppId LIMIT 1];
            if (oppList != null && oppList[0].Contact__c != null) {
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

    /*
    *********************************************************
    @Method Name    : searchRecords
    @description    : Searches records on a specified object using a search key.
    @param          : searchKey - The search string for matching records.
    @param          : objectApiName - The API name of the object to search.
    @return         : List of matching records.
    *********************************************************
    */
    @AuraEnabled
    public static List<sObject> searchRecords(String searchKey, String objectApiName) {
        if (searchKey == null) {
            return new List<sObject>();
        }
        
        String escapedSearchKey = String.escapeSingleQuotes(searchKey);
        String query = 'SELECT Id, Name FROM ' + objectApiName +
            ' WHERE Status__c=\'Available\' AND Name LIKE \'%' + escapedSearchKey + '%\' LIMIT 10';
        
        system.debug(query);
        List<sObject> records = Database.query(query);
        return records;
    }

    /*
    *********************************************************
    @Method Name    : getUnitAndLeadDetails
    @description    : Fetches Unit and related Lead details by Unit Id.
    @param          : unitId - The Id of the Unit record.
    @return         : A map containing Unit and Lead details.
    *********************************************************
    */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getUnitAndLeadDetails(Id unitId) {
        if (unitId == null) {
            return null;
        }
        
        try {
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
            response.put('lead', unitRecord.Leads__r != null && !unitRecord.Leads__r.isEmpty() 
                          ? unitRecord.Leads__r[0] : null);
            return response;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching Unit and Lead details: ' + e.getMessage());
        }
    }

    /*
    *********************************************************
    @Method Name    : saveLeadPlotRecords
    @description    : Inserts Lead_Plot__c and Quote__c records.
    @param          : leadPlotRecords - List of Lead_Plot__c records.
    @param          : quoteRecords - List of Quote__c records.
    @return         : None
    *********************************************************
    */
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

    /*
    *********************************************************
    @Method Name    : saveOpportunity
    @description    : Updates existing Opportunity records.
    @param          : oppRecords - List of Opportunity records.
    @return         : Updated Opportunity records.
    *********************************************************
    */
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