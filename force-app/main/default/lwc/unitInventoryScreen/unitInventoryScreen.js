import { LightningElement,api, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import getTableDimensions from '@salesforce/apex/UnitInventoryScreenController.getTableDimensions';

import ROWS_FIELD from '@salesforce/schema/Phase__c.Grid_Length__c';
import COLUMNS_FIELD from '@salesforce/schema/Phase__c.Grid_Width__c';

export default class unitInventoryScreen extends LightningElement {
    @api recordId;

    @track boxWidth ; // Default width in pixels
    @track boxHeight; // Default height in pixels
    rows = 10;
    columns = 10;
    grid = [];
    columnNames = [''];
    fields = [ROWS_FIELD, COLUMNS_FIELD];


    @wire(getTableDimensions)
    wiredDimensions({ error, data }) {
        if (data) {
            this.boxWidth = data[0].Width__c; 
            this.boxHeight = data[0].Height__c;
        } else if (error) {
            console.error('Error fetching dimensions:', error);
        }
    }

    @wire(getRecord, { recordId: '$recordId', fields: '$fields' })
    wiredPhase({ error, data }) {
        if (data) {
            this.rows = getFieldValue(data, ROWS_FIELD) || 10; 
            this.columns = getFieldValue(data, COLUMNS_FIELD) || 10; 
            this.initializeGrid();
        } else if (error) {
            console.error('Error fetching phase data:', error);
        }
    }

    initializeGrid() {
        this.grid = [];
        this.columnNames = [''];

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

                row.Co.push({
                    id: `${columnName}${i}`,
                    Pv: false,
                    op: ['Plot', 'Garden', 'Road'], 
                    st: "background-color: white;"
                });
                if (i === 1) {
                    this.columnNames.push(columnName);
                }
            }
            this.grid.push(row);
        }
    }

    handleClick(event) {
        const columnKey = event.target.dataset.key; 
        console.log('Clicked Column Key:', columnKey);
    }

    togglePopover(event) {
        const columnKey = event.target.dataset.key;
        const rowId = event.target.dataset.row;

        this.grid = this.grid.map((row) => {
            if (row.Rw === parseInt(rowId, 10)) {
                row.Co = row.Co.map((cell) => {
                    cell.Pv = cell.id === columnKey ? !cell.Pv : false;
                    return cell;
                });
            }
            return row;
        });
        console.log('Updated Grid:--> toggle', JSON.stringify(this.grid));
    }

    handleOptionClick(event) {
        const selectedOption = event.target.dataset.option; 
        const columnKey = event.target.dataset.key; 
        const rowId = parseInt(event.target.dataset.row, 10); 

        console.log('Selected Option:', selectedOption);
        console.log('Clicked Column Key:', columnKey);
        console.log('Row ID:', rowId);

        // Find the row and column and update them
        const row = this.grid.find((r) => r.Rw === rowId);
        if (row) {
            const cell = row.Co.find((c) => c.id === columnKey);
            if (cell) {
                let bgColor = 'white';
                switch (selectedOption) {
                    case 'Plot':
                        bgColor = 'yellow';
                        break;
                    case 'Garden':
                        bgColor = 'green';
                        break;
                    case 'Road':
                        bgColor = 'grey';
                        break;
                }
                cell.Pv = false; // Close the popover
                cell.st = `background-color: ${bgColor};`; // Update the cell style
            }
        }

        // Force the grid to refresh reactively
        this.grid = [...this.grid];

        console.log('Updated Grid: after', JSON.stringify(this.grid));
    }

    // handleMouseOut() {
    //     setTimeout(() => {
    //         this.showDropdown = false;
    //     }, 5000);
	// }

    get dynamicStyle() {
        return `width: ${this.boxWidth}; height: ${this.boxHeight}; text-align: center; cursor: pointer; position: relative;`;
    }
}