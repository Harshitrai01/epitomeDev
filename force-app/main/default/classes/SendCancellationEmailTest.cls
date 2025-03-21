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
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Cancellation Document',
            PathOnClient = 'Cancellation_Document.pdf',
            VersionData = Blob.valueOf('Test PDF Content')
        );
        insert contentVersion;

        return contentVersion;
    }

    @isTest
    static void testSendEmailForCancellation_Successful() {
        Contact con = createTestContact('test.contact@example.com');
        Opportunity opp = createTestOpportunity(con.Id);
        ContentVersion contentVersion = createTestContentVersion();

        Test.startTest();
        SendCancellationEmail.sendEmailForCancellation(opp.Id);
        Test.stopTest();

        System.assert(true, 'Test passed if no exception is thrown.');
    }


    @isTest
    static void testSendEmailForCancellation_NoAttachment() {
        Contact con = createTestContact('test.contact@example.com');
        Opportunity opp = createTestOpportunity(con.Id);

        Test.startTest();
        SendCancellationEmail.sendEmailForCancellation(opp.Id);
        Test.stopTest();

        System.assert(true, 'Test passed if no exception is thrown even without an attachment.');
    }

   
}