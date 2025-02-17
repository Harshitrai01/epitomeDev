import { LightningElement, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import checkOpportunityContact from '@salesforce/apex/KYCVerificationController.checkOpportunityContact';
import updateOpportunityKYCStatus from '@salesforce/apex/KYCVerificationController.updateOpportunityKYCStatus';
import checkFilesSize from '@salesforce/apex/KYCVerificationController.checkFilesSize';
import getConfiguration from '@salesforce/apex/KYCVerificationController.getConfiguration';

export default class KycVerificationScreen extends LightningElement {
    recordId; // Opportunity Id 
    contactId 
    selectedDocumentType = ''; 
    selectedSubType = '';
    subTypeOptions = [];
    aadhaarFileId;
    panFileId;
    otherDocFileId;
    contacts = [];
    acceptedFormats = ['.pdf', '.png', '.jpg', '.jpeg'];
    isContactTagged = true;
    isLoading = true;
    saveEnable = true;
    maxFileSize = 0; //25 * 1024 * 1024; // 25 MB in bytes
    maxSizeLable; //this is use to diplay on UI
    fileStatus; //success file status dynamically assigining 

    documentTypeOptions = [
        { label: 'Onboarded', value: 'Onboarded' },
        { label: 'Booked(KYC Verification)', value: 'Booked' },
        { label: 'AOS', value: 'AOS' },
        { label: 'Loan Process', value: 'Loan Process' },
        { label: 'Progressive', value: 'Progressive' },
        { label: 'Registration Initiate', value: 'Registration Initiate' },
        { label: 'Registered', value: 'Registered' },
        { label: 'Documents Delivered', value: 'Documents Delivered' }
    ];

    subTypeMap = {
        'Onboarded': [
            { label: 'NOC', value: 'NOC' }
        ],
        'Booked': [
            { label: 'Aadhaar Card', value: 'Aadhaar Card' },
            { label: 'Pan Card', value: 'Pan Card' }
        ],
        'AOS': [
            { label: 'Draft AOS', value: 'Draft AOS' },
            { label: 'Customer Signed', value: 'Customer Signed' },
            { label: 'AOS', value: 'AOS' },
            { label: 'NOC', value: 'NOC' }
        ],
        'Loan Process': [
            { label: 'NOC', value: 'NOC' },
            { label: 'Document Using the Link', value: 'Document Using the Link' },
            { label: 'Loan Sanction Letter', value: 'Loan Sanction Letter' }
        ],
        'Progressive': [
            { label: 'Disbursement Cheque', value: 'Disbursement Cheque' },
            { label: 'Affidavit', value: 'Affidavit' },
            { label: 'NOC', value: 'NOC' }
        ],
        'Registration Initiate': [
            { label: 'Draft Saledeed', value: 'Draft Saledeed' },
            { label: 'Board of Resolution', value: 'Board of Resolution' },
            { label: 'Form 32', value: 'Form 32' },
            { label: 'NOC', value: 'NOC' }
        ],
        'Registered': [
            { label: 'Original Sale Deed', value: 'Original Sale Deed' }
        ],
        'Documents Delivered': [
            { label: 'Documents Delivered', value: 'Documents Delivered' }
        ],
        'Documents Delivered': [
            { label: 'Documents Delivered', value: 'Documents Delivered' }
        ],
    };

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId;
            this.checkContactTagged();
            getConfiguration()
            .then( (data) =>{
                if (data) {
                    this.maxFileSize = data[0].File_Size_Limit__c * 1024 * 1024; 
                    this.maxSizeLable = `Upload Document (Max ${data[0].File_Size_Limit__c}MB)`; 
                }
            })
            .catch((error) => {
                console.error('Error fetching File Size limit', JSON.stringify(error));
                this.showToast('Error', error?.body?.message, 'error');
            });
        }
    }

    async checkContactTagged() {
        try {
            this.isLoading = true;
            checkOpportunityContact({ opportunityId: this.recordId })
                .then((data) => {
                    if (data && data.length > 0) {
                        this.contacts = data.map((contact) => ({
                            label: contact.Name,
                            value: contact.Id,
                            email: contact.Email,
                            phone: contact.Phone,
                        }));
                    } else {
                        this.contacts = [];
                       this.showToast('Error', 'No contacts found for this Opportunity.', 'error');
                    }
                    this.isLoading = false;
                })
                .catch((error) => {
                    this.isLoading = false;
                    console.error('Error fetching contacts:', JSON.stringify(error));
                    this.showToast('Error', error?.body?.message, 'error');
                });
        } catch (error) {
            this.showToast('Error', 'Contact not found on Opportunity.', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    handleContactSelection(event) {
        this.selectedContactId = event.detail.value;
        const selectedContact = this.contacts.find(
            (contact) => contact.value === this.selectedContactId
        );
        if (selectedContact) {;
            this.contactId = selectedContact.value;
            // this.isContactTagged = false;
        }
        if (this.selectedSubType) {
            this.isContactTagged = false
        }
    }

    handleDocumentTypeChange(event) {
        this.selectedDocumentType = event.detail.value;
        this.subTypeOptions = this.subTypeMap[this.selectedDocumentType] || [];
        this.selectedSubType = ''; // Reset subType selection when changing document type
        this.isContactTagged = true;
        this.aadhaarFileId = false
    }

    handleSubTypeChange(event) {
        this.selectedSubType = event.detail.value;
        console.log('this.selectedSubType----->',this.selectedSubType);
        this.aadhaarFileId = false;
        if (this.contactId) {
            this.isContactTagged = false
        }
    }
    
    async validateFileSizes(fileData) {
        try {
            // Convert the file data array into JSON
            const jsonInput = JSON.stringify({ files: fileData });
            
            // Call Apex to validate file sizes and rename them
            const fileSizes = await checkFilesSize({
                jsonInput: jsonInput,
                maxSize: this.maxFileSize
            });
    
            let isValid = true;
    
            // Process the response from Apex
            fileSizes.forEach((size, index) => {
                if (size === 0) {
                    // File was deleted due to exceeding max size
                    this.showToast('Error', `${fileData[index].fileType} file size exceeds the limit of ${this.maxFileSize/1024/1024}MB.`, 'error');
                    isValid = false;
                } else {
                    this.saveEnable = false //enable the save button after document uploaded successfully
                    // File was valid and successfully renamed
                    this.showToast('Success', `${fileData[index].fileType} uploaded successfully!`, 'success');
                }
            });
    
            return isValid;
        } catch (error) {
            this.showToast('Error', 'Failed to validate file sizes.', 'error');
            return false;
        }
    }
    
    // Handle Aadhaar Upload
    async handleAadhaarUploadFinished(event) {
        this.fileStatus = `${this.selectedSubType || this.selectedDocumentType} uploaded successfully!`
        const uploadedFiles = event.detail.files;

        if (uploadedFiles.length > 0) {
            const fileData = [];

            // Iterate over uploaded files and generate their names
            uploadedFiles.forEach((file, index) => {
                // Naming convention: First file has no number, subsequent files have an index
                const fileType = index === 0 
                    ? `${this.selectedSubType || this.selectedDocumentType}` 
                    : `${this.selectedSubType || this.selectedDocumentType}${index}`;

                fileData.push({ fileId: file.documentId, fileType: fileType });
            });

            // Validate file sizes and rename them
            const isValid = await this.validateFileSizes(fileData);
            if (isValid) {
                this.aadhaarFileId = isValid 
            }
        }
    }

    // Handle Save Button Click
    async handleSave() {
        this.isLoading = true;
        try {
            await updateOpportunityKYCStatus({ opportunityId: this.recordId, contactId: this.contactId, fileType: this.selectedDocumentType});
            this.showToast('Success', 'KYC Verification is in Progress.', 'success');
            // window.location.reload();
            this.isLoading = false;
            this.handleCancel();
        } catch (error) {
            this.showToast('Error', error?.body?.message, 'error');
        }
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title,
            message,
            variant,
        });
        this.dispatchEvent(event);
    }
    
    handleCancel(){
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}