import { LightningElement,api, wire, track } from 'lwc';
import { getRecord, getFieldValue, updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getTableDimensions from '@salesforce/apex/UnitInventoryScreenController.getTableDimensions';
import searchPlots from '@salesforce/apex/UnitInventoryScreenController.searchPlots';
import updatePlotStatus from '@salesforce/apex/UnitInventoryScreenController.updatePlotStatus';
import getCellData from '@salesforce/apex/UnitInventoryScreenController.getCellData';
import { NavigationMixin } from 'lightning/navigation';

import ROWS_FIELD from '@salesforce/schema/Phase__c.Grid_Length__c';
import COLUMNS_FIELD from '@salesforce/schema/Phase__c.Grid_Width__c';
import PLOT_FIELD from '@salesforce/schema/Phase__c.Plot_JSON__c';
import GARDEN_FIELD from '@salesforce/schema/Phase__c.Garden_JSON__c';
import ROAD_FIELD from '@salesforce/schema/Phase__c.Road_JSON__c';

const delay = 350;

export default class unitInventoryScreen extends NavigationMixin(LightningElement) {
    @api recordId;
    @track isModalOpen = false;  
    @track isQuoteModal = false;
    @track boxWidth ; 
    @track boxHeight;
    @track availablePlot;
    @track bookedPlot;
    @track holdPlot;
    @track roadColor;
    @track gardenColor;
    rows = 10;
    columns = 10;
    plotData;
    roadData;
    gardenData;
    grid = [];
    tempGrid = [];
    tempMultiGrid = [];
    columnNames = [''];
    isEditMode = false
    isSelected = false
    isSingleSelect = false
    selectedPlotName
    selectedPlotId
    @track cellData = [];
    
    @track inputValue = ""; //Search picklist
    @track optionsToDisplay;
    @track openDropDown = false;
    @api disabled = false;
    @api value = "";
    @track label = "";
    @api placeholder = "Search Plot";
    @track searchResults = [];
    @track isSearching = false; // To show loading spinner
    isDropdownOpen = false;
    delaytimeout;
    options = [];
    statusOptions = [{ label: 'None', value: '' },
                    { label: 'Available', value: 'Available' },
                    { label: 'Hold', value: 'Hold' },
                    { label: 'Tmp Blocked', value: 'Tmp Blocked' },
                    { label: 'Blocked', value: 'Blocked' },
                    { label: 'Booked', value: 'Booked' },
                    { label: 'Sold', value: 'Sold' },
                    { label: 'Registered', value: 'Registered' },
                    { label: 'Management Blocked', value: 'Management Blocked' },
                    { label: 'Mortgage', value: 'Mortgage' },
                    { label: 'Not For Sale', value: 'Not For Sale' }];

    filterOptions = [{ label: 'None', value: 'None' },
                    { label: 'Available', value: 'Available' },
                    { label: 'Hold', value: 'Hold' },
                    { label: 'Booked', value: 'Booked' }];
    selectedCellId
    selectedRowId
    selectedPlotStatus = '';

    previousColumnKey = ''; 
    previousRowId = null;

    zoomLevel = 1;

    // multiselect
    multiSelectedCells = [];
    timeoutId = null;
    isMultiSelect = false
    currentIndex = 0;
    cellValue
    previousButton = true
    nextButton = false

    // Filter
    selectedFilter

    fields = [ROWS_FIELD, COLUMNS_FIELD, PLOT_FIELD, GARDEN_FIELD, ROAD_FIELD];

    // connectedCallback() {
    //     this.setOptionsAndValues();
    // }

    @wire(getTableDimensions)
    wiredDimensions({ error, data }) {
        if (data) {
            this.boxWidth = data[0].Width__c; 
            this.boxHeight = data[0].Height__c;
            this.availablePlot = data[0].Available_Plot__c; 
            this.bookedPlot = data[0].Booked_Plot__c;
            this.holdPlot = data[0].Hold_Plot__c; 
            this.roadColor = data[0].Road__c;
            this.gardenColor = data[0].Garden__c;
        } else if (error) {
            console.error('Error fetching dimensions:', error);
        }
    }

    @wire(getRecord, { recordId: '$recordId', fields: '$fields' })
    wiredPhase({ error, data }) {
        if (data) {
            this.rows = getFieldValue(data, ROWS_FIELD) || 10; 
            this.columns = getFieldValue(data, COLUMNS_FIELD) || 10;
            this.plotData = getFieldValue(data, PLOT_FIELD);
            this.gardenData = getFieldValue(data, GARDEN_FIELD);
            this.roadData = getFieldValue(data, ROAD_FIELD);
            this.initializeGrid();
        } else if (error) {
            console.error('Error fetching phase data:', error);
        }
    }

    initializeGrid() {
        this.template.host.style.setProperty('--available-plot-color', this.availablePlot);
        this.template.host.style.setProperty('--hold-plot-color', this.holdPlot);
        this.template.host.style.setProperty('--booked-plot-color', this.bookedPlot);
        this.template.host.style.setProperty('--road-color', this.roadColor);
        this.template.host.style.setProperty('--garden-color', this.gardenColor);
        console.log('hold-->',this.holdPlot);
        
        this.grid = [];
        this.tempGrid = [];
        this.columnNames = [''];
        
        const plotCells = this.plotData ? JSON.parse(this.plotData) : [];
        const gardenCells = this.gardenData ? JSON.parse(this.gardenData) : [];
        const roadCells = this.roadData ? JSON.parse(this.roadData) : [];
        
        for (let i = 1; i <= this.rows; i++) {
            const row = {
                Rw: i,
                Co: []
            };

            for (let j = 1; j <= this.columns; j++) {
                let columnName = '';
                let columnIndex = j;

                while (columnIndex > 0) {
                    const remainder = (columnIndex - 1) % 26;
                    columnName = String.fromCharCode(65 + remainder) + columnName;
                    columnIndex = Math.floor((columnIndex - 1) / 26);
                }
                
                const cellId = `${columnName}${i}`;
                const isPlot = plotCells.find(cell => cell.id === cellId);
                const isGarden = gardenCells.includes(cellId);
                const isRoad = roadCells.includes(cellId);
                // let cellType = '';
                // let cellBgColor = '';
                // let pN = '';
                // let pId = '';
                // let pS = '';

                let cellData = {
                    id: cellId,
                    Pv: false,
                    ty: '',
                    st: ''
                };
                if (isPlot) {
                    // cellType = 'Plot';
                    // cellBgColor = this.getCellColor(isPlot.pS);
                    // pS = isPlot.pS;
                    // pN = isPlot.pN;
                    // pId = isPlot.pId;
                    cellData.ty = 'Plot';
                    // cellData.st = `background-color: ${this.getCellColor(isPlot.pS)};`;
                    cellData.st = isPlot.pS;
                    cellData.pId = isPlot.pId;
                    cellData.pN = isPlot.pN;
                    cellData.pS = isPlot.pS;
                } else if (isGarden) {
                    // cellType = 'Garden';
                    // cellBgColor = this.gardenColor;
                    cellData.ty = 'Garden';
                    cellData.st = 'gd';
                } else if (isRoad) {
                    // cellType = 'Road';
                    // cellBgColor = this.roadColor;
                    cellData.ty = 'Road';
                    cellData.st = 'rd';
                }
                // console.log('113 '+cellBgColor);
                // row.Co.push({
                //     id: `${columnName}${i}`,
                //     Pv: false,
                //     ty: cellType, 
                //     pId: pId,
                //     pN: pN,
                //     pS: pS,
                //     st: `background-color: ${cellBgColor};`
                    
                // });
                row.Co.push(cellData);
                if (i === 1) {
                    this.columnNames.push(columnName);
                }
            }
            this.grid.push(row);

        }
        this.setOptionsAndValues();
        this.tempGrid = structuredClone(this.grid);
        console.log('grid-->',JSON.stringify(this.grid));
        
    }

    openModal(cellId, rowId) {
        this.isModalOpen = true;
        this.selectedCellId = cellId;
        this.selectedRowId = rowId;
    }

    renderedCallback() {
        if (this.openDropDown) {
            this.template.querySelectorAll('.search-input-class').forEach(inputElem => {
                inputElem.focus();
            });
        }
    }

    //Public Method to set options and values
    setOptionsAndValues() {
        try {
            let parsedPlotData;
            let existingPlotIds = [];
            if (this.plotData !== null) {
                parsedPlotData = Array.isArray(this.plotData)
                ? this.plotData  
                : JSON.parse(this.plotData);  
                existingPlotIds = parsedPlotData.map(p => p.pId);
            }
           
            console.log('dd');
            searchPlots({ plotName: '', phaseId: this.recordId })
            .then(result => {
                if (existingPlotIds.length > 0) {
                    
                    this.options = result
                        .filter(plot => !existingPlotIds.includes(plot.Id))
                        .map(plot => ({
                            label: plot.Name,
                            value: plot.Id,
                            bPricePerSqFt: plot.Base_Price_per_Sq_Ft__c,
                            plotPrice: plot.Plot_Price__c,
                            plotStatus: plot.Status__c,
                            type: plot.RecordType.Name
                        }));
                } else {
                    this.options = result.map(plot => ({
                        label: plot.Name,
                        value: plot.Id,
                        bPricePerSqFt: plot.Base_Price_per_Sq_Ft__c,
                        plotPrice: plot.Plot_Price__c,
                        plotStatus: plot.Status__c,
                        type: plot.RecordType.Name
                    }));
                }
            })
            .catch(error => {
                console.error('Error fetching plots:', error);
            });
        } catch (error) {
            console.error('Error processing plotData:', error);
        }
    }

    getLabel(value) {
        let selectedObjArray = this.options.filter(obj => obj.value === value);
        if (selectedObjArray && selectedObjArray.length > 0) {
            return selectedObjArray[0].label;
        }
        return null;
    }

    //Method to open listbox dropdown
    openDropDown(event) {
        this.toggleOpenDropDown(true);
    }

    //Method to close listbox dropdown
    closeDropdown(event) {
        if (event.relatedTarget && event.relatedTarget.tagName == "UL" && event.relatedTarget.className.includes('customClass')) {
            if (this.openDropDown) {
                this.template.querySelectorAll('.search-input-class').forEach(inputElem => {
                    inputElem.focus();
                });
            }
        }
        else {
            window.setTimeout(() => {
                this.toggleOpenDropDown(false);
            }, 300);
        }
    }

    //Method to handle readonly input click
    handleInputClick(event) {
        this.resetParameters();
        this.toggleOpenDropDown(true);
    }
    
    handleChangeStatus(plotStatus){
        this.selectedPlotStatus = plotStatus.target.value
    }


    handleNavigate() {
        var compDefinition = {
        componentDef: 'c:quotationCostingSheet',
        
        };
        // Base64 encode the compDefinition JS object
        var encodedCompDef = btoa(JSON.stringify(compDefinition));
        this[NavigationMixin.Navigate]({
        type: 'standard__webPage',
        attributes: {
            url: '/one/one.app#' + encodedCompDef,
        },
        });
    }

    //Method to reset necessary properties
    resetParameters() {
        this.setInputValue("");
        this.optionsToDisplay = this.options;
    }

    //Method to set inputValue for search input box
    setInputValue(value) {
        this.inputValue = value;
    }

    //Method to set label and value based on
    //the parameter provided
    setValues(value, label) {
        this.isSelected = true;
        // this.selectedPlotName = label;
        this.label = label;
        this.value = value;
    }

    //Method to toggle openDropDown state
    toggleOpenDropDown(toggleState) {
        this.openDropDown = toggleState;
    }

    closeModal() {
        if (this.isMultiSelect === true) {
            this.grid = structuredClone(this.tempMultiGrid);
        }
        this.tempMultiGrid = [];
        this.isModalOpen = false;
        this.isQuoteModal = false;
        this.isMultiSelect = false;
        this.isSelected = false;
        this.isSingleSelect = false;
        this.multiSelectedCells = [];
        this.currentIndex = 0;
        this.previousButton = true;
        this.nextButton = false;

    }

    //getter setter for labelClass
    get labelClass() {
        return (this.fieldLabel && this.fieldLabel != "" ? "slds-form-element__label slds-show" : "slds-form-element__label slds-hide")
    }

    //getter setter for dropDownClass
    get dropDownClass() {
        return (this.openDropDown ? "slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-is-open" : "slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click");
    }

    //getter setter for isValueSelected
    get isValueSelected() {
        return (this.label && this.label != "" ? true : false);
    }

    get isDropdownOpen() {
        return (this.openDropDown ? true : false);
    }

    get dynamicStyle() {
        return `width: ${this.boxWidth}; height: ${this.boxHeight}; text-align: center; cursor: pointer; position: relative;`;
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
}