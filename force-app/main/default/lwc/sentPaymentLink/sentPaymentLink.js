import { LightningElement, track, wire, api } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getContactsByOpportunity from '@salesforce/apex/sendPaymentLink.getContactsByOpportunity';
import createPaymentLink from '@salesforce/apex/EasyCollectPayment.createPaymentLink';
import insertPaymentRecord from '@salesforce/apex/EasyCollectPayment.insertPaymentRecord';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class SentPaymentLink extends LightningElement {

    selectedContactId;
    email;
    phone;
    amount;
    time='30';
    wireRecordId;
    contacts = [];
    isLoading = false;

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.wireRecordId = currentPageReference.state.recordId;
            this.fetchContacts();
        }
    }

    fetchContacts() {
        this.isLoading = true;
        getContactsByOpportunity({ opportunityId: this.wireRecordId })
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
                    this.displayMessage('Error', 'No contacts found for this Opportunity.', 'error');
                }
                this.isLoading = false;
            })
            .catch((error) => {
                this.isLoading = false;
                console.error('Error fetching contacts:', error);
                this.displayMessage('Error', error.body.message, 'error');
            });
    }

    handleContactSelection(event) {
        this.selectedContactId = event.detail.value;
        const selectedContact = this.contacts.find(
            (contact) => contact.value === this.selectedContactId
        );
        if (selectedContact) {
            this.email = selectedContact.email;
            this.phone = selectedContact.phone;
            this.name = selectedContact.label;
        }
    }

    handleEmailChange(event) {
        this.email = event.target.value;
    }

    handlePhoneChange(event) {
        this.phone = event.target.value;
    }

    handleAmountChange(event) {
        this.amount = event.target.value;
    }

    handleTimeChange(event) {
        this.time = event.target.value;
    }

    handleSendLink() {
        if (!this.selectedContactId) {
            this.displayMessage('Error', 'Please select a contact.', 'error');
            return;
        }

        if (!this.email || this.email.trim() === '') {
            this.displayMessage('Error', 'Email is mandatory to enter.', 'error');
            return;
        }

        if (!this.phone || this.phone.trim() === '') {
            this.displayMessage('Error', 'Phone number is mandatory to enter.', 'error');
            return;
        }

        if (this.phone.trim().length !== 10) {
            this.displayMessage('Error', 'Phone number must be exactly 10 digits.', 'error');
            return;
        }

        if (!this.amount || this.amount.trim() === '') {
            this.displayMessage('Error', 'Amount is mandatory to enter.', 'error');
            return;
        }

        if (!this.time || this.time.trim() === '') {
            this.displayMessage('Error', 'Time is mandatory to enter.', 'error');
            return;
        }

        this.sendPaymentLink();
    }

    sendPaymentLink() {
        this.isLoading = true;
        createPaymentLink({
            name: String(this.name),
            amount: String(this.amount),
            phone: String(this.phone),
            email: String(this.email),
            expiryTime: String(this.time),
            oppId: String(this.wireRecordId),
            contactId: String(this.selectedContactId)
        }).then(responseMap => {
                if(responseMap.isSuccess){
                    this.insertPayment(responseMap.response);
                }else{
                    this.displayMessage('Error', responseMap.error, 'error');
                }
                this.isLoading = false;
            })
            .catch((error) => {
                this.isLoading = false;
                this.displayMessage('Error', error.body.message, 'error');
                console.error('Error:', error);
            });
    }

    insertPayment(jsonData) {
        this.isLoading = true;
        insertPaymentRecord({ jsonData })
            .then(result => {
                this.displayMessage('Success', 'Payment link sent successfully!', 'success');
                this.isLoading = false;
                this.dispatchEvent(new CloseActionScreenEvent());
            })
            .catch(error => {
                console.error('Error inserting payment record::', error);
                this.isLoading = false;
                this.displayMessage('Error', error.body.message, 'error');
            });
    }

    displayMessage(title, message, type) {
        try {
            this.dispatchEvent(new ShowToastEvent({
                title: title,
                message: message,
                variant: type,
                mode: 'dismissable'
            }));
        } catch (error) {
            console.log('error in showing toast--->', error.stack)
        }
    }
}