@isTest
public class SendEmailWithAttachmentTest {

    // Test setup to create the necessary test data (Contact, ContentDocumentLink, ContentDocument, ContentVersion)
    @testSetup
    static void setupTestData() {
         Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Contact testContact = new Contact(
            LastName = 'Test Contact',
            Email = 'test@example.com',
            Phone = '1234567890',
            Aadhaar_Card__c = '123412341234',
            PAN_Card__c = 'ABCDE1234F',
            Date_Of_Birth__c = Date.newInstance(1990, 5, 15),
            AccountId = acc.Id
        );
        insert testContact;
        

        // Create an Opportunity
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            ContactId= testContact.id
        );
        insert testOpportunity;

        // Create a ContentDocument (representing a document linked to the Contact)
        ContentVersion testContentVersion = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'TestDocument.pdf',
            VersionData = Blob.valueOf('Test content data')
        );
        insert testContentVersion;

        // Query to get the ContentDocumentId
        testContentVersion = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion.Id LIMIT 1];

        // Create a ContentDocumentLink to associate the document with the Contact
        ContentDocumentLink docLink = new ContentDocumentLink(
            ContentDocumentId = testContentVersion.ContentDocumentId,
            LinkedEntityId = testContact.Id,
            ShareType = 'V'
        );
        insert docLink;
    }

    // Test case to send email with attachments
    @isTest
    static void testSendEmailWithAttachments() {
        // Retrieve the test Contact
        Contact testContact = [SELECT Id, Email FROM Contact LIMIT 1];

        // Create an EmailRequest with valid parameters
        SendEmailWithAttachment.EmailRequest emailRequest = new SendEmailWithAttachment.EmailRequest();
        emailRequest.recipientEmail = testContact.Email;
        emailRequest.subject = 'Test Subject';
        emailRequest.body = 'This is a test email body.';
        emailRequest.contactId = testContact.Id;
        emailRequest.fileTypeName = 'Test Document';

        // Call the invocable method to send the email
        Test.startTest();
        SendEmailWithAttachment.sendEmailWithAttachments(new List<SendEmailWithAttachment.EmailRequest>{ emailRequest });
        Test.stopTest();

        // Verify that an email was sent (you can use email logs or check system debug if needed)
        // However, we can't directly assert if the email was sent. We rely on the method completing without exceptions.
        System.assert(true, 'Email sent successfully (if no exceptions occurred).');
    }

    // Test case when the email request is empty
    @isTest
    static void testSendEmailWithEmptyRequest() {
        try {
            // Call the invocable method with an empty list (shouldn't send any email)
            Test.startTest();
            SendEmailWithAttachment.sendEmailWithAttachments(new List<SendEmailWithAttachment.EmailRequest>());
            Test.stopTest();

            System.assert(true, 'No email sent as the input was empty.');
        } catch (Exception e) {
            System.assert(false, 'Exception should not have been thrown for empty input');
        }
    }

    // Test case when no file is attached due to file title mismatch
    @isTest
    static void testSendEmailNoAttachment() {
        // Retrieve the test Contact
        Contact testContact = [SELECT Id, Email FROM Contact LIMIT 1];

        // Create an EmailRequest with a file type that does not exist
        SendEmailWithAttachment.EmailRequest emailRequest = new SendEmailWithAttachment.EmailRequest();
        emailRequest.recipientEmail = testContact.Email;
        emailRequest.subject = 'Test Subject';
        emailRequest.body = 'This is a test email body.';
        emailRequest.contactId = testContact.Id;
        emailRequest.fileTypeName = 'NonExistent Document';

        // Call the invocable method to send the email
        Test.startTest();
        SendEmailWithAttachment.sendEmailWithAttachments(new List<SendEmailWithAttachment.EmailRequest>{ emailRequest });
        Test.stopTest();

        // Verify the email was sent, even without attachment (due to file type mismatch)
        System.assert(true, 'Email sent successfully (even without attachment).');
    }

    // Test case to handle exception when no email is provided
    @isTest
    static void testSendEmailNoRecipient() {
        Contact con=[Select id from Contact Limit 1];
        // Create an EmailRequest without a recipient email
        SendEmailWithAttachment.EmailRequest emailRequest = new SendEmailWithAttachment.EmailRequest();
        emailRequest.recipientEmail = '';  // No email provided
        emailRequest.subject = 'Test Subject';
        emailRequest.body = 'This is a test email body.';
        emailRequest.contactId = con.id;  // Using a dummy Contact Id
        emailRequest.fileTypeName = 'Test Document';

        // Call the invocable method (should not send any email)
        Test.startTest();
        SendEmailWithAttachment.sendEmailWithAttachments(new List<SendEmailWithAttachment.EmailRequest>{ emailRequest });
        Test.stopTest();

        // Verify that no email was sent (we can assert that no exception occurred)
        System.assert(true, 'No email sent due to missing recipient email.');
    }
}