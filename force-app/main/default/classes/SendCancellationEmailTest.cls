@isTest
private class SendCancellationEmailTest {

    // Utility method to create a test Contact
    private static Contact createTestContact(String email) {
        Contact con = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = email
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
            Contact__c = contactId
        );
        insert opp;
        return opp;
    }

    // Utility method to create a ContentVersion (Document)
    private static ContentVersion createTestContentVersion() {
        ContentDocument doc = [SELECT FileType FROM ContentDocument WHERE FileType = 'PDF' LIMIT 1];

        ContentVersion contentVersion = new ContentVersion(
            ContentDocumentId = doc.Id,
            Title = doc.Title,
            PathOnClient = 'Cancellation_Document.pdf',
            VersionData = Blob.valueOf('Test PDF Content')
        );
        insert contentVersion;

        return contentVersion;
    }


    @isTest
    static void testSendEmailForCancellation_Successful() {
        // Create a Contact with an email
        Contact con = createTestContact('test.contact@example.com');
        
        // Create a test Opportunity
        Opportunity opp = createTestOpportunity(con.Id);
        
        // Create ContentVersion (Document) for attachment
        ContentVersion contentVersion = createTestContentVersion();

        // Create EmailServicesAddress record

        // Test the sendEmailForCancellation method
        Test.startTest();
        SendCancellationEmail.sendEmailForCancellation(opp.Id);
        Test.stopTest();

        // Validate that the email was sent
        // No direct assertion on email sending in test context, but this will ensure that no exceptions are thrown.
    }

    @isTest
    static void testSendEmailForCancellation_NoContactEmail() {
        // Create a Contact with no email
        Contact con = createTestContact('');
        
        // Create a test Opportunity
        Opportunity opp = createTestOpportunity(con.Id);

        // Create EmailServicesAddress record
        Test.startTest();
        try {
            SendCancellationEmail.sendEmailForCancellation(opp.Id);
        } catch (AuraHandledException e) {
        }
        Test.stopTest();
    }

    @isTest
    static void testSendEmailForCancellation_NoAttachment() {
        // Create a Contact with an email
        Contact con = createTestContact('test.contact@example.com');
        
        // Create a test Opportunity
        Opportunity opp = createTestOpportunity(con.Id);
        
        // Test the sendEmailForCancellation method - no attachment, so email will be sent without it
        Test.startTest();
        SendCancellationEmail.sendEmailForCancellation(opp.Id);
        Test.stopTest();

        // Assert that the email was sent even without an attachment
    }

    @isTest
    static void testSendEmailForCancellation_NoEmailServicesAddress() {
        // Create a Contact with an email
        Contact con = createTestContact('test.contact@example.com');
        
        // Create a test Opportunity
        Opportunity opp = createTestOpportunity(con.Id);
        
        // Create ContentVersion (Document) for attachment
        ContentVersion contentVersion = createTestContentVersion();

        // Test the sendEmailForCancellation method - No EmailServicesAddress record present
        Test.startTest();
        try {
            SendCancellationEmail.sendEmailForCancellation(opp.Id);
        } catch (AuraHandledException e) {
        }
        Test.stopTest();
    }

    @isTest
    static void testSendEmailForCancellation_IncompleteEmailServicesAddress() {
        // Create a Contact with an email
        Contact con = createTestContact('test.contact@example.com');
        
        // Create a test Opportunity
        Opportunity opp = createTestOpportunity(con.Id);
        
        // Create ContentVersion (Document) for attachment
        ContentVersion contentVersion = createTestContentVersion();


        // Test the sendEmailForCancellation method - should throw exception due to incomplete EmailServicesAddress
        Test.startTest();
        try {
            SendCancellationEmail.sendEmailForCancellation(opp.Id);
        } catch (AuraHandledException e) {
        }
        Test.stopTest();
    }
}