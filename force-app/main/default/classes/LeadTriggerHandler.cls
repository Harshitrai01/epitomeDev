public class LeadTriggerHandler {
    
    public static void assignLeadsToQueue(List<Lead> newLeads) {
        
        Group preSalesQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Pre_Sales_Queue' LIMIT 1];
        
        if (preSalesQueue == null) {
            System.debug('Error: Pre-Sales Queue not found.');
            return;
        }
        
        for (Lead lead : newLeads) {
            if(!lead.isDuplicate__c){
                lead.OwnerId = preSalesQueue.Id;
            }
        }
    }
    
    public static void checkAssignment(List<Lead> newLeads) {
        
        Group preSalesQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Pre_Sales_Queue' LIMIT 1];
        
        if (preSalesQueue != null) {
            Boolean leadsAssignedToPreSalesQueue = false;
            
            for (Lead lead : newLeads) {
                if (lead.OwnerId == preSalesQueue.Id) {
                    leadsAssignedToPreSalesQueue = true;
                    break;
                }
            }
            
            if (leadsAssignedToPreSalesQueue) {
                UserTriggerHandler.processLeadAssignment();
            }
        }
    }
    
    /*public static void checkDuplicateLead(List<Lead> newLeads){
Id duplicateRecordTypeId = [
SELECT Id 
FROM RecordType 
WHERE DeveloperName = 'Duplicate_Lead' AND SObjectType = 'Lead' 
LIMIT 1
].Id;
for (Lead lead : newLeads) {
String mobilePhone=lead.MobilePhone;
String phone=lead.Phone;
String plot=lead.Plot__c;
String phase=lead.Phase__c;
Lead parentLead = [SELECT 
Id, Salutation, FirstName, LastName, MiddleName, Suffix, NumberOfEmployees, Title, Website, Email, Phone, Phase__c, 
Industry, MobilePhone, LeadSource, Sub_Source__c, Remarks__c, Rating, Intrested_Projects__c, Plot__c,
Enquired_Project__c, Budget__c, Last_Interacted_Date_Time__c, From_Location__c, Facing__c, 
Type_Of_Site_Visit__c, Cab_Amount__c, Feedback__c, Street, City, State, PostalCode, Country, IsDuplicate__c
FROM Lead
WHERE (MobilePhone = :mobilePhone OR Phone = :phone) 
AND Plot__c = :plot 
AND Phase__c = :phase 
AND IsDuplicate__c = false
LIMIT 1
];

if(parentLead.Salutation==null && lead.Salutation!=null){
parentLead.Salutation = lead.Salutation;
}
if(parentLead.FirstName==null && lead.FirstName!=null){
parentLead.FirstName = lead.FirstName;
}
if(parentLead.LastName==null && lead.LastName!=null){
parentLead.LastName = lead.LastName;
}
if(parentLead.MiddleName==null && lead.MiddleName!=null){
parentLead.MiddleName = lead.MiddleName;
}
if(parentLead.Suffix==null && lead.Suffix!=null){
parentLead.Suffix = lead.Suffix;
}
if(parentLead.Email==null && lead.Email!=null){
parentLead.Email = lead.Email;
}
if(parentLead.NumberOfEmployees==null && lead.NumberOfEmployees!=null){
parentLead.NumberOfEmployees = lead.NumberOfEmployees;
}
if(parentLead.Title==null && lead.Title!=null){
parentLead.Title = lead.Title;
}
if(parentLead.Website==null && lead.Website!=null){
parentLead.Website = lead.Website;
}
if(parentLead.Phone==null && lead.Phone!=null){
parentLead.Phone = lead.Phone;
}
if(parentLead.Industry==null && lead.Industry!=null){
parentLead.Industry = lead.Industry;
}
if(parentLead.MobilePhone==null && lead.MobilePhone!=null){
parentLead.MobilePhone = lead.MobilePhone;
}
if(parentLead.LeadSource==null && lead.LeadSource!=null){
parentLead.LeadSource = lead.LeadSource;
}
if(parentLead.Sub_Source__c==null && lead.Sub_Source__c!=null){
parentLead.Sub_Source__c = lead.Sub_Source__c;
}
if(parentLead.Remarks__c==null && lead.Remarks__c!=null){
parentLead.Remarks__c = lead.Remarks__c;
}
if(parentLead.Rating==null && lead.Rating!=null){
parentLead.Rating = lead.Rating;
}
if(parentLead.Intrested_Projects__c==null && lead.Intrested_Projects__c!=null){
parentLead.Intrested_Projects__c = lead.Intrested_Projects__c;
}
if(parentLead.Enquired_Project__c==null && lead.Enquired_Project__c!=null){
parentLead.Enquired_Project__c = lead.Enquired_Project__c;
}
if(parentLead.Budget__c==null && lead.Budget__c!=null){
parentLead.Budget__c = lead.Budget__c;
}
if(parentLead.Last_Interacted_Date_Time__c==null && lead.Last_Interacted_Date_Time__c!=null){
parentLead.Last_Interacted_Date_Time__c = lead.Last_Interacted_Date_Time__c;
}
if(parentLead.From_Location__c==null && lead.From_Location__c!=null){
parentLead.From_Location__c = lead.From_Location__c;
}
if(parentLead.Facing__c==null && lead.Facing__c!=null){
parentLead.Facing__c = lead.Facing__c;
}
if(parentLead.Type_Of_Site_Visit__c==null && lead.Type_Of_Site_Visit__c!=null){
parentLead.Type_Of_Site_Visit__c = lead.Type_Of_Site_Visit__c;
}
if(parentLead.Cab_Amount__c==null && lead.Cab_Amount__c!=null){
parentLead.Cab_Amount__c = lead.Cab_Amount__c;
}
if(parentLead.Feedback__c==null && lead.Feedback__c!=null){
parentLead.Feedback__c = lead.Feedback__c;
}
if(parentLead.Street==null && lead.Street!=null){
parentLead.Street = lead.Street;
}
if(parentLead.City==null && lead.City!=null){
parentLead.City = lead.City;
}
if(parentLead.State==null && lead.State!=null){
parentLead.State = lead.State;
}
if(parentLead.PostalCode==null && lead.PostalCode!=null){
parentLead.PostalCode = lead.PostalCode;
}
if(parentLead.Country==null && lead.Country!=null){
parentLead.Country = lead.Country;
}
lead.isDuplicate__c=true;
lead.Parent_Lead__c=parentLead.Id;
lead.RecordTypeId=duplicateRecordTypeId;
}
}
}*/
    public static void checkDuplicateLead(List<Lead> newLeads) {
        Id duplicateRecordTypeId = [
            SELECT Id 
            FROM RecordType 
            WHERE DeveloperName = 'Duplicate_Lead' AND SObjectType = 'Lead' 
            LIMIT 1
        ].Id;
        Id duplicacyQueueId = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Lead_Duplicacy_Queue' LIMIT 1].Id;
        Set<String> mobileAndEmailSet = new Set<String>();
        for (Lead lead : newLeads) {
            if (lead.MobilePhone != null) {
                mobileAndEmailSet.add(lead.MobilePhone);
            }
            if (lead.Email != null) {
                mobileAndEmailSet.add(lead.Email);
            }
        }
        
        List<Lead> existingLeads = [SELECT Id, Salutation, FirstName, LastName, MiddleName, Suffix, Status,
                                    NumberOfEmployees, Title, Website, Email, Phone, Phase__c, 
                                    Industry, MobilePhone, LeadSource, Sub_Source__c, Remarks__c, 
                                    Rating, Intrested_Projects__c, Plot__c, Enquired_Project__c, 
                                    Budget__c, Last_Interacted_Date_Time__c, From_Location__c, Facing__c, 
                                    Type_Of_Site_Visit__c, Cab_Amount__c, Feedback__c, Street, City, 
                                    State, PostalCode, Country, IsDuplicate__c, Duplicacy_Unique_Key__c,Latest_Lead_Source__c,Latest_Lead_Date__c
                                    FROM Lead
                                    WHERE (MobilePhone IN :mobileAndEmailSet OR Email IN :mobileAndEmailSet)
                                    AND IsDuplicate__c = false];
        
        
        if(existingLeads.isEmpty()){
            system.debug('No Duplicate Found');
            return;
        }
        Map<String, Lead> uniqueKeyMap = new Map<String, Lead>();
        system.debug('ParentLead---->'+existingLeads);
        for (Lead existingLead : existingLeads) {
            if (existingLead.MobilePhone != null) {
                uniqueKeyMap.put(existingLead.MobilePhone, existingLead);
            }
            if (existingLead.Email != null) {
                uniqueKeyMap.put(existingLead.Email, existingLead);
            }
        }
        
        List<Lead> leadsToUpdate = new List<Lead>();
        
        for (Lead lead : newLeads) {
            Lead parentLead = new Lead();
            if (lead.MobilePhone != null && uniqueKeyMap.containsKey(lead.MobilePhone)) {
                parentLead = uniqueKeyMap.get(lead.MobilePhone);
            } else if (lead.Email != null && uniqueKeyMap.containsKey(lead.Email)) {
                parentLead = uniqueKeyMap.get(lead.Email);
            }
            
            if (parentLead != null) {
                if ((parentLead.Salutation == null || parentLead.Salutation != lead.Salutation) && lead.Salutation != null) {
                    parentLead.Salutation = lead.Salutation;
                }
                
                if ((parentLead.FirstName == null || parentLead.FirstName != lead.FirstName) && lead.FirstName != null) {
                    parentLead.FirstName = lead.FirstName;
                }
                
                if ((parentLead.LastName == null || parentLead.LastName != lead.LastName) && lead.LastName != null) {
                    parentLead.LastName = lead.LastName;
                }
                
                if ((parentLead.MiddleName == null || parentLead.MiddleName != lead.MiddleName) && lead.MiddleName != null) {
                    parentLead.MiddleName = lead.MiddleName;
                }
                
                if ((parentLead.Suffix == null || parentLead.Suffix != lead.Suffix) && lead.Suffix != null) {
                    parentLead.Suffix = lead.Suffix;
                }
                
                if ((parentLead.Email == null || parentLead.Email != lead.Email) && lead.Email != null) {
                    parentLead.Email = lead.Email;
                }
                
                if ((parentLead.NumberOfEmployees == null || parentLead.NumberOfEmployees != lead.NumberOfEmployees) && lead.NumberOfEmployees != null) {
                    parentLead.NumberOfEmployees = lead.NumberOfEmployees;
                }
                
                if ((parentLead.Title == null || parentLead.Title != lead.Title) && lead.Title != null) {
                    parentLead.Title = lead.Title;
                }
                
                if ((parentLead.Website == null || parentLead.Website != lead.Website) && lead.Website != null) {
                    parentLead.Website = lead.Website;
                }
                
                if ((parentLead.Phone == null || parentLead.Phone != lead.Phone) && lead.Phone != null) {
                    parentLead.Phone = lead.Phone;
                }
                
                if ((parentLead.Industry == null || parentLead.Industry != lead.Industry) && lead.Industry != null) {
                    parentLead.Industry = lead.Industry;
                }
                
                if ((parentLead.MobilePhone == null || parentLead.MobilePhone != lead.MobilePhone) && lead.MobilePhone != null) {
                    parentLead.MobilePhone = lead.MobilePhone;
                }
                
                if ((parentLead.LeadSource == null || parentLead.LeadSource != lead.LeadSource) && lead.LeadSource != null) {
                    parentLead.LeadSource = lead.LeadSource;
                }
                
                if ((parentLead.Sub_Source__c == null || parentLead.Sub_Source__c != lead.Sub_Source__c) && lead.Sub_Source__c != null) {
                    parentLead.Sub_Source__c = lead.Sub_Source__c;
                }
                
                if ((parentLead.Remarks__c == null || parentLead.Remarks__c != lead.Remarks__c) && lead.Remarks__c != null) {
                    parentLead.Remarks__c = lead.Remarks__c;
                }
                
                if ((parentLead.Rating == null || parentLead.Rating != lead.Rating) && lead.Rating != null) {
                    parentLead.Rating = lead.Rating;
                }
                
                if ((parentLead.Intrested_Projects__c == null || parentLead.Intrested_Projects__c != lead.Intrested_Projects__c) && lead.Intrested_Projects__c != null) {
                    parentLead.Intrested_Projects__c = lead.Intrested_Projects__c;
                }
                
                if ((parentLead.Enquired_Project__c == null || parentLead.Enquired_Project__c != lead.Enquired_Project__c) && lead.Enquired_Project__c != null) {
                    parentLead.Enquired_Project__c = lead.Enquired_Project__c;
                }
                
                if ((parentLead.Budget__c == null || parentLead.Budget__c != lead.Budget__c) && lead.Budget__c != null) {
                    parentLead.Budget__c = lead.Budget__c;
                }
                
                if ((parentLead.Last_Interacted_Date_Time__c == null || parentLead.Last_Interacted_Date_Time__c != lead.Last_Interacted_Date_Time__c) && lead.Last_Interacted_Date_Time__c != null) {
                    parentLead.Last_Interacted_Date_Time__c = lead.Last_Interacted_Date_Time__c;
                }
                
                if ((parentLead.From_Location__c == null || parentLead.From_Location__c != lead.From_Location__c) && lead.From_Location__c != null) {
                    parentLead.From_Location__c = lead.From_Location__c;
                }
                
                if ((parentLead.Facing__c == null || parentLead.Facing__c != lead.Facing__c) && lead.Facing__c != null) {
                    parentLead.Facing__c = lead.Facing__c;
                }
                
                if ((parentLead.Type_Of_Site_Visit__c == null || parentLead.Type_Of_Site_Visit__c != lead.Type_Of_Site_Visit__c) && lead.Type_Of_Site_Visit__c != null) {
                    parentLead.Type_Of_Site_Visit__c = lead.Type_Of_Site_Visit__c;
                }
                
                if ((parentLead.Cab_Amount__c == null || parentLead.Cab_Amount__c != lead.Cab_Amount__c) && lead.Cab_Amount__c != null) {
                    parentLead.Cab_Amount__c = lead.Cab_Amount__c;
                }
                
                if ((parentLead.Feedback__c == null || parentLead.Feedback__c != lead.Feedback__c) && lead.Feedback__c != null) {
                    parentLead.Feedback__c = lead.Feedback__c;
                }
                
                if ((parentLead.Street == null || parentLead.Street != lead.Street) && lead.Street != null) {
                    parentLead.Street = lead.Street;
                }
                
                if ((parentLead.City == null || parentLead.City != lead.City) && lead.City != null) {
                    parentLead.City = lead.City;
                }
                
                if ((parentLead.State == null || parentLead.State != lead.State) && lead.State != null) {
                    parentLead.State = lead.State;
                }
                
                if ((parentLead.PostalCode == null || parentLead.PostalCode != lead.PostalCode) && lead.PostalCode != null) {
                    parentLead.PostalCode = lead.PostalCode;
                }
                
                if ((parentLead.Country == null || parentLead.Country != lead.Country) && lead.Country != null) {
                    parentLead.Country = lead.Country;
                }
                
                
                parentLead.Latest_Lead_Source__c=lead.LeadSource;
                parentLead.Latest_Lead_Date__c=System.now();
                if(parentLead.Status=='Post Visit Lost' || parentLead.Status=='Unqualified'){
                    parentLead.Status='Re-Enquiry';
                }
                
                leadsToUpdate.add(parentLead);
                
                lead.IsDuplicate__c = true;
                lead.Status='Unopened';
                lead.Parent_Lead__c = parentLead.Id;
                lead.RecordTypeId = duplicateRecordTypeId;
                lead.OwnerId=duplicacyQueueId;
            }
        }
        
        if (!leadsToUpdate.isEmpty()) {
            update leadsToUpdate;
        }
    }
}