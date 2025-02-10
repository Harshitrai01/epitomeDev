import { LightningElement, wire} from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import checkOpportunityContact from '@salesforce/apex/KYCVerificationController.checkOpportunityContact';
import getDocumentsByContactId from '@salesforce/apex/sendAOSDocumentController.getDocumentsByContactId';
import sendDocumentEmail from '@salesforce/apex/sendAOSDocumentController.sendDocumentEmail';

export default class SendAOSDocumentScreen extends LightningElement {
    recordId; // Opportunity Id
    contactId
    contacts = [];
    selectedContactId
    documents = []; // Store documents
    documentOptions = []; // Store document options for picklist
    selectedDocumentId;
    isLoading = true;
    isContactTagged = true;
    sendEnable = true;

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId;
            this.checkContactTagged();
        }
    }
    async checkContactTagged() {
        try {
            this.isLoading = true;
            checkOpportunityContact({ opportunityId: this.recordId })
                .then((data) => {
                    if (data && data.length > 0) {
                        this.contacts = data.map((contact) => ({
                            label: contact.Name,
                            value: contact.Id,
                            email: contact.Email,
                            phone: contact.Phone,
                        }));
                    } else {
                        this.contacts = [];
                        this.showToast('Error', 'No contacts found for this Opportunity.', 'error');
                    }
                    this.isLoading = false;
                })
                .catch((error) => {
                    this.isLoading = false;
                    console.error('Error fetching contacts:', JSON.stringify(error));
                    this.showToast('Error', error?.body?.message, 'error');
                });
        } catch (error) {
            this.showToast('Error', 'Contact not found on Opportunity.', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    handleContactSelection(event) {
        this.selectedContactId = event.detail.value;
        const selectedContact = this.contacts.find(
            (contact) => contact.value === this.selectedContactId
        );
        if (selectedContact) {;
            this.contactId = selectedContact.value;
            this.fetchDocuments();
            this.isContactTagged = false;
        }
        // this.isContactTagged = false
    }

    // Fetch documents for the selected contact
    fetchDocuments() {
        if (this.selectedContactId) {
            this.isLoading = true;
            getDocumentsByContactId({ contactId: this.selectedContactId })
                .then((data) => {
                    if (data) {
                        this.documents = data;
                        // Map documents into options for the picklist
                        this.documentOptions = data.map(doc => ({
                            label: doc.Title,
                            value: doc.Id,
                        }));
                    } else {
                        this.showToast('Error', 'No documents found for this contact.', 'error');
                    }
                    this.isLoading = false;
                })
                .catch((error) => {
                    this.isLoading = false;
                    this.showToast('Error', 'Error fetching documents: ' + error.body.message, 'error');
                });
        }
    }

    handleDocumentTypeChange(event) {
        this.selectedDocumentId = event.detail.value;
        this.sendEnable = false
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title,
            message,
            variant,
        });
        this.dispatchEvent(event);
    }

    async handleSend() {
        this.isLoading = true;
        sendDocumentEmail({ contactId: this.selectedContactId, documentId: this.selectedDocumentId, opportunityId: this.recordId })
        .then((result) => {
            this.showToast('Success', result, 'success');
            this.handleCancel(); // Close the screen after sending
        })
        .catch((error) => {
            this.isLoading = false;
            this.showToast('Error', error.body.message, 'error');
        });
    }
    
    handleCancel(){
        this.isLoading = false;
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}