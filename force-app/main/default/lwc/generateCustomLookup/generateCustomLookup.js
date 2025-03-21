import { LightningElement, api, wire } from 'lwc';
import fetchLookupData from '@salesforce/apex/customLookupCmpController.fetchLookupData';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const DELAY = 300;

export default class generateCustomLookup extends LightningElement {

    // public properties with initial default values 
    @api label = 'custom lookup label';
    @api placeholder = 'search...';
    @api iconName = 'standard:account';
    @api sObjectApiName = 'Unit__c';
    @api defaultRecordId = '';
    @api selectedplotid;
    @api phaseId;
    @api projectId;
    // private properties 
    lstResult = []; // to store list of returned records   
    hasRecords = true;
    searchKey = ''; // to store input field value    
    isSearchLoading = false; // to control loading spinner  
    delayTimeout;
    selectedRecord = {}; // to store selected lookup record in object formate 
 
     fetchData() {
        fetchLookupData({ searchKey: this.searchKey, phaseId: this.phaseId, projectId: this.projectId })
            .then(data => {
                  this.isSearchLoading = false;
                      console.log('this.selectedPlotIds---'+JSON.stringify(this.selectedplotid));
            this.hasRecords = data.length == 0 ? false : true;
            let dataValue = JSON.parse(JSON.stringify(data));
            if(this.selectedplotid != null){
                this.lstResult = dataValue.filter(item => !this.selectedplotid.includes(item.Id));
            }else{
                this.lstResult = dataValue
            }
                if (this.lstResult.length === 0) {
                this.searchKey = '';
                this.showToast('Error', 'No plots found.', 'error');
            }
            console.log('this.lstResult---'+JSON.stringify(this.lstResult));
             
            })
            .catch(error => {
                this.isSearchLoading = false;
                console.error('Error fetching data:', error);
            });
    }
    


    @api
    clearSelection() {
        debugger
        console.log('Clearing selected record...');

        this.selectedRecord = null; // Reset selected record
        // Clear search input value

        this.handleRemove();
        this.searchKey = '';
    }



    // update searchKey property on input field change  
    handleKeyChange(event) {
        debugger
           if (!this.phaseId || this.phaseId===null) {
                   this.searchKey = '';
                this.showToast('Error', 'Please select a phase first.', 'error');
                return;
            }
        // Debouncing this method: Do not update the reactive property as long as this function is
        // being called within a delay of DELAY. This is to avoid a very large number of Apex method calls.
        this.isSearchLoading = true;
        window.clearTimeout(this.delayTimeout);
        const searchKey = event.target.value;
        this.delayTimeout = setTimeout(() => {
            this.searchKey = searchKey;
            this.fetchData();
        }, DELAY);
    }
    // method to toggle lookup result section on UI 
    toggleResult(event) {
        const lookupInputContainer = this.template.querySelector('.lookupInputContainer');
        const clsList = lookupInputContainer.classList;
        const whichEvent = event.target.getAttribute('data-source');
        switch (whichEvent) {
            case 'searchInputField':
                clsList.add('slds-is-open');
                break;
            case 'lookupContainer':
                clsList.remove('slds-is-open');
                break;
        }
    }
    // method to clear selected lookup record  
    handleRemove() {
        debugger
        this.lookupRemovehandler(this.selectedRecord); 
        console.log('vvvvvvvvvvvvvvvvvvvvv');
        this.searchKey = '';
        this.selectedRecord = {};
        this.lookupUpdatehandler(null); // update value on parent component as well from helper function 

        // remove selected pill and display input field again 
        const searchBoxWrapper = this.template.querySelector('.searchBoxWrapper');
        searchBoxWrapper.classList.remove('slds-hide');
        searchBoxWrapper.classList.add('slds-show');
        const pillDiv = this.template.querySelector('.pillDiv');
        pillDiv.classList.remove('slds-show');
        pillDiv.classList.add('slds-hide');
    }
    // method to update selected record from search result 
    handelSelectedRecord(event) {
        var objId = event.target.getAttribute('data-recid'); // get selected record Id 
        this.selectedRecord = this.lstResult.find(data => data.Id === objId); // find selected record from list 
        console.log('selectedRecord---'+JSON.stringify(this.selectedRecord));
        this.lookupUpdatehandler(this.selectedRecord); // update value on parent component as well from helper function 
        this.handelSelectRecordHelper(); // helper function to show/hide lookup result container on UI
    }
    /*COMMON HELPER METHOD STARTED*/
    handelSelectRecordHelper() {
        this.template.querySelector('.lookupInputContainer').classList.remove('slds-is-open');
        const searchBoxWrapper = this.template.querySelector('.searchBoxWrapper');
        searchBoxWrapper.classList.remove('slds-show');
        searchBoxWrapper.classList.add('slds-hide');
        const pillDiv = this.template.querySelector('.pillDiv');
        pillDiv.classList.remove('slds-hide');
        pillDiv.classList.add('slds-show');
    }
    // send selected lookup record to parent component using custom event
    lookupUpdatehandler(value) {
        const oEvent = new CustomEvent('lookupupdate',
            {
                'detail': { selectedRecord: value }
            }
        );
        this.dispatchEvent(oEvent);
    }

    lookupRemovehandler(value){
        console.log('hhhhhh');
       const oEvent = new CustomEvent('lookupremove',
            {
                'detail': { selectedRecord: value }
            }
        );
        this.dispatchEvent(oEvent); 
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