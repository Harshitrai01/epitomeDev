import { LightningElement, track, wire } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { closeQuickAction } from 'lightning/uiRecordApi';
export default class SelectInventoryWizard extends NavigationMixin(LightningElement) {

    @track recordId
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId;
            this[NavigationMixin.Navigate]({
                type: 'standard__component',
                attributes: {
                    componentName: "c__InventoryMatrixWizard"
                },
                state: {
                    c__recordId: this.recordId,
                }
            });
        }
    }

    connectedCallback() {
        try {

        } catch (error) {
            console.log('error--->', error.stack)
        }
    }

    hideModalBox(event) {
        try {
            closeQuickAction();
        } catch (error) {
            console.log('error--->', error.stack)
        }
    }
}