/**********
Apex Class Name : customLookupCmpController
Apex Test Class Name: customLookupCmpControllerTest
Created Date: March 18, 2025
@description : This class provides functions for searching lookup records dynamically.
            It is used for a custom searchable combobox that allows selecting plots
            from bulk bookings.
@author : Dolly Bindal
Modify By : Dolly Bindal
Modify Date: March 18, 2025
**********/
public with sharing class customLookupCmpController {
        /*
    **********
    Method Name : searchPlots
    author: Dolly Bindal
    @description: Searches available plots (Unit__c) based on a given search term and phase ID.
                 This is used in the custom combobox to dynamically filter plots for selection.
    @param 
        -searchTerm The keyword entered by the user to search for plot names.
        -phaseId The ID of the phase to filter the search results.
    @return A list of Unit__c records that match the search criteria.
    **********
    */
    @AuraEnabled(cacheable=true)
    public static list<Unit__c> fetchLookupData(string searchKey ,String phaseId,String projectId) {    
      try{
            return [
                SELECT Id, Name, Status__c,Plot_Facing__c,Phase__c FROM Unit__c
                WHERE Name LIKE :('%' + searchKey + '%') AND Status__c='Available' and Phase__c = :phaseId and Project__c = :projectId
            ];
            }catch (Exception e) {
                System.debug('Error in getContactDetails: ' + e.getMessage());
                throw new AuraHandledException('Error fetching plot details: ' + e.getMessage());
            }
    }

    /*
    **********
    Method Name : searchPlots
    author: Dolly Bindal
    @description: Searches available plots (Unit__c) based on a given search term and phase ID.
                 This is used in the custom combobox to dynamically filter plots for selection.
    @param 
        -searchTerm The keyword entered by the user to search for plot names.
        -phaseId The ID of the phase to filter the search results.
    @return A list of Unit__c records that match the search criteria.
    **********
    */
    // @AuraEnabled(cacheable=true)
    //     public static List<Unit__c> searchPlots(String searchTerm,String phaseId) {
    //         try{
    //         return [
    //             SELECT Id, Name, Status__c,Plot_Facing__c,Phase__c FROM Unit__c
    //             WHERE Name LIKE :('%' + searchTerm + '%') AND Status__c='Available' and Phase__c = :phaseId
    //         ];
    //         }catch (Exception e) {
    //             System.debug('Error in getContactDetails: ' + e.getMessage());
    //             throw new AuraHandledException('Error fetching plot details: ' + e.getMessage());
    //         }
    //     }

     /*
    **********
    Method Name : searchLookupRecords
    Author: Ayush Nanda
    @description: Searches for lookup records dynamically across any sObject.
                 This is used in the custom combobox for lookup search functionality.
    @param 
        - searchTerm : The keyword entered by the user to search for records.
        - selectedIds : A list of record IDs to exclude from the results (e.g., already selected items).
        - sObjectName : The API name of the object to search in (e.g., "Account", "Contact", "Unit__c").
        - field : The primary field used for searching (e.g., "Name", "Email").
        - subField : (Optional) A secondary field to display in the search results.
        - maxResults : The maximum number of results to return.
    @return A list of LookupSearchResult objects representing matching records.
    **********
    */
    @AuraEnabled
    public static List<LookupSearchResult> searchLookupRecords(String searchTerm, List<String> selectedIds,String sObjectName, String field, String subField,Integer maxResults) {
        List<LookupSearchResult> results = new List<LookupSearchResult>();
        
        String strQuery = 'SELECT Id, '+field + (String.isNotBlank(subField) ? ' ,'+subField : '')+' FROM '+sObjectName;
        strQuery += ' WHERE '+field+' LIKE \'' + searchTerm + '%\' AND ';  
        strQuery += ' Id NOT IN :selectedIds ORDER BY '+field+' LIMIT :maxResults';
        
        List<sObject> searchResults = Database.query(strQuery);   
        if(searchResults != NUll && !searchResults.isEmpty()){
            for(sObject sObj : searchResults){
                LookupSearchResult res = new LookupSearchResult();
                res.Id = sObj.Id;
                res.title = String.valueOf(sObj.get(field));
                if(String.isNotBlank(subField) && sObj.get(subField) != NULL){
                    res.subtitle = String.valueOf(sObj.get(subField));
                }else{
                    res.subtitle = sObjectName;
                }
                results.add(res);
            } 
        }
        return results;        
    }
    
     /*
    **********
    Method Name : getRecentlyCreatedRecord
    Author: Ayush Nanda
    @description: Retrieves a recently created record by its ID.
                 This is useful for updating UI components dynamically after record creation.
    @param 
        - sObjectName : The API name of the object.
        - recordId : The unique identifier of the record.
        - field : The primary field to display (e.g., "Name").
        - subField : (Optional) A secondary field to display (e.g., "Email").
    @return A LookupSearchResult object representing the retrieved record.
    **********
    */
    @AuraEnabled
    public static LookupSearchResult getRecentlyCreatedRecord(String sObjectName, String recordId, String field, String subField) {
        LookupSearchResult result = new LookupSearchResult();
        String strQuery = 'SELECT Id, '+field + (String.isNotBlank(subField) ? ' ,'+subField : '')+' FROM '+sObjectName +' WHERE Id =:recordId LIMIT 1';
        List<sObject> searchResults = Database.query(strQuery);   
        if(searchResults != NUll && !searchResults.isEmpty()){
            sObject sObj = searchResults.get(0);
            LookupSearchResult res = new LookupSearchResult();
            result.Id = sObj.Id;
            result.title = String.valueOf(sObj.get(field));
            if(String.isNotBlank(subField) && sObj.get(subField) != NULL){
                result.subtitle = String.valueOf(sObj.get(subField));
            }else{
                result.subtitle = sObjectName;
            }
        }
        return result;        
    }
    
    /*
    **********
    Class Name: LookupSearchResult
    Author: Ayush Nanda
    @description: A helper class to store lookup search results.
                 It is used to structure the response from lookup searches.
    **********
    */
    public class LookupSearchResult {
        @AuraEnabled public Id id{get;set;}
        @AuraEnabled public String title{get;set;}
        @AuraEnabled public String subtitle{get;set;}
    }
}