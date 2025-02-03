import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getQuote from '@salesforce/apex/QuotationCostingSheetController.getLeadQuote';
import SaveRecord from '@salesforce/apex/QuotationCostingSheetController.SaveRecord';
import { RefreshEvent } from 'lightning/refresh';

export default class LeadQuotationCostingScreen extends LightningElement {
    @api recordId;
    @track discountApplied = false;
    @track quoteData = {};
    @track campaignValue;
    @track isLoading = false;
    @track totalBasePrice;
    @track isShowModal = false;
    @track discountType;
    @track showTimer = false;
    @track removeDiscount = false;
    @track activeCampaignOptions = [];
    @track showDiscountPercent = false
    @track showLumpsumDiscount = false;
    @track showSchemeLookup = false
    @track OpportunityRecord
    @track plcRecords = [];
    @track isSchemeDiscount = false;
    @track isLumpsumDiscount = false;
    @track milestonePlane = []
    @track Charges = []
    @track ProjectType
    @track isPlot = false
    @track isVilla = false
    @track isAppartment = false
    @track calculatedGstValue
    @track campaignDiscountType
    @track basePriceOriginalValue
    @track TotalChargeAmount = 0
    @track TotalGstforCharge = 0
    @track AllInclusivePrice = 0
    @track isSample = false
    @track isdisabled = false
    @track noSceme = false
    @track plcList = []
    get discountOptions() {
        return [
            { label: 'Manual', value: 'Manual' },
            { label: 'Scheme', value: 'Scheme' }

        ];
    }

    connectedCallback() {
        try {
            this.isLoading = true;
            getQuote({ recordId: this.recordId }).then(result => {
                console.log('Result-->>',result);
                if (result.isSuccess) {
                    this.quoteData = (result.quoteObj);
                    console.log("Quote Object-->>>",this.quoteData);
                    this.OpportunityRecord = this.quoteData.Opportunity.Account.Name
                    this.ProjectType = this.quoteData.Project__r.Project_Type__c
                    this.basePriceOriginalValue = this.quoteData.BasePriceperSqFt__c;
                    if (this.quoteData.Status__c == 'Draft' || this.quoteData.Status__c == 'Approved' || this.quoteData.Status__c == 'Rejected') {
                        this.showTimer = true;
                    }

                    if (this.quoteData.Discount_Type__c == null && this.quoteData.Discount_per_sq_ft__c == null) {
                        this.quoteData.Discount_Amount__c = 0
                    } else {
                        this.discountApplied = true;
                        this.removeDiscount = true;
                    }
                    if (this.ProjectType == 'Apartment') {
                        this.isAppartment = true;
                    } else if (this.ProjectType == 'Plot') {
                        this.isPlot = true;
                    } else if (this.ProjectType == 'Villa') {
                        this.isVilla = true;
                    }
                    if (this.quoteData.PLC_1_Name__c != null) {
                        this.plcList.push({ label: this.quoteData.PLC_1_Name__c, value: this.quoteData.PLC_1_Price__c })
                    }
                    if (this.quoteData.PLC_2_Name__c != null) {
                        this.plcList.push({ label: this.quoteData.PLC_2_Name__c, value: this.quoteData.PLC_2_Price__c })
                    }
                    if (this.quoteData.PLC_3_Name__c != null) {
                        this.plcList.push({ label: this.quoteData.PLC_3_Name__c, value: this.quoteData.PLC_3_Price__c })
                    }
                    if (this.quoteData.PLC_4_Name__c != null) {
                        this.plcList.push({ label: this.quoteData.PLC_4_Name__c, value: this.quoteData.PLC_4_Price__c })
                    }
                    if (this.quoteData.PLC_5_Name__c != null) {
                        this.plcList.push({ label: this.quoteData.PLC_5_Name__c, value: this.quoteData.PLC_5_Price__c })
                    }
                    // if (result.chargeList.length > 0) {
                    //     this.Charges = JSON.parse(JSON.stringify(result.chargeList))
                    // }
                    // if (result.MilestoneList.length > 0) {
                    //     this.milestonePlane = JSON.parse(JSON.stringify(result.MilestoneList))
                    // }
                    if (this.quoteData.IsLocked__c || this.quoteData.Status__c=='Expired') {
                        this.isdisabled = true;
                    }
                    if (!this.quoteData.IsQuoteGenerated__c) {
                        this.calculateTotalBasePrice();
                    } else {
                        this.TotalChargeAmount = this.quoteData.Total_Charge_Amount__c
                        // this.TotalChargeAmount = this.quoteData.TotalChargeAmount__c
                        // this.TotalGstforCharge = this.quoteData.TotalGstforCharge__c
                        this.TotalGstforCharge = this.quoteData.Total_Gst_For_Charge__c
                        // this.AllInclusivePrice = this.quoteData.AllInclusivePrice__c
                        this.AllInclusivePrice = this.quoteData.All_Inclusive_Price__c
                    }
                    this.activeCampaignOptions = result.campaignListedRecord != undefined ? result.campaignListedRecord : [];
                    if (this.activeCampaignOptions.length > 0) {
                        this.titleInfo = 'campaign'
                    } else {
                        this.noSceme = true;
                        this.titleInfo = 'No campaign present'
                    }
                    this.isLoading = false;
                } else {
                    this.isLoading = false;
                    console.log('Inside False');
                }
            })
        } catch (error) {
            this.isLoading = false;
            console.log('error--->', error.stack)
        }
    }

    calculateTotalBasePrice() {
        try {
            this.quoteData.Total_Basic_Cost__c = 0
            this.quoteData.SalesValueOfUnit__c = 0
            this.quoteData.PrivateGardenTerraceAreaCost__c = 0
            this.quoteData.Total_Sale_Consideration__c = 0
            let cornerPlotCharges = this.quoteData.CornerChargePercentage__c!=null?this.quoteData.CornerChargePercentage__c:0
            let plcTotalRate = 0;
            plcTotalRate = this.quoteData.PLC_1_Name__c != null ? Number(this.quoteData.PLC_1_Price__c) : 0
            plcTotalRate += this.quoteData.PLC_2_Name__c != null ? Number(this.quoteData.PLC_2_Price__c) : 0
            plcTotalRate += this.quoteData.PLC_3_Name__c != null ? Number(this.quoteData.PLC_3_Price__c) : 0
            plcTotalRate += this.quoteData.PLC_4_Name__c != null ? Number(this.quoteData.PLC_4_Price__c) : 0
            plcTotalRate += this.quoteData.PLC_5_Name__c != null ? Number(this.quoteData.PLC_5_Price__c) : 0
            var dicountValue = this.quoteData.Discount_Value__c != null ? this.quoteData.Discount_Value__c :0
            if(this.isSchemeDiscount){
                if(this.campaignDiscountType == 'Lumsum'){
                    if (this.isAppartment) {
                        dicountValue = (Number(dicountValue) / (this.quoteData.Super_Builtup_Area_In_Sqft__c == null ? 0 : this.quoteData.Super_Builtup_Area_In_Sqft__c)).toFixed(2);
                    } else if (this.isPlot) {
                        dicountValue = (Number(dicountValue) / (this.quoteData.Plot_Saleable_Area_In_Sqft__c == null ? 0 : this.quoteData.Plot_Saleable_Area_In_Sqft__c)).toFixed(2);
                    } else if (this.isVilla) {
                        dicountValue = (Number(dicountValue) / (this.quoteData.Super_Builtup_Area_In_Sqft__c == null ? 0 : this.quoteData.Super_Builtup_Area_In_Sqft__c)).toFixed(2);
                    }
                }  
            }
            this.quoteData.Total_Basic_Cost__c = (this.basePriceOriginalValue == null ? 0 : this.basePriceOriginalValue) + (this.quoteData.Floor_Rise_Charges__c == null ? 0 : this.quoteData.Floor_Rise_Charges__c + plcTotalRate) + (this.quoteData.Corner_Plot__c == true && cornerPlotCharges>0 ? (this.basePriceOriginalValue * cornerPlotCharges) / 100 : 0) - Number(dicountValue) ;
            if (this.isAppartment) {
                this.quoteData.SalesValueOfUnit__c = (Number(this.quoteData.Total_Basic_Cost__c) * (this.quoteData.Super_Builtup_Area_In_Sqft__c == null ? 0 : this.quoteData.Super_Builtup_Area_In_Sqft__c)).toFixed(2);
            } else if (this.isPlot) {
                this.quoteData.SalesValueOfUnit__c = (Number(this.quoteData.Total_Basic_Cost__c) * (this.quoteData.Plot_Saleable_Area_In_Sqft__c == null ? 0 : this.quoteData.Plot_Saleable_Area_In_Sqft__c)).toFixed(2);
            } else if (this.isVilla) {
                this.quoteData.SalesValueOfUnit__c = (Number(this.quoteData.Total_Basic_Cost__c) * (this.quoteData.Super_Builtup_Area_In_Sqft__c == null ? 0 : this.quoteData.Super_Builtup_Area_In_Sqft__c)).toFixed(2);
            }
            this.quoteData.PrivateGardenTerraceAreaCost__c = (this.quoteData.Terrace_Area_Garden_Area_Cost__c == null ? 0 : this.quoteData.Terrace_Area_Garden_Area_Cost__c).toFixed(2);
            this.quoteData.Total_Sale_Consideration__c = (Number(this.quoteData.SalesValueOfUnit__c) + Number(this.quoteData.PrivateGardenTerraceAreaCost__c)).toFixed(2);
            this.calculateGstValue()
            this.calculateAgreementValue()
            this.calculateCharges()
            this.calculatePaymentPlan()
        } catch (error) {
            console.log('error--->', error.stack)
        }
    }

    calculateCharges() {
        try {
            this.TotalGstforCharge = 0
            this.TotalChargeAmount = 0
            var TotalGstforCharge = 0
            if (this.Charges.length > 0) {
                var basePricePsqft = 0
                if (this.isAppartment) {
                    basePricePsqft = Number(this.quoteData.Super_Builtup_Area_In_Sqft__c)
                } else if (this.isPlot) {
                    basePricePsqft = Number(this.quoteData.Plot_Saleable_Area_In_Sqft__c)
                } else if (this.isVilla) {
                    basePricePsqft = Number(this.quoteData.Super_Builtup_Area_In_Sqft__c)
                }
                this.Charges.forEach(element => {
                    if (element.ChargeType == 'Maintenance Charge') {
                        if (element.CalculationType == 'Per Sq Ft') {
                            if (element.GSTApplicable) {
                                var monthValue = this.CalculateTerm(new Date(element.StartDate), new Date(element.EndDate), new Date(this.quoteData.CreatedDate))
                                element.calculatedValue = 0
                                element.calculatedValue = (Number(element.Values) * Number(monthValue) * Number(basePricePsqft))
                                element.GSTValue = (element.calculatedValue * Number(element.GSTPercentage)) / 100
                                TotalGstforCharge += element.GSTValue;
                            } else {
                                element.calculatedValue = 0
                                var monthValue = this.CalculateTerm(new Date(element.StartDate), new Date(element.EndDate), new Date(this.quoteData.CreatedDate))
                                element.calculatedValue = Number(element.Values) * Number(monthValue)
                            }
                        } else {
                            if (element.GSTApplicable) {
                                var monthValue = this.CalculateTerm(new Date(element.StartDate), new Date(element.EndDate), new Date(this.quoteData.CreatedDate))
                                element.calculatedValue = 0
                                element.calculatedValue = (Number(element.Values) * Number(monthValue))
                                element.GSTValue = (element.calculatedValue * Number(element.GSTPercentage)) / 100
                                TotalGstforCharge += element.GSTValue;
                            } else {
                                element.calculatedValue = 0
                                var monthValue = this.CalculateTerm(new Date(element.StartDate), new Date(element.EndDate), new Date(this.quoteData.CreatedDate))
                                element.calculatedValue = Number(element.Values) * Number(monthValue) * Number(basePricePsqft)
                            }
                        }
                    } else if (element.ChargeType == 'Additional Charges') {
                        if (element.GSTApplicable) {
                            if (element.CalculationType == 'Per Sq Ft') {
                                element.GSTValue = 0
                                element.calculatedValue = 0
                                element.calculatedValue = (basePricePsqft * Number(element.Values))
                                element.GSTValue = (element.calculatedValue * Number(element.GSTPercentage)) / 100
                                TotalGstforCharge += element.GSTValue;
                            } else if (element.CalculationType == 'Lumpsum') {
                                element.calculatedValue = 0
                                element.calculatedValue = Number(element.Values)
                                element.GSTValue = (element.calculatedValue * Number(element.GSTPercentage)) / 100
                                TotalGstforCharge += element.GSTValue;
                            }
                        } else {
                            if (element.CalculationType == 'Per Sq Ft') {
                                element.calculatedValue = 0
                                element.calculatedValue = Number(basePricePsqft) * Number(element.Values)
                            } else if (element.CalculationType == 'Lumpsum') {
                                element.calculatedValue = 0
                                element.calculatedValue = Number(element.Values)
                            }
                        }
                    }

                });
                this.TotalGstforCharge = TotalGstforCharge;
                this.TotalChargeAmount = Number(this.TotalGstforCharge)
                this.Charges.forEach(element => {
                    if (element.calculatedValue != null && element.calculatedValue != undefined) {
                        this.TotalChargeAmount += Number(element.calculatedValue);
                    }

                })
                this.AllInclusivePrice = Number(this.TotalChargeAmount) + Number(this.quoteData.AgreementValueWithGst__c)

            }
        } catch (error) {
            console.log('error--->', error.stack)
        }
    }

    CalculateTerm(StartDate, endDate, DatetoCheck) {
        try {
            var monthValue
            if (StartDate <= DatetoCheck && endDate >= DatetoCheck) {
                monthValue = this.monthDiff(DatetoCheck, endDate)
                return monthValue
            } else {
                monthValue = this.monthDiff(StartDate, endDate)
                return monthValue
            }
        } catch (error) {
            console.log('error--->', error.stack)
        }
    }

    monthDiff(d1, d2) {
        try {
            var months;
            months = (d2.getFullYear() - d1.getFullYear()) * 12;
            months -= d1.getMonth();
            months += d2.getMonth();
            return months <= 0 ? 0 : months;
        } catch (error) {
            console.log('error--->', error.stack)
        }

    }

    calculateDiscount() {
        try {
            this.basePriceOriginalValue = this.quoteData.BasePriceperSqFt__c;
            if (this.discountApplied) {
                if (this.isSchemeDiscount) {
                    if (this.campaignDiscountType == 'Per sq.ft') {
                        if (this.isAppartment) {
                            this.quoteData.Discount_Amount__c = (Number(this.quoteData.Discount_Value__c) * (this.quoteData.Super_Builtup_Area_In_Sqft__c == null ? 0 : this.quoteData.Super_Builtup_Area_In_Sqft__c)).toFixed(2)
                        } else if (this.isPlot) {
                            this.quoteData.Discount_Amount__c = (Number(this.quoteData.Discount_Value__c) * (this.quoteData.Plot_Saleable_Area_In_Sqft__c == null ? 0 : this.quoteData.Plot_Saleable_Area_In_Sqft__c)).toFixed(2)
                        } else if (this.isVilla) {
                            this.quoteData.Discount_Amount__c = (Number(this.quoteData.Discount_Value__c) * (this.quoteData.Super_Builtup_Area_In_Sqft__c == null ? 0 : this.quoteData.Super_Builtup_Area_In_Sqft__c)).toFixed(2)
                        }
                    }else if(this.campaignDiscountType == 'Lumsum'){
                        if (this.isAppartment) {
                            this.quoteData.Discount_Amount__c = (Number(this.quoteData.Discount_Value__c)).toFixed(2)
                        } else if (this.isPlot) {
                            this.quoteData.Discount_Amount__c = (Number(this.quoteData.Discount_Value__c)).toFixed(2)
                        } else if (this.isVilla) {
                            this.quoteData.Discount_Amount__c = (Number(this.quoteData.Discount_Value__c)).toFixed(2)
                        }
                    }
                } else {
                    if (this.isAppartment) {
                        this.quoteData.Discount_Amount__c = (Number(this.quoteData.Discount_Value__c) * (this.quoteData.Super_Builtup_Area_In_Sqft__c == null ? 0 : this.quoteData.Super_Builtup_Area_In_Sqft__c)).toFixed(2)
                    } else if (this.isPlot) {
                        this.quoteData.Discount_Amount__c = (Number(this.quoteData.Discount_Value__c) * (this.quoteData.Plot_Saleable_Area_In_Sqft__c == null ? 0 : this.quoteData.Plot_Saleable_Area_In_Sqft__c)).toFixed(2)
                    } else if (this.isVilla) {
                        this.quoteData.Discount_Amount__c = (Number(this.quoteData.Discount_Value__c) * (this.quoteData.Super_Builtup_Area_In_Sqft__c == null ? 0 : this.quoteData.Super_Builtup_Area_In_Sqft__c)).toFixed(2)
                    }
                }
                this.calculateTotalBasePrice()
            } else {
                this.calculateTotalBasePrice()
            }
        } catch (error) {

        }
    }

    calculateAgreementValue() {
        try {
            this.quoteData.AgreementValueWithGst__c = 0
            this.quoteData.AgreementValueWithGst__c = (Number(this.quoteData.Total_Sale_Consideration__c) + Number(this.quoteData.GstAmount__c)).toFixed(2)//(Number(this.quoteData.Total_Sale_Consideration__c) - Number(this.quoteData.Discount_Amount__c)) + Number(this.quoteData.GstAmount__c);
        } catch (error) {
            console.log('error--->', error.stack)
        }
    }

    calculateGstValue() {
        try {
            if (this.quoteData.GST__c != null && this.quoteData.GST__c != undefined && this.quoteData.GST__c != 0) {
                this.quoteData.GstAmount__c =((Number(this.quoteData.Total_Sale_Consideration__c) * Number(this.quoteData.GST__c)) / 100).toFixed(2) //(((Number(this.quoteData.Total_Sale_Consideration__c) - Number(this.quoteData.Discount_Amount__c)) * Number(this.quoteData.GST__c)) / 100).toFixed(2)
            } else {
                this.quoteData.GstAmount__c = 0;
                this.quoteData.GST__c = 0;
            }
        } catch (error) {
            console.log('error--->', error.stack)
        }
    }

    handleApplyDiscount() {
        try {
            this.isShowModal = true;
        } catch (error) {
            console.log('error--->', error.stack)
        }
    }

    hideModalBox() {
        try {
            this.isShowModal = false;
            this.discountType = null;
            this.showDiscountPercent = false;
            this.showSchemeLookup = false;
            this.quoteData.Discount_Type__c = null;
            this.quoteData.Campaign_Discount__c = null;
            this.isSchemeDiscount = false
            this.isLumpsumDiscount = false
        } catch (error) {
            console.log('error--->', error.stack)
        }
    }

    applyDiscount() {
        try {
            if(this.quoteData.Discount_Value__c !=null && this.quoteData.Discount_Type__c!=null){
                if(Number(this.quoteData.Discount_Value__c)>0){
                    this.isShowModal = false;
                    this.discountApplied = true;
                    this.removeDiscount = true;
                    this.calculateDiscount()
                }else{
                    this.displayMessage('Error', 'Error', 'Discount value should be greater then zero');
                }
            }else{
                this.displayMessage('Error', 'Error', 'Please fill discount value and discount type');
            }   
            
        } catch (error) {
            console.log('error--->', error.stack)
        }
    }

    handleRadioChange(event) {
        try {
            this.discountType = event.target.name;
            if (this.discountType == 'Scheme') {
                this.isPercentDiscount = false;
                this.isSchemeDiscount = true;
                this.isLumpsumDiscount = false;
                this.isLumpsumDiscount = false;
                this.showLumpsumDiscount = false;
                this.quoteData.Discount_Type__c = 'Scheme';
                this.quoteData.Discount_Lumpsum__c = null;
                this.showDiscountPercent = false
                this.showSchemeLookup = true;
            } else if (this.discountType = 'Per Sqft') {
                this.isSchemeDiscount = false
                this.isLumpsumDiscount = true;
                this.showLumpsumDiscount = true;
                this.showDiscountPercent = false
                this.showSchemeLookup = false;
                this.quoteData.Discount_Type__c = 'Per Sqft';
                this.quoteData.Campaign_Discount__c = null;
                this.quoteData.Discount_Value__c = null;
            }
        } catch (error) {
            console.log('error--->', error.stack)
        }
    }

    handleChange(event) {
        try {
            if (this.isSchemeDiscount) {
                this.campaignDiscountType = null
                this.quoteData.Discount_Type__c = ''
                this.campaignDiscountType = ''
                this.quoteData.Campaign_Discount__c = null;
                this.quoteData.Discount_Value__c = null;
                var campaingInfo = event.target.options.find(opt => opt.value === event.target.value);
                this.quoteData.Discount_Type__c = 'Scheme';
                this.campaignDiscountType = campaingInfo.discountType
                this.quoteData.Campaign_Discount__c = campaingInfo.value;
                this.quoteData.Discount_Value__c = campaingInfo.discountValue;
                this.quoteData.Discount_Approval_Required__c = false;
            } else if (this.isLumpsumDiscount) {
                this.quoteData.Discount_Type__c = ''
                this.quoteData.Discount_Value__c = null
                this.quoteData.Discount_Type__c = 'Per Sqft';
                this.quoteData.Discount_Value__c = event.target.value;
                this.quoteData.Discount_Approval_Required__c = true;
            }
        } catch (error) {
            console.log('error--->', error.stack)
        }
    }

    handleSaveRecord() {
        try {
            SaveRecord({ QuoteRecord: this.quoteData, milestonePlane: JSON.stringify(this.milestonePlane), Charges: JSON.stringify(this.Charges), TotalChargeAmount: this.TotalChargeAmount, TotalGstforCharge: this.TotalGstforCharge, AllInclusivePrice: this.AllInclusivePrice }).then(result => {
                if (result.isSuccess) {
                    location.reload();
                    this.dispatchEvent(new RefreshEvent());
                    this.displayMessage('Success', 'Success', 'Record Updated Successfully')
                }
                else {
                    this.displayMessage('Error', 'Error', result.message);
                }
            }).catch(error => {

            })

        } catch (error) {
            console.log('error--->', error.stack)
        }
    }

    handelHeaderChange(event) {
        try {
            if (event.currentTarget.dataset.namevalue == 'Name') {
                this.quoteData.Name = event.target.value
            } else if (event.currentTarget.dataset.namevalue == 'IsSample') {
                this.quoteData.IsSample__c = event.target.checked
            }
        } catch (error) {
            console.log('error--->', error.stack)
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

    calculatePaymentPlan() {
        try {
            var allInclusiveprice = 0
            this.milestonePlane.forEach(element => {
                if (element.percentage != null) {
                    element.percentageCostValue = ((Number(this.quoteData.AgreementValueWithGst__c) * Number(element.percentage)) / 100).toFixed(2)
                    allInclusiveprice += Number(element.percentageCostValue)
                }

            });
            this.AllInclusivePrice = (Number(allInclusiveprice) + Number(this.TotalChargeAmount)).toFixed(2)
        } catch (error) {
            console.log('error--->', error.stack)
        }
    }

    handleRemoveDiscount() {
        try {
            this.campaignDiscountType = null
            this.showSchemeLookup = false;
            this.showLumpsumDiscount = false;
            this.quoteData.Discount_Type__c = ''
            this.quoteData.Campaign_Discount__c = null;
            this.quoteData.Discount_Value__c = null
            this.removeDiscount = false
            this.isSchemeDiscount = false
            this.isLumpsumDiscount = false
            this.quoteData.Discount_Approval_Required__c = false;
            this.discountApplied = false
            this.quoteData.Discount_Amount__c = 0
            this.calculateDiscount()
            this.displayMessage('Success', 'Success', 'Discount removed Successfully');
        } catch (error) {
            console.log('error--->', error.stack)
        }
    }

}