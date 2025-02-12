import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getQuote from '@salesforce/apex/QuotationCostingSheetController.getQuote';
import SaveRecord from '@salesforce/apex/QuotationCostingSheetController.SaveRecord';
import finalizeQuote from '@salesforce/apex/QuotationCostingSheetController.FinalizeQuote';
import sendQuoteEmail from '@salesforce/apex/QuotationCostingSheetController.sendQuoteEmail';
import submitForApproval from '@salesforce/apex/QuotationCostingSheetController.submitForApproval';
import { CurrentPageReference } from 'lightning/navigation';

export default class QuotationCostingSheet extends LightningElement {
    isBookingForm=false;
    isQuotationSheet=true;
    @api recordId;
    quoteData = {};
    quoteRecordToSave={};
    isLocked=false;
    isChecked=false;
    isFinalizedQuoteDisabled=false;
    isFinal=false;
    isLoading = false;
    showTimer = false;
    leadRecord;
    Charges = [];
    ProjectType;
    isPlot = false;
    basePriceOriginalValue
    TotalChargeAmount = 0
    TotalGstforCharge = 0
    AllInclusivePrice = 0
    isSample = false
    isdisabled = false
    plcList = []

    @api quoteId;
    @wire(CurrentPageReference)
    wiredPageRef(pageRef) {
        if (pageRef?.state?.c__quoteId && !this.quoteId) {
            this.quoteId = pageRef.state.c__quoteId;
        }else if(this.recordId!=undefined && this.recordId!=null){
            this.quoteId=this.recordId;
        }
    }

    phaseName='';
    plotName='';
    plotFace='';
    plotSize='';
    plotFlatNumber='';
    plotFloorNumber='';
    plotUnitCode='';
    plotBasePrice='';
    plotDimension='';
    additionalChargeData=[];

    
    priceForNorthEast = 0;
    hundredFtRoadPlots = 0;
    legalAndDocumentationCharges = 0;
    otherCorners = 0;
    corpusFundAndClubHousePayable = 0;
    registrationChargesAsApplicable = 0;
    east = 0;
    premiumPlots = 0;
    ratePerSqYd = 0;

    connectedCallback() {
        try {
            this.isLoading = true;
            getQuote({ recordId: this.quoteId }).then(result => {
                if (result.isSuccess) {
                    this.quoteData = (result.quoteObj);
                    this.additionalChargeData = (result.additonalCharges);
                    this.isLocked=this.quoteData?.IsLocked__c || false;
                    this.isFinal=this.quoteData?.Is_Final__c || false;
                    if(this.isLocked==true || this.quoteData?.Approval_Status__c!='Accepted'){
                        this.isFinalizedQuoteDisabled=true;
                    }
                    this.isChecked=this.quoteData?.IsSample__c || false;
                    this.additionalChargeData.forEach((charge) => {
                        switch (charge.Values__c) {
                            case "100 Ft Road Plots":
                                this.hundredFtRoadPlots = charge.Charges__c || 0;
                                break;
                            case "Price For North East":
                                this.priceForNorthEast = charge.Charges__c || 0;
                                break;
                            case "Legal And Documentation Charges":
                                this.legalAndDocumentationCharges = charge.Charges__c || 0;
                                break;
                            case "Other Corners":
                                this.otherCorners = charge.Charges__c || 0;
                                break;
                            case "Corpus Fund and Club House Payable":
                                this.corpusFundAndClubHousePayable = charge.Charges__c || 0;
                                break;
                            case "Registration Charges As Applicable On The Day Of Registration":
                                this.registrationChargesAsApplicable = charge.Charges__c || 0;
                                break;
                            case "East":
                                this.east = charge.Charges__c || 0;
                                break;
                            case "Premium Plots":
                                this.premiumPlots = charge.Charges__c || 0;
                                break;
                            case "Rate Per Sq. Yd":
                                this.ratePerSqYd = charge.Charges__c || 0;
                                break;
                            default:
                            console.warn(`Unhandled Value: ${charge.Values__c}`);
                        }
                    });

                    this.leadRecord = this.quoteData?.Lead__r?.Name || this.quoteData?.Opportunity__r?.Contact__r?.Name || '';
                    this.ProjectType = 'Plot';

                    this.phaseName=this.quoteData?.Lead__r?.Phase__r?.Name || this.quoteData?.Plot__r?.Phase__r?.Name || '';
                    this.plotName=this.quoteData?.Plot__r?.Name || '';
                    this.plotFace=this.quoteData?.Plot__r?.Plot_Facing__c || '';
                    this.plotSize=this.quoteData?.Plot__r?.Plot_Size__c || '';
                    this.plotFlatNumber=this.quoteData?.Plot__r?.Flat_Number__c || '';
                    this.plotFloorNumber=this.quoteData?.Plot__r?.Floor_Number__c || '';
                    this.plotUnitCode=this.quoteData?.Plot__r?.Unit_Code__c || '';
                    this.plotBasePrice=this.quoteData?.Plot__r?.Base_Price_per_Sq_Ft__c || '';
                    this.plotDimension=this.quoteData?.Plot_Dimension__c || this.quoteData?.Plot__r.Plot_Dimension__c || '';

                    this.basePriceOriginalValue = this.quoteData.BasePriceperSqFt__c;
                    if (this.quoteData.Status__c == 'Draft' || this.quoteData.Status__c == 'Approved' || this.quoteData.Status__c == 'Rejected') {
                        this.showTimer = true;
                    }
                    if (this.ProjectType == 'Plot') {
                        this.isPlot = true;
                    }
                    this.TotalChargeAmount = this.quoteData.Total_Charge_Amount__c
                    this.TotalGstforCharge = this.quoteData.Total_Gst_For_Charge__c
                    this.AllInclusivePrice = this.quoteData.All_Inclusive_Price__c
                    this.isLoading = false;
                } else {
                    this.isLoading = false;
                }
            })
        } catch (error) {
            this.isLoading = false;
            console.log('error--->', error.stack)
        }
    }

    handleTextChnage(event) {
        let name = event.target.name;
        if(name=='IsSample__c'){
            const fieldValue = event.target.checked;
            this.isChecked=fieldValue;
        }else{
            let value = parseFloat(event.target.value);
            this.quoteRecordToSave[name]  = value;
        }
    }

    handleSendForApproval(){
        this.isLoading = true;
        submitForApproval({recordId: this.quoteId})
                .then(() => {
                    this.isLoading = false;
                    this.displayMessage('Success','success','Quote Sent For Approval');
                    window.location.reload();
                })
                .catch(error => {
                    this.isLoading = false;
                    console.error('Error In Sending For Approval', error);
                    this.displayMessage('Error','error',error.body.message);
                });

    }

    handleSaveRecord(){
        this.isLoading = true;
        this.quoteRecordToSave['Id']  = this.quoteId;
        this.quoteRecordToSave['IsSample__c']  = this.isChecked;
        let recordToSave=[this.quoteRecordToSave];
        SaveRecord({quoteRecords: recordToSave})
                .then(() => {
                    this.isLoading = false;
                    this.displayMessage('Success','success','Quote Saved Sucessfully');
                    window.location.reload();
                })
                .catch(error => {
                    this.isLoading = false;
                    console.error('Error updating Quote__c records:', error);
                    this.displayMessage('Error','error',error.body.message);
                });
    }

    handleFinalizeQuote(){
        let recordToSave=[{
            'Id':this.quoteId,
            'IsLocked__c':true,
            'Is_Final__c':true
        }]
        this.isLoading = true;
        finalizeQuote({quoteRecords: recordToSave})
                .then(() => {
                    console.log('Quote__c records updated successfully.');
                    this.displayMessage('Success','success','Quote Finalized Sucessfully');
                    this.isLoading = false;
                    window.location.reload();
                })
                .catch(error => {
                    console.error('Error In Finalizing Quote Record:', error);
                    this.isLoading = false;
                    this.displayMessage('Error','error',error.body.message);
                });
    }

    handleSendQuotePdf(){
        this.isLoading = true;
        let leadEmail = this.quoteData?.Lead__r?.Email || this.quoteData?.Opportunity__r?.Contact__r?.Email || ''
        if(leadEmail!=''){
            sendQuoteEmail({ quoteId: this.quoteId, recipientEmail:leadEmail, name:this.quoteData?.Name})
            .then(() => {
                this.isLoading = false;
                this.displayMessage('Success', 'success', 'Quote sent successfully via email!');
            })
            .catch(error => {
                this.isLoading = false;
                console.log('Error In Sending Pdf-->>>',error);
                this.displayMessage('Error','error', error.body.message);
            });
        }else{
            this.isLoading = false;
            this.displayMessage('Error', 'error', 'Customer has no email.' );
        }
        
    }

    displayMessage(title, type, message) {
        try {
            this.dispatchEvent(new ShowToastEvent({
                title: title,
                message: message,
                variant: type,
                mode: 'dismissable'
            }));
        } catch (error) {
            console.log('error--->', error.stack)
        }
    }

    handleBookingForm(){
        this.isQuotationSheet=false;
        this.isBookingForm=true;
    }


}