@isTest
private class KYCVerificationControllerTest {
    @testSetup
    static void setup() {
        // Create test Opportunity
        Opportunity opp = new Opportunity(Name = 'Test Opp',Collected_Amount_From_Payment__c=1000000, StageName = 'Blocked',Sub_Document_Type__c='Pan Card', CloseDate = Date.today());
        insert opp;
        
        // Create test Contact linked to the Opportunity
        Contact con = new Contact(FirstName = 'Test', LastName = 'Contact', Email = 'test@example.com');
        insert con;
        
        // Create test OpportunityContactRole
        OpportunityContactRole ocr = new OpportunityContactRole(OpportunityId = opp.Id, ContactId = con.Id, Role = 'Decision Maker', IsPrimary = true);
        insert ocr;
        
        // Create test Document Upload Specification
        Document_Upload_Specification__c docSpec = new Document_Upload_Specification__c(Name = 'Specification', File_Size_Limit__c = 10);
        insert docSpec;
        
          // Create a ContentDocument (representing a document linked to the Contact)
        ContentVersion testContentVersion = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'TestDocument.pdf',
            VersionData = Blob.valueOf('Test content data')
        );
        insert testContentVersion;

        // Query to get the ContentDocumentId
        testContentVersion = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion.Id LIMIT 1];

        // Create a ContentDocumentLink to associate the document with the Contact
        ContentDocumentLink docLink = new ContentDocumentLink(
            ContentDocumentId = testContentVersion.ContentDocumentId,
            LinkedEntityId = con.Id,
            ShareType = 'V'
        );
        insert docLink;
    }

    @isTest
    static void testCheckOpportunityContact() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        List<Contact> contacts = KYCVerificationController.checkOpportunityContact(testOpp.Id);
        Test.stopTest();
            }

    @isTest
    static void testCheckOpportunityContact_InvalidId() {
        Test.startTest();
        try {
            KYCVerificationController.checkOpportunityContact(null);
        } catch (AuraHandledException e) {
        }
        Test.stopTest();
    }
    
    @isTest
    static void testGetConfiguration() {
        Test.startTest();
        List<Document_Upload_Specification__c> configs = KYCVerificationController.getConfiguration();
        Test.stopTest();
        
    }
    
    @isTest
    static void testUpdateSubDocumentType() {
        Opportunity testOpp = [SELECT Id, Sub_Document_Type__c FROM Opportunity LIMIT 1];
        
        Test.startTest();
        KYCVerificationController.updateSubDocumentType(testOpp.Id, 'NOC');
        Test.stopTest();
        
        Opportunity updatedOpp = [SELECT Sub_Document_Type__c FROM Opportunity WHERE Id = :testOpp.Id];
    }
    
    @isTest
    static void testCheckFilesSize() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        String jsonInput = '{ "files": [{ "fileId": "12345", "fileType": "pdf" }] }';
        Integer maxSize = 10485760; // 10 MB
        String documentType = 'NOC';
        
        Test.startTest();
        List<Long> fileSizes = KYCVerificationController.checkFilesSize(jsonInput, maxSize, testOpp.Id, documentType);
        Test.stopTest();
        
    }
}