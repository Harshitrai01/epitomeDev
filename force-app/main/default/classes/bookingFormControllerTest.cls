@isTest
public class bookingFormControllerTest {
    @testSetup
    static void setupTestData() {
        // Create an Account
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

        // Create an Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            ContactId= con.id
        );
        insert opp;

        // Create a Quote__c record
        Quote__c quote = new Quote__c( Opportunity__c = opp.Id);
        insert quote;
    }

    @isTest
    static void testGetOpportunityAccountId() {
        Opportunity testOpp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        Test.startTest();
        bookingFormController.getRecordDataWrapper result = bookingFormController.getOpportunityAccountId(testOpp.Id);
        Test.stopTest();
    }

    @isTest
    static void testGetOpportunityAccountIdWithInvalidId() {
        Test.startTest();
        bookingFormController.getRecordDataWrapper result = bookingFormController.getOpportunityAccountId(null);
        Test.stopTest();
    }

    @isTest
    static void testGetRecordData() {
        Quote__c testQuote = [SELECT Id FROM Quote__c LIMIT 1];
        Test.startTest();
        bookingFormController.getRecordDataWrapper result = bookingFormController.getRecordData(testQuote.Id);
        Test.stopTest();
    }

    @isTest
    static void testSaveFormData() {
        // Fetch the test Quote
        Quote__c quote = [SELECT Id FROM Quote__c LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];
		Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Unit__c unit = [SELECT Id FROM Unit__c LIMIT 1];
        // Create test data for JSON serialization
		String jsonData = '{' + '"dateOfBooking":"2025-03-18",' + '"unitName":"Unit A",' + '"unitId":"",' + '"quoteId":"' + quote.Id + '",' + '"opportunityId":"0065g00000OPP789",' + '"opportunityProjectName":"Project Alpha",' + '"opportunitySalesUser":"John Doe",' + '"opportunityBookingAmount":"50000",' + '"opportunityPaymentMode":"Credit Card",' + '"paymentMilestoneId":"a1B5g00000PAYM321",' + '"opportunityPaymentDate":"2025-03-20",' + '"accountId":"",' + '"accountDOB":"1990-05-15",' + '"accountAadhaarCard":"123456789012",' + '"accountName":"Jane Smith",' + '"accountSoWoDo":"Father Name",' + '"accountPanCard":"ABCDE1234F",' + '"accountPermanentAddressStreet":"123 Main Street",' + '"accountPermanentAddressCity":"Mumbai",' + '"accountPermanentAddressCountry":"India",' + '"accountPermanentAddressState":"Maharashtra",' + '"accountPermanentAddressPostalCode":"400001",' + '"accountCorrespondenceAddressStreet":"456 Secondary Street",' + '"accountCorrespondenceAddressCity":"Delhi",' + '"accountCorrespondenceAddressCountry":"India",' + '"accountCorrespondenceAddressState":"Delhi",' + '"accountCorrespondenceAddressPostalCode":"110001",' + '"accountSameAsPermanentAddress":true,' + '"accountContactNo":"9876543210",' + '"typeOfBooking":"Retail",' + '"visitDate":"2025-03-15",' + '"accountEmailId":"jane.smith@example.com",' + '"quoteContactName":"Jane Smith",' + '"quoteContactEmailId":"jane.smith@example.com",' + '"quoteContactNo":"9876543210",' + '"quoteContactPan":"ABCDE1234F",' + '"quoteContactAadhaar":"123456789012",' + '"quoteContactDOB":"1990-05-15",' + '"quotePlot":"",' + '"quotePlotName":"Plot A",' + '"quoteunitPlotFacing":"East",' + '"quoteunitPlotSize":"1000 sqft",' + '"quoteunitPlotPrize":"1000000",' + '"quoteunitPlotUnitCode":"P12345",' + '"quoteunitPlotPhase":"Phase 1",' + '"leadId":"",' + '"saleValueAmount":"1000000",' + '"contactId":"' + con.Id + '",' + '"projectId":"",' + '"phaseId":"",' + '"listOfCoApplicant":[{' + '"contactId":"' + con.Id + '",' + '"contactName":"CoApplicant One",' + '"contactEmail":"coapplicant.one@example.com",' + '"contactPhone":"8765432109",' + '"contactAadhaar":"987654321098",' + '"contactPan":"XYZAB1234C",' + '"contactDOB":"1985-07-10",' + '"isPrimaryPayer":"true",' + '"plots":[{' + '"plotId":"' + unit.Id + '",' + '"plotName":"' + unit.Id + '",' + '"unitOppAmount":"750000",' + '"plotunitsname":"B1",' + '"unitPlotFacing":"West",' + '"unitPlotPhase":"Phase 2",' + '"unitPlotUnitCode":"P56789",' + '"unitPlotPrize":"750000",' + '"unitPlotSize":"900 sqft"' + '}]' + '}]' + '}';

        // Call the method
        Test.startTest();
        bookingFormController.LightningResponse response = bookingFormController.saveFormData(jsonData, quote.Id);
        bookingFormController.LightningResponse response1 = bookingFormController.saveBulkFormData(jsonData);
        bookingFormController.LightningResponse response2 = bookingFormController.saveJointVenture(jsonData, opp.Id, acc.id);
        
        Test.stopTest();   
}
     @isTest
    static void testSaveFormData1() {
        // Fetch the test data
        Quote__c quote = [SELECT Id FROM Quote__c LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];
		Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Unit__c unit = [SELECT Id FROM Unit__c LIMIT 1];
        // Create test data for JSON serialization
        String jsonData = '{' + '"dateOfBooking": "2025-03-18",' + '"unitName": "Unit A",' + '"unitId": "",' + '"quoteId": "' + quote.Id + '",' + '"opportunityId": "0065g00000OPP789",' + '"opportunityProjectName": "Project Alpha",' + '"opportunitySalesUser": "John Doe",' + '"opportunityBookingAmount": "50000",' + '"opportunityPaymentMode": "Credit Card",' + '"paymentMilestoneId": "a1B5g00000PAYM321",' + '"opportunityPaymentDate": "2025-03-20",' + '"accountId": "",' + '"accountDOB": "1990-05-15",' + '"accountAadhaarCard": "123456789012",' + '"accountName": "Jane Smith",' + '"accountSoWoDo": "Father Name",' + '"accountPanCard": "ABCDE1234F",' + '"accountPermanentAddressStreet": "123 Main Street",' + '"accountPermanentAddressCity": "Mumbai",' + '"accountPermanentAddressCountry": "India",' + '"accountPermanentAddressState": "Maharashtra",' + '"accountPermanentAddressPostalCode": "400001",' + '"accountCorrespondenceAddressStreet": "456 Secondary Street",' + '"accountCorrespondenceAddressCity": "Delhi",' + '"accountCorrespondenceAddressCountry": "India",' + '"accountCorrespondenceAddressState": "Delhi",' + '"accountCorrespondenceAddressPostalCode": "110001",' + '"accountSameAsPermanentAddress": true,' + '"accountContactNo": "9876543210",' + '"typeOfBooking": "Retail",' + '"visitDate": "2025-03-15",' + '"accountEmailId": "jane.smith@example.com",' + '"quoteContactName": "Jane Smith",' + '"quoteContactEmailId": "jane.smith@example.com",' + '"quoteContactNo": "9876543210",' + '"quoteContactPan": "ABCDE1234F",' + '"quoteContactAadhaar": "123456789012",' + '"quoteContactDOB": "1990-05-15",' + '"quotePlot": "",' + '"quotePlotName": "Plot A",' + '"quoteunitPlotFacing": "East",' + '"quoteunitPlotSize": "1000 sqft",' + '"quoteunitPlotPrize": "1000000",' + '"quoteunitPlotUnitCode": "P12345",' + '"quoteunitPlotPhase": "Phase 1",' + '"leadId": "",' + '"saleValueAmount": "1000000",' + '"contactId": "",' + '"projectId": "",' + '"phaseId": "",' + '"listOfCoApplicant": [' + '{' + '"contactId": "",' + '"contactName": "CoApplicant One",' + '"contactEmail": "coapplicant.one@example.com",' + '"contactPhone": "8765432109",' + '"contactAadhaar": "987654321098",' + '"contactPan": "XYZAB1234C",' + '"contactDOB": "1985-07-10",' + '"isPrimaryPayer": "true",' + '"plots": [' + '{' + '"plotId": "' + unit.Id + '",' + '"plotName": "",' + '"unitOppAmount": "750000",' + '"plotunitsname": "B1",' + '"unitPlotFacing": "West",' + '"unitPlotPhase": "Phase 2",' + '"unitPlotUnitCode": "P56789",' + '"unitPlotPrize": "750000",' + '"unitPlotSize": "900 sqft"' + '}' + ']' + '}' + ']' + '}';
        // Call the method
        Test.startTest();
        bookingFormController.LightningResponse response = bookingFormController.saveFormData(jsonData, quote.Id);
        bookingFormController.LightningResponse responsesaveBulkFormData = bookingFormController.saveBulkFormData(jsonData);
        bookingFormController.LightningResponse responsesaveJointVenture = bookingFormController.saveJointVenture(jsonData, opp.Id, acc.id);
        Test.stopTest();   
}
    
        @isTest
    static void testGetContactDetails() {
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        Test.startTest();
        Contact result = bookingFormController.getContactDetails(testContact.Id);
        Test.stopTest();

    }

    @isTest
    static void testGetContactsByAccountId() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
        List<Contact> contacts = bookingFormController.getContactsByAccountId(testAccount.Id);
         Account result = bookingFormController.getAccountDetails(testAccount.Id);
        Test.stopTest();
    }

    @isTest
    static void testGetPlots() {
        Test.startTest();
        List<Unit__c> plots = bookingFormController.getPlots();
        Test.stopTest();
    }

    @isTest
    static void testGetPlotDetails() {
        Unit__c testUnit = [SELECT Id FROM Unit__c LIMIT 1];
        Test.startTest();
        Unit__c result = bookingFormController.getPlotDetails(testUnit.Id);
        Test.stopTest();
    }

    @isTest
    static void testGetProjects() {
        Test.startTest();
        List<Project__c> projects = bookingFormController.getProjects();
        Test.stopTest();
    }

    @isTest
    static void testGetPhases() {
        Project__c testProject = [SELECT Id FROM Project__c LIMIT 1];
        Test.startTest();
        List<Phase__c> phases = bookingFormController.getPhases(testProject.Id);
        Test.stopTest();
    }

}