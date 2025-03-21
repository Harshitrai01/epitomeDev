/**********
Apex Class Name : bookingFormController
Apex Test Class Name: bookingFormControllerTest
Created Date: March 18, 2025
@description : This class is used for managing bulk bookings, individual registrations, and joint registrations against Opportunity.
@author : Dolly Bindal
Modify By : Dolly Bindal
Modify Date: March 18, 2025
**********/

public with sharing class bookingFormController {
     /*
    **********
    Method Name : getOpportunityAccountId
    author: Dolly Bindal
    Description: This method retrieves the Account Id associated with a given Opportunity Id for the joint registration process. 
                 The retrieved Account Id can be used to fetch all related Contacts.
    @params: Id opportunityId - The unique identifier of the Opportunity record.
    @return: getRecordDataWrapper - A wrapper object containing the Account Id, which is used to fetch all associated Contacts.
    **********
    */
    @AuraEnabled(cacheable=true)
    public static getRecordDataWrapper getOpportunityAccountId(Id opportunityId) {
        // Wrapper object to store the response
        getRecordDataWrapper responseObj= new getRecordDataWrapper();
        LightningResponse response =new LightningResponse();
        List<Opportunity> listOfOpportunity = new List<Opportunity>();

        try{
            response.isSuccess = true; 
            // Check if the provided opportunityId is not empty or blank
            if(String.isNotEmpty(opportunityId) || String.isNotBlank(opportunityId)){
                // Query the Opportunity record based on the given Id
                listOfOpportunity = [SELECT Id,AccountId FROM Opportunity WHERE Id = :opportunityId];
                if(!(listOfOpportunity.isEmpty())){
                    responseObj.listOfOpportunityR = listOfOpportunity;
                    response.body = 'success';
                    response.accountId =listOfOpportunity[0].AccountId;
                }
            }else{
                // Handle case where the opportunityId is missing
                response.isSuccess = false;
                response.body = 'Record Id not found.';
                response.accountId= 'Account Id not found';
            }
            System.debug('---->'+listOfOpportunity);
        }catch(Exception ex){
            response.isSuccess = false;
            response.body = ex.getMessage();
            response.accountId= 'Account Id not found';
        }
        responseObj.response = response;
        return responseObj;
    }

    /*
    **********
    Method Name : getRecordData
    Author: Dolly Bindal
    Description: This method is used to fetch all relevant data using a Lead and Quote record to prepopulate 
                 fields in the Individual Booking Form. It retrieves Quote details along with related Plot and Lead 
                 information, ensuring seamless data population for the booking process.
    @params: Id recordId - The unique identifier of the Quote__c record.
    @return: getRecordDataWrapper - A wrapper object containing the retrieved Quote, Lead, and Plot details.
    **********
*/
    @AuraEnabled(cacheable=true)
    public static getRecordDataWrapper getRecordData(String recordId){
        // Wrapper object to store the response
        getRecordDataWrapper responseObj= new getRecordDataWrapper();
        LightningResponse response =new LightningResponse();
        List<Quote__c> listOfOpportunity = new List<Quote__c>();
        try{
            response.isSuccess = true; 
            // Check if the provided recordId is not empty or blank
            if(String.isNotEmpty(recordId) || String.isNotBlank(recordId)){
                // Query Quote__c record based on the given Id
                listOfOpportunity = [SELECT Id,Name,Plot__c,Plot__r.Plot_Facing__c, Plot__r.Name, Plot__r.Plot_Size__c, Plot__r.Plot_Price__c, Plot__r.Phase__r.Name, Plot__r.Unit_Code__c,
                                        Lead__c,Lead__r.Id, Lead__r.Name,Lead__r.Email, Lead__r.Phone,Plot__r.Phase__c,Total_Sale_Value__c,Plot__r.Phase__r.Project__r.Name
                                        FROM Quote__c WHERE Id =:recordId];
                if(!(listOfOpportunity.isEmpty())){
                    responseObj.listOfOpportunityRecords = listOfOpportunity;
                    response.body = 'success';
                }
            }else{
                // Handle case where the recordId is missing
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

    /*
    **********
    Method Name : saveFormData
    Author: Dolly Bindal
    Description: This method is used to insert data for an individual booking. It processes and saves Account, 
                 Contact, Opportunity, Quote, and Unit records based on the provided booking form data. 
                 The method ensures data integrity and linkage between records, facilitating seamless individual 
                 registration and booking.
    Process Flow:
    1. Creates or updates an Account record
    2. Creates or updates a Contact record and associates it with the created Account.
    3. Creates an Opportunity record linked to the Account and Contact.
    4. The Contact gets tagged to the Opportunity as the primary contact.
    5. Updates the Quote__c record to associate it with the newly created Opportunity.
    6. Updates the Unit__c (Plot) record, marking it as "Blocked" and associating it with the Contact.

    @params: 
        - String bookingFormData: JSON string containing form details such as Account, Contact, and Opportunity information.
        - String quoteId: The unique identifier of the Quote__c record.

    @return: 
        - LightningResponse: A response object indicating success or failure along with the Account ID if the process is successful.
    **********
*/
    @AuraEnabled
    public static LightningResponse saveFormData(String bookingFormData,String quoteId){
        LightningResponse response =new LightningResponse();
        SavePoint sp = Database.setSavepoint(); 
        try {
                response.isSuccess = true;
                bookingFormData bookingFormDataObj =(bookingFormData) System.JSON.deserialize(bookingFormData, bookingFormData.class);
                if(String.isNotBlank(quoteId)){
                    Account accObj=new Account();
                    accObj.Id = String.isNotBlank(bookingFormDataObj.accountId) ? bookingFormDataObj.accountId: null;
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
                    system.debug('bookingFormDataObj.quoteI11111111111d'+quoteId);
                    system.debug('bookingFormDataObj.quoteI11111111111d'+accObj.id);

                    Contact newContact = new Contact();
                    newContact.Id = String.isNotBlank(bookingFormDataObj.contactId) ? bookingFormDataObj.contactId : null;
                    newContact.LastName = String.isNotBlank(bookingFormDataObj.quoteContactName) ? bookingFormDataObj.quoteContactName : null;
                    newContact.PAN_Card__c = String.isNotBlank(bookingFormDataObj.quoteContactPan) ? bookingFormDataObj.quoteContactPan : null;
                    newContact.Aadhaar_Card__c = String.isNotBlank(bookingFormDataObj.quoteContactAadhaar) ? bookingFormDataObj.quoteContactAadhaar : null;
                    newContact.Date_Of_Birth__c = String.isNotBlank(bookingFormDataObj.quoteContactDOB) ? Date.valueOf(bookingFormDataObj.quoteContactDOB) : null;
                    newContact.Email = String.isNotBlank(bookingFormDataObj.quoteContactEmailId) ? bookingFormDataObj.quoteContactEmailId : null;
                    newContact.Contact_No_91__c = String.isNotBlank(bookingFormDataObj.quoteContactNo) ? bookingFormDataObj.quoteContactNo : null;
                    newContact.Phone = String.isNotBlank(bookingFormDataObj.quoteContactNo) ? bookingFormDataObj.quoteContactNo : null;
                    newContact.AccountId = accObj.Id;
                    upsert newContact;
                    
                    system.debug('newContact------------>'+newContact.id);
                    system.debug('bookingFormDataObj.quoteId'+quoteId);

                    Opportunity opp = new Opportunity();
                    opp.Name=bookingFormDataObj.quoteunitPlotName + '_' + bookingFormDataObj.quoteContactName;
                    opp.First_Booking_Amount__c=String.isNotBlank(bookingFormDataObj.opportunityBookingAmount) ? Decimal.valueOf(bookingFormDataObj.opportunityBookingAmount) : null;
                    opp.AccountId=accObj.Id;
                    opp.StageName='Blocked';
                    opp.CloseDate=Date.today();
                    opp.Unit__c=String.isNotBlank(bookingFormDataObj.quotePlot) ? bookingFormDataObj.quotePlot : null;
                    opp.ContactId = newContact.id;
                    opp.Contact__c = newContact.id;
                    //opp.OwnerId = getCRMUserId();
                    opp.Type_of_Booking__c ='Retail';
                    opp.Sale_Value_Amount__c=String.isNotBlank(bookingFormDataObj.saleValueAmount) ? Decimal.valueOf(bookingFormDataObj.saleValueAmount) : null;
                    opp.Lead_Quote__c=quoteId;
                    opp.Ownership_Type__c='Individual Registration';
                    opp.Lead__c=String.isNotBlank(bookingFormDataObj.leadId) ? bookingFormDataObj.leadId : null;
                    insert opp;

                    Quote__c quoteObj=new Quote__c();
                    quoteObj.Id = quoteId;
                    quoteObj.Opportunity__c = opp.Id;
                    update quoteObj;

                    Unit__c plot=new Unit__c();
                    plot.id=String.isNotBlank(bookingFormDataObj.quotePlot) ? bookingFormDataObj.quotePlot : null;
                    plot.Status__c='Blocked';
                    plot.Contact__c=newContact.id;
                    update plot;

                //     Lead leadObj=new Lead();
                //     leadObj.Id=bookingFormDataObj.leadId;
                //    // leadObj.Status='Booked';
                //     update leadObj;
                    
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

    /*
    **********
    Method Name : saveBulkFormData
    Author:  Dolly Bindal
    Description: This method is used to handle bulk bookings efficiently. It is used to create multiple 
                 Opportunities for different plots associated with contacts.
    Process Flow:      
    1. Creates or updates an Account.
    2. Creates multiple Contact records and associates them with the Account.
    3. Creates multiple Opportunities against each Contact.
    4. Associates a Quote record with each Opportunity.

    @params: 
        - String bookingFormData: JSON string containing bulk booking details, including Account, 
                                  Co-Applicants, and their associated plots.

    @return: 
        - LightningResponse: A response object indicating success or failure along with the Account ID if the process is successful.
    **********
*/
    @AuraEnabled
    public static LightningResponse saveBulkFormData(String bookingFormData){
        LightningResponse response =new LightningResponse();
        SavePoint sp = Database.setSavepoint(); 
        try {
            response.isSuccess = true;
            bookingFormData bookingFormDataObj =(bookingFormData) System.JSON.deserialize(bookingFormData, bookingFormData.class);
                
            if(String.isNotBlank(bookingFormDataObj.accountName) && bookingFormDataObj.listOfCoApplicant != null && !bookingFormDataObj.listOfCoApplicant.isEmpty()){
                // Upserting Account object
                Account accObj=new Account();
                accObj.Id = String.isNotBlank(bookingFormDataObj.accountId) ? bookingFormDataObj.accountId: null;
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
                    
                // Prepare lists
                List<Contact> contactsToInsert = new List<Contact>();
                List<Unit__c> plotsToUpdate = new List<Unit__c>();
                List<Opportunity> opportunitiesToInsert = new List<Opportunity>();

                // Map to store contactName -> Contact
                Map<String, Contact> contactMap = new Map<String, Contact>();

                // Create Contacts (No Nested Loops)
                for (ListOfCoApplicant coApplicant : bookingFormDataObj.listOfCoApplicant) {
                    Contact newContact = new Contact(
                        Id = String.isNotBlank(coApplicant.contactId) ? coApplicant.contactId: null,
                        LastName = coApplicant.contactName,
                        PAN_Card__c = coApplicant.contactPan,
                        Aadhaar_Card__c = coApplicant.contactAadhaar,
                        Date_Of_Birth__c = String.isNotBlank(coApplicant.contactDOB) ? Date.valueOf(coApplicant.contactDOB) : null,
                        Email = coApplicant.contactEmail,
                        Contact_No_91__c = coApplicant.contactPhone,
                        Phone = coApplicant.contactPhone,
                        AccountId = accObj.Id,
                        Primary_Payer__c = Boolean.valueOf(coApplicant.isPrimaryPayer)
                    );

                    contactsToInsert.add(newContact);
                    contactMap.put(coApplicant.contactName, newContact);
                }

                // Bulk insert Contacts
                if (!contactsToInsert.isEmpty()) {
                    upsert contactsToInsert;

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
                                Contact__c = contactId,
                                Status__c='Blocked'
                            ));

                            // Create Opportunity
                            opportunitiesToInsert.add(new Opportunity(
                                Name = plot.plotunitsname + '_' + coApplicant.contactName,
                                First_Booking_Amount__c = Decimal.valueOf(plot.unitOppAmount),
                                AccountId = accObj.Id,
                                StageName = 'Blocked',
                                CloseDate = Date.today(),
                                Unit__c = plot.plotName,
                                Type_of_Booking__c = bookingFormDataObj.typeOfBooking,
                                ContactId = contactId, // Direct assignment (No Double Loop!)
                                Bulk_Booking__c=true,
                                Contact__c = contactId,
                                Sale_Value_Amount__c=String.isNotBlank(plot.unitPlotPrize) ? Decimal.valueOf(plot.unitPlotPrize): null
                                //OwnerId=getCRMUserId()
                            ));
                        }
                    }
                }

                // Bulk update plots with Contact Ids
                if (!plotsToUpdate.isEmpty()) {
                    System.debug('plotsToUpdatebeforee--->'+plotsToUpdate);
                    update plotsToUpdate;
                    System.debug('plotsToUpdateafterrrrrrr--->'+plotsToUpdate);
                }

                // Bulk insert Opportunities
                if (!opportunitiesToInsert.isEmpty()) {
                    insert opportunitiesToInsert;
                    // Insert Quotes in One Pass
                    List<Quote__c> quotesToInsert = new List<Quote__c>();
                    for (Opportunity opp : opportunitiesToInsert) {
                        quotesToInsert.add(new Quote__c(
                            //Quote_Name__c = opp.Name,
                            Opportunity__c = opp.Id,
                             Status__c='Accepted',
                             Base_Price_Per_Sq_Yard__c = opp.Sale_Value_Amount__c
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

    /***********
    Method Name: saveJointVenture
    Author:  Dolly Bindal
    Description: This method is used for joint registration against opportunity. It adds multiple Contacts 
                  under a given Opportunity and marks one of them as the primary contact.

    Process Flow:
    1. Creates or updates Contact records and associates them with the provided Account.
    2. Retrieves existing OpportunityContactRole (OCR) records for the Opportunity.
    3. Updates existing OCRs or creates new ones for each Contact.
    4. Marks the primary payer among the co-applicants.

    @params: 
        - String bookingFormData: JSON string containing co-applicant details.
        - String opportunityId: ID of the Opportunity to associate contacts with.
        - String accountId: ID of the Account the contacts belong to.

    @return: 
        - LightningResponse: A response object indicating success or failure.
    ***********/
    @AuraEnabled
    public static LightningResponse saveJointVenture(String bookingFormData, String opportunityId, String accountId) {
        LightningResponse response = new LightningResponse();
        SavePoint sp = Database.setSavepoint();

        try {
            response.isSuccess = true;
            bookingFormData bookingFormDataObj = (bookingFormData) System.JSON.deserialize(bookingFormData, bookingFormData.class);

            if (bookingFormDataObj.listOfCoApplicant != null && !bookingFormDataObj.listOfCoApplicant.isEmpty()) {
                List<Contact> contactsToUpsert = new List<Contact>();
                Map<String, Contact> contactMap = new Map<String, Contact>();

                // Prepare Contact records for upsert
                for (ListOfCoApplicant coApplicant : bookingFormDataObj.listOfCoApplicant) {
                    Contact newContact = new Contact(
                        Id = String.isNotBlank(coApplicant.contactId) ? coApplicant.contactId : null,
                        LastName = coApplicant.contactName,
                        PAN_Card__c = coApplicant.contactPan,
                        Aadhaar_Card__c = coApplicant.contactAadhaar,
                        Date_Of_Birth__c = String.isNotBlank(coApplicant.contactDOB) ? Date.valueOf(coApplicant.contactDOB) : null,
                        Email = coApplicant.contactEmail,
                        Phone = coApplicant.contactPhone,
                        AccountId = accountId,
                        Primary_Payer__c = Boolean.valueOf(coApplicant.isPrimaryPayer)
                    );
                    contactsToUpsert.add(newContact);
                    contactMap.put(coApplicant.contactId, newContact); // Store for reference
                }

                // **Upsert Contacts**
                if (!contactsToUpsert.isEmpty()) {
                    upsert contactsToUpsert;
                        System.debug('contactsToUpsert'+contactsToUpsert);
                }

                // **Update contactMap with correct Contact IDs after upsert**
                for (Contact c : contactsToUpsert) {
                    if (c.Id != null) {
                        contactMap.put(c.Id, c); // Ensure map has correct IDs
                    }
                }

                // **Query existing OCRs for the given Opportunity and Contacts**
                Map<String, OpportunityContactRole> existingOCRs = new Map<String, OpportunityContactRole>();
                for (OpportunityContactRole ocr : [
                    SELECT Id, ContactId, OpportunityId, Role, IsPrimary
                    FROM OpportunityContactRole 
                    WHERE OpportunityId = :opportunityId 
                    AND ContactId IN :contactMap.values()
                ]) {
                    existingOCRs.put(ocr.ContactId, ocr); // Map ContactId to OCR
                }

                List<OpportunityContactRole> oppContactRolesToUpsert = new List<OpportunityContactRole>();

                // **Prepare OpportunityContactRole records for upsert**
                for (ListOfCoApplicant coApplicant : bookingFormDataObj.listOfCoApplicant) {
                    Contact c = contactMap.get(coApplicant.contactId);
                    if (c != null && c.Id != null) { // Ensure Contact ID exists
                        if (existingOCRs.containsKey(c.Id)) {
                            // **Update existing OCR**
                            OpportunityContactRole existingOCR = existingOCRs.get(c.Id);
                            existingOCR.Role = 'Co-Applicant';
                            existingOCR.IsPrimary = Boolean.valueOf(coApplicant.isPrimaryPayer);
                            oppContactRolesToUpsert.add(existingOCR);
                        } else {
                            // **Create new OCR**
                            OpportunityContactRole newOCR = new OpportunityContactRole(
                                OpportunityId = opportunityId,
                                ContactId = c.Id,
                                Role = 'Co-Applicant',
                                IsPrimary = Boolean.valueOf(coApplicant.isPrimaryPayer)
                            );
                            oppContactRolesToUpsert.add(newOCR);
                        }
                    }
                }

                // **Upsert OCR records**
                if (!oppContactRolesToUpsert.isEmpty()) {
                    upsert oppContactRolesToUpsert;
                    System.debug('oppContactRolesToUpsert'+oppContactRolesToUpsert);
                }

                Opportunity opportunityObj=new Opportunity();
                opportunityObj.Id = opportunityId;
                opportunityObj.Ownership_Type__c='Joint Registration';
                update opportunityObj;
            }
        } catch (Exception e) {
        Database.rollback(sp);
        response.isSuccess = false;
        // response.errorMessage = e.getMessage();
        System.debug('Error in saveJointVenture: ' + e.getMessage());
        }

        return response;
    }

    /***********
    Method Name: getAccountDetails
    Author:  Dolly Bindal
    Description: This method retrieves account details for a given Account ID. 
    @params: 
        - Id accountId: The ID of the Account to retrieve.
    @return: 
        - Account: The Account record matching the given ID.
    ***********/
    @AuraEnabled(cacheable=true)
        public static Account getAccountDetails(Id accountId) {
            try {
                return [
                    SELECT Id, Name, Phone, Email__c, BillingStreet, BillingCity, BillingCountry, 
                            BillingState, BillingPostalCode, ShippingStreet, ShippingCity, 
                            ShippingCountry, ShippingState, ShippingPostalCode, 
                            Same_As_Permanent_Address__c
                    FROM Account
                    WHERE Id = :accountId
                    LIMIT 1
                ];
            } catch (Exception e) {
                System.debug('Error in getAccountDetails: ' + e.getMessage());
                throw new AuraHandledException('Error fetching account details: ' + e.getMessage());
        }
    }

     /***********
    Method Name: getContactDetails
    Author:  Dolly Bindal
    Description: This method retrieves contact details for prepopulating in the individual booking form. 
    @params: 
        - contactId: The ID of the Contact to fetch details for individual booking form.
    @return: 
        - contact: The contact record matching the given ID.
    ***********/
    @AuraEnabled(cacheable=true)
    public static Contact getContactDetails(Id contactId) {
        try {
            return [
                SELECT Id, LastName, Aadhaar_Card__c, Email, PAN_Card__c, Date_Of_Birth__c, Phone
                FROM Contact
                WHERE Id = :contactId
                LIMIT 1
            ];
        }catch (Exception e) {
            System.debug('Error in getContactDetails: ' + e.getMessage());
            throw new AuraHandledException('Error fetching contact details: ' + e.getMessage());
        }
    }

  /***********
    Method Name: getContactsByAccountId
    Author:  Dolly Bindal
    Description: Retrieves a list of Contacts associated with a given Account ID
    @params: accountId The ID of the Account to fetch associated Contacts.
    @return: List of Contact records linked to the provided Account ID.
    ***********/
    @AuraEnabled(cacheable=true)
    public static List<Contact> getContactsByAccountId(Id accountId) {
        try{
            return [
                SELECT Id, LastName, Email, Phone 
                FROM Contact
                WHERE AccountId = :accountId
            ];
        }catch (Exception e) {
            System.debug('Error in getContactDetails: ' + e.getMessage());
            throw new AuraHandledException('Error fetching contact details: ' + e.getMessage());
        }
    }

    /***********
    Method Name: getPlots
    Author:  Dolly Bindal
    Description: Retrieves a list of available plots (Units) against contact.
    @return: List of Unit__c records that have the status 'Available'.
    ***********/
    @AuraEnabled(cacheable=true)
        public static List<Unit__c> getPlots() {
        try{
            return [
                SELECT Id, Name, Status__c 
                FROM Unit__c
                WHERE Status__c = 'Available'
            ];
        }catch (Exception e) {
            System.debug('Error in getContactDetails: ' + e.getMessage());
            throw new AuraHandledException('Error fetching plot details: ' + e.getMessage());
        }
    }

    /***********
    Method Name: getPlotDetails
    Author:  Dolly Bindal
    Description: Retrieves details of a specific plot based on its record ID.
    @param recordId The ID of the Unit__c record (plot) to fetch details for.
    @return: A Unit__c record with the requested details.
    ***********/
    @AuraEnabled(cacheable=true) 
        public static Unit__c getPlotDetails(String recordId) {
            try {
                return [SELECT Id, Name, Plot_Facing__c, Plot_Price__c, Plot_Size__c, Unit_Code__c,Phase__c, Phase__r.Name
                        FROM Unit__c WHERE Id = :recordId LIMIT 1];
            } catch (Exception e) {
                throw new AuraHandledException('Error fetching Plot details: ' + e.getMessage());
            }
    }

    /***********
    Method Name: getProjects
    Author:  Dolly Bindal
    Description: Retrieves a list of active projects
    @return: List of active Project__c records.
    ***********/
    @AuraEnabled(cacheable=true) 
        public static List<Project__c> getProjects() {
            try {
                return [select id,Name,Active__c from Project__c WHERE Active__c = true];
            } catch (Exception e) {
                throw new AuraHandledException('Error fetching Plot details: ' + e.getMessage());
            }
    }
    
    /***********
    Method Name: getPhases
    Author:  Dolly Bindal
    Description: Retrieves a list of phases associated with a given project.
    @param projectId The ID of the Project__c record to fetch related Phases.
    @return: A Unit__c record with the requested details.
    ***********/
    @AuraEnabled(cacheable=true) 
        public static List<Phase__c> getPhases(string projectId) {
            try {
                return [select id,Name,Project__c from Phase__c where Project__c = :projectId ];
            } catch (Exception e) {
                throw new AuraHandledException('Error fetching Plot details: ' + e.getMessage());
            }
    }

    /**
 * @description Wrapper class representing a Plot in the booking form.
 *              This stores information related to individual plots selected during the booking process.
 */
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

    /**
 * @description Wrapper class representing a contact in the booking form.
 *              This stores details of additional applicants for a booking.
 */
    public class ListOfCoApplicant {
        public String contactId;
        public String contactName;
        public String contactEmail;
        public String contactPhone;
        public String contactAadhaar;
        public String contactPan;
        public String contactDOB;
        public String isPrimaryPayer;
        public List<ListOfPlot> plots;
    }

    /**
 * @description Wrapper class representing booking form data.
 *              This stores all necessary details required to process a booking.
 */
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
        public String quoteunitPlotFacing;
        public String quoteunitPlotSize;
        public String quoteunitPlotPrize;
        public String quoteunitPlotUnitCode;
        public String quoteunitPlotName;
        public String quoteunitPlotPhase;
        public String leadId;
        public String saleValueAmount;
        public String contactId;
        public String projectId;
        public String phaseId;
        public List<ListOfCoApplicant> listOfCoApplicant;        
    }

    /**
 * @description Wrapper class to store retrieved records from the system.
 *              This class is used to send multiple record types in a single response.
 */
    public class getRecordDataWrapper{
        @AuraEnabled
        public List<Quote__c> listOfOpportunityRecords{get; set;}
        @AuraEnabled
        public List<Opportunity> listOfOpportunityR{get; set;}
        @AuraEnabled
        public List<Account> listOfAccountRecords{get; set;}
        @AuraEnabled
        public List<Contact> listOfApplicantRecords{get; set;}
        @AuraEnabled
        public List<Unit__c> listOfPlotRecords{get; set;}
        @AuraEnabled
        public LightningResponse response{get; set;}
    }

    /**
 * @description Standard response wrapper for handling API responses.
 *              This class is used to send success status and additional response details.
 */
    public class LightningResponse {
        @AuraEnabled
        public Boolean isSuccess { get; set; }
        @AuraEnabled
        public String body { get; set; }
        @AuraEnabled
        public String accountId { get; set; }
    }
}