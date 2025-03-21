@isTest
public class clientSharedDocumentControllerTest {
    @testSetup
    static void setupTestData() {
        // Create a test Opportunity
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert testOpportunity;

        // Create a test Contact
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'test@example.com'
        );
        insert testContact;

        // Link Contact to Opportunity
        OpportunityContactRole ocr = new OpportunityContactRole(
            OpportunityId = testOpportunity.Id,
            ContactId = testContact.Id,
            Role = 'Decision Maker',
            IsPrimary = true
        );
        insert ocr;

        // Create a test ContentDocumentLink
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'TestDocument.pdf',
            VersionData = Blob.valueOf('Test Data'),
            IsMajorVersion = true
        );
        insert contentVersion;

        ContentDocument contentDocument = [SELECT Id FROM ContentDocument WHERE LatestPublishedVersionId = :contentVersion.Id LIMIT 1];

        ContentDocumentLink contentLink = new ContentDocumentLink(
            LinkedEntityId = testOpportunity.Id,
            ContentDocumentId = contentDocument.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert contentLink;
    }

    @isTest
    static void testGetRelatedFilesByRecordId() {
        Opportunity testOpportunity = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        Map<ID, String> result = clientSharedDocumentController.getRelatedFilesByRecordId(testOpportunity.Id);
        Test.stopTest();

    }

    @isTest
    static void testCheckOpportunityContact() {
        Opportunity testOpportunity = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        List<Contact> contacts = clientSharedDocumentController.checkOpportunityContact(testOpportunity.Id);
        Test.stopTest();

    }
   @isTest
static void testNullCheckOpportunityContact() {
    Test.startTest();
    
    try {
        List<Contact> contacts = clientSharedDocumentController.checkOpportunityContact(null);
    } catch (Exception ex) {
        System.debug('Exception occurred: ' + ex.getMessage());
    }

    Test.stopTest();
}

}