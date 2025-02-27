import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
//import {CurrentPageReference} from 'lightning/navigation';
import getRelatedFilesByRecordId from '@salesforce/apex/clientSharedDocumentController.getRelatedFilesByRecordId';
import checkOpportunityContact from '@salesforce/apex/clientSharedDocumentController.checkOpportunityContact';

export default class ClientSharedDocument extends NavigationMixin(LightningElement) {
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
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title,
            message,
            variant,
        });
        this.dispatchEvent(event);
    }
}