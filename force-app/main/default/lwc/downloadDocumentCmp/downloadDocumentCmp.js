import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
//import {CurrentPageReference} from 'lightning/navigation';
import getRelatedFilesByRecordId from '@salesforce/apex/downloadDocumentCmpController.getRelatedFilesByRecordId';
import checkOpportunityContact from '@salesforce/apex/downloadDocumentCmpController.checkOpportunityContact';
import copyDocumentsToContact from '@salesforce/apex/downloadDocumentCmpController.copyDocumentsToContact';

export default class DownloadDocumentCmp extends NavigationMixin(LightningElement) {
    @api recordId;// Opportunity Id
    @track isLoading = true;
    contacts = [];
    @track selectedContactId;
    contactId;
    filesList =[]
    @track disableButton = true;

    @wire(getRelatedFilesByRecordId, {recordId: '$recordId'})
    wiredResult({data, error}){ 
        if(data){ 
            console.log(data)
            this.filesList = Object.keys(data).map(item=>({"label":data[item],
             "value": item,
             "url":`/sfc/servlet.shepherd/document/download/${item}`
            }))
            this.checkContactTagged();
        }
        if(error){ 
            console.log(error)
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
        this.disableButton = false;
        const selectedContact = this.contacts.find(
            (contact) => contact.value === this.selectedContactId
        );
        if (selectedContact) {;
            this.contactId = selectedContact.value;
        }
        console.log('this.selectedContactId-----------',this.selectedContactId);
    }
    previewFile(event){
        console.log(event.target.dataset.id)
        this[NavigationMixin.Navigate]({ 
            type:'standard__namedPage',
            attributes:{ 
                pageName:'filePreview'
            },
            state:{ 
                selectedRecordId: event.target.dataset.id
            }
        })
    }
    contactAddMethod(event){
        var documentId = event.target.dataset.id;
        copyDocumentsToContact({ contactId: this.selectedContactId, documentId: documentId })
                .then((data) => {
                    if (data = 'true'){
                        this.showToast('Success', 'uploaded to contact', 'success');
                    }else if(data = 'false') {
                        this.showToast('Error', 'No contacts found', 'error');
                    }else{
                        this.showToast('Error', data, 'error');
                    }
                })
                .catch((error) => {
                    console.error('Error uploading to contacts:', JSON.stringify(error));
                    this.showToast('Error', error?.body?.message, 'error');
                });
    }
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title,
            message,
            variant,
        });
        this.dispatchEvent(event);
    }
}