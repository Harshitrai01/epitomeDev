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
import saveFormData1 from '@salesforce/apex/bookingFormController.saveFormData1';
import submitFormData from '@salesforce/apex/bookingFormController.submitFormData';
import getPlotDetails from '@salesforce/apex/bookingFormController.getPlotDetails';
import { refreshApex } from '@salesforce/apex';
const FIELDS = ['Opportunity.RecordTypeId'];

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
    defaultRedirectUrl = '/lightning/o/Opportunity/new'; // Default URL to redirect to
    isDefaultPlot=false;
    // companyLogo = BNMLogo;
    unitPlotFacing;
    unitPlotSize;
    unitPlotPrize;
    unitPlotUnitCode;
    unitPlotName;
    unitPlotPhase;
    nextId = 1;
    istest1 = false;
    istest2 = false;
    istest3 = false;
    istest4 = false;
    selectedPlots=[];
    recordTypeId;
    showComponent = false;
    projectLogo;
    @track isModalOpen = true;
    @api recordId;
    @track isAdd = false;
    @track isAdd1 = false;
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
    hasSalesUserBeenAdded = false;

    @track bookingFormData = {

        dateOfBooking: '',
        opportunityId: '',
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
        visitDate: '',
        typeOfBooking: '',
        listOfPrimaryApplicants: [],
        listOfCoApplicant: []
    }
    @track picklistOptions = {
        typeOfBookingOptions: []
    }
    selectedPlotIds = [];

    recordTypeId;
    selectedRecordId;
    connectedCallback() {
        this.istest3 = true;
     
        console.log(' this.isDefaultPlot---->', this.isDefaultPlot);
        //this.extractRecordTypeIdFromUrl();
        this.addContact();
    }

    extractRecordTypeIdFromUrl() {
        const urlParams = new URLSearchParams(window.location.search);
        this.recordTypeId = urlParams.get('recordTypeId');
        if (this.recordTypeId == '012O4000002tS7NIAU') {
            this.showComponent = true;
        }
        else {
            window.location.href = this.defaultRedirectUrl;
          //  window.location.reload();
        }
        console.log('Extracted Record Type ID:', this.recordTypeId);
    }

    closeModal() {
        this.isModalOpen = false;

        // Navigate to the Lead List View when Cancel is clicked
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Opportunity',
                actionName: 'list'
            },
            state: {
                filterName: 'Recent'
            }
        });
        setTimeout(() => {
            window.location.reload();
        }, 1000);
        // window.location.reload();
        // this.isModalOpen = false;
    }
 @wire(getObjectInfo, { objectApiName: OPPORTUNITY_OBJECT_NAME })
    handleObjectInfo({ data, error }) {
        if (data) {
            // Extract record type information
            const recordTypes = data.recordTypeInfos;

            // Get the 'Bulk Sales' record type ID
            this.recordTypeId = this.getRecordTypeIdByName(recordTypes, 'Bulk Sales');
    console.log('recordTypeId--------->',this.recordTypeId);
            // Check if we have the correct record type ID
            if (this.recordTypeId) {
                // If the record type matches 'Bulk Sales', show the component
                this.showComponent = true;
            } else {
                 this.showComponent = false;
                // If it doesn't match, redirect to the default Opportunity creation page
                window.location.href = this.defaultRedirectUrl;
            }
        } else if (error) {
            console.error('Error fetching record type info:', error);
        }
    }

    // Helper function to get the recordTypeId by recordTypeName
    getRecordTypeIdByName(recordTypes, recordTypeName) {
        return Object.keys(recordTypes).find(
            (key) => recordTypes[key].name === recordTypeName
        );
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


    @wire(getRecord, { recordId: '$selectedRecordId', fields: FIELDSs })
    unit({ error, data }) {
        if (data) {
            console.log('unit data:', data);
            this.unitPlotFacing = data.fields.Plot_Facing__c.value;
            this.unitPlotPrize = data.fields.Plot_Price__c.value;
            this.unitPlotSize = data.fields.Plot_Size__c.value;
            this.unitPlotUnitCode = data.fields.Unit_Code__c.value;
            this.unitPlotPhase = data.fields.Unit_Code__c.value;
            this.unitPlotName = data.fields.Name.value;
            this.updateContactPlots()
            //     this.phaseName = data.fields.Phase__r?.value?.fields?.Name?.value || '';
            console.log(data.fields.Plot_Facing__c.value);
        } else if (error) {
            this.phaseName = '';
            console.error('Error fetching plot phase record:', error);
        }
    }

    updateContactPlots() {
        
        // Find the contact and update its plot details
        this.bookingFormData.listOfCoApplicant.forEach((coApplicant) => {
            coApplicant.plots.forEach((plot) => {
                if (plot.plotName === this.selectedRecordId) {
                    plot.plotunitsname = this.unitPlotName;
                    plot.unitPlotFacing = this.unitPlotFacing;
                    plot.unitPlotSize = this.unitPlotSize;
                    plot.unitPlotPrize = this.unitPlotPrize;
                    plot.unitPlotUnitCode = this.unitPlotUnitCode;
                    plot.unitPlotPhase = this.unitPlotPhase;

                }
            });
        });
        

        console.log('Updated Booking Form Data:', JSON.stringify(this.bookingFormData, null, 2));
    }

    handleValueChange(event) {
        try {

            const contactId = parseInt(event.target.dataset.contactId, 10); // Get contact ID
            const plotId = event.target.dataset.plotId ? parseInt(event.target.dataset.plotId, 10) : null;
            console.log('contactId--->', contactId);
            console.log('plotId--->', plotId);
            const fieldName = event.target.name; // Identify the field being modified
            const value = event.detail.recordId; // Get the recordId
            this.selectedRecordId = event.detail.recordId;
           
           
            // Check if it's for the 'plotName' field, otherwise, just use event.target.value
            const finalValue = fieldName === 'plotName' ? value : event.target.value;

            const contactIndex = this.bookingFormData.listOfCoApplicant.findIndex(
                contact => contact.id === contactId
            );

            if (contactIndex !== -1) {
                // If there is a plotId, update the plot information
                if (plotId) {
                    const plotIndex = this.bookingFormData.listOfCoApplicant[contactIndex].plots.findIndex(
                        plot => plot.id === plotId
                    );
                    if (plotIndex !== -1) {
                        this.bookingFormData.listOfCoApplicant[contactIndex].plots[plotIndex][fieldName] = finalValue;

                    }
                } else {
                    // If there is no plotId, just update the contact information
                    this.bookingFormData.listOfCoApplicant[contactIndex][fieldName] = finalValue;
                }
            }
            console.log('213 ' + event.target.value);
            switch (event.target.name) {

                case 'accountSameAsPermanentAddress':
                    this.bookingFormData[event.target.name] = event.target.checked;
                    this.bookingFormData.accountSameAsPermanentAddressNeeded = !(event.target.checked);
                    this.handleSameAsPermanentChange();
                    break;
                case 'opportunityPaymentMode':
                    this.bookingFormData.opportunityChequeNo = this.bookingFormData[event.target.name] === event.target.value ? this.bookingFormData.opportunityChequeNo : '';
                    this.bookingFormData[event.target.name] = event.target.value;
                    this.showHideFields.showFieldForChequePaymentMode = this.bookingFormData[event.target.name] ? true : false;
                    break;
                    case 'typeOfBooking':
                    this.bookingFormData[event.target.name] = event.target.value;
                   
                    break;
                default:
                //   this.bookingFormData[event.target.name] = event.target.value;
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

    // @track bookingFormData = {
    //         listOfCoApplicant: [], // List of listOfCoApplicant, each with an empty plot list initially
    //     };

    nextId = 1; // Unique ID generator for listOfCoApplicant and plots

    // Add a new contact
    addContact() {
       
         console.log(' this.isDefaultPlot---->', this.isDefaultPlot);
        this.istest1 = true;
        this.istest3 = false;

        const newContact = {
            id: this.nextId++, // Unique ID for the contact
            contactName: '', // Default empty contact name
            contactEmail: '',
            contactPhone: '',
            contactAadhaar: '',
            contactPan: '',
            contactDOB: '',
            plots: [{ id: this.nextId++, plotName: '',unitOppAmount: '',plotunitsname: '', unitPlotFacing: '', unitPlotPhase: '', unitPlotUnitCode: '', unitPlotPrize: '', unitPlotSize: '', showAddMoreButton: true,showRemoveButton: false }], 
             showAddMoreButton: false,// Initially empty plots for this contact
        };

        // Add the new contact to the listOfCoApplicant array with the existing list
        this.bookingFormData.listOfCoApplicant = [...this.bookingFormData.listOfCoApplicant, newContact];
        console.log('first Contact :: ' + JSON.stringify(this.bookingFormData));
         this.updateContactButtons();
    }

    // Add a plot to the selected contact
    addPlot(event) {
        //      console.log('first Contact :: '+this.bookingFormData.listOfCoApplicant[0].contactName);
        //    console.log('first Contact :: '+this.bookingFormData.listOfCoApplicant[1].contactName);
        this.istest2 = true;
        const contactId = parseInt(event.target.dataset.contactId, 10); // Get the ID of the contact
        const contactIndex = this.bookingFormData.listOfCoApplicant.findIndex(
            contact => contact.id === contactId
        );

        if (contactIndex !== -1) {
            // Add a new plot to the plots array of the selected contact
            const newPlot = {
                id: this.nextId++, // Unique ID for the plot
                plotName: '', // Default empty plot name
                unitOppAmount: '',
                plotunitsname: '',
                unitPlotFacing: '',
                unitPlotPhase: '',
                unitPlotUnitCode: '',
                unitPlotPrize: '',
                unitPlotSize: '',
                 showAddMoreButton: false ,
                 showRemoveButton: true

            };

            // Update the contact's plot list with the new plot
            this.bookingFormData.listOfCoApplicant[contactIndex].plots = [
                ...this.bookingFormData.listOfCoApplicant[contactIndex].plots,
                newPlot,
            ];

               this.updatePlotButtons(contactIndex);
        }

    }
    updatePlotButtons(contactIndex) {
    const plots = this.bookingFormData.listOfCoApplicant[contactIndex].plots;

    // Iterate through all plots of the contact
    plots.forEach((plot, index, plotArray) => {
        // Show the "Add More" button only for the last plot
        plot.showAddMoreButton = index === plotArray.length - 1;

        // Show the "Remove" button if there's more than one plot and it's not the first plot
        plot.showRemoveButton = plotArray.length > 1 && index !== 0;
    });

    console.log(
        `Updated plots for contact [${contactIndex}]: `,
        JSON.stringify(plots)
    );
}
updateContactButtons() {
    // Iterate over all contacts to update the visibility of "Add More" buttons
    this.bookingFormData.listOfCoApplicant.forEach((contact, index, contacts) => {
        // Only show the "Add More" button for the last contact in the list
        contact.showAddMoreButton = index === contacts.length - 1;
        
        // Show "Remove" button only if there is more than one contact and it's not the first one
        contact.showRemoveButton = contacts.length > 1 && index !== 0;
    });

    // If there's only one contact, ensure the "Remove" button is hidden for that contact
    if (this.bookingFormData.listOfCoApplicant.length === 1) {
        this.bookingFormData.listOfCoApplicant[0].showRemoveButton = false;
    }

    console.log('Updated Contact List with Buttons Visibility: ', JSON.stringify(this.bookingFormData.listOfCoApplicant));
}
    removeContact(event) {
        const contactId = parseInt(event.target.dataset.contactId, 10); // Get the ID of the contact
        this.bookingFormData.listOfCoApplicant = this.bookingFormData.listOfCoApplicant.filter(
            contact => contact.id !== contactId
        );
         this.updateContactButtons();
    }

    // Remove a plot from a contact by its ID
    removePlot(event) {
        const contactId = parseInt(event.target.dataset.contactId, 10); // Get the ID of the contact
        const plotId = parseInt(event.target.dataset.plotId, 10); // Get the ID of the plot
        const contactIndex = this.bookingFormData.listOfCoApplicant.findIndex(
            contact => contact.id === contactId
        );

        if (contactIndex !== -1) {
            this.bookingFormData.listOfCoApplicant[contactIndex].plots = this.bookingFormData.listOfCoApplicant[
                contactIndex
            ].plots.filter(plot => plot.id !== plotId);
          
          this.updatePlotButtons(contactIndex);
        }
    }

    handleSpinner(event) {
        this.isLoading = event.detail.isLoading;
    }

    handleCoApplicantValueChange(event) {
        this.bookingFormData.listOfCoApplicant[event.target.dataset.rowIndex][event.target.name] = event.target.value;
    }


    handleCancelClick() {
        this.navigateToRecordPage();
        this.dispatchEvent(new CloseActionScreenEvent());
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
    collectFormData() {
        //  if (this.hasSalesUserBeenAdded==false) {
        this.bookingFormData.accountName = this.template.querySelector(".account-name").value;
        this.bookingFormData.accountEmailId = this.template.querySelector(".account-email").value;
        this.bookingFormData.accountContactNo = this.template.querySelector(".account-phone").value;

        console.log('asdfgh', JSON.stringify(this.bookingFormData));
        console.log('asdfgh111', this.bookingFormData.accountName);
        console.log('asdfgh111', this.bookingFormData.accountSoWoDo);

        saveFormData1({ bookingFormData: JSON.stringify(this.bookingFormData) })

        // .then(result => {
        //     if (result.isSuccess) {
        //         this.showToast('Success', result.body, 'success');
        //         this.closeModal();
        //     } else {
        //         this.showToast('Error', result.body, 'error');
        //     }
        // })
        // .catch(error => {
        //     this.showToast('Error', error.message, 'error');
        //     this.closeModal();
        // })


    }



    handleSave(event) {
        //      let allFieldsValid = true;
        // const messages = [];

        // // Select all required fields
        // const primaryApplicantRequiredFields = this.template.querySelectorAll('[data-label="primaryApplicantRequiredFields"]');

        // // Loop through the fields and check validity
        // if (primaryApplicantRequiredFields) {
        //     primaryApplicantRequiredFields.forEach((field) => {
        //         if (!field.checkValidity()) {
        //             field.reportValidity(); // Highlight the field with a validation error
        //             allFieldsValid = false;

        //             // Add a message for each invalid field
        //             messages.push(`${field.label || field.name || 'Field'} is required`);
        //         }
        //     });
        // }

        // // Show a consolidated error message if validation fails
        // if (!allFieldsValid) {
        //     this.showToast(
        //         'Error',
        //         `Please fill all the required fields: ${messages.join(', ')}`,
        //         'error'
        //     );
        //     return; // Stop further execution if fields are invalid
        // }


        this.collectFormData(); // Collect data when Save is clicked
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
                actionName: 'view'
            }
        });
        setTimeout(() => {
            window.location.reload();
        }, 100)
    }
}