/**
*********************************************************
Apex Class Name    : OpportunityTriggerHandler
Created Date       : 
@description       : Trigger Handler class for Opportunity record operations.
Handles logic for Opportunity insert, update, and email notifications.
@author            : Harshit Kumar Rai
Modification Log   :
Ver   Date         Author                         Modification
1.0   18-03-2025   Harshit Kumar Rai             Initial Version
*********************************************************
*/
public class OpportunityTriggerHandler {
    
    /**
*********************************************************
@Method Name    : handleAfterInsert
@description    : Handles logic after Opportunity records are inserted.
- Collects Opportunity Ids.
- Queries related Unit records with Virtual Account details.
- Calls InstaCollectBatch to create Virtual Accounts (outside test context).
@param          : newOpportunities - List of newly inserted Opportunity records.
@return         : None
*********************************************************
*/
    public static void handleAfterInsert(List<Opportunity> newOpportunities) {
        try{
            if(!newOpportunities.isEmpty()){
                List<String> opportunityIds = new List<String>();
                for (Opportunity opp : newOpportunities) {
                    opportunityIds.add(opp.Id);
                }
                List<Opportunity> oppList = [Select Id, Unit__c, Unit__r.Name, Unit__r.Virtual_Account_Id__c, Unit__r.Phase__c,
                                             ContactId
                                             From Opportunity Where ID IN: opportunityIds WITH USER_MODE];
                List<String> responseList = new List<String>();
                Set<Id> listOfPlotIds = New Set<Id>();
                
                if(oppList!=null){
                    for (Opportunity opp : oppList) {
                        if(opp.Unit__c!=null){
                            if(opp?.Unit__r?.Virtual_Account_Id__c == null){
                                if (!Test.isRunningTest()) {
                                    listOfPlotIds.add(opp.Unit__c);
                                    //EasebuzzInstaCollectService.createVirtualAccount(opp.Unit__c);
                                }else {
                                    System.debug('Skipping API call in test context');
                                }
                            }else{
                                System.Debug('Virtual Account Details Already Present');
                            }
                        }else{
                            System.Debug('Plot is not present');
                        }
                    }
                    if (!Test.isRunningTest()) {
                        if(listOfPlotIds!=null && !listOfPlotIds.isEmpty()){
                            Database.executeBatch(new InstaCollectBatch(oppList,listOfPlotIds), 50);
                        }else{
                            Database.executeBatch(new PaymentSendLinkEasyCollect(oppList), 50);
                        }
                    } else {
                        System.debug('Skipping batch execution in test context');
                    }
                }
                
            }
        }catch (Exception ex){
            throw New AuraHandledException(ex.getMessage());
        }
    }
    
    public static void handleAfterUpdate(List<Opportunity> newOpportunities){
        
    }
    
    /**
*********************************************************
@Method Name    : sendPlotCancellationEmail
@description    : Sends cancellation emails to Opportunity contacts.o
oppIds
69
}
70
}catch (Exception ex){
71
throw New AuraHandledException(ex.getMessage());
72
}
73
}
74

75
public static void handleAfterUpdate(List<Opportunity> newOpportunities){
76

77
}
78

79
/**
80
*********************************************************
81
@Method Name    : sendPlotCancellationEmail
82
@description    : Sends cancellation emails to Opportunity contacts.
83
- Updates the Date_of_Cancellation__c field.
84
- Sends an email notification using the 'Plot_Cancellation_Email' template.
85
@param          : oppIds - List of Opportunity record Ids.
86
@return         : None
87
*********************************************************
- Updates the Date_of_Cancellation__c field.
- Sends an email notification using the 'Plot_Cancellation_Email' template.
@param          : oppIds - List of Opportunity record Ids.
@return         : None
*********************************************************
*/
    public static void sendPlotCancellationEmail(List<Id> oppIds){
        List<Opportunity> oppList = [Select Id,Contact__c,Contact__r.Email,Date_of_Cancellation__c From Opportunity Where ID IN:oppIds];
        for(Opportunity opp : oppList){
            opp.Date_of_Cancellation__c=System.Today();
        }
        if(oppList!=null){
            update oppList;
        }
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        EmailTemplate template = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'Plot_Cancellation_Email' LIMIT 1];
        for(Opportunity opp : oppList){
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            String recipientEmail = opp.Contact__r.Email;
            email.setToAddresses(new String[]{ recipientEmail });
            email.setTemplateId(template.Id);
            email.setTargetObjectId(opp.Contact__c); 
            email.setWhatId(opp.Id);
            email.setTreatTargetObjectAsRecipient(false);
            emails.add(email);
        }
        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
    }
    /**
* This method, `handleAfterUpdate`, is part of a trigger handler class and is designed to handle specific logic
* when an Opportunity's stage is updated. It checks for transitions to specific stages (AOS, Registration Initiate, Progressive)
* and triggers corresponding actions, such as generating PDFs using Visualforce pages and updating the Opportunity's `Sub_Document_Type__c` field.
*
* Key Features:
* - Handles stage transitions for Opportunities.
* - Triggers PDF generation for specific stages using Visualforce pages.
* - Enqueues asynchronous jobs for PDF generation.
* - Includes null checks and ensures robust execution.
*/
    
    public static void handleAfterUpdate(List<Opportunity> newOpportunities, Map<Id, Opportunity> oldOpportunitiesMap) {
        // Iterate through the updated Opportunities
        for (Opportunity opp : newOpportunities) {
            // Retrieve the old version of the Opportunity from the map
            Opportunity oldOpp = oldOpportunitiesMap.get(opp.Id);
            
            // Null check: Ensure the old Opportunity record exists
            if (oldOpp == null) {
                continue; // Skip processing if the old record is not found
            }
            
            // Handle AOS Stage
            if (oldOpp.StageName != 'AOS' && opp.StageName == 'AOS') {
                system.debug('AOS');
                handleAOSStage(opp); // Trigger AOS stage logic
            }
            
            // Handle Reg Initiate Stage
            if (oldOpp.StageName != 'Registration Initiate' && opp.StageName == 'Registration Initiate') {
                handleRegInitiateStage(opp); // Trigger Registration Initiate stage logic
            }
            
            // Handle Progressive Stage
            if (oldOpp.StageName != 'Progressive' && opp.StageName == 'Progressive') {
                handleProgressiveStage(opp); // Trigger Progressive stage logic
            }
        }
    }
    
    /**
* Helper method to handle AOS Stage logic.
* Determines the appropriate Visualforce page based on the Opportunity's `Type_of_Booking__c` field
* and enqueues a job to generate a PDF.
*
* @param opp The Opportunity record.
*/
    private static void handleAOSStage(Opportunity opp) {
        String vfPageName;
        // Determine the Visualforce page based on the Opportunity's type
        if (opp.Type_of_Booking__c == 'Retail') {
            vfPageName = 'RetailAOSPdf';
        } else if (opp.Type_of_Booking__c == 'Judiciary' || 
                   opp.Type_of_Booking__c == 'SBI' || 
                   opp.Type_of_Booking__c == 'IDBI') {
                       vfPageName = 'IDBI_JU_SBI_AOS';
                   }
        
        // Null check: Ensure a valid Visualforce page name is determined
        if (vfPageName != null) {
            // Enqueue a job to generate the PDF
            System.enqueueJob(new AOSPDFGenerator(opp.Id, vfPageName, 'System Generated AOS','AOS'));
        }
    }
    
    /**
* Helper method to handle Registration Initiate Stage logic.
* Determines the appropriate Visualforce page based on the Opportunity's `Type_of_Booking__c` field
* and enqueues jobs to generate PDFs for the Sale Deed and Board of Resolution.
*
* @param opp The Opportunity record.
*/
    @TestVisible
    private static void handleRegInitiateStage(Opportunity opp) {
        String vfPageName;
        // Determine the Visualforce page based on the Opportunity's type
        if (opp.Type_of_Booking__c == 'Retail') {
            vfPageName = 'Sales_Deed_Regular';
        } else if (opp.Type_of_Booking__c == 'Judiciary' || 
                   opp.Type_of_Booking__c == 'SBI' || 
                   opp.Type_of_Booking__c == 'IDBI') {
                       vfPageName = 'Sales_Deed_Bulk';
                   }
        
        // Null check: Ensure a valid Visualforce page name is determined
        if (vfPageName != null) {
            // Enqueue jobs to generate PDFs for the Sale Deed and Board of Resolution and Form 32
            System.enqueueJob(new AOSPDFGenerator(opp.Id, vfPageName, 'System Generated Sale Deed','Registration Initiate'));
            System.enqueueJob(new AOSPDFGenerator(opp.Id, 'BoardOfResolution', 'System Generated Board of Resolution','Registration Initiate'));
            System.enqueueJob(new AOSPDFGenerator(opp.Id, 'Form32_VfPage', 'System Generated Form 32','Registration Initiate'));
        }
    }
    
    /**
* Helper method to handle Progressive Stage logic.
* Enqueues a job to generate a PDF for the Demand Letter.
*
* @param opp The Opportunity record.
*/
    @TestVisible
    private static void handleProgressiveStage(Opportunity opp) {
        String vfPageName = 'DemandLetter';
        // Enqueue a job to generate the PDF for the Demand Letter
        System.enqueueJob(new AOSPDFGenerator(opp.Id, vfPageName, 'System Generated Demand Letter','Progressive'));
    }
}