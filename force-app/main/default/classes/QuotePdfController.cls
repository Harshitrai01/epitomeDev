public class QuotePdfController {
	
    public Quote__c quote { get; set; }
    public String dateOfBooking { get; set; }
    
    public QuotePdfController(ApexPages.StandardController stdController) {
        String quoteId= Apexpages.currentPage().getParameters().get('id');
        List<Quote__c> quoteObjList = [
                SELECT Id,Name,IsQuoteGenerated__c,Plot__c,Phase__c,Project__c,IsSample__c,CreatedDate,Lead__r.Name,
                Lead__r.Phase__r.Name,Plot__r.Name,Plot__r.Plot_Facing__c,Plot__r.Plot_Size__c,Plot__r.Flat_Number__c,
                Plot__r.Floor_Number__c,Plot__r.Unit_Code__c,Lead__r.Project__r.Project_Type__c,Plot__r.Base_Price_per_Sq_Ft__c,
                Plot_Dimension__c,Total_Basic_Cost__c,Total_Gst_For_Charge__c,Total_Charge_Amount__c,AgreementValueWithGst__c,
                Base_Price_Per_Sq_Yard__c,Price_For_North_East__c,Other_Corners__c,East__c,X100_Ft_Road_Plots__c,Premium_Plots__c,
                Rate_Per_Sq_Yd__c,Corpus_Fund_and_Club_House_Payable__c,Legal_And_Documentation_Charges__c,Registration_Charges__c,
                IsLocked__c,Approval_Status__c,Lead__r.Email,Lead__r.Phone,
            	Opportunity__r.Contact__r.Name, Opportunity__r.Contact__r.Email, Plot__r.Phase__r.Name, 
                Plot__r.Phase__r.Project__r.Name, Plot__r.Phase__r.Project_Type__c,Plot__r.Plot_Dimension__c
                FROM Quote__c where Id =: quoteId 
            ];
        if(!quoteObjList.isEmpty()){
            quote=quoteObjList[0];
            dateOfBooking = quoteObjList[0].CreatedDate.format('dd/MM/yyyy');
            System.debug('Date-->>'+dateOfBooking);
        }
    }
    
}