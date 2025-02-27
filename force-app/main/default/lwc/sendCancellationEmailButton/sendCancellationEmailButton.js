import { LightningElement, wire, api } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import sendEmailForCancellation from '@salesforce/apex/SendCancellationEmail.sendEmailForCancellation';
import { CloseActionScreenEvent } from 'lightning/actions';
export default class sendCancellationEmailButton extends LightningElement {

    @api wireRecordId;
    isLoading=false;

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.wireRecordId = currentPageReference.state.recordId;
            this.submit();
        }
    }

    submit() {
        this.isLoading = true;
        sendEmailForCancellation({ oppId: this.wireRecordId })
            .then((data) => {
                this.displayMessage('Success', 'Email For Cancellation Sent Succesfully', 'success');
                this.isLoading = false;
                this.dispatchEvent(new CloseActionScreenEvent());
            })
            .catch((error) => {
                this.isLoading = false;
                console.error('Error fetching payments:', error);
                this.displayMessage('Error', error.body.message, 'error');
                this.dispatchEvent(new CloseActionScreenEvent());
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