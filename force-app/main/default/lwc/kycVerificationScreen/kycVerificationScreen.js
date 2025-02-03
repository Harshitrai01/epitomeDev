import { LightningElement, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import checkOpportunityContact from '@salesforce/apex/KYCVerificationController.checkOpportunityContact';
import updateOpportunityKYCStatus from '@salesforce/apex/KYCVerificationController.updateOpportunityKYCStatus';

export default class KycVerificationScreen extends LightningElement {
    recordId; // Opportunity Id 
    contactId 
    aadhaarFileId;
    panFileId;
    otherDocFileId;
    contacts = [];
    acceptedFormats = ['.pdf', '.png', '.jpg', '.jpeg'];
    isContactTagged = true;
    isLoading = true;

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
            this.isContactTagged = false;
        }
    }

    
    // Handle Aadhaar Upload
    handleAadhaarUploadFinished(event) {
        // if (!this.isContactTagged) return;
        const uploadedFiles = event.detail.files;
        this.aadhaarFileId = uploadedFiles[0].documentId;
        this.showToast('Success', 'Aadhaar uploaded successfully!', 'success');
    }

    // Handle PAN Upload
    handlePanUploadFinished(event) {
        // if (!this.isContactTagged) return;
        const uploadedFiles = event.detail.files;
        this.panFileId = uploadedFiles[0].documentId;
        this.showToast('Success', 'PAN uploaded successfully!', 'success');
        
    }

    // Handle Other Document Upload
    handleOtherDocUploadFinished(event) {
        // if (!this.isContactTagged) return;
        const uploadedFiles = event.detail.files;
        this.otherDocFileId = uploadedFiles[0].documentId;
        this.showToast('Success', 'Other document uploaded successfully!', 'success');
    }

    // Handle Save Button Click
    async handleSave() {
        if (!this.aadhaarFileId || !this.panFileId) {
            this.showToast('Error', 'Please upload all required documents.', 'error');
            return;
        }

        try {
            await updateOpportunityKYCStatus({ opportunityId: this.recordId, contactId: this.contactId });
            this.showToast('Success', 'KYC Verification is in Progress.', 'success');
            window.location.reload();
            this.handleCancel();
        } catch (error) {
            console.log("106 "+error);
            this.showToast('Error', error?.body?.message, 'error');
        }
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title,
            message,
            variant,
        });
        this.dispatchEvent(event);
    }
    
    handleCancel(){
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}