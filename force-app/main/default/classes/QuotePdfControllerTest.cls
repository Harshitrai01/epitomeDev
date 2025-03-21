@isTest
private class QuotePdfControllerTest {

    // Helper method to create a test Quote__c record
    private static Quote__c createTestQuote() {
        // Create a sample Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today()
            //AccountId = UserInfo.getUserId()
        );
        insert opp;

        // Create a sample Lead
        Lead lead = new Lead(
            FirstName = 'John',
            LastName = 'Doe',
            Company = 'Test Company',
            Email = 'johndoe@test.com',
            Phone = '1234567890'
        );
        insert lead;

        // Create a sample Plot__c record
        Unit__c plot = new Unit__c(
            Name = 'Test Plot',
            Plot_Facing__c = 'North',
            Plot_Size__c = 1200,
            Flat_Number__c = 245,
            Floor_Number__c = 1,
            Unit_Code__c = 765,
            Base_Price_per_Sq_Ft__c = 2000
        );
        insert plot;

        // Create a test Quote__c record
        Quote__c quote = new Quote__c(
            Lead__c = lead.Id,
            Opportunity__c = opp.Id,
            Plot__c = plot.Id,
            Corpus_Fund_and_Club_House_Payable__c = 50000.0,
            Legal_And_Documentation_Charges__c = 1000.0,
            Registration_Charges__c = 2000.0,
            Time_To_Pay_In_Days__c = 30
        );
        insert quote;

        return quote;
    }

    // Test method for QuotePdfController constructor
    @isTest
    static void testQuotePdfController() {
        // Create a test Quote__c record
        Quote__c quoteRecord = createTestQuote();

        // Simulate the Standard Controller by passing in the ID of the Quote__c record
        ApexPages.StandardController stdController = new ApexPages.StandardController(quoteRecord);
        
        // Initialize the QuotePdfController with the Standard Controller
        QuotePdfController controller = new QuotePdfController(stdController);

        // Check if the controller's fields are populated correctly (using debug to check output)
        System.debug('Date of Booking: ' + controller.dateOfBooking);
        System.debug('GST Amount: ' + controller.gstAmount);
        System.debug('Final Corpus: ' + controller.finalCorpus);
        System.debug('Final Legal and Registration Charges: ' + controller.finalLegalAndRegistrationCharges);
        System.debug('Time in Days: ' + controller.timeDays);
        
        // Simulate empty or null values for some fields to test the behavior
        Quote__c quoteRecord2 = new Quote__c(
            Lead__c = null,
            Opportunity__c = null,
            Plot__c = null,
            Corpus_Fund_and_Club_House_Payable__c = null,
            Legal_And_Documentation_Charges__c = null,
            Registration_Charges__c = null,
            Time_To_Pay_In_Days__c = null
        );
        insert quoteRecord2;

        // Simulate the Standard Controller with the second Quote record
        stdController = new ApexPages.StandardController(quoteRecord2);
        
        // Initialize the QuotePdfController with the second Quote record
        QuotePdfController controller2 = new QuotePdfController(stdController);

        // Check if the controller's fields are populated correctly for the second record (using debug)
        System.debug('Date of Booking: ' + controller2.dateOfBooking);
        System.debug('GST Amount: ' + controller2.gstAmount);
        System.debug('Final Corpus: ' + controller2.finalCorpus);
        System.debug('Final Legal and Registration Charges: ' + controller2.finalLegalAndRegistrationCharges);
        System.debug('Time in Days: ' + controller2.timeDays);
    }
}