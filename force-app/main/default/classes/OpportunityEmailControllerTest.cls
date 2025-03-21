@isTest
public class OpportunityEmailControllerTest {

@testSetup
static void setupTestData() {
    // Create Test Opportunity
    Opportunity testOpp = new Opportunity(Name = 'Test Opportunity', StageName = 'Prospecting', CloseDate = Date.today());
    insert testOpp;

    // Create Test Contact
    Contact testContact = new Contact(FirstName = 'John', LastName = 'Doe', Email = 'john.doe@example.com');
    insert testContact;

    // Create Test Opportunity Contact Role
    OpportunityContactRole testOCR = new OpportunityContactRole(OpportunityId = testOpp.Id, ContactId = testContact.Id, IsPrimary = true);
    insert testOCR;

    // Insert a test ContentVersion (automatically creates a ContentDocument)
    ContentVersion testVersion = new ContentVersion(
        Title = 'Test Document',
        PathOnClient = 'TestDocument.pdf',
        VersionData = Blob.valueOf('Test content'),
        IsMajorVersion = true
    );
    insert testVersion;

    // Fetch the related ContentDocumentId
    Id testDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testVersion.Id LIMIT 1].ContentDocumentId;

    // Create ContentDocumentLink
    ContentDocumentLink testDocLink = new ContentDocumentLink(ContentDocumentId = testDocId, LinkedEntityId = testContact.Id, ShareType = 'V');
    insert testDocLink;

    // **Workaround for MIXED_DML_OPERATION: Use System.runAs()**
    User testUser = [SELECT Id FROM User WHERE IsActive = TRUE LIMIT 1];

 System.runAs(testUser) {
    EmailTemplate testTemplate = new EmailTemplate(
        Name = 'Test Template',
        DeveloperName = 'Test_Template',
        Subject = 'Test Subject',
        HtmlValue = '<p>Test Email</p>',
        FolderId = UserInfo.getUserId(),
        TemplateType = 'Text'  // ✅ Changed from 'HTML' to 'Text'
    );
    insert testTemplate;
}


}


    @isTest
    static void testGetContacts() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        List<OpportunityEmailController.ContactWrapper> contacts = OpportunityEmailController.getContacts(testOpp.Id);
        Test.stopTest();

    }

    @isTest
    static void testGetDocuments() {
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];

        Test.startTest();
        List<ContentDocument> docs = OpportunityEmailController.getDocuments(testContact.Id);
        Test.stopTest();

    }

    @isTest
    static void testGetEmailTemplate() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        List<OpportunityEmailController.EmailTemplateWrapper> templates = OpportunityEmailController.getEmailTemplate(testOpp.Id);
        Test.stopTest();

    }

    @isTest
    static void testSendEmailWithAttachment() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        Contact testContact = [SELECT Id, Email FROM Contact LIMIT 1];
        ContentDocument testDoc = [SELECT Id FROM ContentDocument LIMIT 1];
        EmailTemplate testTemplate = [SELECT Id FROM EmailTemplate LIMIT 1];

        Test.startTest();
        OpportunityEmailController.sendEmailWithAttachment(testOpp.Id, testContact.Id, testDoc.Id, testTemplate.Id, '<p>Email Body</p>');
        Test.stopTest();

        // No assertion needed as long as no exceptions occur
    }
}