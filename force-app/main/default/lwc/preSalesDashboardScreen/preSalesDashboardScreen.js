import { LightningElement, track } from 'lwc';
import getCustomSetting from '@salesforce/apex/PreSalesController.getCustomSetting';
import getUserData from '@salesforce/apex/PreSalesController.getUserData';
import updateUserStatus from '@salesforce/apex/PreSalesController.updateUserStatus';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class PreSalesDashboardScreen extends LightningElement {
    @track isLeadOverload = false; // Holds the toggle value
    @track userData = []; // Holds the user data for the data table
    @track columns = [
        { label: 'Name', fieldName: 'Name' },
        { label: 'Status', fieldName: 'Status__c', type: 'picklist', editable: true },
        { label: 'Capacity', fieldName: 'Capacity__c', type: 'number' },
        { label: 'Queue', fieldName: 'Queue' },
    ];
    @track isLoading = false; // Spinner control
    @track showUserTable = false; // Controls visibility of the table

    connectedCallback() {
        this.isLoading = true;
        this.loadCustomSetting();
    }

    loadCustomSetting() {
        getCustomSetting({ name: 'Lead OverLoad' })
            .then(result => {
                this.isLeadOverload = result === 'true';
            })
            .catch(error => {
                this.showToast('Error', 'Error loading custom setting', 'error');
                console.error(error);
            })
            .finally(() => {
                this.isLoading = false; // Hide spinner
            });
    }

    async handleToggleChange(event) {
        const isChecked = event.target.checked;

        // Show a confirmation dialog to the user
        const confirmation = await this.showConfirmation('Are you sure you want to Change the Lead Overload status?');

        if (confirmation) {
            this.isLeadOverload = isChecked;

            if (this.showUserTable) {
                this.loadUserData();
            }
        } else {
            // Reset the toggle back to its original state if user cancels
            event.target.checked = this.isLeadOverload;
        }
    }

    showConfirmation(message) {
        return new Promise(resolve => {
            const userResponse = window.confirm(message);
            resolve(userResponse); // Resolves true if user confirms, false otherwise
        });
    }

    handleShowUserData() {
        this.showUserTable = true;
        this.loadUserData();
    }

    loadUserData() {
        this.isLoading = true; // Show spinner
        setTimeout(() => { // Add a 1-second delay
            getUserData({ isLeadOverload: this.isLeadOverload })
                .then(result => {
                    this.userData = JSON.parse(result);
                    console.log('this.userData-->', JSON.stringify(this.userData));
                })
                .catch(error => {
                    this.showToast('Error', 'Error loading user data', 'error');
                    console.error(error);
                })
                .finally(() => {
                    this.isLoading = false; // Hide spinner
                });
        }, 1000);
    }

    handleSave(event) {
        this.isLoading = true; // Show spinner during save
        setTimeout(() => { // Add a 1-second delay
            const drafts = event.detail.draftValues.map(draft => {
                return { Id: draft.UserId, Status__c: draft.Status__c };
            });

            console.log('drafts:-', JSON.stringify(drafts));

            updateUserStatus({ updates: drafts })
                .then(() => {
                    this.showToast('Success', 'User data updated successfully', 'success');

                    // Update the local userData array with the new status
                    drafts.forEach(draft => {
                        const user = this.userData.find(user => user.UserId === draft.Id);
                        if (user) {
                            user.Status__c = draft.Status__c; // Update the local value
                        }
                    });

                    this.isLoading = false; // Hide spinner after update
                })
                .catch(error => {
                    this.showToast('Error', 'Error updating user data', 'error');
                    console.error(error);
                    this.isLoading = false;
                });
        }, 1000);
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title,
            message,
            variant
        });
        this.dispatchEvent(evt);
    }
}