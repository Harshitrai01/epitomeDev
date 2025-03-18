@isTest
public class GenerateQuoteTest {
    
    @testSetup
    static void setupTestData() {
        // Create test Account
        Account testAccount = new Account(
            Name = 'Test Account'
        );
        insert testAccount;
        
        // Create test Project
        Project__c testProject = new Project__c(
            Name = 'Test Project',
            Sales_Head__c = UserInfo.getUserId()
        );
        insert testProject;
        
        // Create test Phase
        Phase__c testPhase = new Phase__c(
            Name = 'Test Phase',
            Project__c = testProject.Id
        );
        insert testPhase;
        
        // Create test Tower
        //Tower__c testTower = new Tower__c(
          //  Name = 'Test Tower',
            //Phase__c = testPhase.Id
        //);
        //insert testTower;
        
        // Create test Unit
        Unit__c testUnit = new Unit__c(
            Name = 'Test Unit',
            Unit_Code__c = 563,
            Base_Price_per_Sq_Ft__c = 5000,
            Plot_Facing__c = 'North',
            Project__c = testProject.Id
        );
        insert testUnit;
        
        // Create test Opportunity
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert testOpportunity;
    }
    
    @isTest
    static void testGenerateQuoteSuccess() {
        // Get test data
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        Unit__c unit = [SELECT Id FROM Unit__c WHERE Name = 'Test Unit' LIMIT 1];
        Phase__c phase = [SELECT Id FROM Phase__c WHERE Name = 'Test Phase' LIMIT 1];
        //Tower__c tower = [SELECT Id FROM Tower__c WHERE Name = 'Test Tower' LIMIT 1];
        Project__c project = [SELECT Id FROM Project__c WHERE Name = 'Test Project' LIMIT 1];
        
        // Start the test
        Test.startTest();
        
        GenerateQuote.LightningResponse response = GenerateQuote.generateQuote(
            opp.Id,
            unit.Id,
            phase.Id,
            null,
            project.Id
        );
        
        Test.stopTest();
        
        // Verify the response
        System.assertEquals(true, response.isSuccess, 'The quote generation should succeed');
        System.assertNotEquals(null, response.quoteId, 'Quote ID should not be null');
        
        // Verify the created Quote
        Quote createdQuote = [SELECT Id, Name, Status__c, Sales_Head__c, Project__c, Phase__c, OpportunityId, Unit__c, Quote_End_Date_Time__c 
                             FROM Quote WHERE Id = :response.quoteId];
        
        System.assertEquals('Test Opportunity-Quote', createdQuote.Name, 'Quote name should match the pattern');
        System.assertEquals('Draft', createdQuote.Status__c, 'Status should be Draft');
        System.assertEquals(UserInfo.getUserId(), createdQuote.Sales_Head__c, 'Sales Head should match');
        System.assertEquals(project.Id, createdQuote.Project__c, 'Project should match');
        System.assertEquals(phase.Id, createdQuote.Phase__c, 'Phase should match');
        System.assertEquals(opp.Id, createdQuote.OpportunityId, 'Opportunity should match');
        System.assertEquals(unit.Id, createdQuote.Unit__c, 'Unit should match');
        
        // Verify Quote_End_Date_Time__c is approximately 24 hours in the future
        DateTime expectedEndTime = DateTime.now().addHours(24);
        Long timeDifferenceInMinutes = Math.abs(
            createdQuote.Quote_End_Date_Time__c.getTime() - expectedEndTime.getTime()
        ) / (1000 * 60);
        
        // Allow 5 minutes difference to account for test execution time
        System.assert(timeDifferenceInMinutes < 5, 'End date time should be approximately 24 hours after creation');
    }
    
    @isTest
    static void testGenerateQuoteNullSalesHead() {
        // Get test data
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        Unit__c unit = [SELECT Id FROM Unit__c WHERE Name = 'Test Unit' LIMIT 1];
        Phase__c phase = [SELECT Id FROM Phase__c WHERE Name = 'Test Phase' LIMIT 1];
        //Tower__c tower = [SELECT Id FROM Tower__c WHERE Name = 'Test Tower' LIMIT 1];
        Project__c project = [SELECT Id FROM Project__c WHERE Name = 'Test Project' LIMIT 1];
        
        // Update the project to have null Sales_Head__c
        project.Sales_Head__c = null;
        update project;
        
        // Start the test
        Test.startTest();
        
        GenerateQuote.LightningResponse response = GenerateQuote.generateQuote(
            opp.Id,
            unit.Id,
            phase.Id,
            null,
            project.Id
        );
        
        Test.stopTest();
        
        // Verify the created Quote
        Quote createdQuote = [SELECT Id, Sales_Head__c FROM Quote WHERE Id = :response.quoteId];
    }
    
    @isTest
    static void testGenerateQuoteError() {
        // Start the test
        Test.startTest();
        
        // Pass invalid IDs to trigger an exception
        GenerateQuote.LightningResponse response = GenerateQuote.generateQuote(
            'InvalidOppId',
            'InvalidUnitId',
            'InvalidPhaseId',
            'InvalidTowerId',
            'InvalidProjectId'
        );
        
        Test.stopTest();
    }
}