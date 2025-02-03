import { LightningElement, track, wire } from 'lwc';
import getCurrentUserStatus from '@salesforce/apex/UserStatusController.getCurrentUserStatus';
import getStatusPicklistValues from '@salesforce/apex/UserStatusController.getStatusPicklistValues';
import updateUserStatus from '@salesforce/apex/UserStatusController.updateUserStatus';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class UserStatusScreenCmp extends LightningElement {
    @track status;
    @track selectedStatus;
    @track statusStyle;
    @track statusOptions = [];
    @track priorStatus;

    @wire(getCurrentUserStatus)
    wiredStatus({ error, data }) {
        if (data) {
            this.status = data;
            this.selectedStatus = data;
            this.priorStatus = data;
            this.setStatusStyle(data);
            console.log('status:', JSON.stringify(this.status));
        } else {
            console.log('Error fetching user status:', JSON.stringify(error));
        }
    }

    @wire(getStatusPicklistValues)
    wiredPicklistValues({ error, data }) {
        if (data) {
            this.statusOptions = data.map(value => ({ label: value, value: value }));
            console.log('Status Options:', JSON.stringify(this.statusOptions));
        } else if (error) {
            console.log('Error fetching picklist values:', error);
        }
    }

    setStatusStyle(status) {
        if (status === 'Online') {
            this.statusStyle = 'background-color: green; color: white; padding: 10px; border-radius: 5px;';
        } else if (status === 'Offline') {
            this.statusStyle = 'background-color: red; color: white; padding: 10px; border-radius: 5px;';
        } else {
            this.statusStyle = 'background-color: yellow; color: black; padding: 10px; border-radius: 5px;';
        }
    }

    handleStatusChange(event) {
        this.priorStatus = this.selectedStatus;
        this.selectedStatus = event.target.value;
    }

    async confirmStatusChange() {
        if (confirm(`Are you sure you want to change your status to ${this.selectedStatus}?`)) {
            try {
                if (this.priorStatus === this.selectedStatus) {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'Status is Already ' + this.selectedStatus,
                            variant: 'error'
                        })
                    );
                } else {
                    const result = await updateUserStatus({ newStatus: this.selectedStatus });
                    this.status = this.selectedStatus;
                    this.priorStatus = this.selectedStatus;
                    this.setStatusStyle(this.selectedStatus);
                    this.handleAuraChange();
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: result,
                            variant: 'success'
                        })
                    );
                }
            } catch (error) {
                console.error('Error updating status:', error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Failed to update status',
                        variant: 'error'
                    })
                );
            }
        }
    }
    handleAuraChange() {
    const valueChangeEvent = new CustomEvent("valuechange", {
        detail: { value: this.selectedStatus }
    });
    // Fire the custom event
    this.dispatchEvent(valueChangeEvent);
}

}