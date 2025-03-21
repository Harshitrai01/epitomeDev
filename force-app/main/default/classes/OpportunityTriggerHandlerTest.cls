@isTest
private class OpportunityTriggerHandlerTest {
    
    @testSetup
    static void setupTestData() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Contact contact = new Contact(FirstName = 'Test', LastName = 'User', Email = 'test@example.com', AccountId = acc.Id);
        insert contact;
        
         Project__c proj = new Project__c(Name = 'Test Project', Active__c = true);
        insert proj;
        
        Phase__c phase = new Phase__c(Name = 'Test Phase', Project__c = proj.Id);
        insert phase;
        
        Unit__c unit = new Unit__c(
            Name = 'Test Plot',
            Status__c = 'Available',
           Contact__c=contact.id,
            Phase__c = phase.Id
        );
        insert unit;
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = System.today().addDays(30),
            Contact__c = contact.Id,
            Type_of_Booking__c='SBI',
            Unit__c=unit.id
        );
        insert opp;
    }
    
    @isTest
    static void testHandleAfterInsert() {
        Test.startTest();
        
        Opportunity newOpp = new Opportunity(
            Name = 'New Opportunity',
            StageName = 'Prospecting',
            CloseDate = System.today().addDays(30)
        );
        insert newOpp;
        
        System.assertNotEquals(null, newOpp.Id, 'Opportunity should be inserted successfully');
        
        Test.stopTest();
    }
    
    @isTest
    static void testHandleAfterUpdate() {
        Opportunity opp = [SELECT Id, StageName FROM Opportunity LIMIT 1];
        opp.StageName = 'AOS';
        
        Test.startTest();
        update opp;
        Test.stopTest();
        
        Opportunity updatedOpp = [SELECT Id, StageName FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('AOS', updatedOpp.StageName, 'Opportunity stage should be updated to AOS');
    }
    
    @isTest
    static void testSendPlotCancellationEmail() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        OpportunityTriggerHandler.sendPlotCancellationEmail(new List<Id>{opp.Id});
        Test.stopTest();
        
        Opportunity updatedOpp = [SELECT Id, Date_of_Cancellation__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertNotEquals(null, updatedOpp.Date_of_Cancellation__c, 'Date_of_Cancellation__c should be updated');
    }
  @isTest
static void testHandleRegInitiateStage() {
    Opportunity opp = new Opportunity(
        Name = 'Test Opportunity',
        StageName = 'Prospecting',
        CloseDate = System.today().addDays(30),
        Type_of_Booking__c = 'IDBI'
    );
    insert opp;
    
    Test.startTest();
    OpportunityTriggerHandler.handleRegInitiateStage(opp);
     OpportunityTriggerHandler.handleProgressiveStage(opp);
    
    Test.stopTest();
    
}
      @isTest
static void testhandleProgressiveStage() {
    Opportunity opp = new Opportunity(
        Name = 'Test Opportunity',
        StageName = 'Prospecting',
        CloseDate = System.today().addDays(30),
        Type_of_Booking__c = 'Retail'
    );
    insert opp;
    
    Test.startTest();
    OpportunityTriggerHandler.handleRegInitiateStage(opp);
     OpportunityTriggerHandler.handleProgressiveStage(opp);
    
    Test.stopTest();
    
}


}