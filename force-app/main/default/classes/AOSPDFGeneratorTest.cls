@isTest
public class AOSPDFGeneratorTest {
    
    @testSetup
    static void setupTestData() {
        // Create a test Unit record
        Unit__c testUnit = new Unit__c(Name = 'Test Unit');
        insert testUnit;
        
        // Create a test Opportunity record
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Unit__c = testUnit.Id,
            Sale_Value_Amount__c = 100000
        );
        insert testOpportunity;
        
        // Create a test Contact record
        Contact testContact = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'johndoe@example.com'
        );
        insert testContact;
        
        // Create a test OpportunityContactRole record
        OpportunityContactRole testOCR = new OpportunityContactRole(
            OpportunityId = testOpportunity.Id,
            ContactId = testContact.Id,
            IsPrimary = true
        );
        insert testOCR;
    }
    
    @isTest
    static void testAOSPDFGenerator() {
        // Get test Opportunity record
        Opportunity testOpportunity = [SELECT Id FROM Opportunity LIMIT 1];
        
        // Define test parameters
        String vfPageName = 'TestPage';
        String newValue = 'New Document';
        String documentType = 'PDF';
        
        // Instantiate the class
        Test.startTest();
        AOSPDFGenerator pdfGenerator = new AOSPDFGenerator(testOpportunity.Id, vfPageName, newValue, documentType);
        System.enqueueJob(pdfGenerator);
        Test.stopTest();
        
        // Verify that Opportunity has been updated
        testOpportunity = [SELECT Sub_Document_Type__c FROM Opportunity WHERE Id = :testOpportunity.Id];
        System.assert(testOpportunity.Sub_Document_Type__c.contains(newValue), 'Sub_Document_Type__c should be updated');
        
        // Verify that ContentVersion was created
        List<ContentVersion> contentVersions = [SELECT Id, Title FROM ContentVersion WHERE Title LIKE :newValue + '%'];
        System.assert(contentVersions.size() > 0, 'ContentVersion should be created');
    }
}