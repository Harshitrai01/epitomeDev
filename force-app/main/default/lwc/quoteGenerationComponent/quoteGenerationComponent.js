import { LightningElement,api,wire } from 'lwc';
import { getRecord} from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import getLeadDetails from '@salesforce/apex/leadQuoteGenerateController.getLeadDetails';
import saveLeadPlotRecords from '@salesforce/apex/leadQuoteGenerateController.saveLeadPlotRecords';
import saveLeadQuoteRecords from '@salesforce/apex/leadQuoteGenerateController.saveLeadQuoteRecords';

const FIELDS = [
    'Unit__c.Name',
    'Unit__c.Unit_Code__c',
    'Unit__c.Plot_Facing__c',
    'Unit__c.Id',
    'Unit__c.Plot_Size__c',
    'Unit__c.Status__c',
    'Unit__c.Base_Price_per_Sq_Ft__c',
    ];

const PLOTFIELDS = [
    'Unit__c.Phase__c',
    'Unit__c.Phase__r.Name'
];

export default class QuoteGenerationComponent extends NavigationMixin(LightningElement) {

    @api leadid;
    selectedRecordId;
    unitName;
    leadDetails;
    showUnitDetails=false;
    recordPickerLabel;
    phaseName;
    workspaceAPI;
    showQuoteList=false;
    quoteList=[];
    records = [];

    plotName = '';
    plotCode = '';
    plotFacing = '';
    plotSize = '';
    plotStatus = '';
    phaseName = ''; 
    recordFilter = {
       criteria: [
           {
               fieldPath: 'Status__c',
               operator: 'eq',
               value: 'Available'
           }
       ]
   };

    records = [];  
    columns = [
        { label: 'Name', fieldName: 'name' },
        { label: 'Plot Code', fieldName: 'unitCode' },
        { label: 'Plot Facing', fieldName: 'plotFacing' },
        { label: 'Plot Size', fieldName: 'plotSize' },
        { label: 'Plot Status', fieldName: 'plotStatus' },
        { label: 'Plot Phase', fieldName: 'phaseName' },
        
        {
            label: 'Actions', 
            type: 'button-icon',
            typeAttributes: {
                iconName: 'utility:delete',  // Icon name for delete
                name: 'delete',  // Name for identifying the button
                iconSize: 'small',  // Small icon size
                variant: 'border-filled',  // Variant for styling
                alternativeText: 'Delete',  // Alt text for accessibility
            }
        }
    ];

    connectedCallback() {
        if (this.leadid) {
            this.fetchLeadDetails();
            this.initWorkspaceAPI();
        }
    }

    // Initialize workspaceAPI
    initWorkspaceAPI() {
        if (!this.workspaceAPI && this.template.querySelector('lightning-workspace-api')) {
            this.workspaceAPI = this.template.querySelector('lightning-workspace-api');
        }
    }

    fetchLeadDetails() {
        getLeadDetails({ leadId: this.leadid })
            .then((result) => {
                this.leadDetails = result;
                console.log('Success Lead Details:', this.leadDetails);
            })
            .catch((error) => {
                console.error('Error fetching Lead details:', error);
            });
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
        const plotRecordId = this.unit.data.fields.Id.value;
        const isDuplicate = this.records.some(record => record.plotRecordId === plotRecordId);
        if (isDuplicate) {
            this.showToast('Error', 'The Plot is already added!', 'error');
        }else{
            const newRecord = {
                id: this.records.length + 1,
                name: this.unit.data.fields.Name.value,
                unitCode: this.unit.data.fields.Unit_Code__c.value,
                plotFacing: this.unit.data.fields.Plot_Facing__c.value,
                plotRecordId: this.unit.data.fields.Id.value,
                plotSize: this.unit.data.fields.Plot_Size__c.value,
                plotStatus: this.unit.data.fields.Status__c.value,
                phaseName:this.phaseName,
                basePricePerSqYard:this.unit.data.fields.Base_Price_per_Sq_Ft__c.value,

            };
            this.records = [...this.records, newRecord];
            this.showToast('Success', 'The Plot has been added successfully!', 'success');
        }
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        if (actionName === 'delete') {
            this.records = this.records.filter(record => record.id !== row.id);
        }
    }
        delay=0;
        handleSaveClick() {
            if (this.records.length === 0) {
                this.showToast('Error','No plots to associate with the Lead.','error');
                return;
            }

            const leadPlotRecords = this.records.map(record => ({
                Lead__c: this.leadid,
                Plot__c: record.plotRecordId
            }));

            const quoteRecords = this.records.map(record => ({
                Lead__c: this.leadid,
                Plot__c: record.plotRecordId,
                Base_Price_Per_Sq_Yard__c:record.basePricePerSqYard,
                Time_To_Pay_In_Days__c:30
            }));

            saveLeadPlotRecords({leadPlotRecords})
                .then(() => {
                    console.log('Lead_Plot__c records created successfully.');
                    this.records = [];
                })
                .catch(error => {
                    console.error('Error creating Lead_Plot__c records:', error);
                    alert('Failed to create Lead_Plot__c records.');
                });

            saveLeadQuoteRecords({quoteRecords})
            .then((result) => {
                this.showToast('Success','Quote Generated Successfully.','success');
                this.records = [];
                this.quoteList=result;
                if(this.quoteList.length==1){
                    result.forEach(record => {
                        const quoteId = record.Id;
                        const baseUrl = window.location.origin; // Gets the Salesforce base URL dynamically
                        const fullUrl = `${baseUrl}/lightning/r/Quote__c/${quoteId}/view`; // Constructs the record URL
                        window.open(fullUrl, '_blank', 'noopener,noreferrer');
                    });
                }else{
                    this.showQuoteList=true;
                }
            })
            .catch(error => {
                console.error('Error creating qouote records:', error);
                this.showToast('Error','Failed to create records.','error');
            });
        }
    navigateToQuote(event) {
        //     this[NavigationMixin.Navigate]({
        //     type: 'standard__recordPage',
        //     attributes: {
        //         recordId: quoteId,
        //         actionName: 'view'
        //     }
        // },true);
        const quoteId = event.currentTarget.dataset.id;
        const baseUrl = window.location.origin; // Gets the Salesforce base URL dynamically
        const fullUrl = `${baseUrl}/lightning/r/Quote__c/${quoteId}/view`; // Constructs the record URL
        console.log('URL-->>',fullUrl);
        window.open(fullUrl, '_blank', 'noopener,noreferrer');
    }

        // navigateToQuote(quoteId) {
        //     this[NavigationMixin.GenerateUrl]({
        //         type: 'standard__component',
        //         attributes: {
        //             componentName: 'c__quotationCostingSheet',
        //         },
        //         state: {
        //             c__quoteId: quoteId, // Pass the Quote Id as a parameter
        //         },
        //     }).then(generatedUrl => {
        //         window.open(generatedUrl);
        //     });
        // }

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