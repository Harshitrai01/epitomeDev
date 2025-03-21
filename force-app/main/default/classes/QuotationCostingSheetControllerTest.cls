@isTest
public class QuotationCostingSheetControllerTest {
    @testSetup
    static void setupTestData() {
         Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Contact con = new Contact(
            LastName = 'Test Contact',
            Email = 'test@example.com',
            Phone = '1234567890',
            Aadhaar_Card__c = '123412341234',
            PAN_Card__c = 'ABCDE1234F',
            Date_Of_Birth__c = Date.newInstance(1990, 5, 15),
            AccountId = acc.Id
        );
        insert con;
        
         Project__c proj = new Project__c(Name = 'Test Project', Active__c = true);
        insert proj;
        
        Phase__c phase = new Phase__c(Name = 'Test Phase', Project__c = proj.Id);
        insert phase;
        
        Unit__c unit = new Unit__c(
            Name = 'Test Plot',
            Status__c = 'Available',
           Contact__c=con.id,
            Phase__c = phase.Id
        );
        insert unit;
        
        List<Quote__c> quotes = new List<Quote__c>{
            new Quote__c( Base_Price_Per_Sq_Yard__c = 2000,Plot__c=unit.id,IsQuoteGenerated__c=false),
            new Quote__c( Base_Price_Per_Sq_Yard__c = 2500,Plot__c=unit.id,IsQuoteGenerated__c=false)
        };
        insert quotes;

        List<Opportunity> opps = new List<Opportunity>{
            new Opportunity(Name = 'Test Opp 1', StageName = 'Booked', CloseDate = Date.today(), Sale_Value_Amount__c = 50000,Contact__c=con.id, AccountId = acc.Id,Unit__c=unit.id),
            new Opportunity(Name = 'Test Opp 2', StageName = 'Booked', CloseDate = Date.today(), Sale_Value_Amount__c = 60000,Contact__c=con.id, AccountId = acc.Id,Unit__c=unit.id)
        };
        insert opps;
        
        Additional_Charges__c ac=new Additional_Charges__c();
        ac.Plot__c=unit.id;
        ac.Phase__c=phase.id;
        insert ac;
    }

    @isTest
    static void testSaveRecord() {
        List<Quote__c> quotes = [SELECT Id, Name, Total_Sale_Value__c FROM Quote__c];
        Test.startTest();
        List<Quote__c> result = QuotationCostingSheetController.SaveRecord(quotes);
        Test.stopTest();
        
      
    }

    @isTest
    static void testSaveOpportunityRecord() {
        List<Opportunity> opps = [SELECT Id, Name,Sale_Value_Amount__c FROM Opportunity];
        Test.startTest();
        QuotationCostingSheetController.SaveOpportunityRecord(opps);
        Test.stopTest();
    }

    @isTest
    static void testSubmitForApproval() {
        List<Quote__c> quotes = [SELECT Id FROM Quote__c LIMIT 1];
        Test.startTest();
        QuotationCostingSheetController.submitForApproval(quotes[0].Id);
        Test.stopTest();
    }

    @isTest
    static void testFinalizeQuote() {
        List<Quote__c> quotes = [SELECT Id FROM Quote__c];
        Test.startTest();
        QuotationCostingSheetController.FinalizeQuote(quotes);
        Test.stopTest();
    }

    @isTest
    static void testSendQuoteEmail() {
        List<Quote__c> quotes = [SELECT Id FROM Quote__c LIMIT 1];
        Test.startTest();
        QuotationCostingSheetController.sendQuoteEmail(quotes[0].Id, 'test@example.com', 'Test Quote');
        Test.stopTest();
    }

    @isTest
    static void testGetQuote() {
        List<Quote__c> quotes = [SELECT Id FROM Quote__c LIMIT 1];
        Test.startTest();
        QuotationCostingSheetController.lightningResponseWrapper response = QuotationCostingSheetController.getQuote(quotes[0].Id);
        Test.stopTest();
        
        
    }
    
      @isTest
    static void testIsQuoteGenerated() {
        List<Quote__c> quotes = [SELECT Id,IsQuoteGenerated__c FROM Quote__c LIMIT 1];
        quotes[0].IsQuoteGenerated__c=true;  
        update quotes;
        Test.startTest();
        QuotationCostingSheetController.lightningResponseWrapper response = QuotationCostingSheetController.getQuote(quotes[0].Id);
        Test.stopTest();
        
        
    }

    @isTest
    static void testGetOppDetails() {
        List<Opportunity> opps = [SELECT Id,Sale_Value_Amount__c FROM Opportunity LIMIT 1];
        Test.startTest();
        Opportunity opp = QuotationCostingSheetController.getOppDetails(opps[0].Id);
        QuotationCostingSheetController.sendEmail(opps[0].Id,'test plot','1000','1000','1000','1000');
        Test.stopTest();
        
    }
}