import { LightningElement,api,wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin } from 'lightning/navigation';
import saveLeadQuoteRecords from '@salesforce/apex/leadQuoteGenerateController.saveLeadQuoteRecords';
import getOppDetails from '@salesforce/apex/leadQuoteGenerateController.getOppDetails';
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
                // this.getDetailsOfOpportunity(this.wireRecordId);
                this.getLeadQuoteDetails(this.wireRecordId);
            }
        }
    }

    getDetailsOfOpportunity(oppId){
        this.isLoading=true;
        getOppDetails({ oppId: oppId })
            .then(result => {
                this.unit = result.Unit__c || null;
                this.basePricePerSqFt = result.Unit__r?result.Unit__r?.Base_Price_per_Sq_Ft__c : null;
                this.leadId = result.Lead__c || null;
                if(this.unit==null && this.unit==undefined){
                    this.dispatchEvent(new CloseActionScreenEvent());
                    this.showToast('Error', 'Plot is not defined on opportunity.', 'error');
                    return;
                }
                this.error = undefined;
                console.log('Unit-->>',this.unit);
                console.log('base Price-->>',this.basePricePerSqFt);
                console.log('lead Id-->>',this.leadId);
                this.isLoading=false;
            }).catch(error => {
                this.isLoading=false;
                this.error = error;
                this.unit = undefined;
                this.basePricePerSqFt = undefined;
                console.error('Error fetching Opportunity details:', error);
                this.dispatchEvent(new CloseActionScreenEvent());
                this.showToast('Error', error.body.message, 'error');
            });
            this.isLoading=false;
    }

    getLeadQuoteDetails(oppId){
        this.isLoading=true;
        getLeadQuote({ oppId: oppId })
            .then(result => {
                if(result!=null && result!=undefined){
                    this.leadQuoteId=result.Id;
                    this.isLoading=false;
                    console.log('Lead Quote Id->',this.leadQuoteId);
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

    handleAddClick() {
        const newRecord = {
            plotRecordId: this.unit,
            basePricePerSqYard: this.basePricePerSqFt
        };
        this.records = [...this.records, newRecord];

        const quoteRecords = this.records.map(record => ({
            Opportunity__c: this.wireRecordId,
            Plot__c: record.plotRecordId,
            Base_Price_Per_Sq_Yard__c: record.basePricePerSqYard,
            Lead__c:this.leadId,
            Time_To_Pay_In_Days__c: 30
        }));
        this.saveQuote(quoteRecords);
    }

    saveQuote(quoteRecords) {
        this.isLoading = true;
        saveLeadQuoteRecords({ quoteRecords })
            .then((result) => {
                console.log('Qouote Records-->>', result);
                this.isLoading = false;
                this.records=[];
                this.dispatchEvent(new CloseActionScreenEvent());
                this.showToast('Success', 'Quote Generated Successfully.', 'success');
                result.forEach(record => {
                    this.navigateToQuote(record.Id);
                });
            })
            .catch(error => {
                this.isLoading = false;
                console.error('Error creating qouote records:', error);
                this.showToast('Error', error.body.message, 'error');
                this.dispatchEvent(new CloseActionScreenEvent());
            });
    }

    // navigateToQuote(quoteId) {
    //     this.records=[];
    //     const baseUrl = window.location.origin;
    //     const fullUrl = `${baseUrl}/lightning/r/Quote__c/${quoteId}/view`;
    //     window.open(fullUrl, '_blank');
    // }

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