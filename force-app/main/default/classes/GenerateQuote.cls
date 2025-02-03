public class GenerateQuote {
    
        @AuraEnabled
    public static LightningResponse generateQuote(String recordId,String strunitId,String strPhaseId,String strTowerId,String strProjectId){
        try {
            Decimal gstValue ;
            List<Unit__c> unitDetail = new List<Unit__c>();
            List<Opportunity> oppDetail = new List<Opportunity>();
            List<Phase__c> pahseDetail = new List<Phase__c>();
            List<Project__c> projectDetail = new List<Project__c>(); 
            oppDetail = [SELECT Id,Name,Account.Name FROM Opportunity WHERE Id=:recordId];
            unitDetail = [SELECT Id,Name,Base_Price_per_Sq_Ft__c,Unit_Code__c,
            Plot_Facing__c,Project__r.Project_Type__c FROM Unit__c WHERE Id=:strunitId];
            pahseDetail = [SELECT Id,Name FROM Phase__c WHERE Id=:strPhaseId];
            projectDetail = [SELECT Id,Sales_Head__c FROM Project__c WHERE Id=:strProjectId];
            //gstValue = pahseDetail[0].GST__c ;
            
            Quote newGeneratedQuote = new Quote ();
            newGeneratedQuote.Name = oppDetail[0].Name + '-Quote';
            newGeneratedQuote.Status__c = 'Draft';
            newGeneratedQuote.Sales_Head__c = projectDetail[0].Sales_Head__c!=null? projectDetail[0].Sales_Head__c:null ;
            //newGeneratedQuote.CustomerName__c = oppDetail[0].Account.Name;
            //newGeneratedQuote.BasePriceperSqFt__c = unitDetail[0].Base_Price_per_Sq_Ft__c!=null? unitDetail[0].Base_Price_per_Sq_Ft__c :0;
            //newGeneratedQuote.Tower__c = strTowerId;
            newGeneratedQuote.Project__c = strProjectId;
            newGeneratedQuote.Phase__c = strPhaseId;
            newGeneratedQuote.OpportunityId = recordId;
            newGeneratedQuote.Unit__c = unitDetail[0].Id;
            //newGeneratedQuote.GST__c = gstValue;
            //newGeneratedQuote.Corner_Plot__c = unitDetail[0].Corner_Plot__c;
            //newGeneratedQuote.Plot_Saleable_Area_In_Sqft__c = unitDetail[0].Plot_Saleable_Area_In_Sqft__c!=null? unitDetail[0].Plot_Saleable_Area_In_Sqft__c :0;
            //newGeneratedQuote.Plot_Saleable_Area_In_Sqm__c = unitDetail[0].Plot_Saleable_Area_In_Sqm__c!=null? unitDetail[0].Plot_Saleable_Area_In_Sqm__c :0;
            //newGeneratedQuote.BasePriceperSqFt__c = unitDetail[0].Base_Price_per_Sq_Ft__c!=null? unitDetail[0].Base_Price_per_Sq_Ft__c :0;
            //newGeneratedQuote.Facing__c = unitDetail[0].Facing__c!=null? unitDetail[0].Facing__c :'';
            //newGeneratedQuote.Plot_Dimension__c = unitDetail[0].Plot_Dimension__c!=null? unitDetail[0].Plot_Dimension__c :'';
            //newGeneratedQuote.Carpet_Area_In_sqft__c = unitDetail[0].Carpet_Area_In_sqft__c!=null? unitDetail[0].Carpet_Area_In_sqft__c :0; 
            //newGeneratedQuote.Carpet_Area_In_sqm__c = unitDetail[0].Carpet_Area_In_sqm__c!=null? unitDetail[0].Carpet_Area_In_sqm__c :0; 
            //newGeneratedQuote.Private_Garden_Area_In_Sqm__c = unitDetail[0].Private_Garden_Area_In_Sqm__c!=null? unitDetail[0].Private_Garden_Area_In_Sqm__c :0;  
            //newGeneratedQuote.Private_Garden_Area_In_Sqft__c = unitDetail[0].Private_Garden_Area_In_Sqft__c!=null? unitDetail[0].Private_Garden_Area_In_Sqft__c :0; 
            //newGeneratedQuote.UnitCode__c = unitDetail[0].Unit_Code__c;
            
            DateTime currentDateTime = DateTime.now();
            DateTime futureDateTime = currentDateTime.addHours(24);
            newGeneratedQuote.Quote_End_Date_Time__c = futureDateTime;
            insert newGeneratedQuote;
            LightningResponse response = new LightningResponse();
            response.isSuccess = true;
            response.quoteId = newGeneratedQuote.Id;
            return response;
        } catch (Exception e) {
            System.debug('e line---'+e.getLineNumber());
            System.debug('e message---'+e.getMessage());
            LightningResponse response = new LightningResponse();
            response.isSuccess=false;
            response.message=e.getMessage();
            return response;
        }
    }
    
        public  class LightningResponse {
        @AuraEnabled
        public   Boolean isSuccess {get;set;}
        @AuraEnabled
        public   String message {get;set;}
        @AuraEnabled
        public  set<String>  setFieldsname {get;set;}
        @AuraEnabled
        public  List<Integer>  flatList {get;set;}
         @AuraEnabled
        public String quoteId {get;set;}
    }

}