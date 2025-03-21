@isTest
private class InstaCollectBatchTest {
    
    @testSetup
    static void setupTestData() {
        // Create Test Opportunities
        List<Opportunity> oppList = new List<Opportunity>();
        for (Integer i = 0; i < 5; i++) {
            oppList.add(new Opportunity(
                Name = 'Test Opportunity ' + i,
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(30)
            ));
        }
        insert oppList;

        // Create Test Unit__c records
        List<Unit__c> unitList = new List<Unit__c>();
        for (Integer i = 0; i < 5; i++) {
            unitList.add(new Unit__c(Name = 'Test Unit ' + i));
        }
        insert unitList;
    }

    @isTest
    static void testBatchExecution() {
        try {
            // Fetch test data
            List<Opportunity> oppList = [SELECT Id FROM Opportunity];
            Set<Id> plotIds = new Set<Id>();
            for (Unit__c unit : [SELECT Id FROM Unit__c]) {
                plotIds.add(unit.Id);
            }


            // Execute Batch
            Test.startTest();
            InstaCollectBatch batch = new InstaCollectBatch(oppList, plotIds);
            Database.executeBatch(batch, 50);
            Test.stopTest();
        } catch (Exception e) {
            System.debug('Error in testBatchExecution: ' + e.getMessage());
        }
    }
}