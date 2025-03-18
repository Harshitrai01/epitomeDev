@isTest
public class CancellationEmailHandlerTest {
    @testSetup
    static void setupTestData() {
        // Create a test Opportunity record
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert testOpportunity;
        
        // Create an EmailMessage related to the Opportunity
        EmailMessage testEmailMessage = new EmailMessage(
            RelatedToId = testOpportunity.Id,
            Subject = 'Cancellation Request',
            FromAddress = 'test@example.com',
            ToAddress = 'recipient@example.com',
            MessageDate = System.now(),
            Incoming = true,
            MessageIdentifier = 'test-thread-123'
        );
        insert testEmailMessage;
    }
    
    @isTest
    static void testHandleInboundEmail() {
        // Retrieve test Opportunity
        Opportunity testOpportunity = [SELECT Id FROM Opportunity LIMIT 1];
        EmailMessage testEmailMessage = [SELECT Id, MessageIdentifier FROM EmailMessage LIMIT 1];
        
        // Create test email data
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.subject = 'Cancellation Request';
        email.plainTextBody = 'Please cancel the plot associated with this opportunity.';
        email.references = new String[] { testEmailMessage.MessageIdentifier };
        
        // Create test attachment
        Messaging.InboundEmail.BinaryAttachment attachment = new Messaging.InboundEmail.BinaryAttachment();
        attachment.filename = 'test_doc.pdf';
        attachment.body = Blob.valueOf('Test PDF Content');
        
        email.binaryAttachments = new List<Messaging.InboundEmail.BinaryAttachment> { attachment };
        
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        envelope.fromAddress = 'test@example.com';
        
        // Instantiate the email handler and call the method
        CancellationEmailHandler handler = new CancellationEmailHandler();
        Test.startTest();
        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, envelope);
        Test.stopTest();
        
       
    }
}