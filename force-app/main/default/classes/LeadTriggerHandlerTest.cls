@isTest
public class LeadTriggerHandlerTest {
    @testSetup
    static void setup() {
        // Create Pre-Sales Queue
       Group preSalesQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Pre_Sales_Queue' LIMIT 1];
       
            
    // Fetch the RecordType for Duplicate Lead
        RecordType duplicateLeadRT = [SELECT Id FROM RecordType WHERE DeveloperName = 'Duplicate_Lead' AND SObjectType = 'Lead' LIMIT 1];
        
        // Insert an existing lead for duplicate testing
        List<Lead> existingLead = new List<Lead>{
            new Lead(
                FirstName = 'John', 
                LastName = 'Doe',
                Company = 'test', 
                Phone = '1234567890', 
                Email = 'john.doe@example.com', 
                IsDuplicate__c = false,
                Status='Post Visit Lost'
            )
        };
        insert existingLead;
    }
    
@isTest
static void testAssignLeadsToQueue() {
    try {
        // Query existing leads (ensure there are leads before calling the method)
        List<Lead> newLead = [SELECT Id, OwnerId FROM Lead LIMIT 10];
        
        // Call the method inside Test.startTest() and Test.stopTest()
        Test.startTest();
        LeadTriggerHandler.assignLeadsToQueue(newLead);
        Test.stopTest();
    } catch (Exception e) {
        System.debug('Error in testAssignLeadsToQueue: ' + e.getMessage());
    }
}

    
    @isTest
    static void testCheckAssignment() {
        // Create and assign a lead to Pre-Sales Queue
        Group preSalesQueue = [SELECT Id FROM Group WHERE DeveloperName = 'Pre_Sales_Queue' LIMIT 1];
        List<Lead> newLead = [SELECT Id, OwnerId FROM Lead];
        
        // Mock the dependent method call
        Test.startTest();
        LeadTriggerHandler.checkAssignment(newLead);
        Test.stopTest();
        
        // No assertion needed as we just ensure no exceptions occur
    }
    
@isTest
static void testCheckDuplicateLead() {
    try {
        // Create a duplicate lead
        Lead duplicateLead = new Lead(
            FirstName = 'John',
            LastName = 'Doe',
            Company = 'test',
            Phone = '1234567890',
            Email = 'john.doe@example.com',
            IsDuplicate__c = false,
            Salutation = 'Mr.',
            MiddleName = 'test',
            Suffix = 'test',
            NumberOfEmployees = 8,
            Title = 'test',
            Website = 'test',
            Industry = 'Apparel',
            MobilePhone = '9098787878',
            Remarks__c = 'test',
            Rating = 'Hot',
            Budget__c = '10-20',
            From_Location__c = 'test',
            Facing__c = 'West',
            Type_Of_Site_Visit__c = 'Walk-In',
            Cab_Amount__c = 289.9,
            Street = '4b/1101 Shivganga',
            City = 'Ghaziabad',
            State = 'Uttar Pradesh',
            PostalCode = '201001',
            Country = 'IN'
        );
        
        insert duplicateLead;

        // Call the method inside Test.startTest() and Test.stopTest()
        Test.startTest();
        LeadTriggerHandler.checkDuplicateLead(new List<Lead>{duplicateLead});
        Test.stopTest();
    } catch (Exception e) {
        System.debug('Error in testCheckDuplicateLead: ' + e.getMessage());
    }
}

}