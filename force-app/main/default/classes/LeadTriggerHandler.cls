/**********
Apex Class Name : LeadTriggerHandler
Apex Test Class Name: 
Created Date: feb 10, 2025
@description : This class is a handler for Lead triggers in Salesforce. It contains methods to manage lead assignment, duplicate lead checking, and updating lead records. The class ensures that leads are assigned to the correct queue, checks for duplicates, and updates parent leads with new information.
@author : Varun Rawal
Modify By : 
Modify Date: 
**********/

public with sharing class LeadTriggerHandler {
    
    /*
**********
Method Name : assignLeadsToQueue
author: Varun Rawal
description: Assigns new leads to the Pre-Sales Queue if they are not marked as duplicates.
@params: 
- newLeads: The list of new leads to be assigned.
@return: None
**********
*/
    public static void assignLeadsToQueue(List<Lead> newLeads) {
        // Query the Pre-Sales Queue
        Group preSalesQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Pre_Sales_Queue' LIMIT 1];
        
        // Check if the Pre-Sales Queue exists
        if (preSalesQueue == null) {
            System.debug('Error: Pre-Sales Queue not found.');
        }else{
            
            // Assign leads to the Pre-Sales Queue if they are not duplicates
            for (Lead lead : newLeads) {
                if (!lead.isDuplicate__c) {
                    lead.OwnerId = preSalesQueue.Id;
                }
            }
        }
    }
    
    /*
**********
Method Name : checkAssignment
author: Varun Rawal
description: Checks if any leads are assigned to the Pre-Sales Queue and triggers additional logic if needed.
@params: 
- newLeads: The list of new leads to check.
@return: None
**********
*/
    public static void checkAssignment(List<Lead> newLeads) {
        // Query the Pre-Sales Queue
        Group preSalesQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Pre_Sales_Queue' LIMIT 1];
        
        // Check if the Pre-Sales Queue exists
        if (preSalesQueue != null) {
            Boolean leadsAssignedToPreSalesQueue = false;
            
            // Check if any leads are assigned to the Pre-Sales Queue
            for (Lead lead : newLeads) {
                if (lead.OwnerId == preSalesQueue.Id) {
                    leadsAssignedToPreSalesQueue = true;
                    break;
                }
            }
            
            // Trigger additional logic if leads are assigned to the Pre-Sales Queue
            if (leadsAssignedToPreSalesQueue) {
                UserTriggerHandler.processLeadAssignment();
            }
        }
    }
    
    /*
**********
Method Name : checkDuplicateLead
author: Varun Rawal
description: Checks for duplicate leads based on phone numbers or emails and updates parent leads with new information. While updating or inserting, use as user.
@params: 
- newLeads: The list of new leads to check for duplicates.
@return: None
**********
*/
    public static void checkDuplicateLead(List<Lead> newLeads) {
        // Query the RecordType ID for duplicate leads
        Id duplicateRecordTypeId = [
            SELECT Id 
            FROM RecordType 
            WHERE DeveloperName = 'Duplicate_Lead' AND SObjectType = 'Lead' 
            LIMIT 1
        ].Id;
        
        // Query the Duplicacy Queue ID
        Id duplicacyQueueId = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Lead_Duplicacy_Queue' LIMIT 1].Id;
        
        // Create a set to store unique phone numbers and emails from new leads
        Set<String> mobileAndEmailSet = new Set<String>();
        for (Lead lead : newLeads) {
            if (lead.Phone != null) {
                mobileAndEmailSet.add(lead.Phone);
            }
            if (lead.Email != null) {
                mobileAndEmailSet.add(lead.Email);
            }
        }
        system.debug('mobileAndEmailSet---->' + mobileAndEmailSet);
        
        // Query existing leads that match the phone numbers or emails in the set
        List<Lead> existingLeads = [SELECT Id, Salutation, FirstName, LastName, MiddleName, Suffix, Status,
                                    NumberOfEmployees, Title, Website, Email, Phone, Phase__c, 
                                    Industry, MobilePhone, LeadSource, Sub_Source__c, Remarks__c, 
                                    Rating, Intrested_Projects__c, Plot__c, Enquired_Project__c, 
                                    Budget__c, Last_Interacted_Date_Time__c, From_Location__c, Facing__c, 
                                    Type_Of_Site_Visit__c, Cab_Amount__c, Feedback__c, Street, City, 
                                    State, PostalCode, Country, IsDuplicate__c, Duplicacy_Unique_Key__c, Latest_Lead_Date__c
                                    FROM Lead
                                    WHERE (Phone IN :mobileAndEmailSet OR Email IN :mobileAndEmailSet)
                                    AND IsDuplicate__c = false
                                   ];
        
        system.debug('existingLeads---->' + existingLeads);
        
        // If no existing leads are found, exit the method
        if (existingLeads.isEmpty()) {
            system.debug('No Duplicate Found');
        }else{
            
            // Create a map to store unique keys (phone or email) and their corresponding leads
            Map<String, Lead> uniqueKeyMap = new Map<String, Lead>();
            system.debug('ParentLead---->' + existingLeads);
            for (Lead existingLead : existingLeads) {
                if (existingLead.Phone != null && mobileAndEmailSet.contains(existingLead.Phone)) {
                    uniqueKeyMap.put(existingLead.Phone, existingLead);
                } else if (existingLead.Email != null && mobileAndEmailSet.contains(existingLead.Email)) {
                    uniqueKeyMap.put(existingLead.Email, existingLead);
                }
            }
            system.debug('uniqueKeyMap--->' + uniqueKeyMap);
            
            // List to store parent leads that need to be updated
            List<Lead> leadsToUpdate = new List<Lead>();
            integer i = 0;
            for (Lead lead : newLeads) {
                system.debug('i=' + i++);
                Lead parentLead = new Lead();
                if (lead.Phone != null && uniqueKeyMap.containsKey(lead.Phone)) {
                    parentLead = uniqueKeyMap.get(lead.Phone);
                } else if (lead.Email != null && uniqueKeyMap.containsKey(lead.Email)) {
                    parentLead = uniqueKeyMap.get(lead.Email);
                }
                system.debug('parentLead1--->' + parentLead);
                
                // If a parent lead is found, update its fields with non-null values from the new lead
                if (parentLead != null) {
                    if (parentLead.Salutation == null && lead.Salutation != null) {
                        parentLead.Salutation = lead.Salutation;
                    }
                    
                    if (parentLead.FirstName == null && lead.FirstName != null) {
                        parentLead.FirstName = lead.FirstName;
                    }
                    
                    if (parentLead.LastName == null && lead.LastName != null) {
                        parentLead.LastName = lead.LastName;
                    }
                    
                    if (parentLead.MiddleName == null && lead.MiddleName != null) {
                        parentLead.MiddleName = lead.MiddleName;
                    }
                    
                    if (parentLead.Suffix == null && lead.Suffix != null) {
                        parentLead.Suffix = lead.Suffix;
                    }
                    
                    if (parentLead.Email == null && lead.Email != null) {
                        parentLead.Email = lead.Email;
                    }
                    
                    if (parentLead.NumberOfEmployees == null && lead.NumberOfEmployees != null) {
                        parentLead.NumberOfEmployees = lead.NumberOfEmployees;
                    }
                    
                    if (parentLead.Title == null && lead.Title != null) {
                        parentLead.Title = lead.Title;
                    }
                    
                    if (parentLead.Website == null && lead.Website != null) {
                        parentLead.Website = lead.Website;
                    }
                    
                    if (parentLead.Phone == null && lead.Phone != null) {
                        parentLead.Phone = lead.Phone;
                    }
                    
                    if (parentLead.Industry == null && lead.Industry != null) {
                        parentLead.Industry = lead.Industry;
                    }
                    
                    if (parentLead.MobilePhone == null && lead.MobilePhone != null) {
                        parentLead.MobilePhone = lead.MobilePhone;
                    }
                    
                    if (parentLead.LeadSource == null && lead.LeadSource != null) {
                        parentLead.LeadSource = lead.LeadSource;
                    }
                    
                    if (parentLead.Sub_Source__c == null && lead.Sub_Source__c != null) {
                        parentLead.Sub_Source__c = lead.Sub_Source__c;
                    }
                    
                    if (parentLead.Remarks__c == null && lead.Remarks__c != null) {
                            parentLead.Remarks__c = lead.Remarks__c;
                    }
                    
                    if (parentLead.Rating == null && lead.Rating != null) {
                        parentLead.Rating = lead.Rating;
                    }
                    
                    if (parentLead.Intrested_Projects__c == null && lead.Intrested_Projects__c != null) {
                        parentLead.Intrested_Projects__c = lead.Intrested_Projects__c;
                    }
                    
                    if (parentLead.Enquired_Project__c == null && lead.Enquired_Project__c != null) {
                        parentLead.Enquired_Project__c = lead.Enquired_Project__c;
                    }
                    
                    if (parentLead.Budget__c == null && lead.Budget__c != null) {
                        parentLead.Budget__c = lead.Budget__c;
                    }
                    
                    if (parentLead.Last_Interacted_Date_Time__c == null && lead.Last_Interacted_Date_Time__c != null) {
                        parentLead.Last_Interacted_Date_Time__c = lead.Last_Interacted_Date_Time__c;
                    }
                    
                    if (parentLead.From_Location__c == null && lead.From_Location__c != null) {
                        parentLead.From_Location__c = lead.From_Location__c;
                    }
                    
                    if (parentLead.Facing__c == null && lead.Facing__c != null) {
                        parentLead.Facing__c = lead.Facing__c;
                    }
                    
                    if (parentLead.Type_Of_Site_Visit__c == null && lead.Type_Of_Site_Visit__c != null) {
                        parentLead.Type_Of_Site_Visit__c = lead.Type_Of_Site_Visit__c;
                    }
                    
                    if (parentLead.Cab_Amount__c == null && lead.Cab_Amount__c != null) {
                        parentLead.Cab_Amount__c = lead.Cab_Amount__c;
                    }
                    
                    if (parentLead.Feedback__c == null && lead.Feedback__c != null) {
                        parentLead.Feedback__c = lead.Feedback__c;
                    }
                    
                    if (parentLead.Street == null && lead.Street != null) {
                        parentLead.Street = lead.Street;
                    }
                    
                    if (parentLead.City == null && lead.City != null) {
                        parentLead.City = lead.City;
                    }
                    
                    if (parentLead.State == null && lead.State != null) {
                        parentLead.State = lead.State;
                    }
                    
                    if (parentLead.PostalCode == null && lead.PostalCode != null) {
                        parentLead.PostalCode = lead.PostalCode;
                    }
                    
                    if (parentLead.Country == null && lead.Country != null) {
                        parentLead.Country = lead.Country;
                    }
                    
                    // Update the parent lead's latest interaction date and status if necessary
                    parentLead.Latest_Lead_Date__c = System.now();
                    if (parentLead.Status == 'Post Visit Lost' || parentLead.Status == 'Unqualified') {
                        parentLead.Status = 'Re-Enquiry';
                    }
                    system.debug('parentLead2--->' + parentLead);
                    system.debug('parentLead.Id--->' + parentLead.Id);
                    
                    // Add the parent lead to the list of leads to update
                    leadsToUpdate.add(parentLead);
                    
                    // Mark the new lead as a duplicate and assign it to the Duplicacy Queue
                    lead.IsDuplicate__c = true;
                    lead.Status = 'Unopened';
                    lead.Parent_Lead__c = parentLead.Id;
                    lead.RecordTypeId = duplicateRecordTypeId;
                    lead.OwnerId = duplicacyQueueId;
                }
            }
            system.debug('leadsToUpdate-->' + leadsToUpdate);
            
            // Update the parent leads if any changes were made
            if (!leadsToUpdate.isEmpty()) {
                update leadsToUpdate; // Update as the current user
            }
        }
    }
}