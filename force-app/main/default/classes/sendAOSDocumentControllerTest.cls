@isTest
private class sendAOSDocumentControllerTest {
    
    @testSetup
    static void setupTestData() {
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
    static void testGetDocumentsByContactId() {
        // Fetch test Contact
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];

        // Call the method
        Test.startTest();
        List<ContentDocument> documents = sendAOSDocumentController.getDocumentsByContactId(testContact.Id);
        Test.stopTest();

        // Assertions
    }

    @isTest
    static void testSendDocumentEmail() {
        // Fetch test records
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        Opportunity testOpportunity = [SELECT Id FROM Opportunity LIMIT 1];
        ContentDocument testDoc = [SELECT Id FROM ContentDocument LIMIT 1];

        Test.startTest();
        String result = sendAOSDocumentController.sendDocumentEmail(testContact.Id, testDoc.Id, testOpportunity.Id);
        Test.stopTest();

        // Assertions
    }
}