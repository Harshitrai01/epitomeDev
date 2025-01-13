import { LightningElement, wire, track } from 'lwc';
import getTableDimensions from '@salesforce/apex/UnitInventoryScreenController.getTableDimensions';

export default class unitInventoryScreen extends LightningElement {
    @track boxWidth ; // Default width in pixels
    @track boxHeight; // Default height in pixels
    rows = 70;
    columns = 50;
    grid = [];
    columnNames = [''];

    @wire(getTableDimensions)
    wiredDimensions({ error, data }) {
        if (data) {
            this.boxWidth = data[0].Width__c; 
            this.boxHeight = data[0].Height__c;
        } else if (error) {
            console.error('Error fetching dimensions:', error);
        }
    }

    connectedCallback() {
        for (let i = 1; i <= this.rows; i++) {
            const row = {
                Row: i,
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
                    key: `${columnName}${i}`,
                    isPopoverVisible: false,
                    options: this.getDynamicOptions(columnName, i) // Generate dynamic options
                });
                if (i === 1) {
                    this.columnNames.push(columnName);
                }
            }
            this.grid.push(row);
        }

        // console.log(this.grid);

        const deserializedObject = JSON.stringify(this.grid);
        console.log('selectedMaterialValues---->', deserializedObject);
    }

    handleClick(event) {
        const columnKey = event.target.dataset.key; 
        console.log('Clicked Column Key:', columnKey);
    }

    getDynamicOptions(columnName, rowIndex) {
        // Generate options dynamically based on some conditions
        if (rowIndex % 2 === 0) {
            return [`Edit ${columnName}`, `Delete ${columnName}`, `View ${columnName}`];
        } else {
            return [`Add ${columnName}`, `Remove ${columnName}`, `Info ${columnName}`];
        }
    }

    togglePopover(event) {
        const columnKey = event.target.dataset.key;
        this.grid = this.grid.map((row) => {
            row.Co = row.Co.map((cell) => {
                if (cell.key === columnKey) {
                    cell.isPopoverVisible = !cell.isPopoverVisible;
                    this.resetPopoverTimer(cell);
                } else {
                    cell.isPopoverVisible = false; // Close other popovers
                }
                return cell;
            });
            return row;
        });
    }

    resetPopoverTimer(cell) {
        // If there is already a timeout, clear it
        if (this.timeoutId) {
            clearTimeout(this.timeoutId);
        }

        // Set a new timeout to close the popover after 5 seconds
        this.timeoutId = setTimeout(() => {
            cell.isPopoverVisible = false;
            this.grid = [...this.grid]; // Force reactivity to update the view
        }, 5000); // 5000ms = 5 seconds
    }

    handleOptionClick(event) {
        const selectedOption = event.target.dataset.option;
        console.log('Selected Option:', selectedOption);
        const columnKey = event.target.dataset; 
        console.log('Clicked Column Key:', columnKey);
    }

    handleMouseOut() {
        setTimeout(() => {
            this.showDropdown = false;
        }, 5000);
	}

    get dynamicStyle() {
        return `width: ${this.boxWidth}; height: ${this.boxHeight}; text-align: center; cursor: pointer; position: relative;`;
    }
}