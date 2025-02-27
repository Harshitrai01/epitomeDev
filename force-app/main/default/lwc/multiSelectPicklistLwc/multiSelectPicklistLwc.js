import { LightningElement, api, track } from 'lwc';

export default class MultiSelectPicklistLwc extends LightningElement {
    @api user;
    @api leadSourceOptions;
    @track selectedValues = [];

    connectedCallback() {
        // Initialize selected values if userSources exist
        this.selectedValues = [...(this.user.userSources || [])];
    }

    handleChange(event) {
        this.selectedValues = event.detail.value;
        console.log('Selected Values:', JSON.stringify(this.selectedValues));
        
        // Dispatch event with updated values
        this.dispatchEvent(new CustomEvent('leadsourcechange', {
            detail: {
                value: this.selectedValues,
                userId: this.user.userId
            }
        }));
    }
}