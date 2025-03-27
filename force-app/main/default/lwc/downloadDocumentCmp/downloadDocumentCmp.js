import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { CurrentPageReference } from 'lightning/navigation';
import checkOpportunityContact from '@salesforce/apex/downloadDocumentCmpController.checkOpportunityContact';
import getRelatedFilesByContactId from '@salesforce/apex/downloadDocumentCmpController.getRelatedFilesByContactId';

export default class DownloadDocumentCmp extends NavigationMixin(LightningElement) {
    @track isLoading = true;
    @track contacts = [];
    @track selectedContactId;
    @track filesList = [];
    @track disableButton = true;
    @track showNoDataMessage = false;
    @track recordId; // Opportunity Id

    /**
     * Fetches the current page reference to extract the recordId.
     */
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference && currentPageReference.state.recordId) {
            this.recordId = currentPageReference.state.recordId;
            this.checkContactTagged(); // Fetch contacts once the recordId is available
        }
    }

    /**
     * Fetches contacts associated with the Opportunity.
     */
    async checkContactTagged() {
        try {
            this.isLoading = true;
            const contacts = await checkOpportunityContact({ opportunityId: this.recordId });
            if (contacts && contacts.length > 0) {
                this.contacts = contacts.map(contact => ({
                    label: contact.Name,
                    value: contact.Id,
                    email: contact.Email,
                    phone: contact.Phone,
                }));
            } else {
                this.contacts = [];
                this.showToast('Error', 'No contacts found for this Opportunity.', 'error');
            }
        } catch (error) {
            this.showToast('Error', error.body?.message || 'An error occurred while fetching contacts.', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    /**
     * Handles contact selection and fetches documents for the selected contact.
     * @param {Event} event - The event triggered when a contact is selected.
     */
    handleContactSelection(event) {
        this.selectedContactId = event.detail.value;
        this.disableButton = false;
        this.fetchContactDocuments();
    }

    /**
     * Fetches documents for the selected contact.
     */
    async fetchContactDocuments() {
        try {
            this.isLoading = true;
            const files = await getRelatedFilesByContactId({ contactId: this.selectedContactId, oppId: this.recordId });
            console.log('files---->', files);
            if (files && files.length > 0) {
                this.filesList = files.map(file => ({
                    label: file.title,
                    value: file.contentDocumentId,
                    documentType: file.documentType,
                    url: `/sfc/servlet.shepherd/document/download/${file.ContentDocumentId}`
                }));
                this.showNoDataMessage = false;
            } else {
                this.filesList = [];
                this.showNoDataMessage = true;
            }
        } catch (error) {
            console.error('Error fetching contact documents:', error);
            this.showToast('Error', error.body?.message || 'An error occurred while fetching contact documents.', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    /**
     * Handles file preview.
     * @param {Event} event - The event triggered when the preview button is clicked.
     */
    previewFile(event) {
        console.log('event--->', JSON.stringify(event));
        try {
            const documentId = event.target.dataset.id;
            this[NavigationMixin.Navigate]({
                type: 'standard__namedPage',
                attributes: {
                    pageName: 'filePreview'
                },
                state: {
                    selectedRecordId: documentId
                }
            });
        } catch (error) {
            console.error('Error fetching contact documents:', error);
            this.showToast('Error', error.body?.message || 'An error occurred while previewing the document.', 'error');
        }
    }

    /**
     * Handles file download.
     * @param {Event} event - The event triggered when the download button is clicked.
     */
    downloadFile(event) {
        console.log('event--->', JSON.stringify(event));

        // Extract the documentId from the event
        const documentId = event.target.dataset.id;
        console.log('documentId---->', documentId);

        // Find the file in the filesList
        const file = this.filesList.find(file => file.value === documentId);
        console.log('file--->', JSON.stringify(file));

        if (file) {
            // Construct the URL dynamically if it is undefined or invalid
            let fileUrl = file.url;
            if (!fileUrl || fileUrl.includes('undefined')) {
                // Update the URL with the correct documentId
                fileUrl = `/sfc/servlet.shepherd/document/download/${documentId}`;
            }

            console.log('Updated fileUrl--->', fileUrl);

            // Open the file in a new tab
            if (fileUrl) {
                window.open(fileUrl, '_blank');
            } else {
                this.showToast('Error', 'Invalid file URL.', 'error');
            }
        } else {
            this.showToast('Error', 'File not found.', 'error');
        }
    }

    /**
     * Displays a toast message.
     * @param {string} title - The title of the toast.
     * @param {string} message - The message of the toast.
     * @param {string} variant - The variant of the toast (e.g., 'success', 'error').
     */
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title,
            message,
            variant,
        });
        this.dispatchEvent(event);
    }
}