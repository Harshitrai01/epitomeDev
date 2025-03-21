/**********
Apex Class Name : RetailAosController
Apex Test Class Name: 
Created Date: February 20, 2025
@description : This class is a controller for a Visualforce page or Lightning component. It fetches and processes data related to an Opportunity record, including associated contacts, payments, and other details. The class also performs various calculations and formatting tasks, such as converting amounts to words, masking Aadhaar numbers, calculating ages, and converting plot sizes from square feet to square meters.
@author : Varun Rawal
Modify By : 
Modify Date: 
**********/

public class RetailAosController {
    // Public properties to store data for the Visualforce page or Lightning component
    public Opportunity opportunityRecord { get; set; }
    public String currentDate { get; set; }
    public Integer calculatedAge { get; set; }
    public String maskedAadhaar { get; set; }
    public List<ContactDetails> contactDetailsList { get; set; }
    public String saleAmountInWords { get; set; }
    public String balanceAmountInWords { get; set; }
    public String paidAmountInWords { get; set; }
    public List<PaymentDetails> approvedPayments { get; set; }
    public Double plotSizeInSqM { get; set; } // To store plot size in square meters
    
    /*
**********
Method Name : RetailAosController (Constructor)
author: Varun Rawal
description: Initializes the controller and fetches data related to the Opportunity record.
@params: 
- stdController: The standard controller provided by the Visualforce page.
@return: None
**********
*/
    public RetailAosController(ApexPages.StandardController stdController) {
        try {
            // Retrieve the Opportunity ID from the page parameters
            Id opportunityId = ApexPages.currentPage().getParameters().get('Id');
            System.debug('OpportunityId --> ' + opportunityId);
            Boolean isOpp=true;
            if (opportunityId != null) {
                try {
                    // Fetch the Opportunity record and related fields
                    opportunityRecord = [SELECT Id, AccountId, Account.Name, Contact__r.Salutation, Account.BillingStreet, 
                                         Account.BillingCity, Account.BillingState, Account.BillingCountry, Account.BillingPostalCode,
                                         Contact__r.Aadhaar_Card__c, Contact__r.Date_Of_Birth__c, Unit__r.Name, Unit__r.Plot_Size__c,
                                         Unit__r.North__c, Unit__r.South__c,Unit__r.West__c, Unit__r.East__c,
                                         Unit__r.Plot_Price__c, Sale_Value_Amount__c, Collected_Amount__c, Outstanding_Amount__c,Unit__r.Base_Price_per_Sq_Ft__c
                                         FROM Opportunity WHERE Id = :opportunityId LIMIT 1];
                } catch (Exception e) {
                    // Handle errors while fetching the Opportunity record
                    System.debug('Error fetching Opportunity: ' + e.getMessage());
                    isOpp=false;
                }
                if(isOpp){
                    // Convert sale, balance, and paid amounts to words
                    saleAmountInWords = NumberToCharacter.getNumberTOWordConvertion(opportunityRecord.Sale_Value_Amount__c);
                    balanceAmountInWords = NumberToCharacter.getNumberTOWordConvertion(opportunityRecord.Outstanding_Amount__c);
                    paidAmountInWords = NumberToCharacter.getNumberTOWordConvertion(opportunityRecord.Collected_Amount__c);
                    
                    // Extract plot size in square feet and convert to square meters
                    if (opportunityRecord.Unit__r.Plot_Size__c != null) {
                        plotSizeInSqM = convertPlotSizeToSqM(opportunityRecord.Unit__r.Plot_Size__c);
                    }
                    
                    // Calculate age and mask Aadhaar number if contact details are available
                    if (opportunityRecord.Contact__r != null) {
                        if (opportunityRecord.Contact__r.Date_Of_Birth__c != null) {
                            calculatedAge = calculateAge(opportunityRecord.Contact__r.Date_Of_Birth__c);
                        }
                        if (opportunityRecord.Contact__r.Aadhaar_Card__c != null) {
                            maskedAadhaar = maskAadhaarNumber(opportunityRecord.Contact__r.Aadhaar_Card__c);
                        }
                    }
                    
                    // Fetch related contacts via OpportunityContactRole
                    List<OpportunityContactRole> oppConrole = [SELECT Id, OpportunityId, ContactId FROM OpportunityContactRole WHERE OpportunityId = :opportunityId];
                    List<Id> contactIds = new List<Id>();
                    for (OpportunityContactRole ocr : oppConrole) {
                        if (ocr.ContactId != null) {
                            contactIds.add(ocr.ContactId);
                        }
                    }
                    
                    // Initialize the list to store contact details
                    contactDetailsList = new List<ContactDetails>();
                    try {
                        // Fetch contact details for the related contacts
                        List<Contact> relatedContacts = [SELECT Id, FirstName, Salutation, LastName, Date_Of_Birth__c, Title, Aadhaar_Card__c, 
                                                         Permanent_Address__Street__s, Permanent_Address__City__s, Permanent_Address__StateCode__s, 
                                                         Permanent_Address__CountryCode__s, Permanent_Address__PostalCode__s
                                                         FROM Contact WHERE Id IN :contactIds];
                        
                        for (Contact contact : relatedContacts) {
                            ContactDetails contactDetail = new ContactDetails();
                            contactDetail.name = (contact.FirstName != null ? contact.FirstName.toUpperCase() : '') + ' ' + 
                                (contact.LastName != null ? contact.LastName.toUpperCase() : '');
                            contactDetail.dateOfBirth = contact.Date_Of_Birth__c;
                            contactDetail.salutation = contact.Salutation;
                            contactDetail.occupation = contact.Title;
                            contactDetail.address = (contact.Permanent_Address__Street__s != null ? contact.Permanent_Address__Street__s + ', ' : '') + 
                                (contact.Permanent_Address__City__s != null ? contact.Permanent_Address__City__s + ', ' : '') + 
                                (contact.Permanent_Address__StateCode__s != null ? contact.Permanent_Address__StateCode__s + ', ' : '') + 
                                (contact.Permanent_Address__CountryCode__s != null ? contact.Permanent_Address__CountryCode__s + ', ' : '') + 
                                (contact.Permanent_Address__PostalCode__s != null ? contact.Permanent_Address__PostalCode__s : '');
                            
                            if (contact.Date_Of_Birth__c != null) {
                                contactDetail.age = calculateAge(contact.Date_Of_Birth__c);
                            }
                            if (contact.Aadhaar_Card__c != null) {
                                contactDetail.maskedAadhaar = maskAadhaarNumber(contact.Aadhaar_Card__c);
                            }
                            contactDetailsList.add(contactDetail);
                        }
                    } catch (Exception e) {
                        // Handle errors while fetching contact details
                        System.debug('Error fetching Contacts: ' + e.getMessage());
                    }
                    
                    // Fetch approved payments related to the Opportunity
                    approvedPayments = new List<PaymentDetails>();
                    try {
                        List<Payment__c> payment = [SELECT Id, Payment_Amount__c, Payment_Created_Date__c, Payment_Mode__c, Merchant_Transaction_Id__c, Approval_Status__c
                                                    FROM Payment__c WHERE Opportunity__c = :opportunityRecord.Id AND Approval_Status__c = 'Approved'];
                        
                        for (Payment__c pay : payment) {
                            PaymentDetails paymentDetail = new PaymentDetails();
                            paymentDetail.amountInWords = NumberToCharacter.getNumberTOWordConvertion(pay.Payment_Amount__c);
                            paymentDetail.paymentDate = pay.Payment_Created_Date__c != null ? pay.Payment_Created_Date__c.date() : null;
                            paymentDetail.paymentMode = pay.Payment_Mode__c;
                            paymentDetail.transactionId = pay.Merchant_Transaction_Id__c;
                            approvedPayments.add(paymentDetail);
                        }
                    } catch (Exception e) {
                        // Handle errors while fetching payment details
                        System.debug('Error fetching Payments: ' + e.getMessage());
                    }
                }
            }
        } catch (Exception e) {
            // Handle any unexpected errors in the controller
            System.debug('Error in RetailAosController: ' + e.getMessage());
        }
        
        // Set the current date in a formatted string
        currentDate = formatDate(Date.today());
    }
    
    /*
**********
Method Name : calculateAge
author: Varun Rawal
description: Calculates the age based on the provided birth date.
@params: 
- birthDate: The date of birth.
@return: The calculated age as an integer.
**********
*/
    public Integer calculateAge(Date birthDate) {
        Date today = Date.today();
        Integer age = today.year() - birthDate.year();
        if (today.month() < birthDate.month() || (today.month() == birthDate.month() && today.day() < birthDate.day())) {
            age--;
        }
        return age;
    }
    
    /*
**********
Method Name : maskAadhaarNumber
author: Varun Rawal
description: Masks the Aadhaar number for privacy, showing only the last 4 digits.
@params: 
- aadhaar: The Aadhaar number to mask.
@return: The masked Aadhaar number (e.g., "XXXX-XXXX-1234").
**********
*/
    public String maskAadhaarNumber(String aadhaar) {
        return (aadhaar != null && aadhaar.length() >= 4) ? 'XXXX-XXXX-' + aadhaar.substring(aadhaar.length() - 4) : 'Invalid Aadhaar';
    }
    
    /*
**********
Method Name : formatDate
author: Varun Rawal
description: Formats a date into a readable string (e.g., "25 of December, 2023").
@params: 
- inputDate: The date to format.
@return: The formatted date string.
**********
*/
    public String formatDate(Date inputDate) {
        String day = String.valueOf(inputDate.day());
        String month = getMonthName(inputDate.month());
        String year = String.valueOf(inputDate.year());
        return day + ' of ' + month + ', ' + year;
    }
    
    /*
**********
Method Name : getMonthName
author: Varun Rawal
description: Returns the name of the month based on the month number.
@params: 
- monthNumber: The month number (1-12).
@return: The name of the month (e.g., "January").
**********
*/
    public String getMonthName(Integer monthNumber) {
        String[] months = new String[]{
            'January', 'February', 'March', 'April', 'May', 'June', 
                'July', 'August', 'September', 'October', 'November', 'December'
                };
                    if (monthNumber >= 1 && monthNumber <= 12) {
                        return months[monthNumber - 1];
                    } else {
                        return 'Invalid Month';
                    }
    }
    
    /*
**********
Method Name : convertPlotSizeToSqM
author: Varun Rawal
description: Converts the plot size from square feet to square meters.
@params: 
- plotSize: The plot size in square feet.
@return: The plot size in square meters.
**********
*/
    public Double convertPlotSizeToSqM(Decimal plotSize) {
        if (plotSize != null) {
            // Extract numeric value (e.g., 190 from "190 sq ft")
            Decimal numberString = plotSize;
            system.debug('numberString-->' + numberString);
            if (numberString != null) {
                Double sizeInSqFt = Double.valueOf(numberString);
                return sizeInSqFt * 0.836127; // Convert to square meters
            }
        }
        return 0.0; // Default to 0 if no valid value is found
    }
    
    /*
**********
Class Name : ContactDetails
author: Varun Rawal
description: Inner class to store contact details.
**********
*/
    public class ContactDetails {
        public String name { get; set; }
        public String salutation { get; set; }
        public Date dateOfBirth { get; set; }
        public Integer age { get; set; }
        public String occupation { get; set; }
        public String address { get; set; }
        public String maskedAadhaar { get; set; }
    }
    
    /*
**********
Class Name : PaymentDetails
author: Varun Rawal
description: Inner class to store payment details.
**********
*/
    public class PaymentDetails {
        public String amountInWords { get; set; }
        public Date paymentDate { get; set; }
        public String paymentMode { get; set; }
        public String transactionId { get; set; }
    }
}