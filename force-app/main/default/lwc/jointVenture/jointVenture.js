import { LightningElement, wire, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import saveJointVenture from '@salesforce/apex/bookingFormController.saveJointVenture';
import getContactDetails from '@salesforce/apex/bookingFormController.getContactDetails';
import getOpportunityAccountId from '@salesforce/apex/bookingFormController.getOpportunityAccountId';
import getContactsByAccountId from '@salesforce/apex/bookingFormController.getContactsByAccountId';

export default class JointVenture extends NavigationMixin(LightningElement) {
    @track contacts = [];
    isDuplicateContact = false;
    @api recordId;
    accountId;
    showComponent = false;
    @track recordPickerKey = 0;
    isLoading = false;
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
    activeSections = ['A'];

    @track bookingFormData = {
        listOfCoApplicant: []
    }

    value = 'No';
    get options() {
        return [
            { label: 'Yes', value: 'Yes' },
            { label: 'No', value: 'No' },

        ];
    }

    connectedCallback() {
        this.showComponent = true;
        this.addContact();
    }

    @wire(getOpportunityAccountId, { opportunityId: '$recordId' })
    wiredOpportunity({ error, data }) {
        if (data) {
            if (data.response.isSuccess && data.listOfOpportunityR) {
                this.accountId = data.listOfOpportunityR[0].AccountId ? data.listOfOpportunityR[0].AccountId : '';
                if (this.accountId) {
                    this.fetchContacts();
                } else {
                    this.showToast('Error', 'Account Id not found', 'error');
                    this.handleCancelClick();
                }
                console.log('Fetched AccountId:', this.accountId);
                console.log('this.recordFilter', this.recordFilter);
            } else {
                this.showToast('Error', data.response.body, 'error');
                this.handleCancelClick();
            }
        } else if (error) {
            console.error('Error fetching AccountId:', error);
            this.showToast('Error', error.message, 'error');
            this.handleCancelClick();
        }
    }

    fetchContacts() {
        console.log('Fetching contacts for Account:', this.accountId);
        getContactsByAccountId({ accountId: this.accountId })
            .then((data) => {
                if (data && data.length > 0) {
                    this.contacts = data.map((contact) => ({
                        label: contact.LastName, // Show Last Name in combobox
                        value: contact.Id        // Store Contact Id as value
                    }));
                    console.log('Contacts loaded:', this.contacts);
                } else {
                    this.contacts = [];
                    this.showToast('Error', 'No contacts found for this Account.', 'error');
                }
            })
            .catch(error => {
                console.error('Error fetching contacts:', error);
            });
    }

    handleValueChange(event) {
        try {
            this.isDuplicateContact = false;
            const contactId = parseInt(event.target.dataset.contactId, 10); // Convert contactId to integer
            const fieldName = event.target.name; // Extract field name (e.g., contactName, contactEmail)
            const fieldValue = event.target.value; // Extract field value

            if (!contactId || !fieldName) {
                throw new Error('Missing contact ID or field name.');
            }

            // Find the contact in the list
            const contactIndex = this.bookingFormData.listOfCoApplicant.findIndex(contact => contact.id === contactId);

            if (contactIndex === -1) {
                throw new Error(`Contact with ID ${contactId} not found.`);
            }

            // Update the contact's field value
            this.bookingFormData.listOfCoApplicant[contactIndex] = {
                ...this.bookingFormData.listOfCoApplicant[contactIndex],
                [fieldName]: fieldValue
            };

        } catch (error) {
            console.error('Error in handleValueChange:', error.message);
        }
    }

    handlePrimaryPayerChange(event) {
        const selectedContactId = parseInt(event.target.dataset.contactId, 10);

        this.bookingFormData.listOfCoApplicant = this.bookingFormData.listOfCoApplicant.map(contact => ({
            ...contact,
            isPrimaryPayer: contact.id === selectedContactId // Only the selected contact gets `true`
        }));

        console.log("Primary Payer ID:", selectedContactId);
    }

    // Add a new contact
    addContact() {
        // this.isLoading=true;
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
            showAddMoreButton: false,// Initially empty plots for this contact
            isPrimaryPayer: false
        };
        // Add the new contact to the listOfCoApplicant array with the existing list
        this.bookingFormData.listOfCoApplicant = [...this.bookingFormData.listOfCoApplicant, newContact];
        console.log('first Contact :: ' + JSON.stringify(this.bookingFormData));
        setTimeout(() => {
            this.isLoading = false;
        }, 1000);
        this.updateContactButtons();
    }

    removeContact(event) {
        const contactId = parseInt(event.target.dataset.contactId, 10); // Get the ID of the contact

        this.bookingFormData.listOfCoApplicant = this.bookingFormData.listOfCoApplicant.filter(
            contact => contact.id !== contactId
        );
        this.updateContactButtons();
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

    handleContactCheckboxChange(event) {
        const contactId = parseInt(event.target.dataset.contactId);
        let value = event.detail.value;

        let isChecked = true;
        if (value == 'No') {
            isChecked = false;
        } else if (value == 'Yes') {
            isChecked = true;
        }

        let updatedCoApplicants = this.bookingFormData.listOfCoApplicant.map(coApplicant => {
            if (coApplicant.id === contactId) {
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

        this.bookingFormData.listOfCoApplicant = this.bookingFormData.listOfCoApplicant.map(contact => {
            if (contact.id === contactId) {
                return { ...contact, isContactExist: !isChecked }; // Toggle isContactExist
            }
            return contact;
        });
    }

    handleContactRecordSelection(event) {
        debugger
        this.isDuplicateContact = false;
        const contactId = event.detail.value;
        console.log('contactId------> : ', contactId);
        const contactIndex = parseInt(event.target.dataset.contactId);

        if (contactId) {
            if (this.isDuplicateContactSelected(event, contactId)) return;
            getContactDetails({ contactId })
                .then(contact => {
                    this.isDuplicateContact = false;
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
            this.isDuplicateContact = false;
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
        try {

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
        } catch (error) {
            console.error('Error in isDuplicateContactSelected:', error);
            this.showToast('Error', 'Error in isDuplicateContactSelected', 'error');
            return true; // Prevent execution of further logic
        }
    }


    handleSave(event) {
        try {

            console.log('aaaaaaaaaaa : ', this.accountId);
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
            this.collectFormData(); // Collect data when Save is clicked
        } catch (error) {
            console.error('Error in handleSave:', error);
            this.showToast('Error', 'An unexpected error occurred. Please try again.', 'error');
            this.isLoading = false;
        }
    }

    collectFormData() {
        console.log('asdfgh', JSON.stringify(this.bookingFormData, null, 2));
        saveJointVenture({ bookingFormData: JSON.stringify(this.bookingFormData), opportunityId: this.recordId, accountId: this.accountId })
            .then(result => {

                if (result.isSuccess) {

                    console.log('this.isLoading', this.isLoading);
                    this.showToast('Success', 'Data created successfully', 'success');
                    this.navigateToRecordPage();
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

    handleSpinner(event) {
        // this.isLoading = event.detail.isLoading;
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