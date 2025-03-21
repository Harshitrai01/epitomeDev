@isTest
public class VFPageUploaderControllerTest {
    @testSetup
    static void setupTestData() {
        // Create a test record to attach the PDF
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
    }

    @isTest
    static void testSaveVFAsAttachment() {
        // Fetch the test record
        Account testAccount = [SELECT Id FROM Account LIMIT 1];

        // Mock VF page URL (replace with an actual accessible page in your org)
        String vfPageUrl = '/apex/TestVFPage';

        Test.startTest();
        // Call the method
        String result = VFPageUploaderController.saveVFAsAttachment(vfPageUrl, testAccount.Id);
        Test.stopTest();

        // Validate the response
        System.assertEquals('Success', result);

        // Verify attachment is created
        Attachment attachedFile = [SELECT Id, Name, ParentId FROM Attachment WHERE ParentId = :testAccount.Id LIMIT 1];
        System.assertNotEquals(null, attachedFile);
        System.assert(attachedFile.Name.startsWith('VFPage_'), 'Attachment name should start with VFPage_');
    }
@isTest
static void testNullException() {
    // Mock VF page URL (replace with an actual accessible page in your org)
    String vfPageUrl = '/apex/TestVFPage';
    
    Test.startTest();
    try {
        // Call the method with null recordId
        String result = VFPageUploaderController.saveVFAsAttachment(vfPageUrl, null);
        System.assert(false, 'Method should have thrown an exception but did not.');
    } catch (AuraHandledException e) {
        System.assert(e.getMessage() != null, 'Exception message should not be null');
    }
    Test.stopTest();
}

}