import { LightningElement, track, wire, api } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getContactsByOpportunity from '@salesforce/apex/sendPaymentLink.getContactsByOpportunity';
import { CloseActionScreenEvent } from 'lightning/actions';
export default class RefundPayment extends LightningElement {

    @api wireRecordId;

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.wireRecordId = currentPageReference.state.recordId;
        }
    }

}