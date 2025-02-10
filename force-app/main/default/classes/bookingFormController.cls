public without sharing class bookingFormController {

    @AuraEnabled(cacheable=true)
    public static getRecordDataWrapper getRecordData(String recordId){
        getRecordDataWrapper responseObj= new getRecordDataWrapper();
        LightningResponse response =new LightningResponse();
        List<Quote__c> listOfOpportunity = new List<Quote__c>();
        try{
            response.isSuccess = true; 
            if(String.isNotEmpty(recordId) || String.isNotBlank(recordId)){
                listOfOpportunity = [SELECT Id,Name,Plot__c,Plot__r.Plot_Facing__c, Plot__r.Name, Plot__r.Plot_Size__c, Plot__r.Plot_Price__c, Plot__r.Phase__r.Name, Plot__r.Unit_Code__c
				
                                     FROM Quote__c WHERE Id =:recordId];
                if(!(listOfOpportunity.isEmpty())){
                    responseObj.listOfOpportunityRecords = listOfOpportunity;
                    response.body = 'success';
                }
            }else{
                response.isSuccess = false;
                response.body = 'Record Id not found.';
            }
            System.debug('---->'+listOfOpportunity);
        }catch(Exception ex){
            response.isSuccess = false;
            response.body = ex.getMessage();
        }
        responseObj.response = response;
        return responseObj;
    }

    public static Id getCRMUserId() {
        User crmUser = [select id,Name,profile.Name from User where Profile.Name='CRM Manager' limit 1];
        return crmUser != null ? crmUser.Id : null;
    }

   @AuraEnabled
    public static LightningResponse saveFormData(String bookingFormData){
        LightningResponse response =new LightningResponse();
        SavePoint sp = Database.setSavepoint(); 
        try {
                response.isSuccess = true;
                bookingFormData bookingFormDataObj =(bookingFormData) System.JSON.deserialize(bookingFormData, bookingFormData.class);
                if(String.isNotBlank(bookingFormDataObj.quoteId)){
                    Account accObj=new Account();
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
                    insert accObj;
                    
                    Contact newContact = new Contact();
                    newContact.LastName = String.isNotBlank(bookingFormDataObj.quoteContactName) ? bookingFormDataObj.quoteContactName : null;
                    newContact.PAN_Card__c = String.isNotBlank(bookingFormDataObj.quoteContactPan) ? bookingFormDataObj.quoteContactPan : null;
                    newContact.Aadhaar_Card__c = String.isNotBlank(bookingFormDataObj.quoteContactAadhaar) ? bookingFormDataObj.quoteContactAadhaar : null;
                    newContact.Date_Of_Birth__c = String.isNotBlank(bookingFormDataObj.quoteContactDOB) ? Date.valueOf(bookingFormDataObj.quoteContactDOB) : null;
                    newContact.Email = String.isNotBlank(bookingFormDataObj.quoteContactEmailId) ? bookingFormDataObj.quoteContactEmailId : null;
                    newContact.Phone = String.isNotBlank(bookingFormDataObj.quoteContactNo) ? bookingFormDataObj.quoteContactNo : null;
                    newContact.AccountId = accObj.Id;
                    insert newContact;
                    
                    Opportunity opp = new Opportunity();
                    opp.Name=bookingFormDataObj.quoteunitPlotName + '_' + bookingFormDataObj.quoteContactName;
                    opp.First_Booking_Amount__c=String.isNotBlank(bookingFormDataObj.opportunityBookingAmount) ? Decimal.valueOf(bookingFormDataObj.opportunityBookingAmount) : null;
                    opp.AccountId=accObj.Id;
                    opp.StageName='Blocked';
                    opp.CloseDate=Date.today();
                    opp.Unit__c=String.isNotBlank(bookingFormDataObj.quotePlot) ? bookingFormDataObj.quotePlot : null;
                    opp.ContactId = newContact.id;
                    opp.OwnerId = getCRMUserId();
                    opp.Type_of_Booking__c =String.isNotBlank(bookingFormDataObj.typeOfBooking) ? bookingFormDataObj.typeOfBooking : null;
                    insert opp;
        
                    Quote__c quoteObj=new Quote__c();
                    quoteObj.Id = bookingFormDataObj.quoteId;
                    quoteObj.Opportunity__c = opp.Id;
                    update quoteObj;

                    Unit__c plot=new Unit__c();
                    plot.id=bookingFormDataObj.quotePlot;
                    plot.Contact__c=newContact.id;
                    update plot;
                    
                    response.body = 'success';
                    response.accountId = accObj.Id;

                }else{
                    response.isSuccess = false;
                    response.body = 'Record Id not found.';
                    response.accountId = 'Account id not found';
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
                response.accountId = 'Account id not found';
                Database.rollback(sp);
            }
        return response;
    }

    @AuraEnabled
    public static LightningResponse saveBulkFormData(String bookingFormData){
        LightningResponse response =new LightningResponse();
        SavePoint sp = Database.setSavepoint(); 
        try {
            response.isSuccess = true;
            bookingFormData bookingFormDataObj =(bookingFormData) System.JSON.deserialize(bookingFormData, bookingFormData.class);
             
            if(String.isNotBlank(bookingFormDataObj.accountName) && bookingFormDataObj.listOfCoApplicant != null && !bookingFormDataObj.listOfCoApplicant.isEmpty()){
                Account accObj=new Account();
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
                 
                insert accObj;
                  

               // Prepare lists
                List<Contact> contactsToInsert = new List<Contact>();
                List<Unit__c> plotsToUpdate = new List<Unit__c>();
                List<Opportunity> opportunitiesToInsert = new List<Opportunity>();

                // Map to store contactName -> Contact
                Map<String, Contact> contactMap = new Map<String, Contact>();

                // Create Contacts (No Nested Loops)
                for (ListOfCoApplicant coApplicant : bookingFormDataObj.listOfCoApplicant) {
                    Contact newContact = new Contact(
                        LastName = coApplicant.contactName,
                        PAN_Card__c = coApplicant.contactPan,
                        Aadhaar_Card__c = coApplicant.contactAadhaar,
                        Date_Of_Birth__c = String.isNotBlank(coApplicant.contactDOB) ? Date.valueOf(coApplicant.contactDOB) : null,
                        Email = coApplicant.contactEmail,
                        Phone = coApplicant.contactPhone,
                        AccountId = accObj.Id
                    );

                    contactsToInsert.add(newContact);
                    contactMap.put(coApplicant.contactName, newContact);
                }

                // Bulk insert Contacts
                if (!contactsToInsert.isEmpty()) {
                    insert contactsToInsert;

                    // Update contactMap with inserted Contact Ids
                    for (Contact c : contactsToInsert) {
                        contactMap.put(c.LastName, c);
                    }
                }

                // Create Opportunities & Map Plots in Single Loop
                for (ListOfCoApplicant coApplicant : bookingFormDataObj.listOfCoApplicant) {
                    if (contactMap.containsKey(coApplicant.contactName)) {
                        Id contactId = contactMap.get(coApplicant.contactName).Id;

                        for (ListOfPlot plot : coApplicant.plots) {
                            // Assign contactId to the corresponding plot
                            plotsToUpdate.add(new Unit__c(
                                Id = plot.plotName,
                                Contact__c = contactId
                            ));

                            // Create Opportunity
                            opportunitiesToInsert.add(new Opportunity(
                                Name = plot.plotunitsname + '_' + coApplicant.contactName,
                                First_Booking_Amount__c = Decimal.valueOf(plot.unitOppAmount),
                                AccountId = accObj.Id,
                                StageName = 'Booking',
                                CloseDate = Date.today(),
                                Unit__c = plot.plotName,
                                Type_of_Booking__c = bookingFormDataObj.typeOfBooking,
                                ContactId = contactId, // Direct assignment (No Double Loop!)
                                Bulk_Booking__c=true,
                                OwnerId=getCRMUserId()
                            ));
                        }
                    }
                }

                // Bulk update plots with Contact Ids
                if (!plotsToUpdate.isEmpty()) {
                    update plotsToUpdate;
                }

                // Bulk insert Opportunities
                if (!opportunitiesToInsert.isEmpty()) {
                    insert opportunitiesToInsert;
                    // Insert Quotes in One Pass
                    List<Quote> quotesToInsert = new List<Quote>();
                    for (Opportunity opp : opportunitiesToInsert) {
                        quotesToInsert.add(new Quote(
                            Name = opp.Name,
                            OpportunityId = opp.Id,
                            Status = 'Accepted'
                        ));
                    }
                    if (!quotesToInsert.isEmpty()) {
                        insert quotesToInsert;
                    }
                }
                response.body = 'success';
                response.accountId = accObj.Id;
                }
                else{
                    response.isSuccess = false;
                    response.accountId = 'Account id not found';
                    response.body = 'Record Id not found.';
                }
            } catch(Exception ex){
                response.isSuccess = false;
                response.accountId = 'Account id not found';
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
                Database.rollback(sp);
            }
        return response;
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
    public List<ListOfCoApplicant> listOfCoApplicant;        
}

public class getRecordDataWrapper{
    @AuraEnabled
    public List<Quote__c> listOfOpportunityRecords{get; set;}
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
    @AuraEnabled
    public String accountId { get; set; }
}
}