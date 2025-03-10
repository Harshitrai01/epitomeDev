/**
 * Author: Jaidev Singh
 * Created Date: March 9, 2025
 * Last Modified By: Jaidev Singh
 * Last Modified Date: March 9, 2025
 * Company: SaasWorx Consulting Pvt. Ltd.
 * Description: 
 * Version: 1.0
 */
import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue, updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import NO_ZONE_FIELD from '@salesforce/schema/Phase__c.Number_Of_Zone__c';

export default class UnitInventoryMultiSelectScreen extends LightningElement {
    // Public properties passed in from the parent
    @api recordId;
    @api tempGrid
    @api grid
    @api zoneOptions;
    @api startRow;
    @api endRow;
    @api startColumn;
    @api endColumn;
    @api excludeRowStart;
    @api excludeRowEnd;
    @api excludeColumnStart;
    @api excludeColumnEnd;
    @api multiSelectedCells;

    isEditMode = false;
    noOfZone = 0;

    // Filter
    @track selectedStatusFilters = [];
    @track selectedFacingFilters = [];
    @track selectedZoneFilters = [];

    // zoom
    zoomLevel = 1;

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

    fields = [NO_ZONE_FIELD];

    @wire(getRecord, { recordId: '$recordId', fields: '$fields' })
        wiredPhase({ error, data }) {
            if (data) {
                // this.rows = getFieldValue(data, ROWS_FIELD) || 10; 
                // this.columns = getFieldValue(data, COLUMNS_FIELD) || 10;
                // this.plotData = getFieldValue(data, PLOT_FIELD);
                // this.gardenData = getFieldValue(data, GARDEN_FIELD);
                // this.roadData = getFieldValue(data, ROAD_FIELD);
                // this.roadData = getFieldValue(data, ROAD_FIELD);
                this.noOfZone = getFieldValue(data, NO_ZONE_FIELD) || 0;
                this.generateZonePicklistOptions();
            } else if (error) {
                console.error('Error fetching phase data:', error);
            }
        }

    // Computed property to disable the Select button if any field is missing.
    get isSelectDisabled() {
        // Adjust the condition if "0" is a valid value.
        return !(this.startRow && this.endRow && this.startColumn && this.endColumn);        
    }

    generateZonePicklistOptions() {
        this.zoneOptions = [{ label: 'None', value: 'None' }]
        const dynamicOptions = Array.from({ length: this.noOfZone }, (_, index) => ({
            label: `${index + 1}`,
            value: `${index + 1}`
        }));
        this.zoneOptions = [...this.zoneOptions, ...dynamicOptions];
    }

    handleButton(event) {
        if (event.target.label === 'Save') {
            
            const plotCells = [];
            const gardenCells = [];
            const roadCells = [];

            // Iterate over each sector in the grid.
            this.grid.forEach(sector => {
                // For each row (rM) in the sector
                sector.rM.forEach(row => {
                    // For each column group (Co) in the row
                    row.Co.forEach(colGroup => {
                        // For each cell in the column group's cols array
                        colGroup.cols.forEach(cell => {
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
                });
            });

            // Build the fields object to update the record.
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
        this.handleSubmit();
    }
    /**
     * Handler for field changes. Updates the corresponding property based on the field label.
     * Dispatches a custom event so the parent can also react to the changes if needed.
     */
    handleFieldChange(event) {
        // console.log('grid--->',JSON.stringify(this.grid));
        // console.log('tempGrod--->',JSON.stringify(this.tempGrid));
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

    // /**
    //  * Validates that the exclusion range is entirely within the selected range.
    //  * Returns true if valid; otherwise, displays an error toast and returns false.
    //  */
    validateExcludeRange() {
        // Validate rows if exclusion values are provided
        const startRowNum = parseInt(this.startRow, 10);
        const endRowNum = parseInt(this.endRow, 10);
        if (this.excludeRowStart && this.excludeRowEnd) {
            const excludeRowStartNum = parseInt(this.excludeRowStart, 10);
            const excludeRowEndNum = parseInt(this.excludeRowEnd, 10);
            if (excludeRowStartNum < startRowNum || excludeRowEndNum > endRowNum) {
                this.showToast('Error', 'Exclude row range must be within the selected row range.', 'error');
                return false;
            }
        }
        // Validate columns if exclusion values are provided
        if (this.excludeColumnStart && this.excludeColumnEnd) {
            const startColNum = this.columnLetterToNumber(this.startColumn);
            const endColNum = this.columnLetterToNumber(this.endColumn);
            const excludeColStartNum = this.columnLetterToNumber(this.excludeColumnStart);
            const excludeColEndNum = this.columnLetterToNumber(this.excludeColumnEnd);
            if (excludeColStartNum < startColNum || excludeColEndNum > endColNum) {
                this.showToast('Error', 'Exclude column range must be within the selected column range.', 'error');
                return false;
            }
        }
        return true;
    }

    handleMultiSelect() {
        // Validate the exclusion range first.
        if (!this.validateExcludeRange()) {
            return; // Stop processing if validation fails.
        }
        // Convert main selection inputs
        const startRowNum = parseInt(this.startRow, 10);
        const endRowNum = parseInt(this.endRow, 10);
        const startColNum = this.columnLetterToNumber(this.startColumn);
        const endColNum = this.columnLetterToNumber(this.endColumn);

        // Convert exclusion inputs (if provided)
        let excludeRowStartNum, excludeRowEndNum, excludeColStartNum, excludeColEndNum;
        if (this.excludeRowStart) {
            excludeRowStartNum = parseInt(this.excludeRowStart, 10);
        }
        if (this.excludeRowEnd) {
            excludeRowEndNum = parseInt(this.excludeRowEnd, 10);
        }
        if (this.excludeColumnStart) {
            excludeColStartNum = this.columnLetterToNumber(this.excludeColumnStart);
        }
        if (this.excludeColumnEnd) {
            excludeColEndNum = this.columnLetterToNumber(this.excludeColumnEnd);
        }

        // Reset selected cells array and restore grid from tempGrid if necessary.
        this.multiSelectedCells = [];
        this.grid = structuredClone(this.tempGrid);
        let pv = false;
        // Iterate through the grid (assumed structure: sectors > rM (rows) > Co (column groups) > cols (cells))
        this.grid.forEach(sector => {
            sector.rM.forEach(row => {
                // Check if the row is within the main selection range.
                if (row.Rw >= startRowNum && row.Rw <= endRowNum) {
                    row.Co.forEach(colGroup => {
                        colGroup.cols.forEach(cell => {
                            
                            // Get the cell's column number from its id.
                            const cellColLetters = this.getColumnLetters(cell.id);
                            const cellColNum = this.columnLetterToNumber(cellColLetters);
                            // Check if the cell's column is within the main selection range.
                            if (cellColNum >= startColNum && cellColNum <= endColNum) {
                                // Check exclusion range if all exclusion values are provided.
                                let isExcluded = false;
                                if (
                                    excludeRowStartNum !== undefined &&
                                    excludeRowEndNum !== undefined &&
                                    excludeColStartNum !== undefined &&
                                    excludeColEndNum !== undefined
                                ) {
                                    if (
                                        row.Rw >= excludeRowStartNum &&
                                        row.Rw <= excludeRowEndNum &&
                                        cellColNum >= excludeColStartNum &&
                                        cellColNum <= excludeColEndNum
                                    ) {
                                        isExcluded = true;
                                    }
                                }
                                // If cell is not in the exclusion range, select it.
                                if (!isExcluded) {
                                    if (pv === false) {
                                        cell.Pv = true;
                                        pv = true;
                                    }
                                    cell.st = 'ml'; // Mark cell as selected and colouring it
                                    // Build the custom cell object.
                                    const cellObj = {
                                        sc: sector.sc,                   // Sector ID
                                        ck: colGroup.ck,                 // Column group key
                                        Rw: row.Rw,                      // Row ID
                                        Co: cell.id,              // cell id
                                        pId: cell.pId ? cell.pId : ''     // Plot ID (if exists)
                                    };
                                    // Add the object to the list.
                                    this.multiSelectedCells.push(cellObj);
                                }
                            }
                        });
                    });
                }
            });
        });
    
        // Trigger reactivity if needed.
        this.grid = [...this.grid];
        // console.log('Selected Cells:', JSON.stringify(this.multiSelectedCells));
        this.handleSubmit();
    }

    getColumnLetters(cellId) {
        const match = cellId.match(/^[A-Z]+/i);
        return match ? match[0].toUpperCase() : '';
    }

    // // Helper to convert column letters to a number (e.g., "A" -> 1, "K" -> 11, "AA" -> 27)
    columnLetterToNumber(letter) {
        let number = 0;
        letter = letter.toUpperCase();
        for (let i = 0; i < letter.length; i++) {
            number = number * 26 + (letter.charCodeAt(i) - 64);
        }
        return number;
    }

    // Filter Logic Start Here--------------------------------------
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
        this.handleSubmit();
    }

    filterGridDataStatus(selectedStatusFilters) {
        if (selectedStatusFilters.includes('None') || selectedStatusFilters.length === 0 ) {
            // this.grid = structuredClone(this.tempGrid);
            this.selectedStatusFilters = []
        }
        this.grid = this.filterGrid(this.tempGrid, this.selectedStatusFilters,  this.selectedFacingFilters, this.selectedZoneFilters);
        // console.log('grid-->',JSON.stringify(this.grid));
        this.handleSubmit();
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
        this.handleSubmit();
    }
    
    filterFacingGridData(selectedFacingFilters) {
        
        if ((selectedFacingFilters.includes('None') || selectedFacingFilters.length === 0) ) {
            this.selectedFacingFilters = []
        } 
        this.grid = this.filterGrid(this.tempGrid, this.selectedStatusFilters,  this.selectedFacingFilters, this.selectedZoneFilters);
        this.handleSubmit();
    }

    // ----------------------------------ZONE FILTER----------------------------------------------------
    handleZoneFilter(event) {
        const selectedValue = event.detail.value;
        
        // If the user selects a filter, add it to the selectedZoneFilters array (if not already added)
        if (!this.selectedZoneFilters.includes(selectedValue)) {
            this.selectedZoneFilters.push(selectedValue);
            this.filterZoneGridData(this.selectedZoneFilters);
        }
        // this.handleSubmit();
    }
    
    // Remove selected filter (pills)
    handleRemoveZone(event) {
        const removedFilter = event.detail.name;
        this.selectedZoneFilters = this.selectedZoneFilters.filter(facing => facing !== removedFilter);
        this.filterZoneGridData(this.selectedZoneFilters);
        this.handleSubmit();
    }
    
    filterZoneGridData(selectedZoneFilters) {
        if ((selectedZoneFilters.includes('None') || selectedZoneFilters.length === 0) ) {
            this.selectedZoneFilters = []
        } 
        this.grid = this.filterGrid(this.tempGrid, this.selectedStatusFilters,  this.selectedFacingFilters, this.selectedZoneFilters);
        this.handleSubmit();
    }
    //filter grid based on filter values
    filterGrid(toFilterFromGrid, statusFilters, facingFilters, zSelectedValues) {
        console.log('z--->',JSON.stringify(zSelectedValues));
        
        // Convert filter labels to actual values using a helper method (ensure getFilterValue is defined)
        const statusValues = statusFilters.map(label => this.getFilterValue(label));
    
        // Traverse each sector
        return toFilterFromGrid.map(sector => {
            return {
                ...sector,
                // Traverse each row in the sector
                rM: sector.rM.map(row => {
                    return {
                        ...row,
                        // Traverse each column group in the row
                        Co: row.Co.map(colGroup => {
                            return {
                                ...colGroup,
                                // Traverse each cell in the column group's cols array
                                cols: colGroup.cols.map(cell => {
                                    // console.log('cell--1->',cell);
                                    
                                    const isPlot = cell.ty === "Plot";
                                    const isGardenOrRoad = cell.ty === "Garden" || cell.ty === "Road";
    
                                    // For Plot cells, apply status, facing, and zone filters.
                                    const statusMatch = isPlot ? (statusFilters.length === 0 || statusValues.includes(cell.pS)) : true;
                                    const facingMatch = isPlot ? (facingFilters.length === 0 || facingFilters.includes(cell.pF)) : true;
                                    // For zone, compare as string (assuming cell.z is numeric or string)
                                    const zMatch = zSelectedValues.length === 0 || zSelectedValues.includes(cell.z);
                                    // console.log('cell--2->',cell);
                                    
                                    // If the cell matches based on its type, return the cell as is.
                                    if ((isPlot && statusMatch && facingMatch && zMatch) || (isGardenOrRoad && zMatch)) {
                                        return cell;
                                    } else {
                                        // Otherwise, clear the cell's properties.
                                        return { ...cell, ty: "", st: "", pId: "", pN: "", pS: "", pF: "", z: "" };
                                    }
                                })
                            };
                        })
                    };
                })
            };
        });
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
    // --------------------------------------------END FILTER---------------------------------------------------

    handleZoomIn() {
        // Dispatch an event for zooming in
        this.dispatchEvent(new CustomEvent('zoomin'));
    }
    
    handleZoomOut() {
        // Dispatch an event for zooming out
        this.dispatchEvent(new CustomEvent('zoomout'));
    }
    
    handleResetZoom() {
        // Dispatch an event for resetting zoom
        this.dispatchEvent(new CustomEvent('resetzoom'));
    }

    // **NEW FUNCTION: Dispatches event with all selected values**
    handleSubmit() {
        const selectedValues = {
            startRow: this.startRow,
            endRow: this.endRow,
            startColumn: this.startColumn,
            endColumn: this.endColumn,
            excludeRowStart: this.excludeRowStart,
            excludeRowEnd: this.excludeRowEnd,
            excludeColumnStart: this.excludeColumnStart,
            excludeColumnEnd: this.excludeColumnEnd,
            multiSelectedCells: this.multiSelectedCells,
            girdData: this.grid,
            isEditMode: this.isEditMode
        };

        // Dispatch custom event with data
        this.dispatchEvent(new CustomEvent('inputchanged', {
            detail: selectedValues
        }));

        // Show success toast
        // this.showToast('Success', 'Selection submitted successfully!', 'success');
    }

    dispatchSelectDisabledChange() {
        this.dispatchEvent(new CustomEvent('selectdisablechange', {
            detail: { isSelectDisabled: this.isSelectDisabled }
        }));
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}