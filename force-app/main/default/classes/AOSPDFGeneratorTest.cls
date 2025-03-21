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
            Sub_Document_Type__c='AOS',
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
      String expectedFileName = 'New Document__Test Opportunity'; // newValue + '__' + opp.Name

ContentVersion testContent = new ContentVersion(
    Title = expectedFileName, // Use the dynamically generated file name
    PathOnClient = expectedFileName + '.pdf',
    VersionData = Blob.valueOf('Test Content'), 
    FirstPublishLocationId = testContact.Id,
    Document_Type__c='AOS'
);
insert testContent;
    }
    
    @isTest
    static void testAOSPDFGenerator() {
        // Get test Opportunity record
        Opportunity testOpportunity = [SELECT Id FROM Opportunity LIMIT 1];
        
        // Define test parameters
        String vfPageName = 'TestPage';
        String newValue = 'New Document';
        String documentType = 'AOS';
        
        // Instantiate the class
        Test.startTest();
        AOSPDFGenerator pdfGenerator = new AOSPDFGenerator(testOpportunity.Id, vfPageName, newValue, documentType);
        System.enqueueJob(pdfGenerator);
        Test.stopTest();
        
     
    
}
    @isTest
    static void testAOSPDFGeneratorMethod1() {
        // Get test Opportunity record
        Opportunity testOpportunity = [SELECT Id FROM Opportunity LIMIT 1];
        ContentVersion testCv=[Select id,Title from ContentVersion limit 1];
        testcv.Title='New';
        update testcv;
        // Define test parameters
        String vfPageName = 'TestPage';
        String newValue = 'New Document';
        String documentType = 'AOS';
        
        // Instantiate the class
        Test.startTest();
        AOSPDFGenerator pdfGenerator = new AOSPDFGenerator(testOpportunity.Id, vfPageName, newValue, documentType);
        System.enqueueJob(pdfGenerator);
        Test.stopTest();
        
     
    }
       @isTest
    static void testAOSPDFGeneratorMethod2() {
        // Get test Opportunity record
        Opportunity testOpportunity = [SELECT Id FROM Opportunity LIMIT 1];
        ContentVersion testCv=[Select id,Title from ContentVersion limit 1];
        testcv.Title='New';
        update testcv;
        // Define test parameters
        String vfPageName = 'TestPage';
        String newValue = 'New Document';
        String documentType = 'AOS';
        
        // Instantiate the class
        Test.startTest();
        AOSPDFGenerator pdfGenerator = new AOSPDFGenerator(testOpportunity.Id, vfPageName, 'AOS', documentType);
        System.enqueueJob(pdfGenerator);
        Test.stopTest();
        
     
    }
}