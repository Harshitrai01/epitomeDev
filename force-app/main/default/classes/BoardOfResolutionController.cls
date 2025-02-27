public class BoardOfResolutionController {
	
    public Opportunity opportunityRecord { get; set; }
    public String balanceAmountInWords { get; set; }
    
    public BoardOfResolutionController(ApexPages.StandardController stdController) {
        
        Id opportunityId = ApexPages.currentPage().getParameters().get('Id');
        System.debug('Quote Id-->>'+opportunityId);
       List<Opportunity> opportunityList = [SELECT  id,Name,Unit__r.Name,Unit__r.Address__City__s,Unit__r.Address__CountryCode__s,Unit__r.Address__PostalCode__s,
                                            Unit__r.Address__StateCode__s,Unit__r.Address__Street__s,Board_Of_Resolution_Authority_Person__c,
                                            Board_Of_Resolution_Authority_Person__r.Name,
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
        system.debug('opportunityList--->'+opportunityList);
      
    }
    
}