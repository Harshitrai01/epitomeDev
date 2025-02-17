public without sharing class bookFormController {

    

         @AuraEnabled(cacheable=true)
    public static getRecordDataWrapper getRecordDataAccount(String recordId){
        getRecordDataWrapper responseObj= new getRecordDataWrapper();
        LightningResponse response =new LightningResponse();
        List<Account> listOfAccount = new List<Account>();
   
        try{
            response.isSuccess = true; 
            if(String.isNotEmpty(recordId) || String.isNotBlank(recordId)){
                listOfAccount = [SELECT Id,Name,Email__c,Phone, Same_As_Permanent_Address__c
				
                                     FROM Account WHERE Id =:recordId];
                if(!(listOfAccount.isEmpty())){
                    responseObj.listOfAccountRecords = listOfAccount;
                    response.body = 'success';
                }
            }else{
                response.isSuccess = false;
                response.body = 'Record Id not found.';
            }
            System.debug('---->'+listOfAccount);
        }catch(Exception ex){
            response.isSuccess = false;
            response.body = ex.getMessage();
        }
        responseObj.response = response;
        return responseObj;
    }
    
   @AuraEnabled
    public static LightningResponse saveFormData(String bookingFormData, string recordId){
        LightningResponse response =new LightningResponse();
        SavePoint sp = Database.setSavepoint(); 
        try {
                response.isSuccess = true;
                bookingFormData bookingFormDataObj =(bookingFormData) System.JSON.deserialize(bookingFormData, bookingFormData.class);
                if(String.isNotBlank(recordId)){
                    Account accObj=new Account();
					accObj.Id=bookingFormDataObj.existingAccountId;
                    accObj.Name = String.isNotBlank(bookingFormDataObj.accountName) ? bookingFormDataObj.accountName: null;
                    accObj.Phone =  String.isNotBlank(bookingFormDataObj.accountContactNo) ? bookingFormDataObj.accountContactNo: null;
                    accObj.Email__c =  String.isNotBlank(bookingFormDataObj.accountEmailId) ? bookingFormDataObj.accountEmailId: null;
                    accObj.BillingStreet= String.isNotBlank(bookingFormDataObj.accountPermanentAddressStreet) ? bookingFormDataObj.accountPermanentAddressStreet: null;
                    accObj.BillingCity= String.isNotBlank(bookingFormDataObj.accountPermanentAddressCity) ? bookingFormDataObj.accountPermanentAddressCity: null;
                    accObj.BillingCountry= String.isNotBlank(bookingFormDataObj.accountPermanentAddressCountry) ? bookingFormDataObj.accountPermanentAddressCountry: null;
                    accObj.BillingState= String.isNotBlank(bookingFormDataObj.accountPermanentAddressState) ? bookingFormDataObj.accountPermanentAddressState: null;
                    accObj.BillingPostalCode= String.isNotBlank(bookingFormDataObj.accountPermanentAddressPostalCode) ? bookingFormDataObj.accountPermanentAddressPostalCode: null;
                    accObj.ShippingStreet= String.isNotBlank(bookingFormDataObj.accountCorrespondenceAddressStreet) ? bookingFormDataObj.accountCorrespondenceAddressStreet: null;
                    accObj.ShippingCity= String.isNotBlank(bookingFormDataObj.accountCorrespondenceAddressCity) ? bookingFormDataObj.accountCorrespondenceAddressCity: null;
                    accObj.ShippingCountry= String.isNotBlank(bookingFormDataObj.accountCorrespondenceAddressCountry) ? bookingFormDataObj.accountCorrespondenceAddressCountry: null;
                    accObj.ShippingState= String.isNotBlank(bookingFormDataObj.accountCorrespondenceAddressState) ? bookingFormDataObj.accountCorrespondenceAddressState: null;
                    accObj.ShippingPostalCode= String.isNotBlank(bookingFormDataObj.accountCorrespondenceAddressPostalCode) ? bookingFormDataObj.accountCorrespondenceAddressPostalCode: null;
                    accObj.Same_As_Permanent_Address__c= Boolean.valueOf(bookingFormDataObj.accountSameAsPermanentAddress);
                    upsert accObj;
                    
                //     Contact newContact = new Contact();
                //     newContact.LastName = String.isNotBlank(bookingFormDataObj.quoteContactName) ? bookingFormDataObj.quoteContactName : null;
                //     newContact.PAN_Card__c = String.isNotBlank(bookingFormDataObj.quoteContactPan) ? bookingFormDataObj.quoteContactPan : null;
                //     newContact.Aadhaar_Card__c = String.isNotBlank(bookingFormDataObj.quoteContactAadhaar) ? bookingFormDataObj.quoteContactAadhaar : null;
                //     newContact.Date_Of_Birth__c = String.isNotBlank(bookingFormDataObj.quoteContactDOB) ? Date.valueOf(bookingFormDataObj.quoteContactDOB) : null;
                //     newContact.Email = String.isNotBlank(bookingFormDataObj.quoteContactEmailId) ? bookingFormDataObj.quoteContactEmailId : null;
                //     newContact.Phone = String.isNotBlank(bookingFormDataObj.quoteContactNo) ? bookingFormDataObj.quoteContactNo : null;
                //     newContact.AccountId = accObj.Id;
                //     insert newContact;
                    
                //     system.debug('bookingFormDataObj.quoteId'+bookingFormDataObj.quoteId);

                //     Opportunity opp = new Opportunity();
                //     opp.Name=bookingFormDataObj.quoteunitPlotName + '_' + bookingFormDataObj.quoteContactName;
                //     opp.First_Booking_Amount__c=String.isNotBlank(bookingFormDataObj.opportunityBookingAmount) ? Decimal.valueOf(bookingFormDataObj.opportunityBookingAmount) : null;
                //     opp.AccountId=accObj.Id;
                //     opp.StageName='Blocked';
                //     opp.CloseDate=Date.today();
                //     opp.Unit__c=String.isNotBlank(bookingFormDataObj.quotePlot) ? bookingFormDataObj.quotePlot : null;
                //     opp.ContactId = newContact.id;
                //     opp.Contact__c = newContact.id;
                //     opp.OwnerId = getCRMUserId();
                //     opp.Type_of_Booking__c =String.isNotBlank(bookingFormDataObj.typeOfBooking) ? bookingFormDataObj.typeOfBooking : null;
                //     opp.Sale_Value_Amount__c=String.isNotBlank(bookingFormDataObj.saleValueAmount) ? Decimal.valueOf(bookingFormDataObj.saleValueAmount) : null;
                //     opp.Lead_Quote__c=bookingFormDataObj.quoteId;
                //     insert opp;
        
                //     Quote__c quoteObj=new Quote__c();
                //     quoteObj.Id = bookingFormDataObj.quoteId;
                //     quoteObj.Opportunity__c = opp.Id;
                //     update quoteObj;

                //     Unit__c plot=new Unit__c();
                //     plot.id=bookingFormDataObj.quotePlot;
                //    // plot.Status__c='Booked';
                //     plot.Contact__c=newContact.id;
                //     update plot;

                //     Lead leadObj=new Lead();
                //     leadObj.Id=bookingFormDataObj.leadId;
                //    // leadObj.Status='Booked';
                //     update leadObj;
                    
                    response.body = 'success';
                    // response.accountId = accObj.Id;

                }else{
                    response.isSuccess = false;
                    response.body = 'Record Id not found.';
                  //  response.accountId = 'Account id not found';
                }
            } catch(Exception ex){
                response.isSuccess = false;
                String strTempError = '';
                if (ex.getMessage() != null && ex.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION') == true)
                {
                    strTempError = ((ex.getMessage().split('FIELD_CUSTOM_VALIDATION_EXCEPTION,') [1]).split(':') [0]).trim();
                }

                if (ex.getMessage() != null && ex.getMessage().contains('INVALID_EMAIL_ADDRESS,') == true)
                {
                    strTempError = ((ex.getMessage().split('INVALID_EMAIL_ADDRESS,') [1]).split(':') [0]).trim() + ' : ' + ((ex.getMessage().split('INVALID_EMAIL_ADDRESS,') [1]).split(':') [1]).trim();
                }
                response.body = strTempError != '' ? strTempError : ex.getMessage();
            //    / response.accountId = 'Account id not found';
                Database.rollback(sp);
            }
        return response;
    }

  
   
    @AuraEnabled(cacheable=true)
    public static Account getAccountDetails(Id accountId) {
        return [
            SELECT Id, Name, Phone, Email__c, BillingStreet, BillingCity, BillingCountry, 
                   BillingState, BillingPostalCode, ShippingStreet, ShippingCity, 
                   ShippingCountry, ShippingState, ShippingPostalCode, 
                   Same_As_Permanent_Address__c
            FROM Account
            WHERE Id = :accountId
            LIMIT 1
        ];
    }


public class ListOfPlot {
    public String plotId { get; set; }
    public String plotName { get; set; }
    public String unitOppAmount { get; set; }
    public String plotunitsname { get; set; }
    public String unitPlotFacing { get; set; }
    public String unitPlotPhase { get; set; }
    public String unitPlotUnitCode { get; set; }
    public String unitPlotPrize { get; set; }
    public String unitPlotSize { get; set; }
}

public class ListOfCoApplicant {
	public String contactId;
	public String contactName;
    public String contactEmail;
    public String contactPhone;
    public String contactAadhaar;
    public String contactPan;
    public String contactDOB;
    public List<ListOfPlot> plots;
}
    
   
public class bookingFormData {
	public String dateOfBooking;
    public String unitName;
    public String unitId;
    public string quoteId;
	public String opportunityId;
	public String opportunityProjectName;
	public String opportunitySalesUser;
	public String opportunityBookingAmount;
    public String opportunityPaymentMode;
    public String paymentMilestoneId;
    public String opportunityPaymentDate;
	public String accountDOB;
	public String accountAadhaarCard;
	public String accountName;
    public String accountSoWoDo;
    public String accountPanCard;
	public String accountPermanentAddressStreet;
	public String accountPermanentAddressCity;
	public String accountPermanentAddressCountry;
	public String accountPermanentAddressState;
	public String accountPermanentAddressPostalCode;
    public String accountCorrespondenceAddressStreet;
	public String accountCorrespondenceAddressCity;
	public String accountCorrespondenceAddressCountry;
	public String accountCorrespondenceAddressState;
	public String accountCorrespondenceAddressPostalCode;
    public Boolean accountSameAsPermanentAddress;
	public String accountContactNo;
    public String typeOfBooking;
    public String visitDate;
	public String accountEmailId;
    public String quoteContactName;
    public String quoteContactEmailId;
    public String quoteContactNo;
    public String quoteContactPan;
    public String quoteContactAadhaar;
    public String quoteContactDOB;
    public String quotePlot;
    public String quotePlotName;
    public String quoteunitPlotFacing;
    public String quoteunitPlotSize;
    public String quoteunitPlotPrize;
    public String quoteunitPlotUnitCode;
    public String quoteunitPlotName;
    public String quoteunitPlotPhase;
    public String leadId;
    public String saleValueAmount;
	public string existingAccountId;
    public List<ListOfCoApplicant> listOfCoApplicant;        
}

public class getRecordDataWrapper{
    @AuraEnabled
    public List<Quote__c> listOfOpportunityRecords{get; set;}
    @AuraEnabled
    public List<Account> listOfAccountRecords{get; set;}
    @AuraEnabled
    public List<Contact> listOfApplicantRecords{get; set;}
    @AuraEnabled
    public List<Unit__c> listOfPlotRecords{get; set;}
    @AuraEnabled
    public LightningResponse response{get; set;}
}

public class LightningResponse {
    @AuraEnabled
    public Boolean isSuccess { get; set; }
    @AuraEnabled
    public String body { get; set; }
    // @AuraEnabled
    // public String accountId { get; set; }
}
}