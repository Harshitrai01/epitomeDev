public class leadQuoteGenerateController {
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
                return quoteRecords;
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