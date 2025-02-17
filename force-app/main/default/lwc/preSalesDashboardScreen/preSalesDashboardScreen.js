import { LightningElement, track } from 'lwc';
import getCustomSetting from '@salesforce/apex/PreSalesController.getCustomSetting';
import updateUserStatus from '@salesforce/apex/PreSalesController.updateUserStatus';
import updateCustomSetting from '@salesforce/apex/PreSalesController.updateCustomSetting';
import getUsersData from '@salesforce/apex/PreSalesController.getUsersData';
import getPicklistValues from '@salesforce/apex/PreSalesController.getPicklistValues';
// import updateUserData from '@salesforce/apex/PreSalesController.updateUserData';
import MAX_CAPACITY from "@salesforce/label/c.Lead_Assignment_Capacity";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import scheduleBatch from '@salesforce/apex/PreSalesController.scheduleBatch';
import deleteScheduledJob from '@salesforce/apex/PreSalesController.deleteScheduledJob';



export default class PreSalesDashboardScreen extends LightningElement {
    @track userList = [];
    @track maxCapacity = MAX_CAPACITY;
    @track isPreSalesActive = false;
    @track isSalesActive = false;
    @track preSalesMasterUserData = [];
    @track SalesMasterUserData = [];
    @track preSalesUserDataShow = [];
    @track salesUserDataShow = [];
    @track preSalesDraftValues = [];
    @track salesDraftValues = [];
    @track isLoading = false;
    @track isPreSalesUpdated = false;  // Flag to show Save/Cancel for Pre-Sales
    @track isSalesUpdated = false;     // Flag to show Save/Cancel for Sales
    statusOptions = [];
    @track isShowModal = false;
    @track notificationMinutes = 0;
    @track sendToManager = false;
    @track sendNotification = false;
    @track isDisabled = false;
    connectedCallback() {
        this.isLoading = true;
        this.loadCustomSettings();
        this.loadPicklistValues();
        console.log('this.maxCapacity-->', this.maxCapacity);
    }

    loadPicklistValues() {
        getPicklistValues()
            .then((result) => {
                this.statusOptions = result.map((status) => {
                    return { label: status, value: status };
                });
            })
            .catch((error) => {
                console.error('Error fetching picklist values:', error);
            });
    }

    fetchData(queueName) {
        return getUsersData({ queueName: queueName })
            .then(result => result)
            .catch(error => {
                console.error('Error fetching Data', error);
                return [];
            });
    }

    loadCustomSettings() {
        Promise.all([
            getCustomSetting({ name: 'Pre-Sales Assignment' }),
            getCustomSetting({ name: 'Sales Assignment' }),
            getCustomSetting({ name: 'Send Notification' }),
            getCustomSetting({ name: 'Minutes' }),
            getCustomSetting({ name: 'Send to Manager' }),
        ])
            .then(async ([preSalesResult, salesResult, sendNotificationResult, minutesResult, sendToManagerResult]) => {
                this.isPreSalesActive = preSalesResult === 'true';
                this.isSalesActive = salesResult === 'true';

                if (this.isPreSalesActive) {
                    this.preSalesUserDataShow = await this.fetchData('Pre_Sales_Queue');
                    this.preSalesUserDataShow = await this.preSalesUserDataShow.map(user => {
                        return {
                            ...user,
                            styleColor: 'background-color:none;' // Default style color
                        };
                    });
                    this.preSalesMasterUserData = [...this.preSalesUserDataShow];  // Store original data
                }

                if (this.isSalesActive) {
                    this.salesUserDataShow = await this.fetchData('Sales_Queue');
                    this.salesUserDataShow = await this.salesUserDataShow.map(user => {
                        return {
                            ...user,
                            styleColor: 'background-color:none;' // Default style color
                        };
                    });
                    this.SalesMasterUserData = [...this.salesUserDataShow];  // Store original data
                }
                console.log('sendNotificationResult->', sendNotificationResult);
                console.log('sendToManagerResult->', sendToManagerResult);
                console.log('minutesResult->', minutesResult);
                this.sendNotification = sendNotificationResult === 'true';
                this.sendToManager = sendToManagerResult === 'true';
                this.notificationMinutes = minutesResult;

            })
            .catch(error => {
                this.showToast('Error', 'Error loading custom settings', 'error');
                console.error(error);
            })
            .finally(() => {
                if (this.sendNotification) {
                    this.isDisabled = false;
                } else {
                    this.isDisabled = true;
                }
                this.isLoading = false;
            });
    }

    async handlePreSalesToggleChange(event) {
        try {
            const isChecked = event.target.checked;

            // Ensure at least one toggle is active
            if (!isChecked && !this.isSalesActive) {
                this.showToast('Error', 'At least one toggle must be active', 'error');
                event.target.checked = this.isPreSalesActive; // Revert to previous state
                return;
            }

            // Update state and custom settings
            this.isPreSalesActive = isChecked;
            await this.updateCustomSetting('Pre-Sales Assignment', isChecked);
            // await this.updateUserLeadAssignmentStatus('Pre_Sales_Queue', false);
            // Fetch data if toggle is enabled
            if (isChecked) {
                const data = await this.fetchData('Pre_Sales_Queue');
                this.preSalesUserDataShow = data;
                this.preSalesMasterUserData = [...data];
            } else {
                this.preSalesUserDataShow = []; // Clear data when toggled off
            }
        } catch (error) {
            console.error('Error in handlePreSalesToggleChange:', error);
            this.showToast('Error', 'An error occurred while processing Pre-Sales toggle.', 'error');
        } finally {
            console.log('this.preSalesUserDataShow--> ', JSON.stringify(this.preSalesUserDataShow));
            console.log('this.preSalesMasterUserData--> ', JSON.stringify(this.preSalesMasterUserData));
            this.isLoading = false;
        }
    }

    async handleSalesToggleChange(event) {
        try {
            const isChecked = event.target.checked;

            // Ensure at least one toggle is active
            if (!isChecked && !this.isPreSalesActive) {
                this.showToast('Error', 'At least one toggle must be active', 'error');
                event.target.checked = this.isSalesActive; // Revert to previous state
                return;
            }

            // Update state and custom settings
            this.isSalesActive = isChecked;
            await this.updateCustomSetting('Sales Assignment', isChecked);
            // await this.updateUserLeadAssignmentStatus('Sales_Queue', false);
            // Fetch data if toggle is enabled
            if (isChecked) {
                const data = await this.fetchData('Sales_Queue');
                this.salesUserDataShow = data;
                this.salesMasterUserData = [...data];
            } else {
                this.salesUserDataShow = []; // Clear data when toggled off
            }
        } catch (error) {
            console.error('Error in handleSalesToggleChange:', error);
            this.showToast('Error', 'An error occurred while processing Sales toggle.', 'error');
        } finally {
            console.log('this.salesUserDataShow--> ', JSON.stringify(this.salesUserDataShow));
            console.log('this.salesMasterUserData--> ', JSON.stringify(this.salesMasterUserData));
            this.isLoading = false;
        }
    }

    async updateCustomSetting(settingName, value) {
        this.isLoading = true;
        try {
            await updateCustomSetting({ name: settingName, value: value.toString() });
            //this.showToast('Success', `${settingName} updated successfully`, 'success');
        } catch (error) {
            //this.showToast('Error', `Error updating ${settingName}`, 'error');
            console.error('Error in updateCustomSetting:', error);
        } finally {
            //this.isLoading = false;
        }
    }

    // async updateUserLeadAssignmentStatus(queueName, value) {
    //     this.isLoading = true;
    //     try {
    //         await updateUserData({ queueName: queueName, value: value });
    //         this.showToast('Success', `Queue Users Data updated successfully`, 'success');
    //     } catch (error) {
    //         this.showToast('Error', `Error updating `, 'error');
    //         console.error('Error in updateCustomSetting:', error);
    //     } finally {
    //         this.isLoading = false;
    //     }
    // }


    handlePreSalesStatusChange(event) {
        const userId = event.target.dataset.id;
        const newStatus = event.target.value;

        // Update the show data
        const userIndex = this.preSalesUserDataShow.findIndex((user) => user.userId === userId);
        if (userIndex !== -1) {
            console.log('userId-->', userId);
            const updatedUser = { ...this.preSalesUserDataShow[userIndex], status: newStatus, userChange: true, styleColor: 'background-color:lightyellow;' };

            this.preSalesUserDataShow = [
                ...this.preSalesUserDataShow.slice(0, userIndex),
                updatedUser,
                ...this.preSalesUserDataShow.slice(userIndex + 1)
            ];

            // Add or update the data in the draft array
            const draftIndex = this.preSalesDraftValues.findIndex((draft) => draft.userId === userId);
            if (draftIndex !== -1) {
                // Update existing draft
                this.preSalesDraftValues[draftIndex] = updatedUser;
            } else {
                // Add new draft
                this.preSalesDraftValues = [...this.preSalesDraftValues, updatedUser];
            }

            this.isPreSalesUpdated = true; // Flag set to show save/cancel buttons
        }
    }

    handleSalesStatusChange(event) {
        const userId = event.target.dataset.id;
        const newStatus = event.target.value;

        // Update the show data
        const userIndex = this.salesUserDataShow.findIndex((user) => user.userId === userId);
        if (userIndex !== -1) {
            const updatedUser = { ...this.salesUserDataShow[userIndex], status: newStatus, userChange: true, styleColor: 'background-color:lightyellow;' };

            this.salesUserDataShow = [
                ...this.salesUserDataShow.slice(0, userIndex),
                updatedUser,
                ...this.salesUserDataShow.slice(userIndex + 1)
            ];

            // Add or update the data in the draft array
            const draftIndex = this.salesDraftValues.findIndex((draft) => draft.userId === userId);
            if (draftIndex !== -1) {
                // Update existing draft
                this.salesDraftValues[draftIndex] = updatedUser;
            } else {
                // Add new draft
                this.salesDraftValues = [...this.salesDraftValues, updatedUser];
            }

            this.isSalesUpdated = true; // Flag set to show save/cancel buttons
        }
    }

    handlePreSalesCapacityChange(event) {
        const userId = event.target.dataset.id;
        const capacity = parseInt(event.target.value, 10);
        try {
            let errorMessage = '';

            // Validation
            if (isNaN(capacity)) {
                errorMessage = 'Capacity must be a valid number.';
            } else if (capacity < 0) {
                errorMessage = 'Capacity cannot be less than zero.';
            } else if (capacity > this.maxCapacity) {
                errorMessage = `Capacity cannot exceed the maximum limit of ${this.maxCapacity}.`;
            }

            if (errorMessage) {
                this.showToast('Error', errorMessage, 'error');
                //return; // Exit the method if there's an error
            }

            // Find the user index in the preSalesUserDataShow array
            const userIndex = this.preSalesUserDataShow.findIndex((user) => user.userId === userId);
            if (userIndex !== -1) {
                console.log('userIndex-->', userIndex);
                // Update user data
                const updatedUser = {
                    ...this.preSalesUserDataShow[userIndex],
                    capacity: capacity,
                    userChange: true,
                    styleColor: 'background-color:lightyellow;',
                };

                this.preSalesUserDataShow = [
                    ...this.preSalesUserDataShow.slice(0, userIndex),
                    updatedUser,
                    ...this.preSalesUserDataShow.slice(userIndex + 1),
                ];

                const draftIndex = this.preSalesDraftValues.findIndex((draft) => draft.userId === userId);
                if (draftIndex !== -1) {
                    this.preSalesDraftValues[draftIndex] = updatedUser;
                    console.log('updatedUser--->', JSON.stringify(updatedUser));
                } else {
                    // Add new draft
                    this.preSalesDraftValues = [...this.preSalesDraftValues, updatedUser];
                }

                this.isPreSalesUpdated = true; // Flag to show save/cancel buttons
            } else {
                console.log('ni aaya');
                console.log('userId-->', userId);
            }

        } catch (error) {
            console.error('Error in handlePreSalesCapacityChange:', JSON.stringify(error));
            this.showToast('Error', 'An unexpected error occurred. Please try again.', 'error');
        }
    }

    handleSalesCapacityChange(event) {
        const userId = event.target.dataset.id;
        const capacity = parseInt(event.target.value, 10);
        try {
            let errorMessage = '';

            // Validation
            if (isNaN(capacity)) {
                errorMessage = 'Capacity must be a valid number.';
            } else if (capacity < 0) {
                errorMessage = 'Capacity cannot be less than zero.';
            } else if (capacity > this.maxCapacity) {
                errorMessage = `Capacity cannot exceed the maximum limit of ${this.maxCapacity}.`;
            }

            if (errorMessage) {
                this.showToast('Error', errorMessage, 'error');
                //return; // Exit the method if there's an error
            }

            // Find the user index in the preSalesUserDataShow array
            const userIndex = this.salesUserDataShow.findIndex((user) => user.userId === userId);
            if (userIndex !== -1) {
                console.log('userIndex-->', userIndex);
                // Update user data
                const updatedUser = {
                    ...this.salesUserDataShow[userIndex],
                    capacity: capacity,
                    userChange: true,
                    styleColor: 'background-color:lightyellow;',
                };

                this.salesUserDataShow = [
                    ...this.salesUserDataShow.slice(0, userIndex),
                    updatedUser,
                    ...this.salesUserDataShow.slice(userIndex + 1),
                ];

                const draftIndex = this.salesDraftValues.findIndex((draft) => draft.userId === userId);
                if (draftIndex !== -1) {
                    this.salesDraftValues[draftIndex] = updatedUser;
                    console.log('updatedUser--->', JSON.stringify(updatedUser));
                } else {
                    // Add new draft
                    this.salesDraftValues = [...this.salesDraftValues, updatedUser];
                }

                this.isSalesUpdated = true; // Flag to show save/cancel buttons
            } else {
                console.log('ni aaya');
                console.log('userId-->', userId);
            }

        } catch (error) {
            console.error('Error in handleSalesCapacityChange:', error);
            this.showToast('Error', 'An unexpected error occurred. Please try again.', 'error');
        }
    }

    handleSelectAllPreSales() {
        this.preSalesUserDataShow = this.preSalesUserDataShow.map((user) => {
            return { ...user, leadAssignment: true, userChange: true, styleColor: 'background-color:lightyellow;' }; // Mark as changed for UI update
        });

        this.preSalesDraftValues = this.preSalesUserDataShow;

        this.isPreSalesUpdated = true;

        console.log('Updated Pre-Sales User Data:', JSON.stringify(this.preSalesUserDataShow));
    }

    handleSelectAllSales() {
        this.salesUserDataShow = this.salesUserDataShow.map((user) => {
            return { ...user, leadAssignment: true, userChange: true, styleColor: 'background-color:lightyellow;' }; // Mark as changed for UI update
        });

        this.salesDraftValues = this.salesUserDataShow;

        this.isSalesUpdated = true;

        console.log('Updated Sales User Data:', JSON.stringify(this.salesUserDataShow));
    }

    handlePreSalesLeadAssignmentChange(event) {
        const userId = event.target.dataset.id;
        const leadAssign = event.target.checked;
        try {

            // Find the user index in the preSalesUserDataShow array
            const userIndex = this.preSalesUserDataShow.findIndex((user) => user.userId === userId);
            if (userIndex !== -1) {
                console.log('userIndex-->', userIndex);
                console.log('leadAssign-->', leadAssign);
                // Update user data
                const updatedUser = {
                    ...this.preSalesUserDataShow[userIndex],
                    leadAssignment: leadAssign,
                    userChange: true,
                    styleColor: 'background-color:lightyellow;',
                };

                this.preSalesUserDataShow = [
                    ...this.preSalesUserDataShow.slice(0, userIndex),
                    updatedUser,
                    ...this.preSalesUserDataShow.slice(userIndex + 1),
                ];

                const draftIndex = this.preSalesDraftValues.findIndex((draft) => draft.userId === userId);
                if (draftIndex !== -1) {
                    this.preSalesDraftValues[draftIndex] = updatedUser;
                    console.log('updatedUser--->', JSON.stringify(updatedUser));
                } else {
                    // Add new draft
                    this.preSalesDraftValues = [...this.preSalesDraftValues, updatedUser];
                }

                this.isPreSalesUpdated = true; // Flag to show save/cancel buttons
            } else {
                console.log('ni aaya');
                console.log('userId-->', userId);
            }

        } catch (error) {
            console.error('Error in handlePreSalesCapacityChange:', JSON.stringify(error));
            this.showToast('Error', 'An unexpected error occurred. Please try again.', 'error');
        }
    }

    handleSalesLeadAssignmentChange(event) {
        const userId = event.target.dataset.id;
        const leadAssign = event.target.checked;
        try {

            const userIndex = this.salesUserDataShow.findIndex((user) => user.userId === userId);
            if (userIndex !== -1) {
                console.log('userIndex-->', userIndex);
                const updatedUser = {
                    ...this.salesUserDataShow[userIndex],
                    leadAssignment: leadAssign,
                    userChange: true,
                    styleColor: 'background-color:lightyellow;'
                };

                this.salesUserDataShow = [
                    ...this.salesUserDataShow.slice(0, userIndex),
                    updatedUser,
                    ...this.salesUserDataShow.slice(userIndex + 1),
                ];

                const draftIndex = this.salesDraftValues.findIndex((draft) => draft.userId === userId);
                if (draftIndex !== -1) {
                    this.salesDraftValues[draftIndex] = updatedUser;
                    console.log('updatedUser--->', JSON.stringify(updatedUser));
                } else {
                    this.salesDraftValues = [...this.salesDraftValues, updatedUser];
                }

                this.isSalesUpdated = true; // Flag to show save/cancel buttons
            } else {
                console.log('ni aaya');
                console.log('userId-->', userId);
            }

        } catch (error) {
            console.error('Error in handleSalesCapacityChange:', error);
            this.showToast('Error', 'An unexpected error occurred. Please try again.', 'error');
        }
    }


    async handlePreSalesSave() {
        this.isLoading = true;
        let hasInvalidCapacity = false;
        try {
            const updatedPreSalesData = await this.preSalesDraftValues.map((draft) => {
                const userRow = this.preSalesUserDataShow.find(user => user.userId === draft.userId);
                if (draft.capacity < 0 || draft.capacity > this.maxCapacity) {
                    hasInvalidCapacity = true;
                    userRow.styleColor = 'background-color: lightpink;';
                } else {
                    // Reset the row's background color
                    userRow.styleColor = 'background-color: lightyellow;';
                }

                return {
                    Id: draft.userId,
                    Status__c: draft.status,
                    Capacity__c: draft.capacity,
                    Pre_Sales_Lead_Assignment__c: draft.leadAssignment,
                }
            });
            if (hasInvalidCapacity) {
                this.showToast('Error', 'Please correct the capacity values (0 ≤ Capacity ≤ Max Capacity).', 'error');
                return;
            } else {
                console.log('4');
            }

            console.log('Pre-Sales Save:', JSON.stringify(this.preSalesUserDataShow));
            console.log('Pre-Sales Draft Save:', JSON.stringify(updatedPreSalesData));

            await updateUserStatus({ userStatusData: JSON.stringify(updatedPreSalesData) });

            this.preSalesUserDataShow = this.preSalesUserDataShow.map((user) => {
                if (user.userChange) {
                    return { ...user, userChange: false, styleColor: 'background-color: none;' };
                }
                return user;
            });
            this.preSalesMasterUserData = [];
            this.showToast('Success', 'Pre-Sales data saved successfully', 'success');
            this.preSalesDraftValues = [];
            this.isPreSalesUpdated = false;
        } catch (error) {
            console.error('Error saving Pre-Sales data:', error);
            this.showToast('Error', 'Failed to save Pre-Sales data', 'error');
        } finally {
            if (!(hasInvalidCapacity)) {
                this.preSalesMasterUserData = [...this.preSalesUserDataShow];
            }
            setTimeout(() => {
                this.isLoading = false;
            }, 1000);
        }
    }

    async handleSalesSave() {
        this.isLoading = true;
        let hasInvalidCapacity = false;
        try {

            const updatedSalesData = this.salesDraftValues.map((draft) => {
                const userRow = this.salesUserDataShow.find(user => user.userId === draft.userId);

                if (draft.capacity < 0 || draft.capacity > this.maxCapacity) {
                    hasInvalidCapacity = true;
                    userRow.styleColor = 'background-color: lightpink;';
                } else {
                    userRow.styleColor = 'background-color: lightyellow;';
                }

                return {
                    Id: draft.userId,
                    Status__c: draft.status,
                    Capacity__c: draft.capacity,
                    Pre_Sales_Lead_Assignment__c: draft.leadAssignment,
                };
            });

            if (hasInvalidCapacity) {
                this.showToast('Error', 'Please correct the capacity values (0 ≤ Capacity ≤ Max Capacity).', 'error');
                return;
            }

            console.log('Sales Save:', JSON.stringify(this.salesUserDataShow));
            console.log('Sales Draft Save:', JSON.stringify(updatedSalesData));

            await updateUserStatus({ userStatusData: JSON.stringify(updatedSalesData) });

            this.salesUserDataShow = this.salesUserDataShow.map((user) => {
                if (user.userChange) {
                    return { ...user, userChange: false, styleColor: 'background-color: none;' }; // Update userChange to false
                }
                return user;
            });
            this.SalesMasterUserData = [];
            this.showToast('Success', 'Sales data saved successfully', 'success');
            this.salesDraftValues = []; // Clear draft values
            this.isSalesUpdated = false; // Reset the flag
        } catch (error) {
            console.error('Error saving Sales data:', error);
            this.showToast('Error', 'Failed to save Sales data', 'error');
        } finally {
            if (!(hasInvalidCapacity)) {
                this.SalesMasterUserData = [...this.salesUserDataShow];
            }
            setTimeout(() => {
                this.isLoading = false; // Turn off loader
            }, 1000);
        }
    }

    async handleSave(event) {
        this.isLoading = true;
        let hasInvalidCapacity = false;
        const usertype = event.target.dataset.id;

        const validUserTypes = {
            presales: {
                draftValues: this.preSalesDraftValues,
                showValues: this.preSalesUserDataShow,
                clearDrafts: () => {
                    this.preSalesDraftValues = [];
                    this.preSalesMasterUserData = [];
                }
            },
            sales: {
                draftValues: this.salesDraftValues,
                showValues: this.salesUserDataShow,
                clearDrafts: () => {
                    this.salesDraftValues = [];
                    this.SalesMasterUserData = [];
                }
            }
        };

        if (!validUserTypes[usertype]) {
            console.log('Invalid user type');
            return;
        }

        const { draftValues, showValues, clearDrafts } = validUserTypes[usertype];

        try {
            const updatedData = draftValues.map((draft) => {
                const userRow = showValues.find(user => user.userId === draft.userId);
                const isInvalid = draft.capacity < 0 || draft.capacity > this.maxCapacity;
                userRow.styleColor = isInvalid ? 'background-color: lightpink;' : 'background-color: lightyellow;';
                hasInvalidCapacity ||= isInvalid;
                return {
                    Id: draft.userId,
                    Status__c: draft.status,
                    Capacity__c: draft.capacity,
                    Pre_Sales_Lead_Assignment__c: draft.leadAssignment,
                };
            });
            if (hasInvalidCapacity) {
                this.showToast('Error', 'Please correct the capacity values (0 ≤ Capacity ≤ Max Capacity).', 'error');
                return;
            }
            await updateUserStatus({ userStatusData: JSON.stringify(updatedData) });

            clearDrafts();
            if (usertype === 'presales') {
                this.isPreSalesUpdated = false;
                this.preSalesUserDataShow.forEach(user => {
                    user.userChange = false;
                    user.styleColor = 'background-color: none;';
                });
            } else if (usertype === 'sales') {
                this.isSalesUpdated = false;
                this.salesUserDataShow.forEach(user => {
                    user.userChange = false;
                    user.styleColor = 'background-color: none;';
                });
            }
            this.showToast('Success', 'Data saved successfully', 'success');
        } catch (error) {
            console.error('Error saving data:', error);
            this.showToast('Error', 'Failed to save data', 'error');
        } finally {
            if (!hasInvalidCapacity) {
                if (usertype === 'presales') {
                    this.preSalesMasterUserData = this.preSalesUserDataShow;
                } else if (usertype === 'sales') {
                    this.salesMasterUserData = this.salesUserDataShow;
                }
                setTimeout(() => {
                    this.isLoading = false;
                }, 1000);
            }
        }
    }


    handleCancel(event) {
        this.isLoading = true;
        const userType = event.target.dataset.id;
        console.log('userType:', userType);
        try {
            if (userType === 'presales') {
                this.preSalesUserDataShow = [...this.preSalesMasterUserData];
                this.isPreSalesUpdated = false;
            } else if (userType === 'sales') {
                this.salesUserDataShow = [...this.salesMasterUserData];
                this.isSalesUpdated = false;
            } else {
                console.error('Invalid userType');
                this.showToast('Error', 'Invalid action.', 'error');
            }
        } catch (error) {
            console.error('Error during refresh:', error);
            this.showToast('Error', 'Failed to Cancel data.', 'error');
        } finally {
            this.isLoading = false;
        }
    }


    async handleRefresh() {
        this.isLoading = true;

        try {
            // if (this.isPreSalesActive) {
            //     this.preSalesUserDataShow = [];
            //     this.preSalesUserDataShow = await this.fetchData('Pre_Sales_Queue');
            // }

            // if (this.isSalesActive) {
            //     this.salesUserDataShow = [];
            //     this.salesUserDataShow = await this.fetchData('Sales_Queue');
            // }
            this.loadCustomSettings();

            this.showToast('Success', 'Data refreshed successfully!', 'success');
        } catch (error) {
            console.error('Error during refresh:', error);
            this.showToast('Error', 'Failed to refresh data.', 'error');
        } finally {
            setTimeout(() => {
                this.isLoading = false;
            }, 1000); // 1-second delay

        }
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title,
            message,
            variant,
        });
        this.dispatchEvent(evt);
    }


    showModalBox() {
        this.isShowModal = true;
    }
    hideModalBox() {
        this.isShowModal = false;
        this.isLoading = false;
    }
    handleMinutesChange(event) {
        this.notificationMinutes = event.target.value;
    }
    handleSendManagerNotificationToggleChange(event) {
        this.sendToManager = event.target.checked;
    }
    handleSendNotificationToggleChange(event) {
        this.sendNotification = event.target.checked;
        if (this.sendNotification) {
            this.isDisabled = false;
            this.notificationMinutes = 0;
            this.sendToManager = false;
            // scheduleBatch({ minuteInterval: this.notificationMinutes });
        } else {
            this.isDisabled = true;
            deleteScheduledJob();
        }
    }
    async handleSaveCustomSetting() {
    try {
        await this.updateCustomSetting('Send Notification', this.sendNotification);
        await this.updateCustomSetting('Send to Manager', this.sendToManager);
        await this.updateCustomSetting('Minutes', this.notificationMinutes);

        if (this.sendNotification) {
            const result = await scheduleBatch({ minuteInterval: this.notificationMinutes });
            this.showToast('Success', result, 'success');
        }
    } catch (error) {
        this.showToast('Error', error.body?.message || 'An error occurred', 'error');
    } finally {
        this.showToast('Success', 'Settings saved successfully', 'success');
        this.hideModalBox();
    }
}


}