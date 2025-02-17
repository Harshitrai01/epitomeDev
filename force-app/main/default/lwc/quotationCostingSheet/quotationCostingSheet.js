import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getQuote from '@salesforce/apex/QuotationCostingSheetController.getQuote';
import SaveRecord from '@salesforce/apex/QuotationCostingSheetController.SaveRecord';
import finalizeQuote from '@salesforce/apex/QuotationCostingSheetController.FinalizeQuote';
import sendQuoteEmail from '@salesforce/apex/QuotationCostingSheetController.sendQuoteEmail';
import submitForApproval from '@salesforce/apex/QuotationCostingSheetController.submitForApproval';
import SaveOpportunityRecord from '@salesforce/apex/QuotationCostingSheetController.SaveOpportunityRecord';
import sendEmail from '@salesforce/apex/QuotationCostingSheetController.sendEmail';
import getOppDetails from '@salesforce/apex/QuotationCostingSheetController.getOppDetails';
import { CurrentPageReference } from 'lightning/navigation';

export default class QuotationCostingSheet extends LightningElement {
    isBookingForm=false;
    isQuotationSheet=true;
    @api recordId;
    quoteData = {};
    quoteRecordToSave={};
    oppId;
    oppRecordToSave={};
    quoteName='';
    isLocked=false;
    isChecked=false;
    isFinalizedQuoteDisabled=false;
    isFinal=false;
    isLoading = false;
    isOppIdPresent=false;
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
    toUpdate=false;
    basePricePerSqYard;

    priceForNorthEast = 0;
    hundredFtRoadPlots = 0;
    legalAndDocumentationCharges = 0;
    otherCorners = 0;
    corpusFundAndClubHousePayable = 0;
    registrationChargesAsApplicable = 0;
    east = 0;
    premiumPlots = 0;
    ratePerSqYd = 0;
    totalSaleValue;
    plotId;

    connectedCallback() {
        try {
            this.isLoading = true;
            getQuote({ recordId: this.quoteId }).then(result => {
                if (result.isSuccess) {
                    this.quoteData = (result.quoteObj);
                    this.additionalChargeData = (result.additonalCharges);
                    this.isLocked=this.quoteData?.IsLocked__c || false;
                    this.isFinal=this.quoteData?.Is_Final__c || false;
                    this.quoteName=this.quoteData?.Quote_Name__c || this.quoteData?.Name || '';
                    this.plotId=this.quoteData?.Plot__c;
                    if(this.isLocked==true || this.quoteData?.Approval_Status__c!='Accepted'){
                        this.isFinalizedQuoteDisabled=true;
                    }
                    this.isChecked=this.quoteData?.IsSample__c || false;
                    this.totalSaleValue=this.quoteData?.Total_Sale_Value__c || 0 ;
                    this.additionalChargeData.forEach((charge) => {
                        switch (charge.Values__c) {
                            case "100 Ft Road Plots":
                                this.hundredFtRoadPlots = charge.Charges__c || 0;
                                if(!this.quoteData?.X100_Ft_Road_Plots__c){
                                    this.quoteRecordToSave['X100_Ft_Road_Plots__c']  = parseFloat(this.hundredFtRoadPlots);
                                    this.toUpdate=true;
                                }
                                break;
                            case "Price For North East":
                                this.priceForNorthEast = charge.Charges__c || 0;
                                if(!this.quoteData?.Price_For_North_East__c){
                                    this.quoteRecordToSave['Price_For_North_East__c']  = parseFloat(this.priceForNorthEast);
                                    this.toUpdate=true;
                                }
                                break;
                            case "Legal And Documentation Charges":
                                this.legalAndDocumentationCharges = charge.Charges__c || 0;
                                if(!this.quoteData?.Legal_And_Documentation_Charges__c){
                                    this.quoteRecordToSave['Legal_And_Documentation_Charges__c']  = parseFloat(this.legalAndDocumentationCharges);
                                    this.toUpdate=true;
                                }
                                break;
                            case "Other Corners":
                                this.otherCorners = charge.Charges__c || 0;
                                if(!this.quoteData?.Other_Corners__c){
                                    this.quoteRecordToSave['Other_Corners__c']  = parseFloat(this.otherCorners);
                                    this.toUpdate=true;
                                }
                                break;
                            case "Corpus Fund and Club House Payable":
                                this.corpusFundAndClubHousePayable = charge.Charges__c || 0;
                                if(!this.quoteData?.Corpus_Fund_and_Club_House_Payable__c){
                                    this.quoteRecordToSave['Corpus_Fund_and_Club_House_Payable__c']  = parseFloat(this.corpusFundAndClubHousePayable);
                                    this.toUpdate=true;
                                }
                                break;
                            case "Registration Charges As Applicable On The Day Of Registration":
                                this.registrationChargesAsApplicable = charge.Charges__c || 0;
                                if(!this.quoteData?.Registration_Charges__c){
                                    this.quoteRecordToSave['Registration_Charges__c']  = parseFloat(this.registrationChargesAsApplicable);
                                    this.toUpdate=true;
                                }
                                break;
                            case "East":
                                this.east = charge.Charges__c || 0;
                                if(!this.quoteData?.East__c){
                                    this.quoteRecordToSave['East__c']  = parseFloat(this.east);
                                    this.toUpdate=true;
                                }
                                break;
                            case "Premium Plots":
                                this.premiumPlots = charge.Charges__c || 0;
                                if(!this.quoteData?.Premium_Plots__c){
                                    this.quoteRecordToSave['Premium_Plots__c']  = parseFloat(this.premiumPlots);
                                    this.toUpdate=true;
                                }
                                break;
                            case "Rate Per Sq. Yd":
                                this.ratePerSqYd = charge.Charges__c || 0;
                                if(!this.quoteData?.Rate_Per_Sq_Yd__c){
                                    this.quoteRecordToSave['Rate_Per_Sq_Yd__c']  = parseFloat(this.ratePerSqYd);
                                    this.toUpdate=true;
                                }
                                break;
                            default:
                            console.warn(`Unhandled Value: ${charge.Values__c}`);
                        }
                    });

                    this.oppId=this.quoteData?.Opportunity__c || '';
                    if(this.oppId!=''){
                        this.isOppIdPresent=true;
                        this.fetchOpportunityDetails();
                    }
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
                    this.basePricePerSqYard=this.plotBasePrice;
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
                    console.log('This to Update',this.toUpdate);
                    if(this.toUpdate){
                        this.isLoading=true;
                        this.handleSaveRecord();
                    }
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

    plotName1;
    plotSize1;
    plotBasePrice1;
    totalSaleValue1;
    fetchOpportunityDetails() {
        getOppDetails({ oppId: String(this.oppId) }) 
            .then(result => {
                if (result) {
                    this.plotName1=result?.Plot_Name__c || '';
                    this.plotSize1=result?.Plot_Size__c || '';
                    this.totalSaleValue1=result?.Sale_Value_Amount__c || '';
                    this.plotBasePrice1=result?.Unit__r?.Base_Price_per_Sq_Ft__c || '';
                } else {
                    console.log('No Opportunity Found');
                }
            })
            .catch(error => {
                this.error = error;
                console.error('Error fetching Opportunity:', error);
            });
    }

    handleTextChnage(event) {
        let name = event.target.name;
        if(name=='IsSample__c'){
            const fieldValue = event.target.checked;
            this.isChecked=fieldValue;
        }
        else{
            let value = parseFloat(event.target.value);
            this.quoteRecordToSave[name]  = value;
        }
    }

    handleSendForApproval(){
        this.handleSaveRecord();
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
                .then((result) => {
                    this.isLoading = false;
                    if(!this.toUpdate){
                        this.displayMessage('Success','success','Quote Saved Sucessfully');
                    }
                    this.totalSaleValue = result[0]?.Total_Sale_Value__c;
                    this.basePricePerSqYard = result[0]?.Base_Price_Per_Sq_Yard__c;
                    window.location.reload();
                })
                .catch(error => {
                    this.isLoading = false;
                    console.error('Error updating records:', error);
                    this.displayMessage('Error','error',error.body.message);
                });
    }

    saveOppRecord(){
        this.isLoading = true;
        this.oppRecordToSave['Id'] =  this.oppId;
        this.oppRecordToSave['Sale_Value_Amount__c'] = this.totalSaleValue;
        this.oppRecordToSave['Unit__c'] = this.plotId;
        let oppRecord=[this.oppRecordToSave];
        SaveOpportunityRecord({oppList:oppRecord})
                .then((result) => {
                    this.isLoading = false;
                        this.displayMessage('Success','success','Quote Finalized Sucessfully');
                        if(this.oppId!=''){
                            this.sendEmailForPlotSwap(this.plotName1,this.plotSize1,this.plotBasePrice1,this.totalSaleValue1,this.basePricePerSqYard);
                        }
                    window.location.reload();
                })
                .catch(error => {
                    this.isLoading = false;
                    console.error('Error updating records:', error);
                    this.displayMessage('Error','error',error.body.message);
                });
    }

    handleFinalizeQuote(){
        let recordToSave=[{
            'Id':this.quoteId,
            'IsLocked__c':true,
            'Is_Final__c':true,
            'Name':'Finalized - '+this.plotName
        }]
        this.isLoading = true;
        finalizeQuote({quoteRecords: recordToSave})
                .then(() => {
                    console.log('Quote__c records updated successfully.');
                    //this.displayMessage('Success','success','Quote Finalized Sucessfully');
                    this.isLoading = false;
                    this.saveOppRecord();
                    // window.location.reload();
                })
                .catch(error => {
                    console.error('Error In Finalizing Quote Record:', error);
                    this.isLoading = false;
                    this.displayMessage('Error','error',error.body.message);
                });
    }

    sendEmailForPlotSwap(oldPlotName, oldPlotSize, oldPlotBasePrice, oldTotalSaleValue, newBasePrice){
        this.isLoading=true;
        sendEmail({oppId: this.oppId, oldPlotName:String(oldPlotName), oldPlotSize:String(oldPlotSize), oldPlotBasePrice:String(oldPlotBasePrice), oldTotalSaleValue:String(oldTotalSaleValue), newPlotPrice:String(newBasePrice)})
            .then(() => {
                console.log('Email Sent Succesfully');
                this.isLoading=false;
            })
            .catch(error => {
                this.isLoading=false;
                console.error('Error sending email:', error);
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