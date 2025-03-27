@isTest
private class InstaCollectBatchTest {
    
    // Create test data for Opportunity and Unit__c
    private static void createTestData() {
        // Create Opportunity records
        List<Opportunity> oppList = new List<Opportunity>();
        for (Integer i = 0; i < 10; i++) {
            oppList.add(new Opportunity(
                Name = 'Test Opportunity ' + i,
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(30)
            ));
        }
        insert oppList;

        // Create Unit__c records
        List<Unit__c> unitList = new List<Unit__c>();
        List<Phase__c> phaseList = new List<Phase__c>();
        for (Integer i = 0; i < 10; i++) {
            unitList.add(new Unit__c(
                Name = 'Test Unit ' + i
            ));
            Phase__c phaseRecord = new Phase__c(
                Name = 'Phase' + i
            );
            phaseList.add(phaseRecord);
        }
        insert unitList;
        insert phaseList;
    }

    // Test method for InstaCollectBatch
    @isTest
    static void testInstaCollectBatch() {
        // Step 1: Create the test data
        createTestData();

        // Step 2: Get the inserted Opportunity and Unit__c records
        List<Opportunity> oppList = [SELECT Id FROM Opportunity LIMIT 10];
        Set<Id> plotIds = new Set<Id>();
        list<Unit__c> unitData = [SELECT Id FROM Unit__c LIMIT 10];
        for (Unit__c unit : unitData) {
            plotIds.add(unit.Id);
        }

        // Step 3: Create and execute the batch
        Test.startTest();
        InstaCollectBatch batch = new InstaCollectBatch(oppList, plotIds);
        Database.executeBatch(batch, 50); // Execute the batch
        Test.stopTest();

        // Step 4: Verify that the Unit__c records were processed
        List<Unit__c> processedUnits = [SELECT Id, Virtual_Account_Name__c, Virtual_Account_Number__c,
                                        Virtual_Account_Id__c, Virtual_Account_UPI__c,
                                        Virtual_Account_IFSC__c, UPI_QR_Image__c,
                                        UPI_QR_PDF__c, Unique_Request_Number__c 
                                        FROM Unit__c WHERE Id IN :plotIds];
        
        System.assertNotEquals(processedUnits.size(), 0, 'No Unit__c records were processed.');

        // Step 5: Verify the expected changes in the Unit__c records
        for (Unit__c unit : processedUnits) {
            System.assertNotEquals(unit.Virtual_Account_Name__c, null, 'Virtual Account Name should be populated.');
            System.assertNotEquals(unit.Virtual_Account_Number__c, null, 'Virtual Account Number should be populated.');
            System.assertNotEquals(unit.Virtual_Account_Id__c, null, 'Virtual Account ID should be populated.');
            System.assertNotEquals(unit.Virtual_Account_UPI__c, null, 'Virtual Account UPI should be populated.');
            System.assertNotEquals(unit.Virtual_Account_IFSC__c, null, 'Virtual Account IFSC should be populated.');
            System.assertNotEquals(unit.UPI_QR_Image__c, null, 'UPI QR Image should be populated.');
            System.assertNotEquals(unit.UPI_QR_PDF__c, null, 'UPI QR PDF should be populated.');
            System.assertNotEquals(unit.Unique_Request_Number__c, null, 'Unique Request Number should be populated.');
        }

        // Step 6: Verify the finish method executes the next batch (PaymentSendLinkEasyCollect)
        // Since we're testing a batch process, we can assert the execution here or check system logs
        // for the execution of the next batch. This step may require some custom monitoring in the batch class.
    }
}