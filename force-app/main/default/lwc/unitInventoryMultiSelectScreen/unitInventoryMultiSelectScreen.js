import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class UnitInventoryMultiSelectScreen extends LightningElement {
    // Public properties passed in from the parent
    @api startRow;
    @api endRow;
    @api startColumn;
    @api endColumn;
    @api excludeRowStart;
    @api excludeRowEnd;
    @api excludeColumnStart;
    @api excludeColumnEnd;

    // Computed property to disable the Select button if any field is missing.
    get isSelectDisabled() {
        // Adjust the condition if "0" is a valid value.
        return !(this.startRow && this.endRow && this.startColumn && this.endColumn);
    }

    /**
     * Handler for field changes. Updates the corresponding property based on the field label.
     * Dispatches a custom event so the parent can also react to the changes if needed.
     */
    handleFieldChange(event) {
        const fieldLabel = event.target.label;
        const value = event.target.value;
        switch (fieldLabel) {
            case 'Start Row':
                this.startRow = value;
                break;
            case 'End Row':
                this.endRow = value;
                break;
            case 'Start Column':
                this.startColumn = value.toUpperCase();
                break;
            case 'End Column':
                this.endColumn = value.toUpperCase();
                break;
            case 'Exclude Row Start':
                this.excludeRowStart = value;
                break;
            case 'Exclude Row End':
                this.excludeRowEnd = value;
                break;
            case 'Exclude Column Start':
                this.excludeColumnStart = value.toUpperCase();
                break;
            case 'Exclude Column End':
                this.excludeColumnEnd = value.toUpperCase();
                break;
            default:
                break;
        }
        console.log('--->',value);
        
        // Optionally, dispatch a custom event so that the parent is informed of the change
        this.handleSubmit();
        // Optionally, you can also dispatch a field change event if needed
        // this.dispatchEvent(new CustomEvent('fieldchange', {
        //     detail: { field: fieldLabel, value }
        // }));
    }

    // **NEW FUNCTION: Dispatches event with all selected values**
    handleSubmit() {
        const selectedValues = {
            startRow: this.startRow,
            endRow: this.endRow,
            startColumn: this.startColumn,
            endColumn: this.endColumn,
            excludeRowStart: this.excludeRowStart,
            excludeRowEnd: this.excludeRowEnd,
            excludeColumnStart: this.excludeColumnStart,
            excludeColumnEnd: this.excludeColumnEnd
        };

        // Dispatch custom event with data
        this.dispatchEvent(new CustomEvent('inputchanged', {
            detail: selectedValues
        }));

        // Show success toast
        this.showToast('Success', 'Selection submitted successfully!', 'success');
    }

    dispatchSelectDisabledChange() {
        this.dispatchEvent(new CustomEvent('selectdisablechange', {
            detail: { isSelectDisabled: this.isSelectDisabled }
        }));
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}