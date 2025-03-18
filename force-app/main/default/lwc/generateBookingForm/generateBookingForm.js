import { LightningElement, wire, track, api } from 'lwc';
import OPPORTUNITY_OBJECT_NAME from '@salesforce/schema/Opportunity';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import saveBulkFormData from '@salesforce/apex/bookingFormController.saveBulkFormData';
import getAccountDetails from '@salesforce/apex/bookingFormController.getAccountDetails';
import getContactDetails from '@salesforce/apex/bookingFormController.getContactDetails';
import getPlotDetails from '@salesforce/apex/bookingFormController.getPlotDetails';
import getContactsByAccountId from '@salesforce/apex/bookingFormController.getContactsByAccountId';
import getProjects from '@salesforce/apex/bookingFormController.getProjects';
import getPhases from '@salesforce/apex/bookingFormController.getPhases';

export default class BookingForm extends NavigationMixin(LightningElement) {

    @track contacts = [];
    @track projects = [];
    @track phases = [];
    @track isModalOpen = true;
    @track isAccountSelected = false;
    @api recordId;
    @track isAccountExist = false;
    selectedRecordId;
    recordTypeId;
    showComponent = false;
    isLoading = false;
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

    @track bookingFormData = {
        typeOfBooking: '',
        accountId: null,
        projectId: null,
        phaseId: null,
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
        this.fetchProject();
        this.showComponent = true;
        this.addContact();
        this.isAccountExist = true;
    }


    @wire(getObjectInfo, { objectApiName: OPPORTUNITY_OBJECT_NAME })
    opportunityObjectInfo;

    @wire(getPicklistValues, { recordTypeId: '$opportunityObjectInfo.data.defaultRecordTypeId', fieldApiName: 'Opportunity.Type_of_Booking__c' })
    wiredtypeOfBookingPicklistValues({ error, data }) {
        if (data) {
            // Filtering out 'Retail' from the picklist options
            this.picklistOptions.typeOfBookingOptions = data.values.filter(option => option.value !== 'Retail');
        } else if (error) {
            this.showToast('Error', error.message, 'error');
            this.handleCancelClick();
        }
    }

    handleProjectSelection(event) {
        this.bookingFormData.projectId = event.detail.value;
        this.fetchPhase();
        console.log('this.bookingFormData.projectId--------->', this.bookingFormData.projectId);
    }

    handlePhaseSelection(event) {
        if (!this.bookingFormData.projectId) {
            // Show an error message (you can use toast or set an error variable)
            this.showToast('Error', 'Please select a project first.', 'error');
            return;
        }
        this.bookingFormData.phaseId = event.detail.value;
        console.log('this.bookingFormData.phaseId--------->', this.bookingFormData.phaseId);
    }

    handleAccountChange(event) {
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
                    this.bookingFormData[event.target.name] = event.target.value;
            }
        } catch (error) {
            console.log('handleAccountChange error message------------------>', error.message);
            console.log('handleAccountChange error line number------------------>', error.lineNumber);
        }
    }

    handleValueChange(event) {
        debugger
        try {
            const contactId = parseInt(event.currentTarget.dataset.contactId, 10);
            const plotId = event.currentTarget.dataset.plotId ? parseInt(event.currentTarget.dataset.plotId, 10) : null;
            const fieldName = event.target.name;
            const value = fieldName === 'plotName' ? event.detail.id : event.detail.value;

            this.selectedRecordId = value; // Update selected record ID

            console.log('Selected Record ID:', this.selectedRecordId);

            if (!this.bookingFormData.phaseId) {
                this.clearPlotValues(plotId, contactId);
                this.showToast('Error', 'Please select a phase first.', 'error');
                return;
            }

            if (fieldName === 'contactDOB') {
                let isValidDOB = this.validateDateOfBirth(value, event);
                if (!isValidDOB) return; // Stop further execution if validation fails
            }

            if (fieldName === 'plotName') {
                  if (!value) { // When input is cleared
                this.clearPlotValues(plotId, contactId);
                return;
            }

                if (this.isDuplicatePlotSelected(value)) {
                    this.clearPlotValues(plotId, contactId);
                    this.showToast('Error', 'Duplicate plot selected. Please choose a different plot.', 'error');
                    return;
                }

                this.selectedRecordId = value; // Update selected record ID
                console.log('this.selectedRecordId  : ',this.selectedRecordId );

                // If no record is selected, clear the plot details
                if (!this.selectedRecordId) {
                    this.clearPlotValues(plotId, contactId);
                } else {
                    getPlotDetails({ recordId: this.selectedRecordId })
                        .then(data => {
                            if (data) {
                                console.log('Plot Data:', data);
                                this.unitPlotFacing = data.Plot_Facing__c || '';
                                this.unitPlotPrize = data.Plot_Price__c || '';
                                this.unitPlotSize = data.Plot_Size__c || '';
                                this.unitPlotUnitCode = data.Unit_Code__c || '';
                                this.unitPlotPhase = data.Phase__r ? data.Phase__r.Name : '';
                                this.unitPlotName = data.Name || '';
                                this.updateContactPlots();
                            }
                        })
                        .catch(error => {
                            console.error('Error fetching Plot details:', error);
                        });
                }
            }

            // Determine final value (handling plot name differently)
            const finalValue = fieldName === 'plotName' ? value : event.target.value;
            // Update contact or plot information
            this.updateBookingFormData(contactId, plotId, fieldName, finalValue);

            console.log('Updated Value:', event.target.value);
        } catch (error) {
            console.log('handleValueChange error message------------------>', error.message);
            console.log('handleValueChange error line number------------------>', error.lineNumber);
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

    isDuplicatePlotSelected(plotId) {
        return this.bookingFormData.listOfCoApplicant.some(coApplicant =>
            coApplicant.plots.some(plot => plot.plotName === plotId)
        );
    }

    validateDateOfBirth(value, event) {
        let selectedDate = new Date(value);
        let today = new Date();
        let eighteenYearsBack = new Date();
        eighteenYearsBack.setFullYear(today.getFullYear() - 18);

        // Check if the selected date is in the future
        if (selectedDate > today) {
            this.showToast('Error', 'Date of Birth cannot be a future date.', 'error');
            event.target.value = null; // Reset field
            return false;
        }

        // Check if the applicant is at least 18 years old
        let age = this.getAgeDifferenceInYears(today, selectedDate);
        if (age < 18) {
            this.showToast('Error', 'Applicant must be at least 18 years old.', 'error');
            event.target.value = null; // Reset field
            return false;
        }
        return true; // If validation passes
    }

    clearPlotValues(plotId, contactId) {
        debugger
        // Create a deep copy to trigger LWC reactivity
        const lookupComponents = this.template.querySelectorAll('c-custom-lookup-cmp');

        lookupComponents.forEach(lookup => {
            if (lookup.contactId === contactId && lookup.plotId === plotId) {
                lookup.clearSelection();  // Call child method to reset only the correct lookup
            }
        });
        let updatedBookingFormData = JSON.parse(JSON.stringify(this.bookingFormData));

        // Find the correct co-applicant
        const contactIndex = updatedBookingFormData.listOfCoApplicant.findIndex(
            contact => contact.id === contactId
        );

        if (contactIndex !== -1) {
            // Find the correct plot inside that co-applicant
            const plotIndex = updatedBookingFormData.listOfCoApplicant[contactIndex].plots.findIndex(
                plot => plot.id === plotId
            );

            if (plotIndex !== -1) {
                // Reset only the selected plot's values
                updatedBookingFormData.listOfCoApplicant[contactIndex].plots[plotIndex] = {
                    ...updatedBookingFormData.listOfCoApplicant[contactIndex].plots[plotIndex],
                    plotName: null,
                    plotunitsname: null,
                    unitPlotFacing: null,
                    unitPlotSize: null,
                    unitPlotPrize: null,
                    unitPlotUnitCode: null,
                    unitPlotPhase: null
                };
                console.log('updatedBookingFormData', JSON.stringify(updatedBookingFormData));
            }
        }

        // Assign the updated object back to trigger UI refresh
        this.bookingFormData = updatedBookingFormData;

        // If the deselected plot is the currently selected one, reset class properties

        if (this.selectedRecordId === plotId) {
            this.unitPlotFacing = null;
            this.unitPlotPrize = null;
            this.unitPlotSize = null;
            this.unitPlotUnitCode = null;
            this.unitPlotPhase = null;
            this.unitPlotName = null;
        }

        console.log('Deselected plot reset:', JSON.stringify(this.bookingFormData, null, 2));
    }

    handleClearPlot(event) {
        const { contactId, plotId } = event.detail;
        console.log(`Clearing plot for Contact ID: ${contactId}, Plot ID: ${plotId}`);
        this.clearPlotValues(plotId, contactId);
    }

    updateBookingFormData(contactId, plotId, fieldName, value) {
        try {
            let updatedBookingFormData = JSON.parse(JSON.stringify(this.bookingFormData));

            const contactIndex = updatedBookingFormData.listOfCoApplicant.findIndex(contact => contact.id === contactId);

            if (contactIndex !== -1) {
                if (plotId) {
                    // Update plot details
                    const plotIndex = updatedBookingFormData.listOfCoApplicant[contactIndex].plots.findIndex(plot => plot.id === plotId);
                    if (plotIndex !== -1) {
                        updatedBookingFormData.listOfCoApplicant[contactIndex].plots[plotIndex][fieldName] = value;
                    }
                } else {
                    // Update contact details
                    updatedBookingFormData.listOfCoApplicant[contactIndex][fieldName] = this.processFieldValue(fieldName, value);
                }
            }

            // Assign back to trigger reactivity
            this.bookingFormData = updatedBookingFormData;
        }
        catch (error) {
            console.error('❌ Error in updateBookingFormData:', error);
        }
    }

    processFieldValue(fieldName, value) {
        switch (fieldName) {
            case 'contactPan':
                return typeof value === 'string' ? value.toUpperCase() : value;
            default:
                return value;
        }
    }

    handleCheckboxChange(event) {
        this.value = event.detail.value;
        if (this.value == 'No') {
            this.isAccountSelected = false;

            this.isAccountExist = true;
            this.bookingFormData.listOfCoApplicant = this.bookingFormData.listOfCoApplicant.map(contact => {
                if (contact.contactValue === 'Yes') {
                    return {
                        ...contact,
                        contactId: null,
                        contactName: '',
                        contactEmail: '',
                        contactPhone: '',
                        contactAadhaar: '',
                        contactPan: '',
                        contactDOB: '',
                        contactValue: 'No',
                        isContactExist: true
                    };
                }
                return contact;
            });

        } else if (this.value == 'Yes') {
            this.isAccountExist = false;
        }
        this.clearAccountData();
        console.log('Booking Form Data Before Selecting Account-->>', this.bookingFormData);
    }

    clearAccountData() {
        this.bookingFormData = {
            ...this.bookingFormData,
            accountId: null,
            accountName: '',
            accountContactNo: '',
            accountEmailId: '',
            accountPermanentAddressStreet: '',
            accountPermanentAddressCity: '',
            accountPermanentAddressCountry: '',
            accountPermanentAddressState: '',
            accountPermanentAddressPostalCode: '',
            accountCorrespondenceAddressStreet: '',
            accountCorrespondenceAddressCity: '',
            accountCorrespondenceAddressCountry: '',
            accountCorrespondenceAddressState: '',
            accountCorrespondenceAddressPostalCode: '',
            accountSameAsPermanentAddress: false
        };
    }

    handleRecordSelection(event) {
        const accountId = event.detail.recordId;
        if (accountId) {
            this.isAccountSelected = true;
            getAccountDetails({ accountId })
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

                    this.fetchContacts();
                })
                .catch(error => {
                    console.error('Error fetching account details:', error);
                });
        } else {
            // this.isAccountSelected=false;
            // this.clearAllContacts();
            this.isAccountSelected = false;
            this.clearAllContacts();
            this.clearAccountData();
        }
    }

    fetchProject() {
        debugger
        console.log('Fetching projects for project:', this.bookingFormData.projectId);
        getProjects()
            .then((data) => {
                if (data && data.length > 0) {
                    this.projects = data.map((project) => ({
                        label: project.Name, // Show Last Name in combobox
                        value: project.Id        // Store Contact Id as value
                    }));
                    console.log('project loaded:', this.projects);
                } else {
                    this.projects = [];
                    //this.showToast('Error', 'No contacts found for this Account.', 'error');
                }
            })
            .catch(error => {
                console.error('Error fetching contacts:', error);
            });
    }

    fetchPhase() {
        console.log('Fetching phases for Account:', this.bookingFormData.accountId);
        getPhases({ projectId: this.bookingFormData.projectId })
            .then((data) => {
                if (data && data.length > 0) {
                    this.phases = data.map((phase) => ({
                        label: phase.Name, // Show Last Name in combobox
                        value: phase.Id        // Store Contact Id as value
                    }));
                    console.log('phase loaded:', this.phases);
                } else {
                    this.phases = [];
                    //this.showToast('Error', 'No contacts found for this Account.', 'error');
                }
            })
            .catch(error => {
                console.error('Error fetching contacts:', error);
            });
    }

    fetchContacts() {
        console.log('Fetching contacts for Account:', this.bookingFormData.accountId);
        getContactsByAccountId({ accountId: this.bookingFormData.accountId })
            .then((data) => {
                if (data && data.length > 0) {
                    this.contacts = data.map((contact) => ({
                        label: contact.LastName, // Show Last Name in combobox
                        value: contact.Id        // Store Contact Id as value
                    }));
                    console.log('Contacts loaded:', this.contacts);
                } else {
                    this.contacts = [];
                    //this.showToast('Error', 'No contacts found for this Account.', 'error');
                }
            })
            .catch(error => {
                console.error('Error fetching contacts:', error);
            });
    }

    clearAllContacts() {
        this.bookingFormData.listOfCoApplicant = this.bookingFormData.listOfCoApplicant.map(contact => {
            if (contact.contactValue === 'Yes') {
                return {
                    ...contact,
                    contactId: null,
                    contactName: '',
                    contactEmail: '',
                    contactPhone: '',
                    contactAadhaar: '',
                    contactPan: '',
                    contactDOB: '',
                    contactValue: 'No',
                    isContactExist: true
                };
            }
            return contact;
        });
    }

    handleContactCheckboxChange(event) {
        const contactId = parseInt(event.target.dataset.contactId);
        let value = event.detail.value;
        const selectedValue = event.detail.value; // Yes / No
        let isChecked = true;
        if (value == 'No') {
            isChecked = false;
        } else if (value == 'Yes') {
            isChecked = true;
            this.bookingFormData.listOfCoApplicant = this.bookingFormData.listOfCoApplicant.map(coApplicant =>
                coApplicant.id === contactId
                    ? {
                        ...coApplicant,
                        contactValue: selectedValue,
                        isContactExist: !isChecked,
                        contactId: null,
                        contactName: '',
                        contactEmail: '',
                        contactPhone: '',
                        contactAadhaar: '',
                        contactPan: '',
                        contactDOB: '',
                    }
                    : coApplicant
            );

        }
        let updatedCoApplicants = this.bookingFormData.listOfCoApplicant.map(coApplicant => {
            if (coApplicant.id === contactId) {
                return {
                    ...coApplicant,
                    contactValue: selectedValue, // Ensure each contact stores its own value
                    isContactExist: !isChecked,
                    contactId: selectedValue === 'Yes' ? coApplicant.contactId : null,
                    contactName: selectedValue === 'Yes' ? coApplicant.contactName : '',
                    contactEmail: selectedValue === 'Yes' ? coApplicant.contactEmail : '',
                    contactPhone: selectedValue === 'Yes' ? coApplicant.contactPhone : '',
                    contactAadhaar: selectedValue === 'Yes' ? coApplicant.contactAadhaar : '',
                    contactPan: selectedValue === 'Yes' ? coApplicant.contactPan : '',
                    contactDOB: selectedValue === 'Yes' ? coApplicant.contactDOB : '',
                };
            }
            return coApplicant;
        });


        this.bookingFormData = {
            ...this.bookingFormData,
            listOfCoApplicant: updatedCoApplicants
        };

    }

    handleContactRecordSelection(event) {
        const contactId = event.detail.value;
        const contactIndex = parseInt(event.target.dataset.contactId);

        if (contactId) {
            if (this.isDuplicateContactSelected(event, contactId)) return;
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
        else {
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
        }
    }

    isDuplicateContactSelected(event, contactId) {
        const isDuplicate = this.bookingFormData.listOfCoApplicant.some(
            coApplicant => coApplicant.contactId === contactId
        );

        if (isDuplicate) {
            event.target.value = null; // Reset combobox
            this.isDuplicateContact = true;
            this.showToast('Error', 'Duplicate contact selected. Please choose a different contact.', 'error');
            return true;
        }

        this.isDuplicateContact = false;
        return false;
    }

    handleSave(event) {
        debugger
        this.isLoading = true;
        if (!this.validateFields()) {
            this.isLoading = false;
            return;
        }
        this.collectFormData(); // Collect data when Save is clicked
    }

    collectFormData() {
        console.log('asdfgh', JSON.stringify(this.bookingFormData, null, 2));
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

    validateFields() {
        debugger
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

    addContact() {
        const newContact = {
            id: this.nextId++, // Unique ID for the contact
            contactName: '', // Default empty contact name
            contactEmail: '',
            contactPhone: '',
            contactAadhaar: '',
            contactPan: '',
            contactDOB: '',
            contactId: null,
            isContactExist: true,
            isPrimaryPayer: false, // Default to false
            plots: [{ id: this.nextId++, plotName: '', unitOppAmount: '', plotunitsname: '', unitPlotFacing: '', unitPlotPhase: '', unitPlotUnitCode: '', unitPlotPrize: '', unitPlotSize: '', showAddMoreButton: true, showRemoveButton: false }],
            showAddMoreButton: false,// Initially empty plots for this contact
        };
        // Add the new contact to the listOfCoApplicant array with the existing list
        this.bookingFormData.listOfCoApplicant = [
            ...this.bookingFormData.listOfCoApplicant,
            newContact
        ].map(contact => ({
            ...contact,
            isPrimaryPayer: contact.id === 1 // Set true only for id = 1, false for others
        }));
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
}