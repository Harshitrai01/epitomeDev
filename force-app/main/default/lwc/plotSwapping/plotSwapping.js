import { LightningElement,api,wire } from 'lwc';
import { getRecord} from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import saveOpportunity from '@salesforce/apex/leadQuoteGenerateController.saveOpportunity';
import saveLeadQuoteRecords from '@salesforce/apex/leadQuoteGenerateController.saveLeadQuoteRecords';

const FIELDS = [
    'Unit__c.Name',
    'Unit__c.Unit_Code__c',
    'Unit__c.Plot_Facing__c',
    'Unit__c.Id',
    'Unit__c.Plot_Size__c',
    'Unit__c.Status__c',
    'Unit__c.Base_Price_per_Sq_Ft__c',
    'Unit__c.Plot_Price__c'
    ];

const PLOTFIELDS = [
    'Unit__c.Phase__c',
    'Unit__c.Phase__r.Name'
];

export default class PlotSwapping extends LightningElement {

    showUnitDetails=false;
    @api wireRecordId;
    selectedRecordId;
    phaseName;
    records=[];
    isLoading=false;

    recordFilter = {
       criteria: [
           {
               fieldPath: 'Status__c',
               operator: 'eq',
               value: 'Available'
           }
       ]
   };

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.wireRecordId = currentPageReference.state.recordId;
        }
    }

    @wire(getRecord, { recordId: '$selectedRecordId', fields: FIELDS })
    unit;

    @wire(getRecord, { recordId: '$selectedRecordId', fields: PLOTFIELDS })
    leadRecord({ error, data }) {
        if (data) {
            this.phaseName = data.fields.Phase__r?.value?.fields?.Name?.value || '';
        } else if (error) {
            this.phaseName='';
            console.error('Error fetching plot phase record:', error);
        }
    }

    handleRecordSelection(event) {
        this.selectedRecordId = event.detail.recordId;
        this.showUnitDetails = this.selectedRecordId != null;
    }

    handleAddClick(){
        this.isLoading=true;
        const newRecord = {
                id: this.wireRecordId,
                plotRecordId: this.selectedRecordId,
                basePricePerSqYard: this.unit.data.fields.Base_Price_per_Sq_Ft__c.value,
                plotName:this.unit.data.fields.Name.value
            };
        this.records = [...this.records, newRecord];
        // const oppRecords = this.records.map(record => ({
        //         Id: this.wireRecordId,
        //         Unit__c: record.plotRecordId
        // }));
        const quoteRecords = this.records.map(record => ({
                    Opportunity__c: this.wireRecordId,
                    Plot__c: record.plotRecordId,
                    Base_Price_Per_Sq_Yard__c:record.basePricePerSqYard,
                    Time_To_Pay_In_Days__c:30
                }));
        this.saveQuote(quoteRecords);
        // console.log('Record To Save-->',oppRecords);
        // saveOpportunity({oppRecords})
        //     .then((result) => {
        //         console.log('Opp Records-->>',result);
                
                
        //         this.isLoading=false;
        //     })
        //     .catch(error => {
        //         this.isLoading=false;
        //         this.records=[];
        //         console.error('Error updating quote records', error);
        //         this.showToast('Error',error.body.message,'error');
        //     });
    }

    saveQuote(quoteRecords){
        this.isLoading=true;
        saveLeadQuoteRecords({quoteRecords})
            .then((result) => {
                console.log('Qouote Records-->>',result);
                this.isLoading=false;
                this.dispatchEvent(new CloseActionScreenEvent());
                this.showToast('Success','Quote Generated Successfully.','success');
                result.forEach(record => {
                        this.navigateToQuote(record.Id);
                });
            })
            .catch(error => {
                this.isLoading=false;
                console.error('Error creating qouote records:', error);
                this.showToast('Error',error.body.message,'error');
            });
    }

    navigateToQuote(quoteId) {
        const baseUrl = window.location.origin;
        const fullUrl = `${baseUrl}/lightning/r/Quote__c/${quoteId}/view`;
        console.log('URL-->>',fullUrl);
        window.open(fullUrl, '_blank');
    }
    

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant,
                mode:'dismissable'
            })
        );
    }

}