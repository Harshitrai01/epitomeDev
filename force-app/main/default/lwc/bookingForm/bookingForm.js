import { LightningElement, wire, track, api } from 'lwc';
import OPPORTUNITY_OBJECT_NAME from '@salesforce/schema/Opportunity';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import getRecordData from '@salesforce/apex/bookingFormController.getRecordData';
import saveFormData from '@salesforce/apex/bookingFormController.saveFormData';

export default class BookingForm extends NavigationMixin(LightningElement) {

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
        opportunityBookingAmount: ''
    }
    @track picklistOptions = {
        typeOfBookingOptions: []
    }

    @wire(getRecordData, { recordId: '$recordId' })
    wiredGetRecordData({ error, data }) {
        try {
            this.isLoading = false;

            if (data) {
                if (data.response.isSuccess && data.listOfOpportunityRecords) {
                    setTimeout(() => {
                        this.bookingFormData.dateOfBooking = this.todayDate ? this.todayDate : '';
                        this.bookingFormData.quoteId = data.listOfOpportunityRecords[0].Id ? data.listOfOpportunityRecords[0].Id : '';
                        console.log('OUTPUT : ', this.recordId);
                        if (data.listOfOpportunityRecords[0].Plot__c) {
                            this.bookingFormData.quotePlot = data.listOfOpportunityRecords[0].Plot__c ? data.listOfOpportunityRecords[0].Plot__c : '';
                            this.bookingFormData.quoteunitPlotFacing = data.listOfOpportunityRecords[0].Plot__r.Plot_Facing__c ? data.listOfOpportunityRecords[0].Plot__r.Plot_Facing__c : '';
                            this.bookingFormData.quoteunitPlotSize = data.listOfOpportunityRecords[0].Plot__r.Plot_Size__c ? data.listOfOpportunityRecords[0].Plot__r.Plot_Size__c : '';
                            this.bookingFormData.quoteunitPlotPrize = data.listOfOpportunityRecords[0].Plot__r.Plot_Price__c ? data.listOfOpportunityRecords[0].Plot__r.Plot_Price__c : '';
                            this.bookingFormData.quoteunitPlotUnitCode = data.listOfOpportunityRecords[0].Plot__r.Unit_Code__c ? data.listOfOpportunityRecords[0].Plot__r.Unit_Code__c : '';
                            this.bookingFormData.quoteunitPlotName = data.listOfOpportunityRecords[0].Plot__r.Name ? data.listOfOpportunityRecords[0].Plot__r.Name : '';
                            this.bookingFormData.quoteunitPlotPhase = data.listOfOpportunityRecords[0].Plot__r.Phase__r.Name ? data.listOfOpportunityRecords[0].Plot__r.Phase__r.Name : '';
                        }
                        this.isLoading = false;
                    }, 1500);
                } else {
                    this.isLoading = false;
                    this.showToast('Error', data.response.body, 'error');
                    this.handleCancelClick();
                }
            } else if (error) {
                this.isLoading = false;
                this.showToast('Error', error.message, 'error');
                this.handleCancelClick();
            }
        } catch (error) {
            this.isLoading = false;
            console.error('Error----------------->', error.lineNumber);
            console.error('Error----------------->', error.message);
            this.showToast('Error', error.message, 'error');
            this.handleCancelClick();
        }
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

    handleValueChange(event) {
        try {
            switch (event.target.name) {
                case 'accountSameAsPermanentAddress':
                    this.bookingFormData[event.target.name] = event.target.checked;
                    this.bookingFormData.accountSameAsPermanentAddressNeeded = !(event.target.checked);
                    this.handleSameAsPermanentChange();
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
        this.isLoading = true;
        let allFieldsValid = true;
        const messages = [];

        //  Select all required fields
        const primaryApplicantRequiredFields = this.template.querySelectorAll('[data-label="primaryApplicantRequiredFields"]');

        //  Loop through the fields and check validity
        if (primaryApplicantRequiredFields) {
            primaryApplicantRequiredFields.forEach((field) => {
                if (!field.checkValidity()) {
                    field.reportValidity(); // Highlight the field with a validation error
                    allFieldsValid = false;

                    // Add a message for each invalid field
                    messages.push(`${field.label || field.name || 'Field'} is required`);
                }
            });
        }

        //  Show a consolidated error message if validation fails
        if (!allFieldsValid) {
            this.showToast(
                'Error',
                `Please fill all the required fields: ${messages.join(', ')}`,
                'error'
            );
            this.isLoading = false;
            return; // Stop further execution if fields are invalid
        }

        console.log('data------>', JSON.stringify(this.bookingFormData));
        saveFormData({ bookingFormData: JSON.stringify(this.bookingFormData) })
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