@IsTest
public class downloadDocumentCmpControllerTest {
    @TestSetup
    static void setupTestData() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        Contact testContact = new Contact(
            LastName = 'Test Contact',
            AccountId = testAccount.Id,
            Email = 'test@test.com',
            Phone = '1234567890'
        );
        insert testContact;
        
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = testAccount.Id
        );
        insert testOpp;
        
        OpportunityContactRole oppContactRole = new OpportunityContactRole(
            OpportunityId = testOpp.Id,
            ContactId = testContact.Id,
            Role = 'Decision Maker'
        );
        insert oppContactRole;
        
        ContentVersion content = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'TestDoc.pdf',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert content;
        
        content = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :content.Id];
        
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = content.ContentDocumentId,
            LinkedEntityId = testAccount.Id,
            ShareType = 'V'
        );
        insert cdl;
    }
    
    @IsTest
    static void testGetRelatedFilesByRecordId() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        ContentDocumentLink cdl = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :testAccount.Id LIMIT 1];
        
        Test.startTest();
        Map<ID, String> result = downloadDocumentCmpController.getRelatedFilesByRecordId(testAccount.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(1, result.size(), 'Should return one document');
        System.assert(result.containsKey(cdl.ContentDocumentId), 'Should contain the test document');
    }
    
    @IsTest
    static void testCheckOpportunityContact() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        List<Contact> contacts = downloadDocumentCmpController.checkOpportunityContact(testOpp.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, contacts, 'Contacts should not be null');
        System.assertEquals(1, contacts.size(), 'Should return one contact');
        System.assertEquals('test@test.com', contacts[0].Email, 'Should match test contact email');
    }
    
    @IsTest
    static void testCheckOpportunityContactNullId() {
        Test.startTest();
        try {
            downloadDocumentCmpController.checkOpportunityContact(null);
            System.assert(false, 'Should have thrown an exception');
        } catch (AuraHandledException e) {
            System.assert(true, 'Exception was thrown as expected');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testCopyDocumentsToContact_Success() {
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        ContentVersion content = [SELECT ContentDocumentId FROM ContentVersion LIMIT 1];
        
        Test.startTest();
        string result = downloadDocumentCmpController.copyDocumentsToContact(
            testContact.Id, 
            content.ContentDocumentId
        );
        Test.stopTest();
        
        System.assertEquals('true', result, 'Should return true for successful copy');
        
        List<ContentDocumentLink> links = [
            SELECT Id 
            FROM ContentDocumentLink 
            WHERE LinkedEntityId = :testContact.Id 
            AND ContentDocumentId = :content.ContentDocumentId
        ];
        System.assertEquals(1, links.size(), 'Should have created one link');
    }
}