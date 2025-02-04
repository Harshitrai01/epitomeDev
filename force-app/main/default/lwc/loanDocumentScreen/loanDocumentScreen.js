import { LightningElement } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import checkOpportunityContact from '@salesforce/apex/KYCVerificationController.checkOpportunityContact';
import uploadFile from '@salesforce/apex/KYCVerificationController.uploadFile'; // Apex method to upload file
import updateOpportunityKYCStatus from '@salesforce/apex/KYCVerificationController.updateOpportunityKYCStatus';

export default class LoanDocumentScreen extends LightningElement {

}