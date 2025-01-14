import { LightningElement, track } from 'lwc';
import getCustomSetting from '@salesforce/apex/PreSalesController.getCustomSetting';
import getUserData from '@salesforce/apex/PreSalesController.getUserData';
import updateUserStatus from '@salesforce/apex/PreSalesController.updateUserStatus';
import updateCustomSetting from '@salesforce/apex/PreSalesController.updateCustomSetting';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class PreSalesDashboardScreen extends LightningElement {
    @track isPreSalesActive = false;
    @track isSalesActive = false;
    @track preSalesUserData = [];
    @track salesUserData = [];
    @track preSalesDraftValues = [];
    @track salesDraftValues = [];
    @track columns = [
        { label: 'Name', fieldName: 'Name' },
        { label: 'Status', fieldName: 'Status__c', editable: true },
    ];
    @track isLoading = false;

    connectedCallback() {
        this.isLoading = true;
        this.loadCustomSettings();
    }

    loadCustomSettings() {
        Promise.all([
            getCustomSetting({ name: 'Pre-Sales Assignment' }),
            getCustomSetting({ name: 'Sales Assignment' }),
        ])
            .then(([preSalesResult, salesResult]) => {
                this.isPreSalesActive = preSalesResult === 'true';
                this.isSalesActive = salesResult === 'true';

            })
            .catch(error => {
                this.showToast('Error', 'Error loading custom settings', 'error');
                console.error(error);
            })
            .finally(() => {
                if (this.isPreSalesActive) {
                    this.loadUserData('Pre_Sales_Queue', data => (this.preSalesUserData = data));
                    //console.log('this.preSalesUserData--->',JSON.stringify(this.preSalesUserData));
                }
                if (this.isSalesActive) {
                    this.loadUserData('Sales_Queue', data => (this.salesUserData = data));
                    //console.log('this.salesUserData--->',JSON.stringify(this.salesUserData));
                }
                this.isLoading = false;

            });
    }

    handlePreSalesToggleChange(event) {
        const isChecked = event.target.checked;
        if (!isChecked && !this.isSalesActive) {
            this.showToast('Error', 'At least one toggle must be active', 'error');
            event.target.checked = this.isPreSalesActive;
            return;
        }
        this.isPreSalesActive = isChecked;
        this.updateCustomSetting('Pre-Sales Assignment', isChecked);
        if (isChecked) {
            this.loadUserData('Pre_Sales_Queue', data => (this.preSalesUserData = data));
            console.log('this.preSalesUserData--->',JSON.stringify(this.preSalesUserData));
        }
    }

    handleSalesToggleChange(event) {
        const isChecked = event.target.checked;
        if (!isChecked && !this.isPreSalesActive) {
            this.showToast('Error', 'At least one toggle must be active', 'error');
            event.target.checked = this.isSalesActive;
            return;
        }
        this.isSalesActive = isChecked;
        this.updateCustomSetting('Sales Assignment', isChecked);
        if (isChecked) {
            this.loadUserData('Sales_Queue', data => (this.salesUserData = data));
            console.log('this.salesUserData--->',JSON.stringify(this.salesUserData));
        }
    }

    updateCustomSetting(settingName, value) {
        this.isLoading = true;
        updateCustomSetting({ name: settingName, value: value.toString() })
            .then(() => {
                this.showToast('Success', `${settingName} updated successfully`, 'success');
            })
            .catch(error => {
                this.showToast('Error', `Error updating ${settingName}`, 'error');
                console.error(error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }


    loadUserData(queueName, callback) {
        this.isLoading = true;
        getUserData({ queueName })
            .then(result => {
                callback(JSON.parse(result));
                console.log('result--->',JSON.stringify(result));

            })
            .catch(error => {
                this.showToast('Error', `Error loading ${queueName} user data`, 'error');
                console.error(error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleSavePreSales(event) {
        this.handleSave(event, this.preSalesDraftValues, 'Pre_Sales_Queue');
    }

    handleSaveSales(event) {
        this.handleSave(event, this.salesDraftValues, 'Sales_Queue');
    }

    handleSave(event, draftValues, queueName) {
        draftValues.push(...event.detail.draftValues);
        if (queueName === 'Pre_Sales_Queue' && this.salesDraftValues.length > 0) {
            this.showToast('Error', 'Cannot save data for both queues simultaneously', 'error');
            return;
        }
        if (queueName === 'Sales_Queue' && this.preSalesDraftValues.length > 0) {
            this.showToast('Error', 'Cannot save data for both queues simultaneously', 'error');
            return;
        }

        this.isLoading = true;
        console.log('draftValues-->',JSON.stringify(draftValues));
        updateUserStatus({ userStatusData: JSON.stringify(draftValues) })
            .then(() => {
                this.showToast('Success', `${queueName} data updated successfully`, 'success');
            })
            .catch(error => {
                this.showToast('Error', `Error updating ${queueName} data`, 'error');
                console.error(error);
            })
            .finally(() => {
                this.isLoading = false;
                draftValues.length = 0; // Clear the draft values after save
            });
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title,
            message,
            variant,
        });
        this.dispatchEvent(evt);
    }
}