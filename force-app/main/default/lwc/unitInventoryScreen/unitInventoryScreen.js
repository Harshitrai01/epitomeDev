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
import NO_ZONE_FIELD from '@salesforce/schema/Phase__c.Number_Of_Zone__c';

const delay = 350;

export default class unitInventoryScreen extends NavigationMixin(LightningElement) {
    @api recordId;
    isModalOpen = false;  
    isQuoteModal = false;
    boxWidth ; 
    boxHeight;
    availablePlot;
    bookedPlot;
    holdPlot;
    blockedPlot;
    managBlockedPlot;
    mortgagePlot;
    notForSalePlot;
    regPlot;
    soldPlot;
    tempBlockPlot;
    multiSelect
    roadColor;
    gardenColor;
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
    isZone = false
    isZoneHeader = false
    isSearchPlot = false
    selectedPlotName
    selectedPlotId
    noOfZone = 0;
    selectedZone;
    zoneValue;
    selectedRowId;
    selectedColumnKey; 
    selectedOption = '';
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
    statusOptions = [{ label: 'None', value: 'None' },
                    { label: 'Available', value: 'Available' },
                    { label: 'Hold', value: 'Hold' },
                    { label: 'Temp Blocked', value: 'Temp Blocked' },
                    { label: 'Blocked', value: 'Blocked' },
                    { label: 'Booked', value: 'Booked' },
                    { label: 'Sold', value: 'Sold' },
                    { label: 'Registered', value: 'Registered' },
                    { label: 'Management Blocked', value: 'Management Blocked' },
                    { label: 'Mortgage', value: 'Mortgage' },
                    { label: 'Not For Sale', value: 'Not For Sale' }];

    filterPlotFacing = [{ label: 'None', value: 'None' },
                    { label: 'North', value: 'North' },
                    { label: 'East', value: 'East' },
                    { label: 'West', value: 'West' },
                    { label: 'South', value: 'South' },
                    { label: 'North East', value: 'North East' },
                    { label: 'North West', value: 'North West' },
                    { label: 'South East', value: 'South East' },
                    { label: 'South West', value: 'South West' }];
    zoneOptions = [];
    selectedCellId
    selectedRowId
    selectedPlotStatus = '';
    selectedPlotFacing = '';

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
    selectedStatusFilters = [];
    selectedFacingFilters = [];
    selectedZoneFilters = [];

    fields = [ROWS_FIELD, COLUMNS_FIELD, PLOT_FIELD, GARDEN_FIELD, ROAD_FIELD, NO_ZONE_FIELD];

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
            this.blockedPlot = data[0].Blocked_Plot__c;
            this.managBlockedPlot = data[0].Management_Blocked_Plot__c;
            this.mortgagePlot = data[0].Mortgage_Plot__c;
            this.notForSalePlot = data[0].Not_For_Sale_Plot__c;
            this.regPlot = data[0].Registered_Plot__c;
            this.soldPlot = data[0].Sold_Plot__c;
            this.tempBlockPlot = data[0].Temp_Blocked_Plot__c;
            this.multiSelect = data[0].Multi_Select_Color__c;
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
            this.roadData = getFieldValue(data, ROAD_FIELD);
            this.noOfZone = getFieldValue(data, NO_ZONE_FIELD) || 0;
            this.initializeGrid();
        } else if (error) {
            console.error('Error fetching phase data:', error);
        }
    }

    initializeGrid() {
        this.template.host.style.setProperty('--available-plot-color', this.availablePlot);
        this.template.host.style.setProperty('--hold-plot-color', this.holdPlot);
        this.template.host.style.setProperty('--booked-plot-color', this.bookedPlot);
        this.template.host.style.setProperty('--blockedPlot-plot-color', this.blockedPlot);
        this.template.host.style.setProperty('--managBlockedPlot-plot-color', this.managBlockedPlot);
        this.template.host.style.setProperty('--mortgagePlot-plot-color', this.mortgagePlot);
        this.template.host.style.setProperty('--notForSalePlot-plot-color', this.notForSalePlot);
        this.template.host.style.setProperty('--regPlot-plot-color', this.regPlot);
        this.template.host.style.setProperty('--soldPlot-plot-color', this.soldPlot);
        this.template.host.style.setProperty('--tempBlockPlot-plot-color', this.tempBlockPlot);
        this.template.host.style.setProperty('--multiSelect-color', this.multiSelect);
        this.template.host.style.setProperty('--road-color', this.roadColor);
        this.template.host.style.setProperty('--garden-color', this.gardenColor);

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
                const isGarden = gardenCells.find(cell => cell.id === cellId);
                const isRoad = roadCells.find(cell => cell.id === cellId);
                // let cellType = '';
                // let cellBgColor = '';
                // let pN = '';
                // let pId = '';
                // let pS = '';
                
                let cellData = {
                    id: cellId,
                    Pv: false,
                    ty: '',
                    st: '',
                    z: ''
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
                    cellData.pF = isPlot.pF;
                    cellData.z = isPlot.z;
                } else if (isGarden) {
                    // cellType = 'Garden';
                    // cellBgColor = this.gardenColor;
                    cellData.ty = 'Garden';
                    cellData.st = 'gd';
                    cellData.z = isGarden.z;
                } else if (isRoad) {
                    // cellType = 'Road';
                    // cellBgColor = this.roadColor;
                    cellData.ty = 'Road';
                    cellData.st = 'rd';
                    cellData.z = isRoad.z;
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
        console.log('Initial grid-->',JSON.stringify(this.grid));
        this.generateZonePicklistOptions();
    }
    
    getCellColor(plotStatus){
        const colorMapping = {
            'av': this.availablePlot,
            'hd': this.holdPlot,
            'bk': this.bookedPlot
        };
    
        return colorMapping[plotStatus] || '';
    }

    togglePopover(event) {
        // event.stopPropagation();
        // console.log('grid-->',JSON.stringify(this.grid));
        const columnKey = event.target.dataset.key;
        const rowId = parseInt(event.target.dataset.row, 10);
        const cellLabel = event.target.dataset.label;
        const plotId = event.target.dataset.pid;
        const plotName = event.target.dataset.pn;
        const plotStatus = event.target.dataset.ps;
        this.selectedOption = '';
        console.log('columnKey--->', columnKey);
        console.log('rowId--->', rowId);
        console.log('plotId--->', plotId);
        console.log('plotName--->', plotName);
        console.log('plotStatus--->', plotStatus);
        
        if (this.isEditMode === true && !(event.ctrlKey || event.metaKey)) { //single Select on Edit Mode 
            
            console.log('edit mode');
            this.multiSelectedCells = [];
            if (this.previousRowId !== null && this.previousColumnKey) {
                const previousRow = this.grid.find((r) => r.Rw === this.previousRowId);
                if (previousRow) {
                    const previousCell = previousRow.Co.find((c) => c.id === this.previousColumnKey);
                    if (previousCell) {
                        previousCell.Pv = false;
                        // previousCell.iPV = false;
                    }
                }
            }
    
            const row = this.grid.find((r) => r.Rw === rowId);
            if (row) {
                const cell = row.Co.find((c) => c.id === columnKey);
                if (cell) {
                    console.log(cell.Pv);
                    cell.Pv = !cell.Pv;
                }
            }
            this.isSelected = true;
            this.isZone = true;
            this.isZoneHeader = true;
            this.isSearchPlot = true;
            this.previousColumnKey = columnKey;
            this.previousRowId = rowId;
            this.selectedPlotStatus = this.selectOption(plotStatus);
            this.setValues(plotId ? plotId : '', plotName ? plotName : '');
            this.grid = [...this.grid];
            this.tempGrid = structuredClone(this.grid);
            this.getCellDataFunction(plotId);

        } else if (this.isEditMode === true && (event.ctrlKey || event.metaKey)){ //when multiSelect 
            console.log('multi-->');

            const cellObj = { Rw: rowId, Co: columnKey, pId: plotId ? plotId : '' };
            const isSelect = this.multiSelectedCells.some(cell => cell.Rw === cellObj.Rw && cell.Co === cellObj.Co);
    
            if (isSelect) {
                this.multiSelectedCells = this.multiSelectedCells.filter(cell => !(cell.Rw === cellObj.Rw && cell.Co === cellObj.Co));
            } else {
                this.multiSelectedCells.push(cellObj);
            }
            const row = this.grid.find((r) => r.Rw === rowId);
            if (row) {
                const cell = row.Co.find((c) => c.id === columnKey);
                if (cell) {
                    cell.st = 'ml'; //collor asigining on multi selecting the cell 
                }
            }

            this.grid = [...this.grid];
            if (this.timeoutId) {
                clearTimeout(this.timeoutId);
            }
            this.timeoutId = setTimeout(() => {
                if (this.previousRowId !== null && this.previousColumnKey) {
                    const previousRow = this.grid.find((r) => r.Rw === this.previousRowId);
                    if (previousRow) {
                        const previousCell = previousRow.Co.find((c) => c.id === this.previousColumnKey);
                        if (previousCell) {
                            previousCell.Pv = false;
                            // previousCell.iPV = false;
                        }
                    }
                }
        
                const row = this.grid.find((r) => r.Rw === rowId);
                if (row) {
                    const cell = row.Co.find((c) => c.id === columnKey);
                    if (cell) {
                        console.log(cell.Pv);
                        cell.Pv = !cell.Pv;
                    }
                }
                this.previousColumnKey = columnKey;
                this.previousRowId = rowId;
                this.grid = [...this.grid];
                this.tempGrid = structuredClone(this.grid);
                
            }, 1500);
            console.log('multiSelectedCells-->', this.multiSelectedCells);
        } else{
            this.multiSelectedCells = [];
            if (cellLabel === 'Plot') {
                console.log('dddddd');
                this.isSingleSelect = true;
                this.openModal(columnKey, rowId);
                this.isSelected = true;
                this.setValues(plotId, plotName);
                this.selectedPlotStatus = this.selectOption(plotStatus);
                this.getCellDataFunction(plotId);
            }
        }
        console.log('multiSelectedCells-->',JSON.stringify(this.multiSelectedCells));
        // console.log('grid-->',JSON.stringify(this.grid));
    }

    generateZonePicklistOptions() {
        this.zoneOptions = [{ label: 'None', value: 'None' }]
        const dynamicOptions = Array.from({ length: this.noOfZone }, (_, index) => ({
            label: `${index + 1}`,
            value: `${index + 1}`
        }));
        this.zoneOptions = [...this.zoneOptions, ...dynamicOptions];
    }

    getCellDataFunction(pId){
        if (!pId) { 
            this.cellData = [];
            return;
        }
    
        getCellData({ plotId: pId })
            .then(result => {
                this.cellData = [result];
                console.log('status-->',result.Status__c);
                
                this.selectedPlotStatus = result.Status__c
                this.selectedPlotFacing = result.Plot_Facing__c
            })
            .catch(error => {
                console.error('Error fetching cell data:', error);
            });
    }
    selectOption(plotStatus){
        if (plotStatus === 'av') {
            return 'Available'
        } else if (plotStatus === 'hd') {
            return 'Hold'
        } else if (plotStatus === 'tb') {
            return 'Temp Blocked'
        } else if (plotStatus === 'bl') {
            return 'Blocked'
        } else if (plotStatus === 'bk') {
            return 'Booked'
        } else if (plotStatus === 'sd') {
            return 'Sold'
        } else if (plotStatus === 'rg') {
            return 'Registered'
        } else if (plotStatus === 'mb') {
            return 'Management Blocked'
        } else if (plotStatus === 'mg') {
            return 'Mortgage'
        } else if (plotStatus === 'ns') {
            return 'Not For Sale'
        }
        return '';
    }

    handleOptionClick(event) { //when Edit Mode is true
        // console.log('sjkv');
        event.stopPropagation();
        const selectedOption = event.target.dataset.option;
        const plotId = event.target.dataset.pid;
        console.log('selected',selectedOption);
        
        if (this.multiSelectedCells.length === 0) { // Single Click
            this.isMultiSelect = false;
            this.columnIndex = 0;
            const columnKey = event.target.dataset.key; 
            const rowId = parseInt(event.target.dataset.row, 10); 
            if (plotId !== '' && selectedOption === 'Plot') {
                this.isSingleSelect = true;
                this.isZone = true;
                this.isSearchPlot = true;
                this.openModal(columnKey, rowId);
                this.getCellDataFunction(plotId);
                this.grid = this.updateCellSelection(this.grid, rowId, columnKey, selectedOption, false);
                this.tempGrid = structuredClone(this.grid);
            } else if (selectedOption !== 'None') {
                this.isSingleSelect = false;
                this.isModalOpen = true;
                this.isZone = true;
                this.isSearchPlot = false;
                this.selectedOption = selectedOption;
                this.selectedRowId = rowId;
                this.selectedColumnKey = columnKey;
            } else {
                this.grid = this.updateCellSelection(this.grid, rowId, columnKey, selectedOption, false);
                this.tempGrid = structuredClone(this.grid);
            }
            
        } else if (selectedOption === 'Plot') { // Multiple Select of Plots
            const len = this.multiSelectedCells.length;
            this.isZone = true;
            this.isSearchPlot = true;
            this.isSelected = true;
            this.isMultiSelect = true
            this.isSingleSelect = false;
            this.isModalOpen = true
            this.cellValue = this.multiSelectedCells[this.currentIndex].Co
            // disableing the last cell option
            this.grid = this.updateCellSelection(this.grid, this.multiSelectedCells[len - 1].Rw, this.multiSelectedCells[len - 1].Co, selectedOption, false);
            this.getCellDataFunction(this.multiSelectedCells[this.currentIndex].pId);
            this.tempMultiGrid = structuredClone(this.grid);
            this.tempGrid = structuredClone(this.grid);
        } else if (selectedOption !== 'None') { // Multiple Select apart from Plot
            this.isSingleSelect = false;
            this.isModalOpen = true;
            this.isZone = true;
            this.isSearchPlot = false;
            this.selectedOption = selectedOption;
        } else {
            this.multiSelectedCells.forEach(({ Rw, Co }) => {
                this.grid = this.updateCellSelection(this.grid, Rw, Co, selectedOption, false);
                this.tempGrid = structuredClone(this.grid);
            });
            this.multiSelectedCells = [];
        }
        // console.log('Updated Grid: after', JSON.stringify(this.grid));
    }

    updateCellSelection(grid, rowId, columnKey, selectedOption, isOpenModal) {
        // console.log('selectde---->',selectedOption);
        // console.log('columnKey---->',columnKey);
        // console.log('rowId---->',rowId);
        
        const newGrid = grid.map(row => {
            if (row.Rw === rowId) {
                return {
                    ...row,
                    Co: row.Co.map(cell => {
                        if (cell.id === columnKey) {
                            let updatedCell = { ...cell };
                            switch (selectedOption) {
                                case 'None':
                                    updatedCell.ty = '';
                                    updatedCell.Pv = false;
                                    delete updatedCell.pId;
                                    delete updatedCell.pN;
                                    delete updatedCell.pS;
                                    delete updatedCell.st;
                                    delete updatedCell.pF;
                                    break;
                                case 'Plot':
                                    updatedCell.Pv = false;
                                    if (isOpenModal) {
                                        this.openModal(columnKey, rowId);
                                    }
                                    break;
                                case 'Garden':
                                    // updatedCell.st = `background-color: ${this.gardenColor};`;
                                    updatedCell.st = 'gd';
                                    updatedCell.Pv = false;
                                    updatedCell.z = this.selectedZone;
                                    delete updatedCell.pId;
                                    delete updatedCell.pN;
                                    delete updatedCell.pS;
                                    delete updatedCell.pF;
                                    break;
                                case 'Road':
                                    // updatedCell.st = `background-color: ${this.roadColor};`;
                                    updatedCell.st = 'rd';
                                    updatedCell.Pv = false;
                                    updatedCell.z = this.selectedZone;
                                    delete updatedCell.pId;
                                    delete updatedCell.pN;
                                    delete updatedCell.pS;
                                    delete updatedCell.pF;
                                    break;
                            }
                            if (selectedOption !== 'None') {
                                updatedCell.ty = selectedOption;
                            }
                            return updatedCell;
                        }
                        return cell;
                    })
                };
            }
            return row;
        });
        return newGrid;
    }

    handleButton(event) {
        if (event.target.label === 'Save') {
            
            const plotCells = [];
            const gardenCells = [];
            const roadCells = [];

            this.grid.forEach(row => {
                row.Co.forEach(cell => {
                    if (cell.ty === 'Plot') {
                        plotCells.push({
                            id: cell.id,
                            pN: cell.pN,
                            pId: cell.pId,
                            pS: cell.pS,
                            pF: cell.pF,
                            z: cell.z
                        });
                    } else if (cell.ty === 'Garden') {
                        gardenCells.push({
                            id: cell.id,
                            z: cell.z
                        });
                    } else if (cell.ty === 'Road') {
                        roadCells.push({
                            id: cell.id,
                            z: cell.z
                        });
                    }
                });
            });

            // console.log('JSON.stringify(this.grid);-->',JSON.stringify(this.grid));
            // console.log('JSON.stringify(plotCells);-->',JSON.stringify(plotCells));
            
            const fields = {};
            fields.Id = this.recordId;
            fields[PLOT_FIELD.fieldApiName] = JSON.stringify(plotCells);
            fields[GARDEN_FIELD.fieldApiName] = JSON.stringify(gardenCells);
            fields[ROAD_FIELD.fieldApiName] = JSON.stringify(roadCells);

            const recordInput = { fields };
            updateRecord(recordInput)
            .then(() => {
                this.showToast('Success', 'Record updated successfully!', 'success');
            })
            .catch(error => {
                this.showToast('Error', 'Error updating record', 'error');
                console.error('Error updating record', error);
            });
        } else if (event.target.label === 'Edit') {
            this.isEditMode = true;
        } else if (event.target.label === 'View') {
            this.isEditMode = false;
        }
    }

    openModal(cellId, rowId) {
        this.isModalOpen = true;
        this.selectedCellId = cellId;
        this.selectedRowId = rowId;
    }

    // not using anywhere 
    handlePlotNameChange(event) {
        this.plotName = event.target.value;
    }

    handlePlotDescriptionChange(event) {
        this.plotDescription = event.target.value;
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
                            type: plot.RecordType.Name,
                            plotFacing: plot.Plot_Facing__c
                        }));
                } else {
                    this.options = result.map(plot => ({
                        label: plot.Name,
                        value: plot.Id,
                        bPricePerSqFt: plot.Base_Price_per_Sq_Ft__c,
                        plotPrice: plot.Plot_Price__c,
                        plotStatus: plot.Status__c,
                        type: plot.RecordType.Name,
                        plotFacing: plot.Plot_Facing__c
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

    //Method to handle key press on text input
    handleKeyPress(event) {
        const searchKey = event.target.value;
        if (searchKey.length >= 3) {
            this.setInputValue(searchKey);
            if (this.delaytimeout) {
                window.clearTimeout(this.delaytimeout);
            }

            this.delaytimeout = setTimeout(() => {
                // Filter dropdown list based on search key
                // if (searchKey.length >= 3) {
                    searchPlots({ plotName: searchKey, phaseId: this.recordId})
                    .then(result => {
                        this.optionsToDisplay = result.map(plot => ({
                            label: plot.Name,
                            value: plot.Id,
                            bPricePerSqFt: plot.Base_Price_per_Sq_Ft__c,
                            plotPrice: plot.Plot_Price__c,
                            plotStatus: plot.Status__c,
                            type: plot.RecordType.Name,
                            plotFacing: plot.Plot_Facing__c
                        }));
                    })
                    .catch(error => {
                        console.error('Error','Error searching plots:', error);
                    });
                // }            
            }, delay);
        }
    }

    //Method to filter dropdown list
    filterDropdownList(key) {
        const filteredOptions = this.options.filter(item => item.label.toLowerCase().includes(key.toLowerCase()));
        this.optionsToDisplay = filteredOptions;
    }

    handleZoneChange(event) {
        this.selectedZone = event.detail.value;
        console.log('selected Option--->',this.selectedOption);
        
        if (this.selectedOption !== '') {
            if (this.multiSelectedCells.length === 0 ) { 
                this.grid = this.updateCellSelection(this.grid, this.selectedRowId, this.selectedColumnKey, this.selectedOption, false);
                this.tempGrid = structuredClone(this.grid);
            } else{
                this.multiSelectedCells.forEach(({ Rw, Co }) => {
                    this.grid = this.updateCellSelection(this.grid, Rw, Co, this.selectedOption, false);
                    this.tempGrid = structuredClone(this.grid);
                });
                this.multiSelectedCells = [];
            }
            this.closeModal();
        }
    }
    //Method to handle selected options in listbox
    optionsClickHandler(event) {
        const  value = event.target.closest('li').dataset.value;
        const  label = event.target.closest('li').dataset.label;
        console.log('vale-->',value);
        console.log('label-->',label);
        
        this.setValues(value, label);
        this.toggleOpenDropDown(false);
        // this.closeDropdown();
        const detail = {
            value: value,
            label: label
        };
        this.getCellDataFunction(value);
        this.dispatchEvent(new CustomEvent('change', { detail: detail }));
    }
    
    handleChangeStatus(plotStatus){
        this.selectedPlotStatus = plotStatus.target.value
    }

    handlePlotSave(event) {
        if (event.target.label === 'Save') {
            let plotStatusMap = {};
            const row = this.grid.find((r) => r.Rw === this.selectedRowId);
            if (row) {
                const cell = row.Co.find((c) => c.id === this.selectedCellId);
                if (cell && this.isSelected === true) {
                    cell.pId = this.value;
                    cell.pN = this.label;
                    cell.z = this.selectedZone;
                    
                    // cellId = cell.pId;
                    const statusMapping = {
                        'Available': 'av',
                        'Hold': 'hd',
                        'Temp Blocked': 'tb',
                        'Blocked': 'bl',
                        'Booked': 'bk',
                        'Sold': 'sd',
                        'Registered': 'rg',
                        'Management Blocked': 'mb',
                        'Mortgage': 'mg',
                        'Not For Sale': 'ns'
                    };
        
                    cell.pS = statusMapping[this.selectedPlotStatus] || '';
                    // cell.st = `background-color: ${this.getCellColor(cell.pS)};`
                    cell.st = cell.pS;
                    cell.pF = this.selectedPlotFacing;
                    plotStatusMap[this.value] = this.selectedPlotStatus;
                }
            }

            this.grid = [...this.grid];
            this.tempGrid = structuredClone(this.grid);
            this.label = "";
            this.value = "";
            
            // console.log('Updated Grid: after', JSON.stringify(this.grid));
            console.log('Updated Grid: after', this.selectedPlotStatus);
            
            if (this.isSelected === true && Object.keys(plotStatusMap).length > 0) {
                updatePlotStatus({ plotStatusMap }) 
                .then(result => {
                    // console.log('Bulk update result--->', result);
                    this.showToast('Success', 'Plot mapped successfully!', 'success');
                    this.closeModal();
                })
                .catch(error => {
                    console.error('Error updating plots:', error);
                });
            }
        } else if (event.target.label === 'Create Quote') {
            this.isQuoteModal = true
            this.isModalOpen = false
            

        } else if (event.target.label === 'Back') {
            this.isQuoteModal = false
            this.isModalOpen = true
        } else if (event.target.label === 'Create') {
            this.isQuoteModal = false
            this.isModalOpen = false
            this.handleNavigate();
        }
    }
    
    handleMultiNavigationButton(event){
        if (event.target.label === 'Previous' && this.currentIndex > 0) {
            console.log('index-->',this.currentIndex);
            console.log('lbel---ddpre>',this.selectedPlotStatus);
            if (this.selectedPlotStatus !== '') {
                let selectedPId, selectedpN;
                console.log('lbel---pre>',this.selectedPlotStatus);
                selectedpN = this.label;

                if (this.value) {
                    selectedPId = this.value;
                    this.multiSelectedCells[this.currentIndex].pId = selectedPId;
                } else if (this.multiSelectedCells[this.currentIndex] && this.multiSelectedCells[this.currentIndex].pId) {
                    selectedPId = this.multiSelectedCells[this.currentIndex].pId;
                } 
                const row = this.grid.find((r) => r.Rw === this.multiSelectedCells[this.currentIndex].Rw);
                if (row) {
                    const cell = row.Co.find((c) => c.id === this.multiSelectedCells[this.currentIndex].Co);
                    if (cell && this.isSelected === true) {
                        cell.pId = selectedPId;
                        cell.pN = selectedpN ? selectedpN : cell.pN;
                        cell.ty = 'Plot';
                        
                        // cellId = cell.pId;
                        const statusMapping = {
                            'Available': 'av',
                            'Hold': 'hd',
                            'Temp Blocked': 'tb',
                            'Blocked': 'bl',
                            'Booked': 'bk',
                            'Sold': 'sd',
                            'Registered': 'rg',
                            'Management Blocked': 'mb',
                            'Mortgage': 'mg',
                            'Not For Sale': 'ns'
                        };
            
                        cell.pS = statusMapping[this.selectedPlotStatus] || '';
                        cell.pF = this.selectedPlotFacing;
                        // cell.st = `background-color: ${this.getCellColor(cell.pS)};`
                        cell.st = cell.pS
                        cell.z = this.selectedZone
                    }
                }
                // this.getCellDataFunction(this.multiSelectedCells[this.currentIndex].pId);

                this.grid = [...this.grid];
                this.tempGrid = structuredClone(this.grid);
                this.label = "";
                this.value = "";
                this.selectedPlotStatus = '';
                this.selectedPlotFacing = '';
                this.selectedZone = '';
                this.zoneValue = '';
            }
            this.currentIndex--;
            console.log('index-2->',this.currentIndex);
            this.previousButton = this.currentIndex === 0;  
            this.cellValue = this.multiSelectedCells[this.currentIndex].Co;
            let selectedPId, selectedpN;
            console.log('lbel---pre>',this.label);
            selectedpN = this.label;

            if (this.value) {
                selectedPId = this.value;
                this.multiSelectedCells[this.currentIndex].pId = selectedPId;
            } else if (this.multiSelectedCells[this.currentIndex] && this.multiSelectedCells[this.currentIndex].pId) {
                selectedPId = this.multiSelectedCells[this.currentIndex].pId;
            } 
            console.log('prev');
            this.getCellDataFunction(selectedPId);
            this.nextButton = false; 
            console.log('prev 2');
            console.log('this.value',selectedPId);
            console.log('.selectedpN',selectedpN);
            this.selectedPlotStatus = '';
            this.selectedPlotFacing = '';
            console.log('Updated Grid: after pre', JSON.stringify(this.multiSelectedCells));

        } else if (event.target.label === 'Next' && this.currentIndex < this.multiSelectedCells.length - 1) {
            this.currentIndex++;
            this.cellValue = this.multiSelectedCells[this.currentIndex].Co;
            this.nextButton = this.currentIndex === this.multiSelectedCells.length - 1;
            // this.getCellDataFunction(this.multiSelectedCells[this.currentIndex].pId);
            this.previousButton = false;
            console.log('lbel---nex>',this.label);
            
            let selectedPId, selectedpN;
            selectedpN = this.label;

            if (this.multiSelectedCells[this.currentIndex] && this.multiSelectedCells[this.currentIndex].pId) {
                selectedPId = this.multiSelectedCells[this.currentIndex].pId;
            } else if (this.value) {
                selectedPId = this.value;
                this.multiSelectedCells[this.currentIndex].pId = selectedPId;
            }
            this.getCellDataFunction(selectedPId);
            console.log('this.value',selectedPId);
            console.log('.selectedpN',selectedpN);

            if (selectedPId) {
                this.multiSelectedCells[this.currentIndex].pId = selectedPId;
                const row = this.grid.find((r) => r.Rw === this.multiSelectedCells[this.currentIndex-1].Rw);
                if (row) {
                    const cell = row.Co.find((c) => c.id === this.multiSelectedCells[this.currentIndex-1].Co);
                    if (cell && this.isSelected === true) {
                        cell.pId = selectedPId;
                        cell.pN = selectedpN ? selectedpN : cell.pN;
                        cell.ty = 'Plot';
                        
                        // cellId = cell.pId;
                        const statusMapping = {
                            'Available': 'av',
                            'Hold': 'hd',
                            'Temp Blocked': 'tb',
                            'Blocked': 'bl',
                            'Booked': 'bk',
                            'Sold': 'sd',
                            'Registered': 'rg',
                            'Management Blocked': 'mb',
                            'Mortgage': 'mg',
                            'Not For Sale': 'ns'
                        };
            
                        cell.pS = statusMapping[this.selectedPlotStatus] || '';
                        // cell.st = `background-color: ${this.getCellColor(cell.pS)};`
                        cell.pF = this.selectedPlotFacing;
                        cell.st = cell.pS
                        cell.z = this.selectedZone
                    }
                }
                this.getCellDataFunction(selectedPId);

                this.grid = [...this.grid];
                this.tempGrid = structuredClone(this.grid);
                this.label = "";
                this.value = "";
                this.selectedPlotStatus = '';
                this.selectedPlotFacing = '';
                this.selectedZone = '';
                this.zoneValue = '';
            }
            
            
            console.log('Updated Grid: after', JSON.stringify(this.multiSelectedCells));
        } else if (event.target.label === 'Save') {
            console.log('prev 4', this.currentIndex);
            console.log('value', this.value);
            this.isModalOpen = false;
            this.isMultiSelect = false;
            this.isSingleSelect = false;
            this.previousButton = true;
            this.nextButton = false;

            let selectedPId, selectedpN;
            selectedpN = this.label;

            if (this.value) {
                selectedPId = this.value;
                this.multiSelectedCells[this.currentIndex].pId = selectedPId;
            } else if (this.multiSelectedCells[this.currentIndex] && this.multiSelectedCells[this.currentIndex].pId) {
                selectedPId = this.multiSelectedCells[this.currentIndex].pId;
            }
            console.log('this.value',selectedPId);
            console.log('.selectedpN',selectedpN);
            this.getCellDataFunction(selectedPId);

            if (this.value || this.multiSelectedCells[this.currentIndex].pId !== '') {
                this.multiSelectedCells[this.currentIndex].pId = selectedPId;
                const row = this.grid.find((r) => r.Rw === this.multiSelectedCells[this.currentIndex].Rw);
                if (row) {
                    const cell = row.Co.find((c) => c.id === this.multiSelectedCells[this.currentIndex].Co);
                    if (cell && this.isSelected === true) {
                        cell.pId = selectedPId;
                        cell.pN = selectedpN ? selectedpN : cell.pN;
                        cell.ty = 'Plot';
                        
                        // cellId = cell.pId;
                        const statusMapping = {
                            'Available': 'av',
                            'Hold': 'hd',
                            'Temp Blocked': 'tb',
                            'Blocked': 'bl',
                            'Booked': 'bk',
                            'Sold': 'sd',
                            'Registered': 'rg',
                            'Management Blocked': 'mb',
                            'Mortgage': 'mg',
                            'Not For Sale': 'ns'
                        };
            
                        cell.pS = statusMapping[this.selectedPlotStatus] || '';
                        // cell.st = `background-color: ${this.getCellColor(cell.pS)};`
                        cell.pF = this.selectedPlotFacing;
                        cell.st = cell.pS
                        cell.z = this.selectedZone
                    }
                }

                this.grid = [...this.grid];
                this.tempGrid = structuredClone(this.grid);
                this.label = "";
                this.value = "";
                
                console.log('Updated Grid: after', JSON.stringify(this.multiSelectedCells));
                this.multiSelectedCells = [];
                this.isSelected = false;
                this.tempMultiGrid = [];
                this.currentIndex = 0;
                this.selectedPlotStatus = '';
                this.selectedPlotFacing = '';
                this.selectedZone = '';
                this.zoneValue = '';
            }
            
            console.log('Updated Grid: after', JSON.stringify(this.grid));
        }
    }

    // Filter accroding to selected Status--------------------------------------
    handleStatusFilter(event) {
        const selectedValue = event.detail.value;
        // If the user selects a filter, add it to the selectedStatusFilters array (if not already added)
        if (!this.selectedStatusFilters.includes(selectedValue)) {
            this.selectedStatusFilters.push(selectedValue);
            this.filterGridDataStatus(this.selectedStatusFilters);
        }
        // console.log('selectedStatusFilters--->', JSON.stringify(this.selectedStatusFilters));
    }

    handleRemoveStatus(event) {
        const removedFilter = event.detail.name;
        // Remove the filter from the selectedStatusFilters array
        this.selectedStatusFilters = this.selectedStatusFilters.filter(filter => filter !== removedFilter);
        // Apply filtering after removal
        this.filterGridDataStatus(this.selectedStatusFilters);
    }

    filterGridDataStatus(selectedStatusFilters) {
        if (selectedStatusFilters.includes('None') || selectedStatusFilters.length === 0 ) {
            // this.grid = structuredClone(this.tempGrid);
            this.selectedStatusFilters = []
        }
        this.grid = this.filterGrid(this.tempGrid, this.selectedStatusFilters,  this.selectedFacingFilters, this.selectedZoneFilters);
    }
    //------------------------------------------------------------------------
    
    //  

    handleFacingFilter(event) {
        const selectedValue = event.detail.value;
        
        // If the user selects a filter, add it to the selectedFacingFilters array (if not already added)
        if (!this.selectedFacingFilters.includes(selectedValue)) {
            this.selectedFacingFilters.push(selectedValue);
            this.filterFacingGridData(this.selectedFacingFilters);
        }
    }
    
    // Remove selected filter (pills)
    handleRemoveFacing(event) {
        const removedFilter = event.detail.name;
        this.selectedFacingFilters = this.selectedFacingFilters.filter(facing => facing !== removedFilter);
        this.filterFacingGridData(this.selectedFacingFilters);
    }
    
    filterFacingGridData(selectedFacingFilters) {
        
        if ((selectedFacingFilters.includes('None') || selectedFacingFilters.length === 0) ) {
            this.selectedFacingFilters = []
        } 
        this.grid = this.filterGrid(this.tempGrid, this.selectedStatusFilters,  this.selectedFacingFilters, this.selectedZoneFilters);
        
    }

    // ----------------------------------ZONE FILTER----------------------------------------------------
    handleZoneFilter(event) {
        const selectedValue = event.detail.value;
        
        // If the user selects a filter, add it to the selectedZoneFilters array (if not already added)
        if (!this.selectedZoneFilters.includes(selectedValue)) {
            this.selectedZoneFilters.push(selectedValue);
            this.filterZoneGridData(this.selectedZoneFilters);
        }
    }
    
    // Remove selected filter (pills)
    handleRemoveZone(event) {
        const removedFilter = event.detail.name;
        this.selectedZoneFilters = this.selectedZoneFilters.filter(facing => facing !== removedFilter);
        this.filterZoneGridData(this.selectedZoneFilters);
    }
    
    filterZoneGridData(selectedZoneFilters) {
        
        if ((selectedZoneFilters.includes('None') || selectedZoneFilters.length === 0) ) {
            this.selectedZoneFilters = []
        } 
        this.grid = this.filterGrid(this.tempGrid, this.selectedStatusFilters,  this.selectedFacingFilters, this.selectedZoneFilters);
    }

    // ----------------------------------------------------
    filterGrid(toFilterFromGrid, statusFilters, facingFilters, zSelectedValues) {
        const statusValues = statusFilters.map(label => this.getFilterValue(label)); // Convert labels to actual filter values
    
        return toFilterFromGrid.map(row => ({
            ...row,
            Co: row.Co.map(item => {
                const isPlot = item.ty === "Plot";
                const isGardenOrRoad = item.ty === "Garden" || item.ty === "Road";
    
                const statusMatch = isPlot ? (statusFilters.length === 0 || statusValues.includes(item.pS)) : true;
                const facingMatch = isPlot ? (facingFilters.length === 0 || facingFilters.includes(item.pF)) : true;
                const zMatch = zSelectedValues.length === 0 || zSelectedValues.includes(item.z.toString()); // Convert z to string for comparison
    
                // Apply filters based on type
                if ((isPlot && statusMatch && facingMatch && zMatch) || (isGardenOrRoad && zMatch)) {
                    return item;
                } else {
                    // Otherwise, clear the item
                    return { ...item, ty: "", st: "", pId: "", pN: "", pS: "", pF: "", z: "" };
                }
            })
        }));
    }

    getFilterValue(status) {
        const statusMap = {
            "Available": "av",
            "Hold": "hd",
            "Temp Blocked": "tb",
            "Blocked": "bl",
            "Booked": "bk",
            "Sold": "sd",
            "Registered": "rg",
            "Management Blocked": "mb",
            "Mortgage": "mg",
            "Not For Sale": "ns"
        };
        return statusMap[status] || '';
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

    zoomIn() {
        if (this.zoomLevel < 2) { // Maximum zoom level
            this.zoomLevel += 0.1;
            this.updateZoom();
        }
    }

    zoomOut() {
        if (this.zoomLevel > 0.5) { // Minimum zoom level
            this.zoomLevel -= 0.1;
            this.updateZoom();
        }
    }

    resetZoom() {
        this.zoomLevel = 1;
        this.updateZoom();
    }

    updateZoom() {
        this.template.querySelector('.zoom-wrapper').style.transform = `scale(${this.zoomLevel})`;
    }
}