import { LightningElement,api,wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin } from 'lightning/navigation';
import getLeadQuote from '@salesforce/apex/leadQuoteGenerateController.getLeadQuote';
export default class ChnagePrice extends NavigationMixin(LightningElement) {

    @api wireRecordId;
    isLoading = false;

    unit;
    basePricePerSqFt;
    leadId;
    leadQuoteId;
    error;
    records=[];

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.wireRecordId = currentPageReference.state.recordId;
            if(this.wireRecordId!=null){
                this.getLeadQuoteDetails(this.wireRecordId);
            }
        }
    }

    getLeadQuoteDetails(oppId){
        this.isLoading=true;
        getLeadQuote({ oppId: oppId })
            .then(result => {
                if(result!=null && result!=undefined){
                    this.leadQuoteId=result.Id;
                    this.isLoading=false;
                    this.dispatchEvent(new CloseActionScreenEvent());
                    this.navigateToQuote(this.leadQuoteId);
                }else{
                    this.showToast('Error', 'No prior finalized quote is found on opportunity.', 'error');
                    return;
                }
                this.isLoading=false;
            }).catch(error => {
                this.error = error;
                console.error('Error fetching Opportunity details:', error);
                this.showToast('Error', error.body.message, 'error');
                this.isLoading=false;
                this.dispatchEvent(new CloseActionScreenEvent());
            });
    }

    navigateToQuote(quoteId) {
            this[NavigationMixin.GenerateUrl]({
                type: 'standard__component',
                attributes: {
                    componentName: 'c__quotationCostingSheet',
                },
                state: {
                    c__quoteId: quoteId, // Pass the Quote Id as a parameter
                    c__editable:true
                },
            }).then(generatedUrl => {
                window.open(generatedUrl);
            });
        }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant,
                mode: 'dismissable'
            })
        );
    }

}