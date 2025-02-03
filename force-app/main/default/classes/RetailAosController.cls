public class RetailAosController {
    public Opportunity opportunityRecord { get; set; }
    public String currentDate { get; set; }
    public Integer calculatedAge { get; set; }
    public String maskedAadhaar { get; set; }
    public List<ContactDetails> contactDetailsList { get; set; }
    public Unit__c plotRecord { get; set; }
    public String saleAmountInWords { get; set; }
    public String balanceAmountInWords { get; set; }
    public String paidAmountInWords { get; set; }
    public List<PaymentDetails> approvedPayments { get; set; }

    public RetailAosController() {
        try {
            Id opportunityId = ApexPages.currentPage().getParameters().get('Id');
            System.debug('OpportunityId --> ' + opportunityId);

            if (opportunityId != null) {
                try {
                    opportunityRecord = [SELECT Id, AccountId, Account.Name, Contact__r.Salutation, Account.BillingStreet, 
                                         Account.BillingCity, Account.BillingState, Account.BillingCountry, Account.BillingPostalCode,
                                         Contact__r.Aadhaar_Card__c, Contact__r.Date_Of_Birth__c, Unit__r.Name, Unit__r.Plot_Size__c, 
                                         Unit__r.Plot_Price__c, Sale_Value_Amount__c, Collected_Amount__c, Outstanding_Amount__c
                                         FROM Opportunity WHERE Id = :opportunityId LIMIT 1];
                } catch (Exception e) {
                    System.debug('Error fetching Opportunity: ' + e.getMessage());
                    return;
                }
                
                saleAmountInWords = NumberToCharacter.getNumberTOWordConvertion(opportunityRecord.Sale_Value_Amount__c);
                balanceAmountInWords = NumberToCharacter.getNumberTOWordConvertion(opportunityRecord.Outstanding_Amount__c);
                paidAmountInWords = NumberToCharacter.getNumberTOWordConvertion(opportunityRecord.Collected_Amount__c);

                if (opportunityRecord.Contact__r != null) {
                    if (opportunityRecord.Contact__r.Date_Of_Birth__c != null) {
                        calculatedAge = calculateAge(opportunityRecord.Contact__r.Date_Of_Birth__c);
                    }
                    if (opportunityRecord.Contact__r.Aadhaar_Card__c != null) {
                        maskedAadhaar = maskAadhaarNumber(opportunityRecord.Contact__r.Aadhaar_Card__c);
                    }
                }

                contactDetailsList = new List<ContactDetails>();
                try {
                    List<Contact> relatedContacts = [SELECT Id, FirstName, Salutation, LastName, Date_Of_Birth__c, Title, Aadhaar_Card__c, 
                                                     Permanent_Address__Street__s, Permanent_Address__City__s, Permanent_Address__StateCode__s, 
                                                     Permanent_Address__CountryCode__s, Permanent_Address__PostalCode__s
                                                     FROM Contact WHERE AccountId = :opportunityRecord.AccountId];
                    
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
                    System.debug('Error fetching Contacts: ' + e.getMessage());
                }

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
                    System.debug('Error fetching Payments: ' + e.getMessage());
                }
            }
        } catch (Exception e) {
            System.debug('Error in RetailAosController: ' + e.getMessage());
        }

        currentDate = formatDate(Date.today());
    }

    public Integer calculateAge(Date birthDate) {
        Date today = Date.today();
        Integer age = today.year() - birthDate.year();
        if (today.month() < birthDate.month() || (today.month() == birthDate.month() && today.day() < birthDate.day())) {
            age--;
        }
        return age;
    }

    public String maskAadhaarNumber(String aadhaar) {
        return (aadhaar != null && aadhaar.length() >= 4) ? 'XXXX-XXXX-' + aadhaar.substring(aadhaar.length() - 4) : 'Invalid Aadhaar';
    }
    
     public String formatDate(Date inputDate) {
        // Get the day, month, and year from the date
        String day = String.valueOf(inputDate.day());
        String month = getMonthName(inputDate.month()); // Convert month number to month name
        String year = String.valueOf(inputDate.year());
        
        // Construct the formatted date string
        return day + ' of ' + month + ', ' + year;
    }
    
    // Method to convert month number to month name
    public String getMonthName(Integer monthNumber) {
        // Array of month names
        String[] months = new String[]{
            'January', 'February', 'March', 'April', 'May', 'June', 
                'July', 'August', 'September', 'October', 'November', 'December'
                };
                    
                    // Return the corresponding month name (subtract 1 because array is 0-based)
                    if (monthNumber >= 1 && monthNumber <= 12) {
                        return months[monthNumber - 1];
                    } else {
                        return 'Invalid Month'; // Handle invalid month numbers
                    }
    }

    public class ContactDetails {
        public String name { get; set; }
        public String salutation { get; set; }
        public Date dateOfBirth { get; set; }
        public Integer age { get; set; }
        public String occupation { get; set; }
        public String address { get; set; }
        public String maskedAadhaar { get; set; }
    }

    public class PaymentDetails {
        public String amountInWords { get; set; }
        public Date paymentDate { get; set; }
        public String paymentMode { get; set; }
        public String transactionId { get; set; }
    }
}