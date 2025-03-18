import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import searchPlots from '@salesforce/apex/customLookupCmpController.searchPlots';

export default class CustomLookupCmp extends LightningElement {
    @track searchTerm = '';
    @track plots = [];
    @track showOptions = false;
    searchTimeout;
    @track selectedRecordId;
    @api selectedPlotId;
    @api contactId; // Receiving contactId from parent
    @api plotId;    // Receiving plotId from parent
    @api phaseId;

    @api clearSelection() {
        debugger
        this.selectedRecordId = null;
        this.searchTerm = ''; // Clears input field
        this.plots = [];
        this.showOptions = false;
        console.log('Cleared selection for:', this.contactId, this.plotId);
    }

    handleSearch(event) {
        debugger
        try {
            const inputValue = event.target?.value || ''; // Ensure event.target.value is defined
            this.searchTerm = inputValue;

            clearTimeout(this.searchTimeout); // Debounce to avoid too many Apex calls
            this.searchTimeout = setTimeout(() => {
                try {
                    if (this.searchTerm.length > 0) {
                        this.fetchPlots(); // Ensure fetchPlots has error handling
                    } else {
                        this.plots = [];
                        this.showOptions = false;
                        if (!this.searchTerm) {
                            this.dispatchEvent(new CustomEvent('select', { // Dispatch event when searchTerm is blank
                                detail: { id: null, name: '' }
                            }));
                        }
                    }
                } catch (innerError) {
                    console.error('Error inside debounce function:', innerError);
                }
            }, 300);
        } catch (error) {
            console.error('Error in handleSearch:', error);
        }
    }

    fetchPlots() {
        debugger
        console.log('Fetching plots with searchTerm:', this.searchTerm, 'and phaseId:', this.phaseId);

        searchPlots({ searchTerm: this.searchTerm, phaseId: this.phaseId })
            .then(result => {
                console.log('Plots fetched:', result);
                this.plots = result;
                this.showOptions = result.length > 0;

                 if (result.length === 0) {
                this.showToast('Error', 'No plots found for phase.', 'error');
            }
            })
            .catch(error => {
                console.error('Error fetching plots:', JSON.stringify(error));
                this.plots = [];
                this.showOptions = false;
                this.showToast('Error', 'Failed to fetch plots. Please try again.', 'error');
            });
    }


    handleSelect(event) {
        try {
            const selectedId = event.currentTarget?.dataset?.id;
            const selectedName = event.currentTarget?.dataset?.name;

            if (!selectedId || !selectedName) {
                console.warn('Missing dataset values in handleSelect:', event.currentTarget?.dataset);
                return;
            }

            this.selectedRecordId = selectedId;
            this.searchTerm = selectedName;
            this.showOptions = false;

            this.dispatchEvent(new CustomEvent('select', {
                detail: { id: this.selectedRecordId, name: this.searchTerm } // Fire event with selected plot details
            }));
        } catch (error) {
            console.error('Error in handleSelect:', error);
        }
    }


    showDropdown() {
        this.showOptions = this.plots.length > 0;
    }

    hideDropdownWithDelay() {
        setTimeout(() => {
            this.showOptions = false;
        }, 200);
    }

    showToast(title, message, variant) {
    const event = new ShowToastEvent({
        title: title,
        message: message,
        variant: variant,
    });
    this.dispatchEvent(event);
}
}