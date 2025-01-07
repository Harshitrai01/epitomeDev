import { LightningElement, track } from 'lwc';

export default class ExcelLikeGrid extends LightningElement {
  @track rows = [
    { id: 1, column1: 'Row 1 Col 1', column2: 'Row 1 Col 2', picklistValue: 'Option1', selected: false },
    { id: 2, column1: 'Row 2 Col 1', column2: 'Row 2 Col 2', picklistValue: 'Option2', selected: false },
    { id: 3, column1: 'Row 3 Col 1', column2: 'Row 3 Col 2', picklistValue: 'Option3', selected: false },
  ];

  picklistOptions = [
    { label: 'Option 1', value: 'Option1' },
    { label: 'Option 2', value: 'Option2' },
    { label: 'Option 3', value: 'Option3' },
  ];

  handleRowSelection(event) {
    const rowId = event.target.dataset.id;
    const selected = event.target.checked;
    this.rows = this.rows.map((row) =>
      row.id === parseInt(rowId) ? { ...row, selected } : row
    );
  }

  handlePicklistChange(event) {
    const rowId = event.target.dataset.id;
    const picklistValue = event.target.value;
    this.rows = this.rows.map((row) =>
      row.id === parseInt(rowId) ? { ...row, picklistValue } : row
    );
  }
}