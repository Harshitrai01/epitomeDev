import { LightningElement, wire, track, api } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import OPPORTUNITY_OBJECT_NAME from '@salesforce/schema/Opportunity';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import saveBulkFormData from '@salesforce/apex/bookingFormController.saveBulkFormData';
import getAccountDetails from '@salesforce/apex/bookingFormController.getAccountDetails';
import getContactDetails from '@salesforce/apex/bookingFormController.getContactDetails';
import getPlotDetails from '@salesforce/apex/bookingFormController.getPlotDetails';


const FIELDS = [
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
    @track isModalOpen = true;
    @api recordId;
    selectedRecordId;
    recordTypeId;
    showComponent = false;
    isLoading = false;
    // companyLogo = BNMLogo;
    unitPlotFacing;
    unitPlotSize;
    unitPlotPrize;
    unitPlotUnitCode;
    unitPlotName;
    unitPlotPhase;
    nextId = 1; // Unique ID generator for listOfCoApplicant and plots

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

    @track bookingFormData = {
        typeOfBooking: '',
        accountId:null,
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
        listOfCoApplicant: []
    }

    @track picklistOptions = {
        typeOfBookingOptions: []
    }

    connectedCallback() {
        this.showComponent = true;
        this.addContact();
        this.isAccountExist = true;
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

    @wire(getRecord, { recordId: '$selectedRecordId', fields: FIELDS })
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
            console.log(data.fields.Plot_Facing__c.value);
        } else if (error) {
            this.phaseName = '';
            console.error('Error fetching plot phase record:', error);
        }
    }

    // fetchPlotDetails() {
    //     getPlotDetails({ recordId: this.selectedRecordId })
    //         .then(data => {
    //             console.log('Fetched Plot Data:', data);
    //             this.unitPlotFacing = data.plotFacing;
    //             this.unitPlotPrize = data.plotPrice;
    //             this.unitPlotSize = data.plotSize;
    //             this.unitPlotUnitCode = data.unitCode;
    //             this.unitPlotPhase = data.plotPhase;
    //             this.unitPlotName = data.plotName;
    //             this.updateContactPlots();
    //         })
    //         .catch(error => {
    //             this.phaseName = '';
    //             console.error('Error fetching plot details:', error);
    //         });
    // }

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

    handleSave(event) {
        this.isLoading = true;
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

    collectFormData() {
        console.log('asdfgh', JSON.stringify(this.bookingFormData));
        saveBulkFormData({ bookingFormData: JSON.stringify(this.bookingFormData) })
            .then(result => {
                if (result.isSuccess) {
                    console.log('this.isLoading--->', this.isLoading);
                    this.showToast('Success', 'Data ' + result.body + ' created successfully', 'success');
                    this[NavigationMixin.Navigate]({
                        type: 'standard__recordPage',
                        attributes: {
                            recordId: result.accountId, // Account Id from Apex
                            objectApiName: 'Account',
                            actionName: 'view'
                        }
                    });
                    setTimeout(() => {
                        window.location.reload();
                    }, 1000);
                    this.isLoading = false;
                    this.isModalOpen = false;
                } else {
                    this.showToast('Error', result.body, 'error');
                }
            })
            .catch(error => {
                this.showToast('Error', error.message, 'error');
                this.closeModal();
            })
    }

    handleValueChange(event) {
        try {
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
                case 'accountName':
                    this.bookingFormData[event.target.name] = event.target.value;
                    break;
                case 'accountEmailId':
                    this.bookingFormData[event.target.name] = event.target.value;
                    break;
                case 'accountContactNo':
                    this.bookingFormData[event.target.name] = event.target.value;
                    break;
                default:
                    // handle change for contact and plot list
                    const contactId = parseInt(event.target.dataset.contactId, 10); // Get contact ID
                    const plotId = event.target.dataset.plotId ? parseInt(event.target.dataset.plotId, 10) : null;
                    console.log('contactId--->', contactId);
                    console.log('plotId--->', plotId);
                    const fieldName = event.target.name; // Identify the field being modified
                    const value = event.detail.recordId; // Get the recordId
                    this.selectedRecordId = event.detail.recordId;
                    console.log('fieldName--->', fieldName);

                    // Check if it's for the 'plotName' field, otherwise, just use event.target.value
                    const finalValue = fieldName === 'plotName' ? value : event.target.value;

                    const contactIndex = this.bookingFormData.listOfCoApplicant.findIndex(
                        contact => contact.id === contactId
                    );

                    if (contactIndex !== -1) {
                        // If there is a plotId, update the plot information
                        if (plotId) {
                            console.log('aaaaaaaaaaaaaaaaaaaa');
                            const plotIndex = this.bookingFormData.listOfCoApplicant[contactIndex].plots.findIndex(
                                plot => plot.id === plotId
                            );
                            if (plotIndex !== -1) {
                                console.log('bbbbbbbbbbbbbbbbbbbbbb');
                                this.bookingFormData.listOfCoApplicant[contactIndex].plots[plotIndex][fieldName] = finalValue;

                            }
                        } else {
                            console.log('ccccccccccccccccc');
                            // If there is no plotId, just update the contact information
                            this.bookingFormData.listOfCoApplicant[contactIndex][fieldName] = finalValue;
                        }
                    }
                    console.log('213 ' + event.target.value);
            }
        } catch (error) {
            console.log('handleValueChange error message------------------>', error.message);
            console.log('handleValueChange error line number------------------>', error.lineNumber);
        }
    }

    // Add a new contact
    addContact() {
        const newContact = {
            id: this.nextId++, // Unique ID for the contact
            contactName: '', // Default empty contact name
            contactEmail: '',
            contactPhone: '',
            contactAadhaar: '',
            contactPan: '',
            contactDOB: '',
            contactId:null,
            isContactExist: true,
            plots: [{ id: this.nextId++, plotName: '', unitOppAmount: '', plotunitsname: '', unitPlotFacing: '', unitPlotPhase: '', unitPlotUnitCode: '', unitPlotPrize: '', unitPlotSize: '', showAddMoreButton: true, showRemoveButton: false }],
            showAddMoreButton: false,// Initially empty plots for this contact
        };
        // Add the new contact to the listOfCoApplicant array with the existing list
        this.bookingFormData.listOfCoApplicant = [...this.bookingFormData.listOfCoApplicant, newContact];
        console.log('first Contact :: ' + JSON.stringify(this.bookingFormData));
        this.updateContactButtons();
    }

    // Add a plot to the selected contact
    addPlot(event) {
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
                showAddMoreButton: false,
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
        this.showComponent = false;
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

    @track isAccountExist = false;

    handleCheckboxChange(event) {
        if (!(event.target.checked)) {
            this.isAccountExist = true;
        } else if(event.target.checked){
            this.isAccountExist = false;
        }
        console.log('Booking Form Data Before Selecting Account-->>',this.bookingFormData);
    }
    
     handleRecordSelection(event) {
        const accountId = event.detail.recordId;

        if (accountId) {
            getAccountDetails({ accountId })
                .then(account => {
                    console.log('Fetched Account Data:'+JSON.stringify(account));
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
                })
                .catch(error => {
                    console.error('Error fetching account details:', error);
                });
        }else {
            this.bookingFormData['accountId'] = null;
            this.bookingFormData['accountName'] = '';
            this.bookingFormData['accountContactNo'] = '';
            this.bookingFormData['accountEmailId'] = '';
            this.bookingFormData['accountPermanentAddressStreet'] = '';
            this.bookingFormData['accountPermanentAddressCity'] = '';
            this.bookingFormData['accountPermanentAddressCountry'] = '';
            this.bookingFormData['accountPermanentAddressState'] = '';
            this.bookingFormData['accountPermanentAddressPostalCode'] = '';
            this.bookingFormData['accountCorrespondenceAddressStreet'] = '';
            this.bookingFormData['accountCorrespondenceAddressCity'] = '';
            this.bookingFormData['accountCorrespondenceAddressCountry'] = '';
            this.bookingFormData['accountCorrespondenceAddressState'] = '';
            this.bookingFormData['accountCorrespondenceAddressPostalCode'] = '';
            this.bookingFormData['accountSameAsPermanentAddress'] = false;
        }
    }

    handleContactCheckboxChange(event) {
        const contactId = parseInt(event.target.dataset.contactId); // Get the contact ID from the dataset
        const isChecked = event.target.checked; 
        this.bookingFormData.listOfCoApplicant = this.bookingFormData.listOfCoApplicant.map(contact => {
            if (contact.id === contactId) {
                return { ...contact, isContactExist: !isChecked }; // Toggle isContactExist
            }
            return contact;
        });
    }
    
     handleContactRecordSelection(event) {
        const contactId = event.detail.recordId;
        const contactIndex = parseInt(event.target.dataset.contactId);

        if (contactId) {
            getContactDetails({ contactId })
                .then(contact => {
                    let updatedCoApplicants = this.bookingFormData.listOfCoApplicant.map(coApplicant => {
                    if (coApplicant.id === contactIndex) {
                        return {
                            ...coApplicant, // Spread existing co-applicant data
                            contactId: contact.Id,
                            contactName: contact.LastName || '',
                            contactEmail: contact.Email || '',
                            contactPhone: contact.Phone || '',
                            contactAadhaar: contact.Aadhaar_Card__c || '',
                            contactPan: contact.PAN_Card__c || '',
                            contactDOB: contact.Date_Of_Birth__c || '',
                        };
                    }
                    return coApplicant; // Return unchanged co-applicants
                });

                // Update the bookingFormData object to trigger UI reactivity
                this.bookingFormData = {
                    ...this.bookingFormData,
                    listOfCoApplicant: updatedCoApplicants
                };
                    
                })
                .catch(error => {
                    console.error('Error fetching contact details:', error);
                });
        }
        else{

       let updatedCoApplicants = this.bookingFormData.listOfCoApplicant.map(coApplicant => {
            if (coApplicant.id === contactIndex) {
                return {
                    ...coApplicant,
                    contactId: null,
                    contactName: null,
                    contactEmail: null,
                    contactPhone: null,
                    contactAadhaar: null,
                    contactPan: null,
                    contactDOB: null,
                };
            }
            return coApplicant;
        });

        this.bookingFormData = {
            ...this.bookingFormData,
            listOfCoApplicant: updatedCoApplicants
        };
    } }
    }