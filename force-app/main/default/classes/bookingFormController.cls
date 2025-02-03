public without sharing class bookingFormController {

    @AuraEnabled(cacheable=true)
    public static getRecordDataWrapper getRecordData(String recordId){
        getRecordDataWrapper responseObj= new getRecordDataWrapper();
        LightningResponse response =new LightningResponse();
        List<Quote__c> listOfOpportunity = new List<Quote__c>();
        try{
            response.isSuccess = true; 
            if(String.isNotEmpty(recordId) || String.isNotBlank(recordId)){
                listOfOpportunity = [SELECT Id,Name,Plot__c
				
				
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
    @AuraEnabled
public static Unit__c getPlotDetails(Id plotName) {
    return [SELECT Id, Name, Plot_Facing__c, Plot_Price__c FROM Unit__c WHERE Id = :plotName LIMIT 1];
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
                opp.Name=bookingFormDataObj.quotePlotName + '_' + bookingFormDataObj.quoteContactName;
                opp.First_Booking_Amount__c=Decimal.valueOf(bookingFormDataObj.opportunityBookingAmount);
                opp.AccountId=accObj.Id;
                opp.StageName='Booking';
                opp.CloseDate=Date.today();
                opp.Unit__c=bookingFormDataObj.quotePlot;
                // opp.OwnerId=salesQueueId;
                insert opp;

                system.debug('oppid---->'+opp.id);
                system.debug('oppid---->'+opp.ownerId);
            //     CustomNotificationHelper.sendNotification(
            //     'Opportunity_Notification', // Custom Notification Type API Name
            //     'New Opportunity Created',
            //     'An Opportunity named "' + name + '" has been created!',
            //     opp.Id,
            //     recipientIds
            // );
                Quote__c quoteObj=new Quote__c();
                quoteObj.Id = bookingFormDataObj.quoteId;
                quoteObj.Opportunity__c = opp.Id;
                update quoteObj;
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
            Database.rollback(sp);
        }
        return response;
    }

//  public static void notifyUsers(Set<String> recipientsIds, String targetId, CustomNotificationType notificationType,String titleText,String bodyText) {
//         try {
//             List<Messaging.CustomNotification> listOfCustomNotification = new List<Messaging.CustomNotification>();
//             // Create a new custom notification
//             Messaging.CustomNotification notification = new Messaging.CustomNotification();
//             // Set the contents for the notification
//             notification.setTitle(titleText);
//             notification.setBody(bodyText);
//             // Set the notification type and target
//             notification.setNotificationTypeId(notificationType.Id);
//             notification.setTargetId(targetId);
//             // Actually send the notification
//             notification.send(recipientsIds);
//         }
//         catch (Exception ex) {
//             System.debug('notifyUsers error message----------------->'+ex.getMessage());
//             throw new AuraHandledException(ex.getMessage());
//         }
//     }

    @AuraEnabled
    public static LightningResponse saveFormData1(String bookingFormData){
        LightningResponse response =new LightningResponse();
        SavePoint sp = Database.setSavepoint(); 
        try {
            response.isSuccess = true;
            bookingFormData bookingFormDataObj =(bookingFormData) System.JSON.deserialize(bookingFormData, bookingFormData.class);
             
            if(String.isNotBlank(bookingFormDataObj.accountName)){
                 
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
                  

                //   Id salesQueueId = getSalesQueueId();
                 List<Opportunity> opportunitiesToInsert = new List<Opportunity>();
                // Initialize necessary lists and maps
// Step 1: Initialize data structures
List<Unit__c> plotsToUpdate = new List<Unit__c>();
List<Contact> contactsToInsert = new List<Contact>();
Map<String, List<Unit__c>> contactKeyToPlotsMap = new Map<String, List<Unit__c>>();

// Step 2: Prepare Contacts and map their plots
for (ListOfCoApplicant coApplicant : bookingFormDataObj.listOfCoApplicant) {
    // Create contact
    Contact newContact = new Contact();
    newContact.LastName = String.isNotBlank(coApplicant.contactName) ? coApplicant.contactName : null;
    newContact.PAN_Card__c = String.isNotBlank(coApplicant.contactPan) ? coApplicant.contactPan : null;
    newContact.Aadhaar_Card__c = String.isNotBlank(coApplicant.contactAadhaar) ? coApplicant.contactAadhaar : null;
    newContact.Date_Of_Birth__c = String.isNotBlank(coApplicant.contactDOB) ? Date.valueOf(coApplicant.contactDOB) : null;
    newContact.Email = String.isNotBlank(coApplicant.contactEmail) ? coApplicant.contactEmail : null;
    newContact.Phone = String.isNotBlank(coApplicant.contactPhone) ? coApplicant.contactPhone : null;
    newContact.AccountId = accObj.Id;
    contactsToInsert.add(newContact);
    
     

           
      

   

    // Use unique identifier for mapping: e.g., combination of LastName and a counter
    String uniqueKey = coApplicant.contactName + '_' + contactsToInsert.size();

    // Prepare plots for the contact
    for (ListOfPlot plot : coApplicant.plots) {
                          
                            
        Unit__c newPlot = new Unit__c();
        newPlot.Id = plot.plotName;
        newPlot.Contact__c = null;

        // Store plot with unique key
        if (!contactKeyToPlotsMap.containsKey(uniqueKey)) {
            contactKeyToPlotsMap.put(uniqueKey, new List<Unit__c>());
        }
        contactKeyToPlotsMap.get(uniqueKey).add(newPlot);

        Opportunity opp = new Opportunity();
    opp.Name=plot.plotunitsname + '_' + coApplicant.contactName;
    opp.First_Booking_Amount__c=Decimal.valueOf(plot.unitOppAmount);
    opp.AccountId=accObj.Id;
    opp.StageName='Booking';
                opp.CloseDate=Date.today();
                opp.Unit__c=plot.plotName;
                opp.Type_of_Booking__c=String.isNotBlank(bookingFormDataObj.typeOfBooking) ? bookingFormDataObj.typeOfBooking: null;
                // opp.OwnerId=salesQueueId;
                opportunitiesToInsert.add(opp);




    }
   
}

// Step 3: Insert Contacts and map them back
if (!contactsToInsert.isEmpty()) {
    insert contactsToInsert;

    // Map unique keys to Contact Ids
    Map<String, Id> contactKeyToIdMap = new Map<String, Id>();
    for (Integer i = 0; i < contactsToInsert.size(); i++) {
        String uniqueKey = contactsToInsert[i].LastName + '_' + (i + 1);
        contactKeyToIdMap.put(uniqueKey, contactsToInsert[i].Id);
    }
    system.debug('map'+contactKeyToPlotsMap);
    system.debug('map'+contactKeyToIdMap);
    // Step 4: Update plots with Contact Ids
    for (String key : contactKeyToPlotsMap.keySet()) {

        if (contactKeyToIdMap.containsKey(key)) {
            Id contactId = contactKeyToIdMap.get(key);
            for (Unit__c plot : contactKeyToPlotsMap.get(key)) {
             
                plot.Contact__c = contactId;
                plotsToUpdate.add(plot);
            }
        }
    }

    // Step 5: Perform update
    if (!plotsToUpdate.isEmpty()) {
        system.debug('plotsToUpdate---->'+plotsToUpdate);
        update plotsToUpdate;
    }


if (!opportunitiesToInsert.isEmpty()) {
    insert opportunitiesToInsert;

    // After Opportunity insert, assign Opportunity Id to Quotes and insert Quotes
    List<Quote> quotesToInsert = new List<Quote>();
    for (Opportunity opp : opportunitiesToInsert) {
        String quoteName = opp.Name; // Use Opportunity Name or customize
        Quote quoteObj = new Quote();
        quoteObj.Name = opp.Name;
        quoteObj.OpportunityId = opp.Id; // Now the Opportunity Id is available
        quoteObj.Status='Accepted';
        quotesToInsert.add(quoteObj);
    }

    if (!quotesToInsert.isEmpty()) {
        insert quotesToInsert;
    }
}

                response.body = 'success';
            }

                // Contact con=new Contact();
                // con.LastName=bookingFormDataObj.accountSoWoDo;
                // insert con;
            //     Opportunity opp=new Opportunity();
            //     opp.Name=bookingFormDataObj.accountName;
            //     opp.StageName='Booking';
            //     opp.CloseDate=Date.today();
            //     //opp.Unit__c=bookingFormDataObj.unitId;
            //     opp.Plot_Dimension__c=bookingFormDataObj.unitName;
            //     //opp.Date_of_Booking__c=Date.today();
            //     //opp.Booking_Amount__c=Decimal.valueOf(bookingFormDataObj.opportunityBookingAmount);
               
            //     opp.AccountId=accObj.Id;
            //   //  opp.ContactId=con.Id;
                
            //     insert opp;
		
                
                

            }
            if(String.isNotBlank(bookingFormDataObj.opportunityId) ){
                Opportunity opportunityObj=new  Opportunity();
                opportunityObj.Id =  String.isNotBlank(bookingFormDataObj.opportunityId) ? bookingFormDataObj.opportunityId: null;
                opportunityObj.Booking_Amount__c =  String.isNotBlank(bookingFormDataObj.opportunityBookingAmount) ? Decimal.valueOf(bookingFormDataObj.opportunityBookingAmount): null;
                opportunityObj.Sales_User__c =  String.isNotBlank(bookingFormDataObj.opportunitySalesUser) ? bookingFormDataObj.opportunitySalesUser: null;
                opportunityObj.Date_of_Booking__c =  String.isNotBlank(bookingFormDataObj.dateOfBooking) ? Date.valueOf(bookingFormDataObj.dateOfBooking): null;
                opportunityObj.Payment_Mode__c =  String.isNotBlank(bookingFormDataObj.opportunityPaymentMode) ? bookingFormDataObj.opportunityPaymentMode: null;     
                opportunityObj.Payment_Date__c =  String.isNotBlank(bookingFormDataObj.opportunityPaymentDate) ? Date.valueOf(bookingFormDataObj.opportunityPaymentDate): null;           
                upsert opportunityObj;
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
            Database.rollback(sp);
        }
        return response;
    }

    @AuraEnabled
    public static LightningResponse submitFormData(String bookingFormData){
        LightningResponse response =new LightningResponse();
        SavePoint sp = Database.setSavepoint(); 
        try{
            bookingFormData bookingFormDataObj =(bookingFormData) System.JSON.deserialize(bookingFormData, bookingFormData.class);
            response.isSuccess = true;
            Opportunity opportunityObj=new Opportunity();
            opportunityObj.Id = bookingFormDataObj.opportunityId;
            opportunityObj.Date_of_Booking__c = Date.today();
            //opportunityObj.Blocked_Approval_Status__c ='Submitted';
            update opportunityObj;
            response.body='Form submitted successfully';
        }catch(Exception ex){
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
            Database.rollback(sp);
        }
        return response;
    }
public class ListOfPlot {
           public String plotId { get; set; }
            String plotName { get; set; }
             String unitOppAmount { get; set; }
         String plotunitsname { get; set; }
         String unitPlotFacing { get; set; }
         String unitPlotPhase { get; set; }
         String unitPlotUnitCode { get; set; }
         String unitPlotPrize { get; set; }
         String unitPlotSize { get; set; }
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
		public String accountId;
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
    }
}