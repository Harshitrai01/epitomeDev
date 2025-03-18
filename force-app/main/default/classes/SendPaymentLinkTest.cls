@isTest
private class SendPaymentLinkTest {

    // Utility method to create an Opportunity and related Contact for testing
    private static Opportunity createOpportunity() {
        // Create a new Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addMonths(1)
        );
        insert opp;
        return opp;
    }

    // Utility method to create a Contact for testing
    private static Contact createContact() {
        Contact con = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'test.contact@example.com',
            Phone = '1234567890'
        );
        insert con;
        return con;
    }

    // Utility method to create OpportunityContactRole for testing
    private static void createOpportunityContactRole(Id opportunityId, Id contactId) {
        OpportunityContactRole ocr = new OpportunityContactRole(
            OpportunityId = opportunityId,
            ContactId = contactId,
            Role = 'Decision Maker'
        );
        insert ocr;
    }

    @isTest
    static void testGetContactsByOpportunityValidId() {
        // Step 1: Setup data for testing
        Opportunity opp = createOpportunity();  // Create a test Opportunity
        Contact con = createContact();  // Create a test Contact
        createOpportunityContactRole(opp.Id, con.Id);  // Link the Contact to the Opportunity

        Test.startTest();
        
        // Step 2: Call the method with a valid Opportunity Id
        List<Contact> contacts = sendPaymentLink.getContactsByOpportunity(opp.Id);
        
        Test.stopTest();

    }

    @isTest
    static void testGetContactsByOpportunityInvalidId() {
        Test.startTest();
        
        // Step 1: Test with a null Opportunity ID
        try {
            sendPaymentLink.getContactsByOpportunity(null);
        } catch (AuraHandledException e) {
        }

        // Step 2: Test with an empty Opportunity ID
        try {
            sendPaymentLink.getContactsByOpportunity(null);
        } catch (AuraHandledException e) {
        }
        
        Test.stopTest();
    }

    @isTest
    static void testGetContactsByOpportunityNoContacts() {
        // Step 1: Setup data for testing
        Opportunity opp = createOpportunity();  // Create a test Opportunity without any contacts

        Test.startTest();
        
        // Step 2: Call the method with a valid Opportunity Id but no associated contacts
        List<Contact> contacts = sendPaymentLink.getContactsByOpportunity(opp.Id);
        
        Test.stopTest();

        // Step 3: Assertions to validate the results
    }

   
}