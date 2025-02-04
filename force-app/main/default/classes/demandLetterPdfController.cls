public class demandLetterPdfController {
	
    public Opportunity opportunityRecord { get; set; }
    
    public demandLetterPdfController(ApexPages.StandardController stdController) {
        
        String opportunityId='006O400000G2sccIAB';
       // System.debug('Quote Id-->>'+quoteId);
       List<Opportunity> opportunityList = [SELECT  id,Name,AccountId,Account.Name, Unit__r.Name,Account.ShippingState,Account.ShippingCity, Account.ShippingCountry,
                                         Account.ShippingStreet,Account.ShippingPostalCode ,  Account.Branch_Name__c, Account.IFSC_Code__c
                                        FROM Opportunity WHERE Id = :opportunityId LIMIT 1];
         if(!opportunityList.isEmpty()){
            opportunityRecord=opportunityList[0];
            
        }
        system.debug('opportunityList--->'+opportunityList);
      
    }
    
}