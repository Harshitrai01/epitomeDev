import { LightningElement, track, wire, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import fetchProjectdetails from '@salesforce/apex/InventroyMetrixController.fetchProjectdetails';
import fetchMaterialMetrix from '@salesforce/apex/InventroyMetrixController.fetchMaterialMetrix';
import fetchPlotMetrix from '@salesforce/apex/InventroyMetrixController.fetchPlotMetrix';
import fetchOpportunityProjectdetails from '@salesforce/apex/InventroyMetrixController.fetchOpportunityProjectdetails';
import generateQuote from '@salesforce/apex/InventroyMetrixController.generateQuote';
import { getPicklistValues, getObjectInfo } from "lightning/uiObjectInfoApi";
import UNIT_OBJECT from '@salesforce/schema/Unit__c';
import STATUS_FIELD from "@salesforce/schema/Unit__c.Status__c";
import DIMENSION_FIELD from "@salesforce/schema/Unit__c.Plot_Dimension__c";
import TYPOLOGY_FIELD from "@salesforce/schema/Unit__c.Typology__c";
import FACING_FIELD from "@salesforce/schema/Unit__c.Facing__c";
import LightningConfirm from 'lightning/confirm';
import availableColorcode from '@salesforce/label/c.Available_Colorcode';
import blockedColorcode from '@salesforce/label/c.Blocked_Colorcode';
import bookedColorcode from '@salesforce/label/c.Booked_ColorCode';
import notforsaleColorcode from '@salesforce/label/c.Not_for_Sale_ColorCode';
import onholdColorcode from '@salesforce/label/c.On_Hold_ColorCode';
import reservedColorcode from '@salesforce/label/c.Reserved_ColorCode';
import soldColorcode from '@salesforce/label/c.Sold_ColorCode';

import { NavigationMixin } from 'lightning/navigation';

export default class InventroyMetrix extends NavigationMixin(LightningElement) {
    @api recordId
    @api oppid
    objectInfoData;
    defaultRecordTypeId;
    @track strProjectID //FilterVariable
    @track strPhaseID //FilterVariable
    @track strTowerID //FilterVariable
    @track strUnitID = 'NONE'//FilterVariable
    @track strFaceValue = 'NONE' //FilterVariable
    @track strTypologyValue = 'NONE' //FilterVariable
    @track strStatusValue = 'NONE' //FilterVariable
    @track strDimensionValue = 'NONE' //FilterVariable


    @track projectOption = [] //FilterVariable
    @track towerOption = [] //FilterVariable
    @track phaseOption = [] //FilterVariable
    @track unitOption = [] //FilterVariable
    @track allTowerOption = [] //FilterVariable
    @track FacingOption = [] //FilterVariable
    @track TypologyOption = [] //FilterVariable
    @track StatusOption = [] //FilterVariable
    @track DimensionOption = [] //FilterVariable


    @track desableTower = true; //FilterVariable
    @track desablePhase = true; //FilterVariable
    @track desableUnit = true; //FilterVariable
    @track desableFacing = false; //FilterVariable
    @track desableTypology = false; //FilterVariable
    @track desableStatus = false; //FilterVariable
    @track desableDimension = false; //FilterVariable

    @track openModelBox = false;
    @track modelBoxRecordId
    @track modelBoxUnitName
    @track modelStatusValue

    @track desableDimension = false; //FilterVariable
    @track showmatrix = true; //FilterVariable


    //Legend variable

    availableColorIndicator = 'background:  ' + availableColorcode + ';'
    bookedColorCoderIndicator = 'background:  ' + bookedColorcode + ';'
    blockedColorCodeIndicator = 'background:  ' + blockedColorcode + ';'
    reservedColorCodeIndicator = 'background:  ' + reservedColorcode + ';'
    notforsaleColorCodeIndicator = 'background:  ' + notforsaleColorcode + ';'
    onHoldColorCodeIndicator = 'background:  ' + onholdColorcode + ';'
    onSoldColorCodeIndicator = 'background:  ' + soldColorcode + ';'


    @track ShowTowerOption = false //FilterVariable
    @track isVillaOption = false
    @track isPlotOption = false
    @track FilterData //FilterVariable
    @track showdropDownScreen = false //FilterVariable
    @track Loading = true;
    @track showMetrix = false;
    @track FloarDeatil = []
    @track StaticFloarDeatil = []
    @track fieldsetValue = []
    @track showHover = false
    @track previousDiv
    @track flatList = []
    @track plotList = []
    @track staticPlotList = []
    @track showButton = false;
    @track showPlotMetrix = false
    @track errorMessage = false;
    materixErrorMessage = ''
    showQuoteScreen = false
    objectInfoData
    defaultRecordTypeId
    @track showbody = true;

    @wire(getObjectInfo, { objectApiName: UNIT_OBJECT })
    wireObjectInfo({ error, data }) {
        if (data) {
            this.objectInfoData = data; // if you still need it
            this.defaultRecordTypeId = data.defaultRecordTypeId;
        } else if (error) {
            console.log(error);
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$defaultRecordTypeId', fieldApiName: STATUS_FIELD })
    statusValues({ error, data }) {
        if (data) {
            this.StatusOption = data.values.map(plValue => {
                return {
                    label: plValue.label,
                    value: plValue.value
                };
            });
            const customElement = { label: '--None--', value: 'NONE' };
            this.StatusOption.unshift(customElement);
        } else if (error) {
            console.log(error);
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$defaultRecordTypeId', fieldApiName: TYPOLOGY_FIELD })
    typologyValues({ error, data }) {
        if (data) {
            this.TypologyOption.push({ label: '--None--', value: 'NONE' })
            this.TypologyOption = data.values.map(plValue => {
                return {
                    label: plValue.label,
                    value: plValue.value
                };
            });
            const customElement = { label: '--None--', value: 'NONE' };
            this.TypologyOption.unshift(customElement);
        } else if (error) {
            console.log(error);
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$defaultRecordTypeId', fieldApiName: FACING_FIELD })
    facingValues({ error, data }) {
        if (data) {
            this.FacingOption.push({ label: '--None--', value: 'NONE' })
            this.FacingOption = data.values.map(plValue => {
                return {
                    label: plValue.label,
                    value: plValue.value
                };
            });
            const customElement = { label: '--None--', value: 'NONE' };
            this.FacingOption.unshift(customElement);
        } else if (error) {
            console.log(error);
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$defaultRecordTypeId', fieldApiName: DIMENSION_FIELD })
    dimensionValues({ error, data }) {
        if (data) {
            this.DimensionOption.push({ label: '--None--', value: 'NONE' })
            this.DimensionOption = data.values.map(plValue => {
                return {
                    label: plValue.label,
                    value: plValue.value
                };
            });
            const customElement = { label: '--None--', value: 'NONE' };
            this.DimensionOption.unshift(customElement);
        } else if (error) {
            console.log(error);
        }
    }

    connectedCallback() {
        try {
            this.recordId = this.oppid
            this.fetchDropDownValues();
        } catch (error) {
            console.log('error--->', error.stack)
        }

    }

    fetchOppDetail() {
        try {
            fetchOpportunityProjectdetails({ recordId: this.recordId }).then((result) => {
                if (result) {
                    var oppItem = JSON.parse(result);
                    this.strProjectID = oppItem[0].Project__c
                    if (this.strProjectID != null && this.strProjectID != undefined) {
                        this.errorMessage = false
                        this.materixErrorMessage = ''
                        var projectData = JSON.parse(JSON.stringify(this.FilterData.projectArrays.filter((row) => row.Id == this.strProjectID)))
                        if (projectData[0].Type == 'Apartment') {
                            this.ShowTowerOption = true;
                        } else if (projectData[0].Type != 'Apartment') {
                            this.ShowTowerOption = false;
                        }
                        if (projectData[0].Type == 'Villa') {
                            this.isVillaOption = true;
                        } else if (projectData[0].Type == 'Plot') {
                            this.isPlotOption = true;
                        }
                        this.phaseOption = []
                        this.phaseOption.push({ label: '--None--', value: 'NONE' })
                        var phasedependentOption = JSON.parse(JSON.stringify(this.FilterData.phaseArrays.filter((row) => row.projectId == this.strProjectID)))
                        phasedependentOption.forEach(element => {
                            this.phaseOption.push({ label: element.Name, value: element.Id })
                        });
                        this.desablePhase = false
                    } else {
                        this.showMetrix = false;
                        this.desableTower = true;
                        this.desablePhase = true;
                        this.desableUnit = true;
                        this.desableFacing = true;
                        this.desableTypology = true;
                        this.desableStatus = true;
                        this.desableDimension = true;
                        this.errorMessage = true
                        this.materixErrorMessage = 'No project found on opportunity'
                        this.showPlotMetrix = false
                        this.Loading = false;
                    }
                    this.Loading = false;
                } else {
                    this.showMetrix = false;
                    this.errorMessage = true
                    this.materixErrorMessage =
                        this.showPlotMetrix = false
                    this.Loading = false;
                }
            }).catch((error) => {

            })
        } catch (error) {
            console.log('error--->', error.stack)
        }
    }

    fetchDropDownValues() {
        try {
            fetchProjectdetails({}).then((result) => {
                if (result.isSuccess) {
                    var filterDAta = result.FilterArrays;
                    if (filterDAta != null) {
                        this.projectOption.push({ label: '--None--', value: 'NONE' })
                        this.FilterData = filterDAta;
                        this.FilterData.projectArrays.forEach(element => {
                            this.projectOption.push({ label: element.Name, value: element.Id, Type: element.Type })
                        });
                        this.showdropDownScreen = true;
                    }
                    if (this.recordId != undefined) {
                        this.showButton = true
                        this.fetchOppDetail()
                    }
                } else {
                    this.displayMessage('Error', 'error', result.message);
                }
            }).catch((error) => {
                console.log('error--->', error.stack)
            });
        } catch (error) {
            console.log('error--->', error.stack)
        }
    }

    handleProjectChange(event) {
        try {
            this.showMetrix = false;
            this.showPlotMetrix = false;
            this.Loading = true;
            this.strProjectID = event.detail.value;
            if (this.strProjectID != 'NONE') {
                this.FloarDeatil = []
                this.flatList = []
                var projectData = JSON.parse(JSON.stringify(this.FilterData.projectArrays.filter((row) => row.Id == event.detail.value)))
                if (projectData[0].Type == 'Apartment') {
                    this.ShowTowerOption = true;
                } else if (projectData[0].Type != 'Apartment') {
                    this.ShowTowerOption = false;
                }
                this.phaseOption = []
                this.phaseOption.push({ label: '--None--', value: 'NONE' })
                var phaseDAta = this.FilterData.phaseArrays;
                var pahsedependentOption = phaseDAta.filter((row) => row.projectId == event.detail.value)
                pahsedependentOption.forEach(element => {
                    this.phaseOption.push({ label: element.Name, value: element.Id })
                });
                this.desablePhase = false;
            } else {
                this.desablePhase = true;
                this.desableTower = true;
                this.desableUnit = true;
                this.strUnitID = 'NONE'
                this.strFaceValue = 'NONE'
                this.strTypologyValue = 'NONE'
                this.strStatusValue = 'NONE'
                this.strDimensionValue = 'NONE'
            }

            this.Loading = false;
        } catch (error) {
            console.log('error--->', error.stack)
        }

    }

    handlePhaseChange(event) {
        try {
            this.showMetrix = false;
            this.Loading = true;
            this.FloarDeatil = []
            this.flatList = []
            this.strPhaseID = event.detail.value;
            if (this.strPhaseID != 'NONE') {
                if (!this.ShowTowerOption) {
                    this.unitOption = []
                    this.unitOption.push({ label: '--None--', value: 'NONE' })
                    var unitdependentOption = JSON.parse(JSON.stringify(this.FilterData.unitArrays.filter((row) => row.phaseId == this.strPhaseID)))
                    unitdependentOption.forEach(element => {
                        this.unitOption.push({ label: element.Name, value: element.Id })
                    });
                    this.desableUnit = false
                    this.fetchPlotMetrix()
                } else {
                    this.towerOption = []
                    this.towerOption.push({ label: '--None--', value: 'NONE' })
                    var towerData = this.FilterData.towerArrays;
                    var towerdependentOption = towerData.filter((row) => row.projectId == this.strProjectID && row.phaseId == event.detail.value)
                    towerdependentOption.forEach(element => {
                        this.towerOption.push({ label: element.Name, value: element.Id })
                    });
                    this.desableTower = false;
                }
            } else {
                this.unitOption = []
                this.towerOption = []
                this.desableUnit = true
                this.desableTower = true;
                this.showPlotMetrix = false
                this.showMetrix = false
                this.strUnitID = 'NONE'
                this.strFaceValue = 'NONE'
                this.strTypologyValue = 'NONE'
                this.strStatusValue = 'NONE'
                this.strDimensionValue = 'NONE'
            }

            this.Loading = false;
        } catch (error) {
            console.log('error--->', error.stack)
        }
    }

    handleTowerChange(event) {
        try {
            this.Loading = true;
            this.strTowerID = event.detail.value;
            if (this.strTowerID != 'NONE') {
                this.showMetrix = false;
                this.showdropDownScreen = false;
                this.FloarDeatil = []
                this.flatList = []
                if (this.ShowTowerOption) {
                    this.unitOption = []
                    this.unitOption.push({ label: '--None--', value: 'NONE' })
                    var unitdependentOption = JSON.parse(JSON.stringify(this.FilterData.unitArrays.filter((row) => row.towerId == this.strTowerID && row.projectId == this.strProjectID && row.phaseId == this.strPhaseID)))
                    unitdependentOption.forEach(element => {
                        this.unitOption.push({ label: element.Name, value: element.Id })
                    });
                    this.desableUnit = false
                    this.fetchMetrixData();
                }
            } else {
                this.unitOption = []
                this.desableUnit = true
                this.showMetrix = false;
                this.showPlotMetrix = false;
                this.strUnitID = 'NONE'
                this.strFaceValue = 'NONE'
                this.strTypologyValue = 'NONE'
                this.strStatusValue = 'NONE'
                this.strDimensionValue = 'NONE'
            }
            this.Loading = false;
        } catch (error) {
            console.log('error--->', error.stack)
        }
    }

    handleUnitChange(event) {
        try {
            this.strUnitID = event.target.value;
            this.Loading = true;
            if (!this.ShowTowerOption) {
                var staticList = this.staticPlotList
                this.filter(staticList)
            } else {
                this.filterMetixUnit()
            }
            this.Loading = false;
        } catch (error) {
            console.log('error--->', error.stack)
        }
    }

    handleTypologyChange(event) {
        try {
            this.strTypologyValue = event.target.value;
            this.Loading = true;
            if (!this.ShowTowerOption) {
                var staticList = this.staticPlotList
                this.filter(staticList)
            } else {
                this.filterMetixUnit()
            }
            this.Loading = false;
        } catch (error) {
            console.log('error--->', error.stack)
        }
    }

    handleFaceChange(event) {
        try {
            this.strFaceValue = event.target.value;
            this.Loading = true;
            if (!this.ShowTowerOption) {
                var staticList = this.staticPlotList
                this.filter(staticList)
            } else {

            }
            this.Loading = false;
        } catch (error) {
            console.log('error--->', error.stack)
        }
    }

    handleStatusChange(event) {
        try {
            this.strStatusValue = event.target.value;
            this.Loading = true;
            if (!this.ShowTowerOption) {
                var staticList = this.staticPlotList
                this.filter(staticList)
            } else {
                this.filterMetixUnit()
            }
            this.Loading = false;

        } catch (error) {
            console.log('error--->', error.stack)
        }
    }

    handleDimensionChange(event) {
        try {
            this.Loading = true;
            this.strDimensionValue = event.target.value;
            if (!this.ShowTowerOption) {
                var staticList = this.staticPlotList
                this.filter(staticList)
            } else {

            }
            this.Loading = false;
        } catch (error) {
            console.log('error--->', error.stack)
        }
    }

    filter(staticList) {
        try {
            if (this.strUnitID != 'NONE') {
                staticList = staticList.filter((row) => row.Id == this.strUnitID)
            }
            if (this.strDimensionValue != 'NONE') {
                staticList = staticList.filter((row) => row.PlotDimension == this.strDimensionValue)
            }
            if (this.strTypologyValue != 'NONE') {
                staticList = staticList.filter((row) => row.Typology == this.strTypologyValue)
            }
            if (this.strFaceValue != 'NONE') {
                staticList = staticList.filter((row) => row.Facing == this.strFaceValue)
            }
            if (this.strStatusValue != 'NONE') {
                staticList = staticList.filter((row) => row.Status == this.strStatusValue)
            }
            if (this.strUnitID == 'NONE' && this.strDimensionValue == 'NONE' && this.strTypologyValue == 'NONE' && this.strFaceValue == 'NONE' && this.strStatusValue == 'NONE') {
                this.plotList = staticList
            }
            this.plotList = staticList
            if (this.plotList != null && this.plotList != undefined) {
                if (this.plotList.length == 0) {
                    this.showbody = false;
                } else {
                    this.showbody = true;
                }
            }else{
                this.showbody = true;
            }

        } catch (error) {
            console.log('error--->', error.stack)
        }
    }

    filterMetixUnit() {
        try {
            this.showMetrix = false;
            new Promise(
                (resolve, reject) => {
                    setTimeout(() => {
                        if (this.StaticFloarDeatil.length > 0) {
                            if (this.strTypologyValue != 'NONE' || this.strUnitID != 'NONE' || this.strStatusValue != 'NONE') {
                                var staticList = JSON.parse(JSON.stringify(this.StaticFloarDeatil))
                                staticList.forEach(element => {
                                    element.FloarmetrixDeatils.forEach(flatItem => {
                                        if (this.strTypologyValue != 'NONE') {
                                            if (flatItem.Typology != this.strTypologyValue) {
                                                flatItem.colourCode = 'background-color: grey;color: white;';
                                                flatItem.statusAbbrivation = 'N/A'
                                                flatItem.unitId = '1'
                                                flatItem.Typology = null
                                            }
                                        }
                                        if (this.strUnitID != 'NONE') {
                                            if (flatItem.unitId != this.strUnitID) {
                                                flatItem.colourCode = 'background-color: grey;color: white;';
                                                flatItem.statusAbbrivation = 'N/A'
                                                flatItem.unitId = '1'
                                                flatItem.Typology = null
                                            }
                                        }
                                        if (this.strStatusValue != 'NONE') {
                                            if (flatItem.statusAbbrivation != this.strStatusValue) {
                                                flatItem.colourCode = 'background-color: grey;color: white;';
                                                flatItem.statusAbbrivation = 'N/A'
                                                flatItem.unitId = '1'
                                                flatItem.Typology = null
                                            }
                                        }

                                    })
                                })
                                this.FloarDeatil = []
                                this.FloarDeatil = staticList
                            } else if (this.strTypologyValue == 'NONE' && this.strUnitID == 'NONE' && this.strStatusValue == 'NONE') {
                                this.FloarDeatil = this.StaticFloarDeatil
                            }
                            this.showMetrix = true
                        }
                        resolve();
                    }, 200);
                }).then(

                );


        } catch (error) {
            console.log('error--->', error.stack)
        }
    }

    fetchMetrixData() {
        try {
            fetchMaterialMetrix({ projectId: this.strProjectID, towerId: this.strTowerID }).then((result) => {
                if (result.isSuccess) {
                    this.errorMessage = false;
                    this.materixErrorMessage = ''
                    this.FloarDeatil = result.floarDeatil;
                    if (this.recordId != undefined) {
                        this.FloarDeatil.forEach(element => {
                            element.FloarmetrixDeatils.forEach(flatItem => {
                                if (flatItem.unitId == this.strUnitID && this.strUnitID != undefined) {
                                    flatItem.blockButton = false;
                                } else {
                                    flatItem.blockButton = true;
                                }
                                if (flatItem.statusAbbrivation != 'N/A') {
                                    flatItem.show = true
                                } else {
                                    flatItem.hide = false
                                }
                            })
                        });
                        this.StaticFloarDeatil = this.FloarDeatil
                    }
                    this.fieldsetValue = result.setFieldsname
                    this.flatList = result.flatList
                    this.showMetrix = true;
                    this.Loading = false;
                    this.showdropDownScreen = true;
                    this.filterMetixUnit();
                } else {
                    this.errorMessage = true
                    this.materixErrorMessage = result.message;
                    this.Loading = false;
                    this.showdropDownScreen = true;
                    this.displayMessage('Error', 'Error', result.message)
                }
            }).catch((error) => {
                console.log('error--->', error.stack)
                this.Loading = false;
                this.showdropDownScreen = true;
            });
        } catch (error) {
            this.Loading = false;
            this.showdropDownScreen = true;
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
            console.log(error.stack);
        }
    }

    fetchPlotMetrix() {
        try {
            this.Loading = true;
            fetchPlotMetrix({ projectId: this.strProjectID, phaseId: this.strPhaseID }).then((result) => {
                if (result.isSuccess) {
                    this.showMetrix = false;
                    this.plotList = JSON.parse(JSON.stringify(result.UnitDeatils))
                    this.staticPlotList = this.plotList
                    this.fieldsetValue = result.setFieldsname
                    this.Loading = false;
                    this.showPlotMetrix = true;
                    this.filter(this.staticPlotList);
                } else {
                    this.Loading = false;
                    this.displayMessage('Error', 'Error', result.message)

                }
            })
        } catch (error) {
            console.log('error--->', error.stack)
        }
    }



    handelHover(event) {
        try {
            if (event.currentTarget.dataset.status != 'N/A') {
                if (event.currentTarget.dataset.materialid) {
                    this.modelBoxUnitName = event.currentTarget.dataset.unitname
                    this.modelBoxRecordId = event.currentTarget.dataset.materialid
                    this.modelStatusValue = event.currentTarget.dataset.status
                    this.openModelBox = true;
                    console.log('event.currentTarget.dataset.status--->', event.currentTarget.dataset.status)
                    if (event.currentTarget.dataset.status == 'Available') {
                        this.showButton = true
                    } else {
                        this.showButton = false
                    }
                }
            }

        } catch (error) {
            console.log('error--->', error.stack)
        }
    }
    closeModal(event) {
        try {
            this.openModelBox = false;
            this.modelBoxUnitName = ''
            this.modelBoxRecordId = ''

        } catch (error) {
            console.log('error--->', error.stack)
        }
    }

    hideHoverWizard(event) {
        try {
            if (this.previousDiv) {
                const hideDiv = this.template.querySelectorAll(`[data-id="${this.previousDiv}"]`);
                if (hideDiv) {
                    hideDiv.forEach(element => {
                        element.classList.add('ctip-hide');
                        element.classList.remove('tshow');
                    })
                }
            }
        } catch (error) {
            this.consoleLog(error.stack);
        }
    }

    async handelQuoteScreen(event) {
        try {
            if (this.modelBoxRecordId != undefined) {
                var unitId = this.modelBoxRecordId
            } else {
                var unitId = event.currentTarget.dataset.id
            }
            if (this.modelStatusValue != undefined) {
                var status = this.modelStatusValue;
            } else {
                var status = event.currentTarget.dataset.status;
            }

            if (status == 'Available') {
                const result = await LightningConfirm.open({
                    message: 'Are sure you want to continue with this unit',
                    variant: 'headerless',
                    label: 'Quote Confirmation',
                });
                if (result) {
                    generateQuote({ recordId: this.recordId, strunitId: unitId, strPhaseId: this.strPhaseID, strTowerId: this.strTowerID, strProjectId: this.strProjectID }).then((result) => {
                        if (result.isSuccess) {
                            this.displayMessage('Success', 'Success', 'Record has been saved successfully');
                            this[NavigationMixin.Navigate]({
                                type: 'standard__recordPage',
                                attributes: {
                                    recordId: result.quoteId,
                                    actionName: 'view'
                                }
                            });
                        } else {
                            this.displayMessage('Error', 'error', result.message)
                        }
                    }).catch((error) => {
                        console.log('error--->', error.stack)
                    })
                } else {

                }
            }

        } catch (error) {
            console.log('error--->', error.stack);
        }
    }
}