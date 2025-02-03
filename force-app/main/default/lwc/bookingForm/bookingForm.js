import { LightningElement, wire, track, api } from 'lwc';
import LEAD_OBJECT_NAME from '@salesforce/schema/Lead';
import ACCOUNT_OBJECT_NAME from '@salesforce/schema/Account';
import { getRecord } from 'lightning/uiRecordApi';
import OPPORTUNITY_OBJECT_NAME from '@salesforce/schema/Opportunity';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import getRecordData from '@salesforce/apex/bookingFormController.getRecordData';
import saveFormData from '@salesforce/apex/bookingFormController.saveFormData';
import submitFormData from '@salesforce/apex/bookingFormController.submitFormData';
import { refreshApex } from '@salesforce/apex';

const FIELDSs = [
    'Unit__c.Name',
    'Unit__c.Unit_Code__c',
    'Unit__c.Plot_Facing__c',
    'Unit__c.Id',
    'Unit__c.Plot_Size__c',
    'Unit__c.Status__c',
    'Unit__c.Plot_Price__c',
    'Unit__c.Phase__c'
];

export default class BookingForm extends NavigationMixin(LightningElement) {
   // companyLogo = BNMLogo;
    projectLogo;
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
    @track showHidePages = {
        showPageOne: false,
        showPageTwo: false,
        showPageThree: false
    }
    @track showHideFields = {
        // showFieldsForApartmentType: false,
        // showFieldsForPlotType: false,
        // showFieldsForVillaType: false,
        showFieldForChequePaymentMode: false
    }
    @track bookingFormData = {

        dateOfBooking: '',
        opportunityId: '',
        quoteId:'',
        opportunityProjectName: '',
        opportunitySalesUser: '',
        accountSAadharCard: '',
        accountPhone: '',
        accountEmail: '',
        opportunityBookingAmount: '',
        opportunityPaymentMode: '',
        opportunityChequeNo: '',
        opportunityPaymentDate: '',
        paymentId: '',
        paymentMilestoneId: '',
        paymentAdjustmentId: '',
        leadId: '',
        leadName: '',
        leadLeadSource: '',
        leadLeadSubSource: '',
        opportunityRemark: '',
        accountId: '',
        accountsalutation: '',
        accountFirstName: '',
        accountLastName: '',
        accountName: '',
        accountDOB: '',
        accountSoWoDo: '',
        accountProfession: '',
        accountDesignation: '',
        accountAnnualIncome: '',
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
        accountEmailId: '',
        accountContactNo: '',
        accountAadhaarCard: '',
        accountPassportNumber: '',
        accountMaritalStatus: '',
        projectId: '',
        projectName: '',
        phaseId: '',
        phaseName: '',
        towerId: '',
        towerName: '',
        unitId: '',
        unitName: '',
        unitPhase: '',
        listOfPrimaryApplicants: [],
        listOfCoApplicant: [],
        quoteContactName: '',
        quoteContactEmailId: '',
        quoteContactNo: '',
        quoteContactPan: '',
        quoteContactAadhaar: '',
        quoteContactDOB: '',
        quotePlot: '',
        quotePlotName:'',
    }
    @track picklistOptions = {
        accountProfessionOptions: [],
        accountAnnualIncomeOptions: [],
        permanentAddressCountryOptions: [],
        permanentAddressStateMapOptions: {},
        correspondenceAddressCountryOptions: [],
        correspondenceAddressStateMapOptions: {},
        accountMaritalStatusOptions: [],
        paymentModeOptions: [],
        additionalLeadSourceOptions: [],
        additionalLeadSubSourceOptions: [],
        applicantTypeOptions: [],
        accountsalutationOptions: [],
        typeOfBookingOptions: []
    }
    selectedRecordId;
     unitPlotFacing;
    unitPlotSize;
    unitPlotPrize;
    unitPlotUnitCode;
    unitPlotName;
    unitPlotPhase;

  
        @wire(getRecord, { recordId: '$selectedRecordId', fields: FIELDSs })
    unit({ error, data }) {
        if (data) {
            console.log('unit data:', data);
            this.unitPlotFacing = data.fields.Plot_Facing__c.value;
            this.unitPlotPrize = data.fields.Plot_Price__c.value;
            this.unitPlotSize = data.fields.Plot_Size__c.value;
            this.unitPlotUnitCode = data.fields.Unit_Code__c.value;
            this.unitPlotPhase = data.fields.Unit_Code__c.value;
            this.bookingFormData.quotePlotName = data.fields.Name.value;
            //     this.phaseName = data.fields.Phase__r?.value?.fields?.Name?.value || '';
            console.log(data.fields.Plot_Facing__c.value);
        } else if (error) {
            this.phaseName = '';
            console.error('Error fetching plot phase record:', error);
        }
    }
    // connectedCallback() {
    //     if (this.recordId) {
    //     } else {
    //         this.showToast('Error', 'Record Id not found', 'error');
    //         this.handleCancelClick();
    //     }
    // }
     @wire(getRecordData, { recordId: '$recordId' })
    wiredGetRecordData({ error, data }) {
        try {
            this.isLoading = false;
            
            if (data) {
                if (data.response.isSuccess && data.listOfOpportunityRecords) {
                    setTimeout(() => {
                        this.bookingFormData.dateOfBooking = this.todayDate ? this.todayDate : '';
                      //  this.bookingFormData.projectName = data.listOfOpportunityRecords[0].Opportunity__r.Project_Name__c ? data.listOfOpportunityRecords[0].Opportunity__r.Project_Name__c : '';
                        this.bookingFormData.quoteId = data.listOfOpportunityRecords[0].Id ? data.listOfOpportunityRecords[0].Id : '';
                         this.bookingFormData.quotePlot = data.listOfOpportunityRecords[0].Plot__c ? data.listOfOpportunityRecords[0].Plot__c : '';
                        console.log('OUTPUT : ',this.recordId);

                      
                      
                        this.isLoading = false;
                    }, 1500);
                } else {
                    this.isLoading = false;
                    this.showToast('Error', data.response.body, 'error');
                 //   this.handleCancelClick();
                }
            } else if (error) {
                this.isLoading = false;
                this.showToast('Error', error.message, 'error');
              //  this.handleCancelClick();
            }
        } catch (error) {
            this.isLoading = false;
            console.error('Error----------------->', error.lineNumber);
            console.error('Error----------------->', error.message);
            this.showToast('Error', error.message, 'error');
           // this.handleCancelClick();
        }
    }
    connectedCallback() {
        console.log('recordid',this.recordId);
    }
    // @wire(getRecordData, { recordId: '$recordId' })
    // wiredGetRecordData({ error, data }) {
    //     try {
    //         this.isLoading = false;
    //         this.bookingFormData.listOfCoApplicant = [];
    //         this.bookingFormData.listOfPrimaryApplicants = [];
    //         if (data) {
    //             if (data.response.isSuccess && data.listOfOpportunityRecords) {
    //                 setTimeout(() => {
    //                     this.bookingFormData.dateOfBooking = this.todayDate ? this.todayDate : '';
    //                     this.bookingFormData.projectName = data.listOfOpportunityRecords[0].Opportunity.Project_Name__c ? data.listOfOpportunityRecords[0].Opportunity.Project_Name__c : '';
    //                     this.bookingFormData.opportunityId = data.listOfOpportunityRecords[0].Id ? data.listOfOpportunityRecords[0].Id : '';
    //                     this.bookingFormData.opportunityBookingAmount = data.listOfOpportunityRecords[0].Opportunity.Booking_Amount__c ? data.listOfOpportunityRecords[0].Opportunity.Booking_Amount__c : '';
    //                     this.bookingFormData.opportunityPaymentMode = data.listOfOpportunityRecords[0].Opportunity.Payment_Mode__c ? data.listOfOpportunityRecords[0].Opportunity.Payment_Mode__c : '';
    //                     this.bookingFormData.opportunityPaymentDate = data.listOfOpportunityRecords[0].Opportunity.Payment_Date__c ? data.listOfOpportunityRecords[0].Opportunity.Payment_Date__c : '';
    //                     this.showHideFields.showFieldForChequePaymentMode = false;

    //                     if (data.listOfOpportunityRecords[0].Opportunity.Unit__c) {
    //                         this.bookingFormData.unitId = data.listOfOpportunityRecords[0].Opportunity.Unit__r.Id ? data.listOfOpportunityRecords[0].Opportunity.Unit__r.Id : '';
    //                         this.bookingFormData.unitName = data.listOfOpportunityRecords[0].Opportunity.Unit__r.Name ? data.listOfOpportunityRecords[0].Opportunity.Unit__r.Name : '';
    //                         this.bookingFormData.unitPhase = data.listOfOpportunityRecords[0].Opportunity.Unit__r.Phase__r.Name ? data.listOfOpportunityRecords[0].Opportunity.Unit__r.Phase__r.Name : '';
    //                     }
    //                    if (data.listOfOpportunityRecords[0].Opportunity.Lead__c) {
    //                         this.bookingFormData.leadId = data.listOfOpportunityRecords[0].Opportunity.Lead__r.Id ? data.listOfOpportunityRecords[0].Opportunity.Lead__r.Id : '';
    //                       //  this.bookingFormData.leadName = data.listOfOpportunityRecords[0].Lead__r.Name ? data.listOfOpportunityRecords[0].Lead__r.Name : '';
    //                         this.bookingFormData.leadLeadSource = data.listOfOpportunityRecords[0].Opportunity.Lead__r.LeadSource ? data.listOfOpportunityRecords[0].Opportunity.Lead__r.LeadSource : '';
    //                         this.bookingFormData.leadLeadSubSource = data.listOfOpportunityRecords[0].Opportunity.Lead__r.Sub_Source__c ? data.listOfOpportunityRecords[0].Opportunity.Lead__r.Sub_Source__c : '';
    //                     }
    //                     console.log(' this.bookingFormData.leadLeadSubSource---->', this.bookingFormData.leadLeadSubSource);
    //                     if (data.listOfOpportunityRecords[0].Opportunity.AccountId) {
    //                         this.bookingFormData.accountId = data.listOfOpportunityRecords[0].Opportunity.Account.Id ? data.listOfOpportunityRecords[0].Opportunity.Account.Id : '';
    //                    this.bookingFormData.accountName = data.listOfOpportunityRecords[0].Opportunity.Account.Name ? data.listOfOpportunityRecords[0].Opportunity.Account.Name : '';
    //                     this.bookingFormData.accountDOB = data.listOfOpportunityRecords[0].Opportunity.Account.Birthdate__c ? data.listOfOpportunityRecords[0].Opportunity.Account.Birthdate__c : '';
    //                        this.bookingFormData.accountSameAsPermanentAddress = data.listOfOpportunityRecords[0].Opportunity.Account.Same_As_Permanent_Address__c;
    //                     this.bookingFormData.accountSameAsPermanentAddressNeeded = !(data.listOfOpportunityRecords[0].Opportunity.Account.Same_As_Permanent_Address__c);
    //                     this.bookingFormData.accountEmailId = data.listOfOpportunityRecords[0].Opportunity.Account.Email__c ? data.listOfOpportunityRecords[0].Opportunity.Account.Email__c : '';
    //                     this.bookingFormData.accountContactNo = data.listOfOpportunityRecords[0].Opportunity.Account.Phone ? data.listOfOpportunityRecords[0].Opportunity.Account.Phone : '';
    //                     this.bookingFormData.accountPanCard = data.listOfOpportunityRecords[0].Opportunity.Account.PAN_Card__c ? data.listOfOpportunityRecords[0].Opportunity.Account.PAN_Card__c : '';
    //                     this.bookingFormData.accountAadhaarCard = data.listOfOpportunityRecords[0].Opportunity.Account.Spouse_Adhaar_Card__c ? data.listOfOpportunityRecords[0].Opportunity.Account.Spouse_Adhaar_Card__c : '';
    //                      if (data.listOfOpportunityRecords[0].Opportunity.Account.BillingAddress) {
    //                        this.bookingFormData.accountPermanentAddressStreet = data.listOfOpportunityRecords[0].Opportunity.Account.BillingStreet ? data.listOfOpportunityRecords[0].Opportunity.Account.BillingStreet : '';
    //                          this.bookingFormData.accountPermanentAddressCity = data.listOfOpportunityRecords[0].Opportunity.Account.BillingCity ? data.listOfOpportunityRecords[0].Opportunity.Account.BillingCity : '';
    //                         this.bookingFormData.accountPermanentAddressCountry = data.listOfOpportunityRecords[0].Opportunity.Account.BillingCountry ? data.listOfOpportunityRecords[0].Opportunity.Account.BillingCountry : '';
    //                         this.bookingFormData.accountPermanentAddressState = data.listOfOpportunityRecords[0].Opportunity.Account.BillingState ? data.listOfOpportunityRecords[0].Opportunity.Account.BillingState : '';
    //                         this.bookingFormData.accountPermanentAddressPostalCode = data.listOfOpportunityRecords[0].Opportunity.Account.BillingPostalCode ? data.listOfOpportunityRecords[0].Opportunity.Account.BillingPostalCode : '';
    //                     }
    //                      console.log(' this.bookingFormData.leadLeadSubSource11---->', this.bookingFormData.accountPermanentAddressStreet);
    //                       console.log(' this.bookingFormData.leadLeadSubSource-11--33->',  this.bookingFormData.accountPermanentAddressCity);
    //                        console.log(' this.bookingFormData.leadLeadSubSource--22-->', this.bookingFormData.accountPanCard);
    //                     if (data.listOfOpportunityRecords[0].Opportunity.Account.ShippingAddress) {
    //                         this.bookingFormData.accountCorrespondenceAddressStreet = data.listOfOpportunityRecords[0].Opportunity.Account.ShippingStreet ? data.listOfOpportunityRecords[0].Opportunity.Account.ShippingStreet : '';
    //                         this.bookingFormData.accountCorrespondenceAddressCity = data.listOfOpportunityRecords[0].Opportunity.Account.ShippingCity ? data.listOfOpportunityRecords[0].Opportunity.Account.ShippingCity : '';
    //                         this.bookingFormData.accountCorrespondenceAddressCountry = data.listOfOpportunityRecords[0].Opportunity.Account.ShippingCountry ? data.listOfOpportunityRecords[0].Opportunity.Account.ShippingCountry : '';
    //                         this.bookingFormData.accountCorrespondenceAddressState = data.listOfOpportunityRecords[0].Opportunity.Account.ShippingState ? data.listOfOpportunityRecords[0].Opportunity.Account.ShippingState : '';
    //                         this.bookingFormData.accountCorrespondenceAddressPostalCode = data.listOfOpportunityRecords[0].Opportunity.Account.ShippingPostalCode ? data.listOfOpportunityRecords[0].Opportunity.Account.ShippingPostalCode : '';
    //                     }

    //                     }
                      
    //                     this.isLoading = false;
    //                 }, 1500);
    //             } else {
    //                 this.isLoading = false;
    //                 this.showToast('Error', data.response.body, 'error');
    //                 this.handleCancelClick();
    //             }
    //         } else if (error) {
    //             this.isLoading = false;
    //             this.showToast('Error', error.message, 'error');
    //             this.handleCancelClick();
    //         }
    //     } catch (error) {
    //         this.isLoading = false;
    //         console.error('Error----------------->', error.lineNumber);
    //         console.error('Error----------------->', error.message);
    //         this.showToast('Error', error.message, 'error');
    //         this.handleCancelClick();
    //     }
    // }

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
          
           switch(event.target.name){
                case 'accountSameAsPermanentAddress':
                    this.bookingFormData[event.target.name] = event.target.checked;
                    this.bookingFormData.accountSameAsPermanentAddressNeeded = !(event.target.checked);
                    this.handleSameAsPermanentChange();
                    break;
                case 'opportunityPaymentMode':
                    this.bookingFormData[event.target.name] = event.target.value;
                    break;
                    case 'quotePlot':
                      if (!event.detail || !event.detail.recordId) {
                    // If the record picker is cleared, reset related fields
                    this.selectedRecordId = null;
                    this.bookingFormData.quotePlot = null;
                    this.bookingFormData.phase = '';
                    this.bookingFormData.plotSize = '';
                    this.bookingFormData.plotPrice = '';
                    this.bookingFormData.plotFacing = '';
                    this.bookingFormData.unitCode = '';
                } else {
                      this.selectedRecordId = event.detail.recordId;
                    this.bookingFormData[event.target.name] = event.detail.recordId;
                }
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
        this.bookingFormData.accountPermanentAddressState = (this.bookingFormData.accountPermanentAddressCountry === event.detail.country) ? event.detail.province : '';
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
        this.bookingFormData.accountCorrespondenceAddressState = this.bookingFormData.accountCorrespondenceAddressCountry === event.detail.country ? event.detail.province : '';
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

        // Navigate to the Lead List View when Cancel is clicked
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                actionName: 'view'
            }
        });
        setTimeout(() => {
            window.location.reload();
        }, 100)
        // window.location.reload();
        // this.isModalOpen = false;
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
    handleSaveAndNextClick(event) {
        
        console.log('data------>',JSON.stringify(this.bookingFormData));
        saveFormData({ bookingFormData: JSON.stringify(this.bookingFormData) })
        // try {
//                 const panCardRegex = new RegExp(/^[A-Z]{5}[0-9]{4}[A-Z]{1}$/);
//                 const aadharCardNumberRegex = new RegExp(/^[0-9]{12}$/);
//                 const passportNumberRegex = new RegExp(/^[A-Z]{1}[1-9]{1}[0-9]{1}[0-9]{4}[1-9]{1}$/);
//                 // const chequeNumberRegex = new RegExp(/^[0-9]{6}$/);
//                 const contactNumberRegex = new RegExp(/^[1-9]{1}[0-9]{9}$/);
//                 // const emailIdRegex =new RegExp(/^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]{1,8}+\\\\.[a-zA-Z]{2,6}$/);
//                 let isRequired = true;
//                 let checkRequired = true;
//                 let listOfRequiredFields = [];
//                 let isValidation = true;
//                 let checkValidation = true;
             
// if (checkRequired && checkValidation) {
//                     saveFormData({ bookingFormData: JSON.stringify(this.bookingFormData) })
//                         .then(result => {
//                             if (result.isSuccess) {
//                                 this.showHidePages.showPageOne = false;
//                                 this.showHidePages.showPageTwo = true;
//                                 this.showHidePages.showPageThree = false;
//                             } else {
//                                 this.showToast('Error', result.body, 'error');
//                             }
//                         })
//                         .catch(error => {
//                             this.showToast('Error', error.message, 'error');
//                             this.handleCancelClick();
//                         })
//                 }
        
//                 submitFormData({ bookingFormData: JSON.stringify(this.bookingFormData) })
//                     .then(result => {
//                         if (result.isSuccess) {
//                             this.showToast('Success', result.body, 'success');
//                             this.handleCancelClick();
//                         } else {
//                             this.showToast('Error', result.body, 'error');
//                         }
//                     })
//                     .catch(error => {
//                         this.showToast('Error', error.message, 'error');
//                         this.handleCancelClick();
//                     })
            

//         } catch (error) {
//             console.log('saveFormData error message------------------->', error.lineNumber);
//             console.log('saveFormData error message------------------->', error.message);
//             this.showToast('Error', error.message, 'error');
//         }
    
    }
    isCheckEmpty(value) {
        return (value == null || value === null || value === undefined || value.length === 0);
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