public class demandLetterPdfController {
	
    public Opportunity opportunityRecord { get; set; }
    public OpportunityContactRole OpportunityContactRolesRecord { get; set; }
    public String balanceAmountInWords { get; set; }
    
    public demandLetterPdfController(ApexPages.StandardController stdController) {
        
        Id opportunityId = ApexPages.currentPage().getParameters().get('Id');
        System.debug('Quote Id-->>'+opportunityId);
       List<Opportunity> opportunityList = [SELECT  id,Name,Unit__r.Name,Unit__r.Bank_Name__c,Unit__r.Virtual_Account_IFSC__c,Unit__r.Virtual_Account_Number__c,
                                            Sale_Value_Amount__c, Collected_Amount__c, Outstanding_Amount__c
                                            FROM Opportunity WHERE Id = :opportunityId LIMIT 1];
        
         if(!opportunityList.isEmpty()){
            opportunityRecord=opportunityList[0];
        }
        if(opportunityRecord.Outstanding_Amount__c>0){
            balanceAmountInWords = NumberToCharacter.getNumberTOWordConvertion(opportunityRecord.Outstanding_Amount__c);
        }else{
            balanceAmountInWords='-';
        }
        
        
         List<OpportunityContactRole> OpportunityContactRolesList = [SELECT Id,ContactId, Contact.Name, Contact.Email, Contact.Phone ,Contact.Permanent_Address__City__s,
                                             Contact.Permanent_Address__CountryCode__s,Contact.Permanent_Address__StateCode__s,Contact.Permanent_Address__PostalCode__s,
                                             Contact.Permanent_Address__Street__s ,OpportunityId
            								 FROM OpportunityContactRole WHERE IsPrimary = TRUE and OpportunityId=: opportunityId LIMIT 1];
        
          if(!OpportunityContactRolesList.isEmpty()){
            OpportunityContactRolesRecord=OpportunityContactRolesList[0];
        }
        
        system.debug('opportunityList--->'+opportunityList);
      
    }
    
}