import { LightningElement, track, api, wire } from 'lwc';
import getContacts from '@salesforce/apex/OpportunityEmailController.getContacts';
import getDocuments from '@salesforce/apex/OpportunityEmailController.getDocuments';
import getEmailTemplates from '@salesforce/apex/OpportunityEmailController.getEmailTemplate';
import sendEmailWithAttachment from '@salesforce/apex/OpportunityEmailController.sendEmailWithAttachment';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation';

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
        try {
            if (currentPageReference) {
                this.recordId = currentPageReference.state.recordId;
            }
        } catch (error) {
            console.error('Error fetching state parameters:', error);
        }
    }

    connectedCallback() {
        try {
            this.fetchContacts();
            this.fetchEmailTemplates();
        } catch (error) {
            console.error('Error in connectedCallback:', error);
        }
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
            console.error('Error fetching contacts:', error);
        }
    }

    async handleContactChange(event) {
        try {
            this.selectedContactId = event.detail.value;
            const selectedContact = this.contactOptions.find(contact => contact.value === this.selectedContactId);
            this.contactEmail = selectedContact?.email || '';

            this.selectedDocumentId = null;
            this.selectedTemplateId = null;
            this.emailBody = '';
            this.documents = [];

            await this.fetchDocuments();
        } catch (error) {
            console.error('Error handling contact change:', error);
        }
    }

    async fetchDocuments() {
        if (this.selectedContactId) {
            this.isLoading = true;
            try {
                const data = await getDocuments({ contactId: this.selectedContactId });
                this.documents = data.length ? data.map(doc => ({ label: doc.Title, value: doc.Id })) : [];
            } catch (error) {
                this.showToast('Error', 'Error fetching documents', 'error');
                console.error('Error fetching documents:', error);
            } finally {
                this.isLoading = false;
            }
        }
    }

    handleDocumentSelect(event) {
        try {
            this.selectedDocumentId = event.detail.value;
            const selectedDocument = this.documents.find(doc => doc.value === this.selectedDocumentId);
            if (selectedDocument) {
                const prefix = selectedDocument.label.split('_')[0];
                const matchingTemplate = this.emailTemplates.find(template => template.label.includes(prefix));
                this.selectedTemplateId = matchingTemplate?.value || null;
                this.emailBody = matchingTemplate ? matchingTemplate.body.replace(/\{!([\w.]+)\}/g, '<b><<< $1 >>></b>') : '';
                if (!matchingTemplate) {
                    this.showToast('Warning', `No matching email template found for prefix: ${prefix}`, 'warning');
                }
            }
        } catch (error) {
            console.error('Error handling document select:', error);
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
        } catch (error) {
            this.showToast('Error', 'Error fetching email templates', 'error');
            console.error('Error fetching email templates:', error);
        }
    }

    async handleSendEmail() {
        if (!this.selectedContactId || !this.contactEmail || !this.selectedDocumentId || !this.emailBody) {
            this.showToast('Error', 'All fields must be selected and email body cannot be empty', 'error');
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
            this.navigateToOpportunity();
        } catch (error) {
            this.showToast('Error', 'Failed to send email', 'error');
            console.error('Error sending email:', error);
        } finally {
            this.isLoading = false;
        }
    }

    navigateToOpportunity() {
        try {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.recordId,
                    actionName: 'view'
                }
            });
        } catch (error) {
            console.error('Error navigating to Opportunity:', error);
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}