/**
 * @author Varun Rawal
 *
 * This class, `AOSPDFGenerator`, is a Queueable class that generates a PDF from a Visualforce page,
 * attaches it to the primary contact of an Opportunity, and updates the Opportunity's `Sub_Document_Type__c` field.
 * It implements `Database.AllowsCallouts` to allow HTTP callouts for generating the PDF.
 *
 * Key Features:
 * - Generates a PDF from a specified Visualforce page.
 * - Attaches the PDF to the primary contact of the Opportunity.
 * - Updates the `Sub_Document_Type__c` field on the Opportunity.
 * - Updates or inserts the `Document_Type__c` field on the `ContentVersion` object.
 * - Handles null checks and exceptions to ensure robust execution.
 */

public with sharing class AOSPDFGenerator implements Queueable, Database.AllowsCallouts {
    private Id opportunityId;  // Stores the Opportunity ID
    private String vfPageName; // Stores the Visualforce page name for generating the PDF
    private String newValue;   // Stores the value for Sub_Document_Type__c field on Opportunity
    private String documentType; // Stores the value for Document_Type__c field on ContentVersion

    /**
     * Constructor to initialize class variables.
     *
     * @param opportunityId The ID of the Opportunity.
     * @param vfPageName The name of the Visualforce page used to generate the PDF.
     * @param newValue The value to update the `Sub_Document_Type__c` field on the Opportunity.
     * @param documentType The value to update or insert the `Document_Type__c` field on the ContentVersion.
     */
    public AOSPDFGenerator(Id opportunityId, String vfPageName, String newValue, String documentType) {
        this.opportunityId = opportunityId;
        this.vfPageName = vfPageName;
        this.newValue = newValue;
        this.documentType = documentType;
    }

    /**
     * Execute method required by the Queueable interface.
     * This method generates a PDF, attaches it to the primary contact, and updates the Opportunity.
     *
     * @param context The QueueableContext object provided by the system.
     */
    public void execute(QueueableContext context) {
        try {
            // Null Checks to ensure all necessary parameters are provided
            if (String.isEmpty(opportunityId) || String.isEmpty(vfPageName) || String.isEmpty(newValue) || String.isEmpty(documentType)) {
                System.debug('Error: Opportunity ID, VF Page Name, newValue, and documentType are required.');
                return; // Exit execution if any required parameter is missing
            }

            // Fetch the Opportunity record
            System.debug('Fetching Opportunity Record...');
            Opportunity opp = [SELECT Id, Name, Sub_Document_Type__c FROM Opportunity WHERE Id = :opportunityId LIMIT 1];

            // Generate the PDF from the provided Visualforce Page
            System.debug('Generating PDF from VF Page...');
            PageReference pdfPage = new PageReference('/apex/' + vfPageName);
            pdfPage.getParameters().put('id', opportunityId);
            Blob pdfBlob;
            if(!test.isRunningTest()){
                pdfBlob = pdfPage.getContentAsPDF(); // Callout to generate PDF
            }else{
                 pdfBlob= Blob.valueOf('test'); 
            }
            
            System.debug('PDF Generated Successfully.');

            // Fetch the Primary Contact Role for the Opportunity
            System.debug('Fetching Primary Contact Role...');
            OpportunityContactRole primaryOCR = [
                SELECT ContactId 
                FROM OpportunityContactRole 
                WHERE OpportunityId = :opportunityId 
                AND IsPrimary = TRUE 
                LIMIT 1
            ];

            // Null Check: Ensure a primary contact role exists before proceeding
            if (primaryOCR == null || primaryOCR.ContactId == null) {
                System.debug('No Primary Contact Role found for this Opportunity.');
                return; // Exit if no primary contact is associated with the Opportunity
            }

            // Generate the ContentDocument Title using the Opportunity Name and newValue
            String fileName = newValue + '__' + opp.Name;

            // Check if a document with the same title already exists for the Contact
            System.debug('Checking if document already exists...');
            List<ContentVersion> existingDocuments = [
                SELECT Id, Title, ContentDocumentId 
                FROM ContentVersion 
                WHERE FirstPublishLocationId = :primaryOCR.ContactId 
                AND Title = :fileName 
                ORDER BY CreatedDate DESC 
                LIMIT 1
            ];

            if (!existingDocuments.isEmpty()) {
                // If a document with the same title exists, create a new version of it
                System.debug('Existing document found, creating a new version...');
                ContentVersion newVersion = new ContentVersion();
                newVersion.Title = fileName;
                newVersion.PathOnClient = fileName + '.pdf';
                newVersion.VersionData = pdfBlob;
                newVersion.ContentDocumentId = existingDocuments[0].ContentDocumentId; // Attach as a new version of the existing document
                newVersion.Document_Type__c = documentType; // Set the Document_Type__c field
                insert newVersion;
                System.debug('New version created: ' + newVersion.Id);
            } else {
                // If no document exists, create a new one
                System.debug('No existing document found, creating a new document...');
                ContentVersion cv = new ContentVersion();
                cv.Title = fileName;
                cv.PathOnClient = fileName + '.pdf';
                cv.VersionData = pdfBlob;
                cv.FirstPublishLocationId = primaryOCR.ContactId; // Attach to Contact
                cv.Document_Type__c = documentType; // Set the Document_Type__c field
                insert cv;
                System.debug('New document attached: ' + cv.Id);
            }

            // Update Sub_Document_Type__c field on Opportunity
            System.debug('Updating Sub_Document_Type__c on Opportunity...');
            if (String.isEmpty(opp.Sub_Document_Type__c)) {
                // If the field is empty, assign the new value directly
                opp.Sub_Document_Type__c = newValue;
            } else {
                // If the field already has values, split them and check if newValue exists
                List<String> existingValues = opp.Sub_Document_Type__c.split(';');
                if (!existingValues.contains(newValue)) {
                    // Append newValue if it does not already exist
                    opp.Sub_Document_Type__c += ';' + newValue;
                }
            }

            // Save the updated Opportunity record
            update opp;
            System.debug('Opportunity updated successfully.');

        } catch (Exception e) {
            // Catch any unexpected errors and log them for debugging
            System.debug('Error in generating or attaching PDF: ' + e.getMessage());
            System.debug('Cause: ' + e.getCause());
            System.debug('Stack Trace: ' + e.getStackTraceString());
        }
    }
}