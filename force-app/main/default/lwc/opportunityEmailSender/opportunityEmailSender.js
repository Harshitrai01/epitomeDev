import { LightningElement, track, api, wire } from 'lwc';
import getContacts from '@salesforce/apex/OpportunityEmailController.getContacts';
import getDocuments from '@salesforce/apex/OpportunityEmailController.getDocuments';
import getEmailTemplates from '@salesforce/apex/OpportunityEmailController.getEmailTemplate';
import sendEmailWithAttachment from '@salesforce/apex/OpportunityEmailController.sendEmailWithAttachment';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation'; // Import NavigationMixin

// Use NavigationMixin
export default class OpportunityEmailSender extends NavigationMixin(LightningElement) {
    @api recordId;
    @track contactOptions = [];
    @track documents = [];
    @track emailTemplates = [];
    selectedContactId;
    selectedDocumentId;
    selectedTemplateId;
    contactEmail = '';
    emailBody = '';
    isLoading = false;

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            console.log('currentPageReference ', currentPageReference);
            this.recordId = currentPageReference.state.recordId;
        }
    }

    connectedCallback() {
        console.log('this.recordId--->', this.recordId);
        this.fetchContacts();
        this.fetchEmailTemplates();
    }

    async fetchContacts() {
        try {
            const data = await getContacts({ opportunityId: this.recordId });
            this.contactOptions = data.map(contact => ({
                label: contact.label,
                value: contact.value,
                email: contact.email
            }));
        } catch (error) {
            this.showToast('Error', 'Error fetching contacts', 'error');
        }
    }

    async handleContactChange(event) {
        this.selectedContactId = event.detail.value;

        // Find the selected contact and retrieve its email
        const selectedContact = this.contactOptions.find(contact => contact.value === this.selectedContactId);
        console.log('selectedContact-->' + JSON.stringify(selectedContact));
        if (selectedContact && selectedContact.email !== null) {
            this.contactEmail = selectedContact.email; // Update email if available
        } else {
            this.contactEmail = ''; // Clear email if not available
        }

        // Reset dependent fields when the contact changes
        this.selectedDocumentId = null;
        this.selectedTemplateId = null;
        this.emailBody = '';
        this.documents = [];

        // Fetch Documents and check if available
        await this.fetchDocuments();
    }

    async fetchDocuments() {
        if (this.selectedContactId) {
            this.isLoading = true;
            try {
                const data = await getDocuments({ contactId: this.selectedContactId });

                if (!data || data.length === 0) {
                    throw new Error('No documents available for the selected contact.');
                }

                this.documents = data.map(doc => ({ label: doc.Title, value: doc.Id }));
            } catch (error) {
                this.showToast('Error', error.message || 'Error fetching documents', 'error');
            } finally {
                this.isLoading = false;
            }
        }
    }

    handleDocumentSelect(event) {
        this.selectedDocumentId = event.detail.value;

        // Find the selected document
        const selectedDocument = this.documents.find(doc => doc.value === this.selectedDocumentId);
        if (selectedDocument) {
            // Extract the prefix from the document title (e.g., "AOS" from "AOS_Letter")
            const prefix = selectedDocument.label.split('_')[0];

            // Find the corresponding email template
            const matchingTemplate = this.emailTemplates.find(template => template.label.includes(prefix));
            if (matchingTemplate) {
                this.selectedTemplateId = matchingTemplate.value;
                this.emailBody = matchingTemplate.body.replace(/\{!([\w.]+)\}/g, '<b><<< $1 >>></b>');
            } else {
                // Reset emailBody and selectedTemplateId if no matching template is found
                this.selectedTemplateId = null;
                this.emailBody = '';
                this.showToast('Warning', `No matching email template found for prefix: ${prefix}`, 'warning');
            }
        } else {
            // Reset emailBody and selectedTemplateId if no document is found
            this.selectedTemplateId = null;
            this.emailBody = '';
        }
    }

    async fetchEmailTemplates() {
        try {
            const data = await getEmailTemplates({ recordId: this.recordId });
            this.emailTemplates = data.map(template => ({
                label: template.name,
                value: template.id,
                body: template.mergedHtmlValue
            }));
            console.log('this.emailTemplates------->',JSON.stringify(this.emailTemplates));
        } catch (error) {
            this.showToast('Error', 'Error fetching email templates', 'error');
        }
    }

    handleTemplateSelect(event) {
        this.selectedTemplateId = event.detail.value;
        const selectedTemplate = this.emailTemplates.find(t => t.value === this.selectedTemplateId);
        if (selectedTemplate) {
            // Updated regex to include dots (.) in the capturing group
            this.emailBody = selectedTemplate.body.replace(/\{!([\w.]+)\}/g, '<b><<< $1 >>></b>');
            console.log('Updated Email Body:', this.emailBody);
        }
    }

    handleEmailChange(event) {
        // Updated regex to include dots (.) in the capturing group
        this.emailBody = event.target.value;
        console.log('Updated Email Body on Change:', this.emailBody);
    }

    async handleSendEmail() {
        if (!this.selectedContactId) {
            this.showToast('Error', 'Please select a contact', 'error');
            return;
        }
        if (!this.contactEmail) {
            this.showToast('Error', 'Selected contact does not have an email address', 'error');
            return;
        }
        if (!this.selectedDocumentId) {
            this.showToast('Error', 'Please select a document', 'error');
            return;
        }
        if (!this.emailBody) {
            this.showToast('Error', 'Email body cannot be empty', 'error');
            return;
        }

        this.isLoading = true;
        try {
            await sendEmailWithAttachment({
                opportunityId: this.recordId,
                contactId: this.selectedContactId,
                documentId: this.selectedDocumentId,
                emailTemplateId: this.selectedTemplateId,
                emailBody: this.emailBody
            });
            this.showToast('Success', 'Email sent successfully', 'success');

            // Navigate back to the Opportunity record page after sending the email
            this.navigateToOpportunity();
        } catch (error) {
            this.showToast('Error', 'Failed to send email', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    navigateToOpportunity() {
        // Use NavigationMixin to navigate to the Opportunity record page
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                actionName: 'view'
            }
        });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}