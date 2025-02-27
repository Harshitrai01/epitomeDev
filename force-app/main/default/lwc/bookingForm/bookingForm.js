import { LightningElement, wire, track, api } from 'lwc';
import OPPORTUNITY_OBJECT_NAME from '@salesforce/schema/Opportunity';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import getRecordData from '@salesforce/apex/bookingFormController.getRecordData';
import saveFormData from '@salesforce/apex/bookingFormController.saveFormData';
import getAccountDetails from '@salesforce/apex/bookingFormController.getAccountDetails';
import getContactDetails from '@salesforce/apex/bookingFormController.getContactDetails';

export default class BookingForm extends NavigationMixin(LightningElement) {
    @track contacts = []; // Store contact options
    @track isAccountSelected = false;
    @track isAccountExist = false;
    @track isContactExist = false;
    @track isModalOpen = true;
    @api recordId;
    today = new Date();
    year = this.today.getFullYear();
    month = String(this.today.getMonth() + 1).padStart(2, '0');
    day = String(this.today.getDate()).padStart(2, '0');
    todayDate = `${this.year}-${this.month}-${this.day}`;
    eighteenYearsBack = this.subtractYears(this.today, 18);
    eighteenYearsBackYear = this.eighteenYearsBack.getFullYear();
    eighteenYearsBackMonth = String(this.eighteenYearsBack.getMonth() + 1).padStart(2, '0');
    eighteenYearsBackDay = String(this.eighteenYearsBack.getDate()).padStart(2, '0');
    eighteenYearsBackDate = `${this.eighteenYearsBackYear}-${this.eighteenYearsBackMonth}-${this.eighteenYearsBackDay}`;
    activeSections = ['A', 'B', 'C', 'D', 'E'];
    isLoading = false;

    @track bookingFormData = {
        dateOfBooking: '',
        quoteId: '',
        typeOfBooking: '',
        accountId: '',
        accountName: '',
        accountEmailId: '',
        accountContactNo: '',
        accountPermanentAddressStreet: '',
        accountPermanentAddressCity: '',
        accountPermanentAddressCountry: '',
        accountPermanentAddressState: '',
        accountPermanentAddressPostalCode: '',
        accountSameAsPermanentAddress: false,
        accountSameAsPermanentAddressNeeded: false,
        accountCorrespondenceAddressStreet: '',
        accountCorrespondenceAddressCity: '',
        accountCorrespondenceAddressCountry: '',
        accountCorrespondenceAddressState: '',
        accountCorrespondenceAddressPostalCode: '',
        quoteContactName: '',
        quoteContactEmailId: '',
        quoteContactNo: '',
        quoteContactPan: '',
        quoteContactAadhaar: '',
        quoteContactDOB: '',
        quotePlot: '',
        quotePlotName: '',
        quoteunitPlotFacing: '',
        quoteunitPlotSize: '',
        quoteunitPlotPrize: '',
        quoteunitPlotUnitCode: '',
        quoteunitPlotName: '',
        quoteunitPlotPhase: '',
        opportunityBookingAmount: '',
        leadId: '',
        saleValueAmount: '',
        contactId: ''
    }

    @track picklistOptions = {
        typeOfBookingOptions: []
    }

    value = 'No';
    get options() {
        return [
            { label: 'Yes', value: 'Yes' },
            { label: 'No', value: 'No' },

        ];
    }

    contactValue = 'No';
    get contactOptions() {
        return [
            { label: 'Yes', value: 'Yes' },
            { label: 'No', value: 'No' },

        ];
    }

    connectedCallback() {
        //   this.bookingFormData.quoteId = this.recordId;
        this.isAccountExist = true;
        this.isContactExist = true;
        this.fetchOpportunityData();
    }

    @wire(getObjectInfo, { objectApiName: OPPORTUNITY_OBJECT_NAME })
    opportunityObjectInfo;

    @wire(getPicklistValues, { recordTypeId: '$opportunityObjectInfo.data.defaultRecordTypeId', fieldApiName: 'Opportunity.Type_of_Booking__c' })
    wiredtypeOfBookingPicklistValues({ error, data }) {
        if (data) {
            this.picklistOptions.typeOfBookingOptions = [...data.values];
        } else if (error) {
            this.showToast('Error', error.message, 'error');
            this.handleCancelClick();
        }
    }

    handleAccountCheckboxChange(event) {
        this.value = event.detail.value;
        if (this.value === 'No') {
            debugger
            //   this.bookingFormData.accountId = '';
            this.isAccountSelected = false;
            this.isAccountExist = true;
            this.contactValue = 'No';
            this.isContactExist = true;
            this.clearBookingFormData('account');
            this.fetchOpportunityData();

        } else if (this.value === 'Yes') {
            console.log('checkkkkkkkkkkkkked : ');
            this.isAccountExist = false;
            this.clearBookingFormData('account');
            //this.fetchOpportunityData1();
        }
        console.log('Booking Form Data Before Selecting Account-->>', this.bookingFormData);
    }

    handleContactCheckboxChange(event) {
        debugger
        this.contactValue = event.detail.value;
        if (this.contactValue === 'No') {
            this.isContactExist = true;

            this.clearBookingFormData('contact');
            this.fetchOpportunityData();
            // this.fetchOpportunityDatacontact();

        } else if (this.contactValue === 'Yes') {
            console.log('checkkkkkkkkkkkkked : ');
            this.isContactExist = false;
            this.clearBookingFormData('contact');
            //this.fetchOpportunityData1();

        }
        console.log('Booking Form Data Before Selecting Account-->>', this.bookingFormData);
    }

    handleValueChange(event) {
        try {
            switch (event.target.name) {
                case 'accountSameAsPermanentAddress':
                    this.bookingFormData[event.target.name] = event.target.checked;
                    this.bookingFormData.accountSameAsPermanentAddressNeeded = !(event.target.checked);
                    this.handleSameAsPermanentChange();
                    break;
                case 'quoteContactPan':
                    this.bookingFormData[event.target.name] = event.target.value.toUpperCase();
                    break;
                default:
                    this.bookingFormData[event.target.name] = event.target.value;
            }
        } catch (error) {
            console.log('handleValueChange error message------------------>', error.message);
            console.log('handleValueChange error line number------------------>', error.lineNumber);
        }
    }

    handleSameAsPermanentChange() {
        if (this.bookingFormData.accountSameAsPermanentAddress) {
            this.bookingFormData.accountCorrespondenceAddressStreet = this.bookingFormData.accountPermanentAddressStreet;
            this.bookingFormData.accountCorrespondenceAddressCity = this.bookingFormData.accountPermanentAddressCity;
            this.bookingFormData.accountCorrespondenceAddressState = this.bookingFormData.accountPermanentAddressState;
            this.bookingFormData.accountCorrespondenceAddressCountry = this.bookingFormData.accountPermanentAddressCountry;
            this.bookingFormData.accountCorrespondenceAddressPostalCode = this.bookingFormData.accountPermanentAddressPostalCode;
        } else {
            this.bookingFormData.accountCorrespondenceAddressStreet = '';
            this.bookingFormData.accountCorrespondenceAddressCity = '';
            this.bookingFormData.accountCorrespondenceAddressState = '';
            this.bookingFormData.accountCorrespondenceAddressCountry = '';
            this.bookingFormData.accountCorrespondenceAddressPostalCode = '';
        }
    }

    handlePermanentAddressChange(event) {
        this.bookingFormData.accountPermanentAddressStreet = event.detail.street;
        this.bookingFormData.accountPermanentAddressCity = event.detail.city;
        this.bookingFormData.accountPermanentAddressState = event.detail.province;
        console.log('this.bookingFormData.accountPermanentAddressState--->', event.detail.state);
        console.log('this.bookingFormData.accountPermanentAddressState--->', event.detail.province);
        this.bookingFormData.accountPermanentAddressCountry = event.detail.country;
        this.bookingFormData.accountPermanentAddressPostalCode = event.detail.postalCode;

        if (this.bookingFormData.accountSameAsPermanentAddress) {
            this.bookingFormData.accountCorrespondenceAddressStreet = this.bookingFormData.accountPermanentAddressStreet;
            this.bookingFormData.accountCorrespondenceAddressCity = this.bookingFormData.accountPermanentAddressCity;
            this.bookingFormData.accountCorrespondenceAddressState = this.bookingFormData.accountPermanentAddressState;
            this.bookingFormData.accountCorrespondenceAddressCountry = this.bookingFormData.accountPermanentAddressCountry;
            this.bookingFormData.accountCorrespondenceAddressPostalCode = this.bookingFormData.accountPermanentAddressPostalCode;
        }

    }

    handleCorrespondenceAddressChange(event) {
        this.bookingFormData.accountCorrespondenceAddressStreet = event.detail.street;
        this.bookingFormData.accountCorrespondenceAddressCity = event.detail.city;
        this.bookingFormData.accountCorrespondenceAddressState = event.detail.province;
        this.bookingFormData.accountCorrespondenceAddressCountry = event.detail.country;
        this.bookingFormData.accountCorrespondenceAddressPostalCode = event.detail.postalCode;
    }

    fetchOpportunityData(fetchType) {
        try {
            debugger
            this.isLoading = true;
            getRecordData({ recordId: this.recordId })
                .then((data) => {
                    if (data && data.response.isSuccess && data.listOfOpportunityRecords) {
                        this.populateBookingData(data.listOfOpportunityRecords[0]);

                    } else {
                        this.showToast('Error', 'No Opportunity Data Found', 'error');
                    }
                })
                .catch((error) => {
                    this.showToast('Error', error.message, 'error');
                })
                .finally(() => {
                    this.isLoading = false;
                });
        } catch (error) {
            console.error('Unexpected error in fetchOpportunityData:', error);
            this.showToast('Error', 'An unexpected error occurred.', 'error');
            this.isLoading = false;
        }
    }

    populateBookingData(opportunity) {
        try {
            if (!opportunity || typeof opportunity !== 'object') {
                console.error('Error: Invalid opportunity object', opportunity);
                this.showToast('Error', 'Invalid opportunity data. Please refresh and try again.', 'error');
                return;
            }
            this.bookingFormData = {
                ...this.bookingFormData,
                dateOfBooking: this.todayDate,
                quoteId: opportunity.Id || '',
                saleValueAmount: opportunity.Total_Sale_Value__c || '',
                quotePlot: opportunity.Plot__c || '',
                quoteunitPlotFacing: opportunity.Plot__r?.Plot_Facing__c || '',
                quoteunitPlotSize: opportunity.Plot__r?.Plot_Size__c || '',
                quoteunitPlotPrize: opportunity.Plot__r?.Plot_Price__c || '',
                quoteunitPlotUnitCode: opportunity.Plot__r?.Unit_Code__c || '',
                quoteunitPlotName: opportunity.Plot__r?.Name || '',
                quoteunitPlotPhase: opportunity.Plot__r?.Phase__r?.Name || '',
                leadId: opportunity.Lead__r?.Id || ''
            };

            if (this.isAccountExist) {
                Object.assign(this.bookingFormData, {
                    accountName: opportunity.Lead__r?.Name || '',
                    accountEmailId: opportunity.Lead__r?.Email || '',
                    accountContactNo: opportunity.Lead__r?.Phone || ''
                });
            }

            if (this.isContactExist) {
                Object.assign(this.bookingFormData, {
                    quoteContactName: opportunity.Lead__r?.Name || '',
                    quoteContactEmailId: opportunity.Lead__r?.Email || '',
                    quoteContactNo: opportunity.Lead__r?.Phone || ''
                });
            }
        } catch (error) {
            console.error('Error in populateBookingData:', error);
            this.showToast('Error', 'An error occurred while processing booking data. Please try again.', 'error');
        }
    }

    handleRecordSelection(event) {
        console.log('fetchOpportunityData11111111111 : ');
        this.bookingFormData.accountId = event.detail.recordId;

        this.bookingFormData.quoteId = this.recordId;
        if (this.bookingFormData.accountId) {
            this.isAccountSelected = true;
            getAccountDetails({ accountId: this.bookingFormData.accountId })
                .then(account => {
                    console.log('Fetched Account Data:' + JSON.stringify(account));

                    this.bookingFormData['accountId'] = account.Id || null;
                    this.bookingFormData['accountName'] = account.Name || '';
                    this.bookingFormData['accountContactNo'] = account.Phone || '';
                    this.bookingFormData['accountEmailId'] = account.Email__c || '';
                    this.bookingFormData['accountPermanentAddressStreet'] = account.BillingStreet || '';
                    this.bookingFormData['accountPermanentAddressCity'] = account.BillingCity || '';
                    this.bookingFormData['accountPermanentAddressCountry'] = account.BillingCountry || '';
                    this.bookingFormData['accountPermanentAddressState'] = account.BillingState || '';
                    this.bookingFormData['accountPermanentAddressPostalCode'] = account.BillingPostalCode || '';
                    this.bookingFormData['accountCorrespondenceAddressStreet'] = account.ShippingStreet || '';
                    this.bookingFormData['accountCorrespondenceAddressCity'] = account.ShippingCity || '';
                    this.bookingFormData['accountCorrespondenceAddressCountry'] = account.ShippingCountry || '';
                    this.bookingFormData['accountCorrespondenceAddressState'] = account.ShippingState || '';
                    this.bookingFormData['accountCorrespondenceAddressPostalCode'] = account.ShippingPostalCode || '';
                    this.bookingFormData['accountSameAsPermanentAddress'] = account.Same_As_Permanent_Address__c || false;

                    this.recordFilter = {
                        criteria: [
                            {
                                fieldPath: 'AccountId',
                                operator: 'eq',
                                value: this.bookingFormData.accountId
                            }
                        ]
                    };
                })
                .catch(error => {
                    console.error('Error fetching account details:', error);
                });
        } else {
            this.isAccountSelected = false;
            this.handleContactCheckboxChange({ detail: { value: 'No' } });
            this.clearBookingFormData('account');
        }
    }


    handleContactRecordSelection(event) {
        console.log('fetchOpportunityData11111111111 : ');
        this.bookingFormData.contactId = event.detail.recordId;
        this.bookingFormData.quoteId = this.recordId;
        if (this.bookingFormData.contactId) {
            getContactDetails({ contactId: this.bookingFormData.contactId })
                .then(contact => {
                    console.log('Fetched contact Data:' + JSON.stringify(contact));

                    this.bookingFormData['contactId'] = contact.Id || null;
                    this.bookingFormData['quoteContactName'] = contact.LastName || '';
                    this.bookingFormData['quoteContactEmailId'] = contact.Email || '';
                    this.bookingFormData['quoteContactNo'] = contact.Phone || '';
                    this.bookingFormData['quoteContactAadhaar'] = contact.Aadhaar_Card__c || '';
                    this.bookingFormData['quoteContactPan'] = contact.PAN_Card__c || '';
                    this.bookingFormData['quoteContactDOB'] = contact.Date_Of_Birth__c || '';
                })
                .catch(error => {
                    console.error('Error fetching account details:', error);
                });
        } else {
            this.clearBookingFormData('contact')
        }
    }

    clearBookingFormData(objectType) {
        if (objectType === 'account') {
            this.bookingFormData = {
                ...this.bookingFormData,
                accountName: '',
                accountEmailId: '',
                accountContactNo: '',
                accountPermanentAddressStreet: '',
                accountPermanentAddressCity: '',
                accountPermanentAddressCountry: '',
                accountPermanentAddressState: '',
                accountPermanentAddressPostalCode: '',
                accountSameAsPermanentAddress: false,
                accountSameAsPermanentAddressNeeded: false,
                accountCorrespondenceAddressStreet: '',
                accountCorrespondenceAddressCity: '',
                accountCorrespondenceAddressCountry: '',
                accountCorrespondenceAddressState: '',
                accountCorrespondenceAddressPostalCode: '',
                accountId: null
            };
        } else if (objectType === 'contact') {
            this.bookingFormData = {
                ...this.bookingFormData,
                quoteContactName: '',
                quoteContactEmailId: '',
                quoteContactNo: '',
                quoteContactPan: '',
                quoteContactAadhaar: '',
                quoteContactDOB: '',
                contactId: null
            };
        }
    }

    handleSpinner(event) {
        this.isLoading = event.detail.isLoading;
    }

    handleCancelClick() {
        this.navigateToRecordPage();
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    closeModal() {
        this.isModalOpen = false;
        this.navigateToRecordPage();
    }

    subtractYears(date, years) {
        date.setFullYear(date.getFullYear() - years);
        return date;
    }

    getAgeDifferenceInYears(currentDate, selectedDate) {
        let currentDateYear = currentDate.getFullYear();
        let currentDateMonth = currentDate.getMonth();
        let currentDateDate = currentDate.getDate();
        let selectedDateYear = selectedDate.getFullYear();
        let selectedDateMonth = selectedDate.getMonth();
        let selectedDateDate = selectedDate.getDate();
        let differenceBetweenYears = currentDateYear - selectedDateYear;
        if (selectedDateMonth > currentDateMonth) {
            differenceBetweenYears--;
        }
        else {
            if (selectedDateMonth == currentDateMonth) {
                if (selectedDateDate > currentDateDate) {
                    differenceBetweenYears--;
                }
            }
        }
        return parseInt(differenceBetweenYears, 10);
    }

    handleSave(event) {
        try {
            this.isLoading = true;
            if (!this.validateFields()) {
                this.isLoading = false;
                return;
            }
            this.collectFormData(); // Collect data when Save is clicked
        } catch (error) {
            console.error('Unexpected error in handleSave:', error);
            this.showToast('Error', 'An unexpected error occurred.', 'error');
            this.isLoading = false;
        }
    }

    collectFormData() {
        console.log('data------>', JSON.stringify(this.bookingFormData));
        saveFormData({ bookingFormData: JSON.stringify(this.bookingFormData), quoteId: this.recordId })
            .then(result => {

                if (result.isSuccess) {

                    console.log('this.isLoading', this.isLoading);
                    this.showToast('Success', 'Data created successfully', 'success');
                    this[NavigationMixin.Navigate]({
                        type: 'standard__recordPage',
                        attributes: {
                            recordId: result.accountId, // ✅ Account Id from Apex
                            objectApiName: 'Account',
                            actionName: 'view'
                        }
                    });
                    setTimeout(() => {
                        this.isLoading = false;
                        //window.location.reload();
                    }, 100);
                    this.isLoading = false;
                    this.isModalOpen = false;
                } else {
                    this.showToast('Error', result.body, 'error');
                    this.isLoading = false;
                }
            })
            .catch(error => {
                this.showToast('Error', error.message, 'error');
                this.closeModal();
                this.isLoading = false;
            })

    }

    validateFields() {
        let allFieldsValid = true;
        const messages = [];
        const requiredFields = this.template.querySelectorAll('[data-label="primaryApplicantRequiredFields"]');

        if (requiredFields) {
            requiredFields.forEach(field => {
                if (!field.checkValidity()) {
                    field.reportValidity(); // Highlight invalid field
                    allFieldsValid = false;
                    messages.push(`${field.label || field.name || 'Field'} is required`);
                }
            });
        }

        if (!allFieldsValid) {
            this.showToast('Error', `Please fill all the required fields: ${messages.join(', ')}`, 'error');
        }

        return allFieldsValid;
    }

    showToast(title, message, variant) {
        try {
            this.dispatchEvent(new ShowToastEvent({
                label: title,
                title: title,
                message: message,
                variant: variant,
                mode: 'dismissable'
            }));
        } catch (error) {
            console.log('showToast error message----------------------->', error.message);
        }
    }

    navigateToRecordPage() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'Quote__c',
                actionName: 'view'

            }
        });
        setTimeout(() => {
            window.location.reload();
        }, 100)
    }
}