@isTest
private class sendAOSDocumentControllerTest {

    // Utility method to create a test Contact
    private static Contact createTestContact() {
        Contact con = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'test.contact@example.com'
        );
        insert con;
        return con;
    }

    // Utility method to create a test Opportunity
    private static Opportunity createTestOpportunity(Id contactId) {
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addMonths(1),
            ContactId = contactId,
            Sale_Value_Amount__c = 500000
        );
        insert opp;
        return opp;
    }

    // Utility method to create a test ContentDocument and ContentVersion
    private static ContentVersion createTestDocument(Id opportunityId, Id contactId) {
        // Fetch a ContentDocument first
        ContentDocument doc = [SELECT FileType FROM ContentDocument WHERE FileType = 'PDF' LIMIT 1];
        

        // Create ContentVersion related to ContentDocument
        ContentVersion contentVersion = new ContentVersion(
            ContentDocumentId = doc.Id,
            Title = doc.Title,
            PathOnClient = 'AOS_Document.pdf',
            FirstPublishLocationId = contactId,
            VersionData = Blob.valueOf('Test PDF Content')
        );
        insert contentVersion;

        return contentVersion;
    }

    @isTest
    static void testGetDocumentsByContactId() {
        // Create test data
        Contact con = createTestContact();
        Opportunity opp = createTestOpportunity(con.Id);
        ContentVersion contentVersion = createTestDocument(opp.Id, con.Id);

        // Link the document to the contact via ContentDocumentLink
        ContentDocumentLink docLink = new ContentDocumentLink(
            ContentDocumentId = contentVersion.ContentDocumentId,
            LinkedEntityId = con.Id
        );
        insert docLink;

        // Test the getDocumentsByContactId method
        Test.startTest();
        List<ContentDocument> docs = sendAOSDocumentController.getDocumentsByContactId(con.Id);
        Test.stopTest();

    }

    @isTest
    static void testSendDocumentEmail() {
        // Create test data
        Contact con = createTestContact();
        Opportunity opp = createTestOpportunity(con.Id);
        ContentVersion contentVersion = createTestDocument(opp.Id, con.Id);

        // Link the document to the contact via ContentDocumentLink
        ContentDocumentLink docLink = new ContentDocumentLink(
            ContentDocumentId = contentVersion.ContentDocumentId,
            LinkedEntityId = con.Id
        );
        insert docLink;

        // Create an Email Template for testing
        EmailTemplate emailTemplate = new EmailTemplate(
            DeveloperName = 'AOS_Email_Template',
            Name = 'AOS Email Template',
            Subject = 'Test Subject',
            HtmlValue = 'Test HTML Content',
            IsActive = true
        );
        insert emailTemplate;

        Test.startTest();
        
        // Call the sendDocumentEmail method to simulate sending the email
        String result = sendAOSDocumentController.sendDocumentEmail(con.Id, contentVersion.ContentDocumentId, opp.Id);
        
        Test.stopTest();

        // Assert that the email is sent successfully
    }

    @isTest
    static void testSendDocumentEmailNoEmail() {
        // Create test data without Email for Contact
        Contact con = new Contact(
            FirstName = 'Test',
            LastName = 'Contact'
        );
        insert con;
        
        Opportunity opp = createTestOpportunity(con.Id);
        ContentVersion contentVersion = createTestDocument(opp.Id, con.Id);
        ContentDocumentLink docLink = new ContentDocumentLink(
            ContentDocumentId = contentVersion.ContentDocumentId,
            LinkedEntityId = con.Id
        );
        insert docLink;

        Test.startTest();
        
        // Try sending email with contact having no email
        try {
            sendAOSDocumentController.sendDocumentEmail(con.Id, contentVersion.ContentDocumentId, opp.Id);
        } catch (AuraHandledException e) {
        }

        Test.stopTest();
    }

    @isTest
    static void testSendDocumentEmailNoDocument() {
        // Create test data
        Contact con = createTestContact();
        Opportunity opp = createTestOpportunity(con.Id);
        
        Test.startTest();
        
        // Try sending email with a non-existing document
        try {
            sendAOSDocumentController.sendDocumentEmail(con.Id, 'non_existing_document_id', opp.Id);
        } catch (AuraHandledException e) {
        }

        Test.stopTest();
    }

    @isTest
    static void testSendDocumentEmailNoOpportunity() {
        // Create test data
        Contact con = createTestContact();
        ContentVersion contentVersion = createTestDocument(null, null);  // No Opportunity ID

        Test.startTest();

        // Try sending email with a non-existing opportunity
        try {
            sendAOSDocumentController.sendDocumentEmail(con.Id, contentVersion.ContentDocumentId, 'non_existing_opportunity_id');
        } catch (AuraHandledException e) {
        }

        Test.stopTest();
    }

}