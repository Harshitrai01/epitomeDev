/**
 * Test class for QuotePdfController
 * @author: Harshit Kumar Rai
 * @date: March 24, 2025
 */
@isTest
private class QuotePdfControllerTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test project
        Project__c project = new Project__c(
            Name = 'Test Project',
            Project_Type__c = 'Plot'
        );
        insert project;
        
        // Create test phase
        Phase__c phase = new Phase__c(
            Name = 'Test Phase',
            Project__c = project.Id
        );
        insert phase;
        
        // Create test plot
        Unit__c plot = new Unit__c(
            Name = 'Test Plot',
            Phase__c = phase.Id,
            Plot_Facing__c = 'North',
            Plot_Size__c = 200,
            Flat_Number__c = 101,
            Floor_Number__c = 1,
            Unit_Code__c = 001,
            Base_Price_per_Sq_Ft__c = 5000,
            Plot_Dimension__c = '10x20'
        );
        insert plot;
        
        // Create test lead
        Lead lead = new Lead(
            LastName = 'Test Lead',
            Email = 'test@example.com',
            Phone = '9876543210',
            Phase__c = phase.Id,
            Project__c = project.Id,
            Company = 'testingComay'
        );
        insert lead;
        
        // Create test Contact
        Contact contact = new Contact(
            LastName = 'Test Contact',
            Email = 'testcontact@example.com',
            Phone = '9876543211'
        );
        insert contact;
        
        // Create test Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            ContactId = contact.Id
        );
        insert opp;
        
        // Create test Quote
        Quote__c quote = new Quote__c(
            Lead__c = lead.Id,
            Plot__c = plot.Id,
            Phase__c = phase.Id,
            Project__c = project.Id,
            IsSample__c = false,
            IsQuoteGenerated__c = false,
            Total_Basic_Cost__c = 1000000,
            Total_Gst_For_Charge__c = 180000,
            Total_Charge_Amount__c = 1180000,
            AgreementValueWithGst__c = 1200000,
            Base_Price_Per_Sq_Yard__c = 5000,
            Price_For_North_East__c = 50000,
            Other_Corners__c = 20000,
            East__c = 30000,
            X100_Ft_Road_Plots__c = 40000,
            Premium_Plots__c = 60000,
            Rate_Per_Sq_Yd__c = 5000,
            Corpus_Fund_and_Club_House_Payable__c = 100000,
            Legal_And_Documentation_Charges__c = 50000,
            Registration_Charges__c = 25000,
            IsLocked__c = false,
            Approval_Status__c = 'Pending',
            Time_To_Pay_In_Days__c = 30,
            Opportunity__c = opp.Id
        );
        insert quote;
    }
    
    @isTest
    static void testQuotePdfController() {
        // Get the test quote
        Quote__c quote = [SELECT Id FROM Quote__c LIMIT 1];
        
        // Set up the page with the quote ID
        PageReference pageRef = Page.QuotePDF; // Assuming your VF page is named QuotePDF
        pageRef.getParameters().put('id', quote.Id);
        Test.setCurrentPage(pageRef);
        
        // Create the standard controller
        ApexPages.StandardController stdController = new ApexPages.StandardController(quote);
        
        // Test constructor
        Test.startTest();
        QuotePdfController controller = new QuotePdfController(stdController);
        Test.stopTest();
        
        // Verify the controller initialized the values correctly
        System.assertNotEquals(null, controller.quote);
        System.assertNotEquals(null, controller.dateOfBooking);
        System.assertNotEquals(null, controller.gstAmount);
        System.assertNotEquals(null, controller.finalCorpus);
        System.assertNotEquals(null, controller.finalLegalAndRegistrationCharges);
        System.assertNotEquals(null, controller.timeDays);
        
        // Verify calculations were performed correctly
        System.assertEquals('30', controller.timeDays);
        System.assertEquals(18000, controller.gstAmount); // 100,000 * 0.18
        System.assertEquals(118000, controller.finalCorpus); // 100,000 + 18,000
        System.assertEquals(75000, controller.finalLegalAndRegistrationCharges); // 50,000 + 25,000
    }
    
    @isTest
    static void testQuotePdfControllerWithNullValues() {
        // Get the test quote
        Quote__c quote = [SELECT Id FROM Quote__c LIMIT 1];
        
        // Update quote with null values to test null-handling
        quote.Corpus_Fund_and_Club_House_Payable__c = null;
        quote.Legal_And_Documentation_Charges__c = null;
        quote.Registration_Charges__c = null;
        quote.Time_To_Pay_In_Days__c = null;
        update quote;
        
        // Set up the page with the quote ID
        PageReference pageRef = Page.QuotePDF;
        pageRef.getParameters().put('id', quote.Id);
        Test.setCurrentPage(pageRef);
        
        // Create the standard controller
        ApexPages.StandardController stdController = new ApexPages.StandardController(quote);
        
        // Test constructor with null values
        Test.startTest();
        QuotePdfController controller = new QuotePdfController(stdController);
        Test.stopTest();
        
        // Verify the controller handled null values correctly
        System.assertNotEquals(null, controller.quote);
        System.assertNotEquals(null, controller.dateOfBooking);
        System.assertEquals(null, controller.gstAmount);
        System.assertEquals(null, controller.finalCorpus);
        System.assertEquals(0, controller.finalLegalAndRegistrationCharges);
        System.assertEquals(null, controller.timeDays);
    }
    
    @isTest
    static void testQuotePdfControllerWithNoRecord() {
        // Create a non-existent quote ID
        Id nonExistentId = createTestId(Quote__c.SObjectType);
        
        // Set up the page with the non-existent ID
        PageReference pageRef = Page.QuotePDF;
        pageRef.getParameters().put('id', nonExistentId);
        Test.setCurrentPage(pageRef);
        
        // Create a new Quote__c record with the fake ID
        Quote__c nonExistentQuote = new Quote__c(Id = nonExistentId);
        
        // Create the standard controller
        ApexPages.StandardController stdController = new ApexPages.StandardController(nonExistentQuote);
        
        // Test constructor with no record found
        Test.startTest();
        QuotePdfController controller = new QuotePdfController(stdController);
        Test.stopTest();
        
        // Verify the controller handled no record found correctly
        System.assertEquals(null, controller.quote);
        System.assertEquals(null, controller.dateOfBooking);
        System.assertEquals(null, controller.gstAmount);
        System.assertEquals(null, controller.finalCorpus);
        System.assertEquals(null, controller.timeDays);
    }
    
    /**
     * Utility method to create a test ID
     */
    private static Id createTestId(Schema.SObjectType sObjectType) {
        String keyPrefix = sObjectType.getDescribe().getKeyPrefix();
        return Id.valueOf(keyPrefix + '000000000001');
    }
}