/**
 * Author: Jaidev Singh
 * Created Date: March 9, 2025
 * Last Modified By: Jaidev Singh
 * Last Modified Date: March 9, 2025
 * Company: SaasWorx Consulting Pvt. Ltd.
 * Description: 
 * Version: 1.0
 */
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

    isSelectDisabled = true
    inputValues = '';
    // Main selection fields
    startRow;
    endRow;
    startColumn;
    endColumn;
    // Exclusion fields
    excludeRowStart;
    excludeRowEnd;
    excludeColumnStart;
    excludeColumnEnd
    
    multiSelect
    roadColor;
    gardenColor;
    rows = 5;
    columns = 5;
    plotData;
    roadData;
    gardenData;
    @track grid = [];
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
    selectedSectorId
    selectedColumnGroupKey;
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
    selectedCellId
    selectedRowId
    selectedPlotStatus = '';
    selectedPlotFacing = '';

    previousColumnGroupKey = ''; 
    previousColumnKey = ''; 
    previousRowId = null;
    previousSectorId = null
    zoomLevel = 1;

    // multiselect
    multiSelectedCells = [];
    timeoutId = null;
    isMultiSelect = false
    currentIndex = 0;
    cellValue
    previousButton = true
    nextButton = false

    statusOptions = [
        { label: 'Available', value: 'Available' },
        { label: 'Hold', value: 'Hold' },
        { label: 'Temp Blocked', value: 'Temp Blocked' },
        { label: 'Blocked', value: 'Blocked' },
        { label: 'Booked', value: 'Booked' },
        { label: 'Sold', value: 'Sold' },
        { label: 'Registered', value: 'Registered' },
        { label: 'Management Blocked', value: 'Management Blocked' },
        { label: 'Mortgage', value: 'Mortgage' },
        { label: 'Not For Sale', value: 'Not For Sale' }
    ];


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
        // Set CSS variables for colors
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
    
        const plotCells = this.plotData ? JSON.parse(this.plotData) : [];
        const gardenCells = this.gardenData ? JSON.parse(this.gardenData) : [];
        const roadCells = this.roadData ? JSON.parse(this.roadData) : [];
    
        this.grid = [];
        this.tempGrid = [];
        this.columnNames = [''];

        let sectionNumber = 1;
        let currentSection = { sc: sectionNumber, rM: [] };
        let rowCount = 0;

        for (let i = 1; i <= this.rows; i++) {
            const row = { Rw: i, Co: [] };
            let currentColumnGroup = { ck: `${i}1`, cols: [] };
            let columnCount = 0;
            let columnGroupIndex = 1;

            for (let j = 1; j <=this.columns; j++) {
                let columnName = this.getColumnName(j);
                const cellId = `${columnName}${i}`;
                const isPlot = plotCells.find(cell => cell.id === cellId);
                const isGarden = gardenCells.find(cell => cell.id === cellId);
                const isRoad = roadCells.find(cell => cell.id === cellId);

                let cellData = {
                    id: cellId,
                    Pv: false,
                    ty: '',
                    st: '',
                    z: ''
                };

                if (isPlot) {
                    cellData.ty = 'Plot';
                    cellData.st = isPlot.pS;
                    cellData.pId = isPlot.pId;
                    cellData.pN = isPlot.pN;
                    cellData.pS = isPlot.pS;
                    cellData.pF = isPlot.pF;
                    cellData.z = isPlot.z;
                } else if (isGarden) {
                    cellData.ty = 'Garden';
                    cellData.st = 'gd';
                    cellData.z = isGarden.z;
                } else if (isRoad) {
                    cellData.ty = 'Road';
                    cellData.st = 'rd';
                    cellData.z = isRoad.z;
                }

                currentColumnGroup.cols.push(cellData);
                columnCount++;

            //    if (columnCount === 5 || j === this.columns) {
                if (columnCount == 5 ) {
                    row.Co.push({ ck: `${i}${columnGroupIndex}`, cols: currentColumnGroup.cols });
                    columnGroupIndex++;
                    currentColumnGroup = { ck: `${i}${columnGroupIndex}`, cols: [] };
                    columnCount = 0;
                }
                   
                if (i === 1) {
                    this.columnNames.push(columnName);
                }
            }

            currentSection.rM.push(row);
            rowCount++;

            if (rowCount === 10 || i === this.rows) {
            // if (rowCount === 5) {
                this.grid.push(currentSection); 
                if (i !== this.rows) {
                    sectionNumber++;
                    currentSection = { sc: sectionNumber, rM: [] };
                    rowCount = 0;
                }
            }

           // console.log('426 '+JSON.stringify(this.grid));
        }
    
        this.setOptionsAndValues();
        this.tempGrid = structuredClone(this.grid);
        // console.log('Generated Grid Sections:', JSON.stringify(this.grid));
        this.generateZonePicklistOptions();
    }
    
    // Helper function to generate column names (A, B, ..., Z, AA, AB, etc.)
    getColumnName(index) {
        let columnName = '';
        while (index > 0) {
            const remainder = (index - 1) % 26;
            columnName = String.fromCharCode(65 + remainder) + columnName;
            index = Math.floor((index - 1) / 26);
        }
        return columnName;
    }
    
    getCellColor(plotStatus){
        const colorMapping = {
            'av': this.availablePlot,
            'hd': this.holdPlot,
            'bk': this.bookedPlot
        };
        return colorMapping[plotStatus] || '';
    }

    generateZonePicklistOptions() {
        this.zoneOptions = [{ label: 'None', value: 'None' }]
        const dynamicOptions = Array.from({ length: this.noOfZone }, (_, index) => ({
            label: `${index + 1}`,
            value: `${index + 1}`
        }));
        this.zoneOptions = [...this.zoneOptions, ...dynamicOptions];
    }

    handleInputChanged(event) {
        const {
            startRow,
            endRow,
            startColumn,
            endColumn,
            excludeRowStart,
            excludeRowEnd,
            excludeColumnStart,
            excludeColumnEnd,
            multiSelectedCells,
            girdData,
            isEditMode
        } = event.detail;

        // Map the received values to the parent component's variables
        this.startRow = startRow;
        this.endRow = endRow;
        this.startColumn = startColumn;
        this.endColumn = endColumn;
        this.excludeRowStart = excludeRowStart;
        this.excludeRowEnd = excludeRowEnd;
        this.excludeColumnStart = excludeColumnStart;
        this.excludeColumnEnd = excludeColumnEnd;
        this.multiSelectedCells = multiSelectedCells;
        this.grid = [...girdData];
        this.isEditMode = isEditMode;
        
        // if(this.startRow && this.endRow && this.startColumn && this.endColumn){
        //     this.isSelectDisabled = false;
        // } else{
        //     this.isSelectDisabled = true;
        // }
    }

    togglePopover(event) {
        try{
        // event.stopPropagation();
        // console.log('grid-->',JSON.stringify(this.grid));
       
        const sectorId = parseInt(event.target.dataset.sector, 10);
        //  console.log('sector Id '+sectorId);
        //   console.log('sector value '+event.target.dataset.sector);
        const rowId = parseInt(event.target.dataset.row, 10);
        const columnGroupKey = event.target.dataset.colkey;
        const columnKey = event.target.dataset.key;
        const plotId = event.target.dataset.pid;
        const cellLabel = event.target.dataset.label;
        const plotName = event.target.dataset.pn;
        const plotStatus = event.target.dataset.ps;
        this.selectedOption = '';
        // console.log('columnGroupKey--->', columnGroupKey);
        // console.log('previousColumnKey--->', this.previousColumnKey);
        // console.log('sectorId--->', sectorId);
        // console.log('rowId--->', rowId);
        // console.log('columnKey--->', columnKey);
        // console.log('plotId--->', plotId);
        // console.log('plotName--->', plotName);
        // console.log('plotStatus--->', plotStatus);
        //single Select on Edit Modev
        if (this.isEditMode === true && !(event.ctrlKey || event.metaKey)) { 
            let mutableGrid = JSON.parse(JSON.stringify(this.grid));

            // Use Map for faster lookup on the cloned grid
            const sectorMap = new Map(mutableGrid.map(sec => [sec.sc, sec]));
            
            // Clear previous selection, update current selection, etc.
            if (this.previousSectorId) {
                const prevSector = sectorMap.get(this.previousSectorId);
                if (prevSector) {
                    const previousRow = prevSector.rM.find(r => r.Rw === this.previousRowId);
                    if (previousRow) {
                        const previousColumnGroup = previousRow.Co.find(cg => cg.ck === this.previousColumnGroupKey);
                        if (previousColumnGroup) {
                            const previousCell = previousColumnGroup.cols.find(c => c.id === this.previousColumnKey);
                            if (previousCell) {
                                previousCell.Pv = false;
                            }
                        }
                    }
                }
            }
            
            // Update current selection
            const sector = sectorMap.get(parseInt(event.target.dataset.sector, 10));
            if (sector) {
                const row = sector.rM.find(r => r.Rw === parseInt(event.target.dataset.row, 10));
                if (row) {
                    const columnGroup = row.Co.find(cg => cg.ck === event.target.dataset.colkey);
                    if (columnGroup) {
                        const cell = columnGroup.cols.find(c => c.id === event.target.dataset.key);
                        if (cell) {
                            cell.Pv = !cell.Pv;
                        }
                    }
                }
            }

            // Reassign the updated mutableGrid back to grid (or dispatch it to the parent)
            this.grid = mutableGrid;
            // console.log('grid-->',JSON.stringify(this.grid));
            
            // Minimize unnecessary re-renders
            this.previousSectorId = sectorId;
            this.previousRowId = rowId;
            this.previousColumnGroupKey = columnGroupKey;
            this.previousColumnKey = columnKey;
            this.selectedPlotStatus = this.selectOption(plotStatus);
            this.grid = JSON.parse(JSON.stringify(this.grid));
            this.tempGrid = this.grid;
            this.isSelected = true;
            this.isZone = true;
            this.isZoneHeader = false;
            this.isSearchPlot = true;
        } else if (this.isEditMode === true && (event.ctrlKey || event.metaKey)){ //when multiSelect 
            const cellObj = { sc: sectorId, ck: columnGroupKey, Rw: rowId, Co: columnKey, pId: plotId };
    
            // Toggle selection state
            const isSelected = this.multiSelectedCells.some(cell => cell.Rw === rowId && cell.Co === columnKey);
            this.multiSelectedCells = isSelected
                ? this.multiSelectedCells.filter(cell => !(cell.Rw === rowId && cell.Co === columnKey))
                : [...this.multiSelectedCells, cellObj];
            console.log('sssA');
            
            // Retrieve sector, row, cellGroup, and cell efficiently using Maps
            const sector = this.gridMap.get(sectorId);
            const rowObj = sector?.rM?.get(rowId);
            const cellGroup = rowObj?.Co?.get(columnGroupKey);
            const cell = cellGroup?.cols?.get(columnKey);
    
            if (cell) {
                cell.st = 'ml'; // Assign color on multi-select
            }
    
            console.log('--->', JSON.stringify(cellObj));
            console.log('multiSelectedCells--->', JSON.stringify(this.multiSelectedCells));
    
            // Optimize debounce for UI updates
            if (this.timeoutId) clearTimeout(this.timeoutId);
    
            this.timeoutId = setTimeout(() => {
                // Reset previous selection
                if (this.previousColumnKey) {
                    console.log('Reset previous ->', this.previousColumnKey);
                    const prevSector = this.gridMap.get(this.previousSectorId);
                    const prevRow = prevSector?.rM?.get(this.previousRowId);
                    const prevCellGroup = prevRow?.Co?.get(this.previousColumnGroupKey);
                    const prevCell = prevCellGroup?.cols?.get(this.previousColumnKey);
    
                    if (prevCell) prevCell.Pv = false;
                }
    
                // Update current selection
                const currentSector = this.gridMap.get(sectorId);
                const currentRow = currentSector?.rM?.get(rowId);
                const currentCellGroup = currentRow?.Co?.get(columnGroupKey);
                const currentCell = currentCellGroup?.cols?.get(columnKey);
    
                if (currentCell) currentCell.Pv = !currentCell.Pv;
    
                // Save previous selection
                this.previousSectorId = sectorId;
                this.previousRowId = rowId;
                this.previousColumnGroupKey = columnGroupKey;
                this.previousColumnKey = columnKey;
    
                // Ensure only modified parts of the grid are updated
                this.tempGrid = structuredClone(this.grid);
            }, 1000); // Reduced debounce time for better responsiveness
            console.log('multiSelectedCells-->', JSON.stringify(this.multiSelectedCells));
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
        // console.log('multiSelectedCells-->',JSON.stringify(this.multiSelectedCells));
        // console.log('grid-->',JSON.stringify(this.grid));
    
    }catch(ex){
            console.log("togglePopover  : "+ex);
        }
    }
    // // Computed property to disable the Select button if any field is missing.
    // get isSelectDisabled() {
    //     // Adjust the condition if "0" is a valid value.
    //     return !(this.startRow && this.endRow && this.startColumn && this.endColumn);
    // }

    handleFieldChange(event) {
        const fieldLabel = event.target.label;
        const value = event.target.value;
        switch (fieldLabel) {
            case 'Start Row':
                this.startRow = value;
                break;
            case 'End Row':
                this.endRow = value;
                break;
            case 'Start Column':
                this.startColumn = value.toUpperCase();
                break;
            case 'End Column':
                this.endColumn = value.toUpperCase();
                break;
            case 'Exclude Row Start':
                this.excludeRowStart = value;
                break;
            case 'Exclude Row End':
                this.excludeRowEnd = value;
                break;
            case 'Exclude Column Start':
                this.excludeColumnStart = value.toUpperCase();
                break;
            case 'Exclude Column End':
                this.excludeColumnEnd = value.toUpperCase();
                break;
            default:
                break;
        }
    }   

    // Handle the custom event from the child component
    handleSelectDisabledChange(event) {
        this.isSelectDisabled = event.detail.isSelectDisabled;
    }

    // generateZonePicklistOptions() {
    //     this.zoneOptions = [{ label: 'None', value: 'None' }]
    //     const dynamicOptions = Array.from({ length: this.noOfZone }, (_, index) => ({
    //         label: `${index + 1}`,
    //         value: `${index + 1}`
    //     }));
    //     this.zoneOptions = [...this.zoneOptions, ...dynamicOptions];
    // }

    async getCellDataFunction(pId){
        if (!pId) { 
            this.cellData = [];
            return;
        }
    ``
        getCellData({ plotId: pId })
            .then(result => {
                this.cellData = [result];
                console.log('status-->',result.Status__c);
                console.log('status-->',JSON.stringify(this.cellData));
                
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

    async handleOptionClick(event) { //when Edit Mode is true
        // console.log('sjkv');
        event.stopPropagation();
        const sectorId = parseInt(event.target.dataset.sector, 10);
        const columnGroupKey = event.target.dataset.colkey;
        const selectedOption = event.target.dataset.option;
        const plotId = event.target.dataset.pid;
        const plotName = event.target.dataset.pn;
        // console.log('selected',selectedOption);
        
        if (this.multiSelectedCells.length === 0) { // Single Click
            this.isMultiSelect = false;
            this.columnIndex = 0;
            const columnKey = event.target.dataset.key; 
            const rowId = parseInt(event.target.dataset.row, 10); 
            // console.log('row--->',rowId);
            
            if (plotId !== '' && selectedOption === 'Plot') {
                this.isSingleSelect = true;
                this.isZone = true;
                this.isSearchPlot = true;
                this.openModal(columnKey, rowId);
                await this.setValues(plotId ? plotId : '', plotName ? plotName : '');
                await this.getCellDataFunction(plotId);
                this.grid = this.updateCellSelection(this.grid, sectorId, rowId, columnGroupKey, columnKey, selectedOption, false);
                this.tempGrid = structuredClone(this.grid);
            } else if (selectedOption !== 'None') {
                this.isSingleSelect = false;
                this.isModalOpen = true;
                this.isZone = true;
                this.isSearchPlot = false;
                this.selectedOption = selectedOption;
                this.selectedSectorId = sectorId
                this.selectedColumnGroupKey = columnGroupKey
                this.selectedRowId = rowId;
                this.selectedColumnKey = columnKey;
            } else {
                this.grid = this.updateCellSelection(this.grid, sectorId, rowId, columnGroupKey, columnKey, selectedOption, false);
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
            this.grid = this.updateCellSelection(this.grid, this.multiSelectedCells[len - 1].sc,  this.multiSelectedCells[len - 1].rw, this.multiSelectedCells[len - 1].ck, this.multiSelectedCells[len - 1].Co, selectedOption, false);
            await this.getCellDataFunction(this.multiSelectedCells[this.currentIndex].pId);
            this.tempMultiGrid = structuredClone(this.grid);
            this.tempGrid = structuredClone(this.grid);
        } else if (selectedOption !== 'None') { // Multiple Select apart from Plot and None
            this.isSingleSelect = false;
            this.isModalOpen = true;
            this.isZone = true;
            this.isZoneHeader = true;
            this.isSearchPlot = false;
            this.selectedOption = selectedOption;
        } else {
            // this.multiSelectedCells.forEach(({ Rw, Co }) => {
            //     this.grid = this.updateCellSelection(this.grid, Rw, Co, selectedOption, false);
            //     this.tempGrid = structuredClone(this.grid);
            // });
            // this.multiSelectedCells = [];
            this.multiSelectedCells.forEach(({ sc, ck, Rw, Co }) => {
                this.grid = this.updateCellSelection(
                    this.grid, 
                    sc,  // Sector ID
                    Rw,  // Row ID
                    ck,  // Column Group Key
                    Co,  // Column Key
                    selectedOption, 
                    false
                );
            });
            
            // Ensure immutability and avoid unnecessary reassignments
            this.grid = [...this.grid];  
            this.tempGrid = structuredClone(this.grid);
        }
        // console.log('Updated Grid: after', JSON.stringify(this.grid));
    }

    updateCellSelection(grid, sectorId, rowId, columnGroupKey, columnKey, selectedOption, isOpenModal) {
        // console.log('sectorId---->', sectorId);
        // console.log('rowId---->', rowId);
        // console.log('columnGroupKey---->', columnGroupKey);
        // console.log('columnKey---->', columnKey);
        // console.log('selectedOption---->', selectedOption);
    
        // Create an updated copy of the grid
        const updatedGrid = grid.map(sector => {
            // Only update if the sector matches
            if (sector.sc !== sectorId) {
                return sector;
            }
            return {
                ...sector,
                rM: sector.rM.map(row => {
                    // Only update if the row matches
                    if (row.Rw !== rowId) {
                        return row;
                    }
                    return {
                        ...row,
                        Co: row.Co.map(columnGroup => {
                            // Only update if the column group matches
                            if (columnGroup.ck !== columnGroupKey) {
                                return columnGroup;
                            }
                            return {
                                ...columnGroup,
                                cols: columnGroup.cols.map(cell => {
                                    // Only update the cell if the cell id matches
                                    if (cell.id !== columnKey) {
                                        return cell;
                                    }
                                    // Clone cell to update it immutably.
                                    let updatedCell = { ...cell };
    
                                    // Apply selection logic based on the selected option.
                                    switch (selectedOption) {
                                        case 'None':
                                            updatedCell.ty = '';
                                            updatedCell.Pv = false;
                                            // Remove any plot-specific properties
                                            delete updatedCell.pId;
                                            delete updatedCell.pN;
                                            delete updatedCell.pS;
                                            delete updatedCell.st;
                                            delete updatedCell.pF;
                                            break;
                                        case 'Plot':
                                            updatedCell.Pv = false;
                                            // Open modal if required
                                            if (isOpenModal) {
                                                this.openModal(columnKey, rowId);
                                            }
                                            break;
                                        case 'Garden':
                                            updatedCell.st = 'gd'; // Set style for Garden
                                            updatedCell.Pv = false;
                                            updatedCell.z = this.selectedZone; // Set zone from component state
                                            // Remove any plot-specific properties
                                            delete updatedCell.pId;
                                            delete updatedCell.pN;
                                            delete updatedCell.pS;
                                            delete updatedCell.pF;
                                            break;
                                        case 'Road':
                                            updatedCell.st = 'rd'; // Set style for Road
                                            updatedCell.Pv = false;
                                            updatedCell.z = this.selectedZone; // Set zone from component state
                                            // Remove any plot-specific properties
                                            delete updatedCell.pId;
                                            delete updatedCell.pN;
                                            delete updatedCell.pS;
                                            delete updatedCell.pF;
                                            break;
                                        default:
                                            // Optionally handle other cases or do nothing
                                            break;
                                    }
    
                                    // If the selected option is not 'None', set the type.
                                    if (selectedOption !== 'None') {
                                        updatedCell.ty = selectedOption;
                                    }
                                    return updatedCell;
                                })
                            };
                        })
                    };
                })
            };
        });
        return updatedGrid;
    }
    
    // handleButton(event) {
    //     if (event.target.label === 'Save') {
            
    //         const plotCells = [];
    //         const gardenCells = [];
    //         const roadCells = [];

    //         // Iterate over each sector in the grid.
    //         this.grid.forEach(sector => {
    //             // For each row (rM) in the sector
    //             sector.rM.forEach(row => {
    //                 // For each column group (Co) in the row
    //                 row.Co.forEach(colGroup => {
    //                     // For each cell in the column group's cols array
    //                     colGroup.cols.forEach(cell => {
    //                         if (cell.ty === 'Plot') {
    //                             plotCells.push({
    //                                 id: cell.id,
    //                                 pN: cell.pN,
    //                                 pId: cell.pId,
    //                                 pS: cell.pS,
    //                                 pF: cell.pF,
    //                                 z: cell.z
    //                             });
    //                         } else if (cell.ty === 'Garden') {
    //                             gardenCells.push({
    //                                 id: cell.id,
    //                                 z: cell.z
    //                             });
    //                         } else if (cell.ty === 'Road') {
    //                             roadCells.push({
    //                                 id: cell.id,
    //                                 z: cell.z
    //                             });
    //                         }
    //                     });
    //                 });
    //             });
    //         });

    //         // Build the fields object to update the record.
    //         const fields = {};
    //         fields.Id = this.recordId;
    //         fields[PLOT_FIELD.fieldApiName] = JSON.stringify(plotCells);
    //         fields[GARDEN_FIELD.fieldApiName] = JSON.stringify(gardenCells);
    //         fields[ROAD_FIELD.fieldApiName] = JSON.stringify(roadCells);

    //         const recordInput = { fields };
    //         updateRecord(recordInput)
    //         .then(() => {
    //             this.showToast('Success', 'Record updated successfully!', 'success');
    //         })
    //         .catch(error => {
    //             this.showToast('Error', 'Error updating record', 'error');
    //             console.error('Error updating record', error);
    //         });
    //     } else if (event.target.label === 'Edit') {
    //         this.isEditMode = true;
    //     } else if (event.target.label === 'View') {
    //         this.isEditMode = false;
    //     }
    // }

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
        // console.log('selected Option--->',this.selectedOption);
        // console.log('multiSelectedCells--->',JSON.stringify(this.multiSelectedCells));
        
        // if (this.selectedOption !== '') {
        //     if (this.multiSelectedCells.length === 0 ) { 
        //         this.grid = this.updateCellSelection(this.grid, this.selectedRowId, this.selectedColumnKey, this.selectedOption, false);
        //         this.tempGrid = structuredClone(this.grid);
        //     } else{
        //         this.multiSelectedCells.forEach(({ Rw, Co }) => {
        //             this.grid = this.updateCellSelection(this.grid, Rw, Co, this.selectedOption, false);
        //             this.tempGrid = structuredClone(this.grid);
        //         });
        //         this.multiSelectedCells = [];
        //     }
        //     this.closeModal();
        // }

        if (this.selectedOption !== '') {
            if (this.multiSelectedCells.length === 0) { 
                this.grid = this.updateCellSelection(
                    this.grid, 
                    this.selectedSectorId, 
                    this.selectedRowId, 
                    this.selectedColumnGroupKey, 
                    this.selectedColumnKey, 
                    this.selectedOption, 
                    false
                );
            } else {
                this.multiSelectedCells.forEach(({ sc, ck, Rw, Co }) => {
                    this.grid = this.updateCellSelection(
                        this.grid, 
                        sc,  // Sector ID
                        Rw,  // Row ID
                        ck,  // Column Group Key
                        Co,  // Column Key
                        this.selectedOption, 
                        false
                    );
                });

                // Clear multi-selected cells after updating
                this.multiSelectedCells = [];
            }

            // Ensure reactivity by deep cloning
            this.tempGrid = structuredClone(this.grid);
            // console.log('grid--->',JSON.stringify(this.grid));
            this.closeModal();
        }
    }
    //Method to handle selected options in listbox
    async optionsClickHandler(event) {
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
        await this.getCellDataFunction(value);
        this.dispatchEvent(new CustomEvent('change', { detail: detail }));
    }
    
    handleChangeStatus(plotStatus){
        this.selectedPlotStatus = plotStatus.target.value
    }

    handlePlotSave(event) {
        try {
            if (event.target.label === 'Save') {
                // Create a mutable copy of the grid so we can update it.
                let mutableGrid = JSON.parse(JSON.stringify(this.grid));
                let plotStatusMap = {};
                let cellFound = false;
    
                // Iterate over each sector in the mutable grid
                for (const sector of mutableGrid) {
                    // Find the row with the matching selectedRowId
                    const row = sector.rM.find(r => r.Rw === this.selectedRowId);
                    if (row) {
                        // Iterate over each column group in the row
                        for (const colGroup of row.Co) {
                            // Find the cell with the matching selectedCellId
                            const cell = colGroup.cols.find(c => c.id === this.selectedCellId);
                            if (cell && this.isSelected === true) {
                                // Update cell properties
                                cell.pId = this.value;
                                cell.pN = this.label;
                                cell.z = this.selectedZone;
                                
                                // Map the full status text to its abbreviation
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
                                cell.st = cell.pS;
                                cell.pF = this.selectedPlotFacing;
                                plotStatusMap[this.value] = this.selectedPlotStatus;
                                
                                cellFound = true;
                                break; // Stop once the cell is updated
                            }
                        }
                    }
                    if (cellFound) break; // Exit outer loop if cell is updated
                }
                
                if (cellFound) {
                    // Update reactive properties by assigning the modified grid copy
                    this.grid = mutableGrid;
                    this.tempGrid = structuredClone(mutableGrid);
                    this.label = "";
                    this.value = "";
                    
                    console.log('Updated Grid: after', this.selectedPlotStatus);
                    
                    // If cell was updated and we have a valid plotStatusMap, call the API to update
                    if (this.isSelected === true && Object.keys(plotStatusMap).length > 0) {
                        updatePlotStatus({ plotStatusMap })
                            .then(result => {
                                this.showToast('Success', 'Plot mapped successfully!', 'success');
                                this.closeModal();
                            })
                            .catch(error => {
                                console.error('Error updating plots:', error);
                            });
                    }
                } else {
                    console.error('Cell not found for selectedRowId and selectedCellId');
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
        } catch (error) {
            this.showToast(
                'Error',
                error.message,
                'error'
            );
        }
    }
    
    async handleMultiNavigationButton(event){
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
            await this.getCellDataFunction(selectedPId);
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
            await this.getCellDataFunction(selectedPId);
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
                await this.getCellDataFunction(selectedPId);

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
            // console.log('prev 4', this.currentIndex);
            // console.log('value', this.value);
            // this.isModalOpen = false;
            // this.isMultiSelect = false;
            // this.isSingleSelect = false;
            // this.previousButton = true;
            // this.nextButton = false;

            // let selectedPId, selectedpN;
            // selectedpN = this.label;

            // if (this.value) {
            //     selectedPId = this.value;
            //     this.multiSelectedCells[this.currentIndex].pId = selectedPId;
            // } else if (this.multiSelectedCells[this.currentIndex] && this.multiSelectedCells[this.currentIndex].pId) {
            //     selectedPId = this.multiSelectedCells[this.currentIndex].pId;
            // }
            // console.log('this.value',selectedPId);
            // console.log('.selectedpN',selectedpN);
            // await this.getCellDataFunction(selectedPId);

            // if (this.value || this.multiSelectedCells[this.currentIndex].pId !== '') {
            //     this.multiSelectedCells[this.currentIndex].pId = selectedPId;
            //     const row = this.grid.find((r) => r.Rw === this.multiSelectedCells[this.currentIndex].Rw);
            //     if (row) {
            //         const cell = row.Co.find((c) => c.id === this.multiSelectedCells[this.currentIndex].Co);
            //         if (cell && this.isSelected === true) {
            //             cell.pId = selectedPId;
            //             cell.pN = selectedpN ? selectedpN : cell.pN;
            //             cell.ty = 'Plot';
                        
            //             // cellId = cell.pId;
            //             const statusMapping = {
            //                 'Available': 'av',
            //                 'Hold': 'hd',
            //                 'Temp Blocked': 'tb',
            //                 'Blocked': 'bl',
            //                 'Booked': 'bk',
            //                 'Sold': 'sd',
            //                 'Registered': 'rg',
            //                 'Management Blocked': 'mb',
            //                 'Mortgage': 'mg',
            //                 'Not For Sale': 'ns'
            //             };
            
            //             cell.pS = statusMapping[this.selectedPlotStatus] || '';
            //             // cell.st = `background-color: ${this.getCellColor(cell.pS)};`
            //             cell.pF = this.selectedPlotFacing;
            //             cell.st = cell.pS
            //             cell.z = this.selectedZone
            //         }
            //     }

            //     this.grid = [...this.grid];
            //     this.tempGrid = structuredClone(this.grid);
            //     this.label = "";
            //     this.value = "";
                
            //     console.log('Updated Grid: after', JSON.stringify(this.multiSelectedCells));
            //     this.multiSelectedCells = [];
            //     this.isSelected = false;
            //     this.tempMultiGrid = [];
            //     this.currentIndex = 0;
            //     this.selectedPlotStatus = '';
            //     this.selectedPlotFacing = '';
            //     this.selectedZone = '';
            //     this.zoneValue = '';
            // }
            
            // console.log('Updated Grid: after', JSON.stringify(this.grid));
            console.log('prev 4', this.currentIndex);
            console.log('value', this.value);
            this.isModalOpen = false;
            this.isMultiSelect = false;
            this.isSingleSelect = false;
            this.previousButton = true;
            this.nextButton = false;

            let selectedPId, selectedpN;
            selectedpN = this.label;

            // Determine the selected Plot Id
            if (this.value) {
                selectedPId = this.value;
                this.multiSelectedCells[this.currentIndex].pId = selectedPId;
            } else if (this.multiSelectedCells[this.currentIndex] && this.multiSelectedCells[this.currentIndex].pId) {
                selectedPId = this.multiSelectedCells[this.currentIndex].pId;
            }
            console.log('this.value', selectedPId);
            console.log('selectedpN', selectedpN);

            await this.getCellDataFunction(selectedPId);

            if (this.value || (this.multiSelectedCells[this.currentIndex] && this.multiSelectedCells[this.currentIndex].pId !== '')) {
                this.multiSelectedCells[this.currentIndex].pId = selectedPId;

                // Create a mutable copy of the grid
                let mutableGrid = JSON.parse(JSON.stringify(this.grid));
                let foundCell = null;

                // The grid structure: grid (array of sectors) → each sector has rM (rows) → each row has Co (column groups) → each column group has cols (cells)
                for (let sector of mutableGrid) {
                    const row = sector.rM.find(r => r.Rw === this.multiSelectedCells[this.currentIndex].Rw);
                    if (row) {
                        for (let colGroup of row.Co) {
                            foundCell = colGroup.cols.find(c => c.id === this.multiSelectedCells[this.currentIndex].Co);
                            if (foundCell) {
                                break;
                            }
                        }
                    }
                    if (foundCell) {
                        break;
                    }
                }

                if (foundCell && this.isSelected === true) {
                    foundCell.pId = selectedPId;
                    foundCell.pN = selectedpN ? selectedpN : foundCell.pN;
                    foundCell.ty = 'Plot';

                    // Map full status text to abbreviation
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

                    foundCell.pS = statusMapping[this.selectedPlotStatus] || '';
                    foundCell.pF = this.selectedPlotFacing;
                    foundCell.st = foundCell.pS; // or use a helper for color if needed
                    foundCell.z = this.selectedZone;
                }

                // Update reactive properties by assigning the modified mutableGrid back
                this.grid = mutableGrid;
                this.tempGrid = structuredClone(mutableGrid);

                // Reset temporary variables
                this.label = "";
                this.value = "";
                console.log('Updated MultiSelectedCells:', JSON.stringify(this.multiSelectedCells));
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
    async setValues(value, label) {
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
        // this.multiSelectedCells = [];
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