import { LightningElement, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import checkOpportunityContact from '@salesforce/apex/KYCVerificationController.checkOpportunityContact';
import uploadFile from '@salesforce/apex/KYCVerificationController.uploadFile'; // Apex method to upload file
import updateOpportunityKYCStatus from '@salesforce/apex/KYCVerificationController.updateOpportunityKYCStatus';
import checkFileSize from '@salesforce/apex/KYCVerificationController.checkFileSize';

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
    maxFileSize = 25 * 1024 * 1024; // 25 MB in bytes
    fileStatus; //success file status dynamically assigining 

    documentTypeOptions = [
        { label: 'KYC', value: 'KYC' },
        { label: 'AOS', value: 'AOS' },
        { label: 'LOAN', value: 'LOAN' },
        { label: 'Sales Deed', value: 'Sales Deed' },
        { label: 'BR', value: 'BR' }
    ];

    subTypeMap = {
        'KYC': [
            { label: 'Aadhaar Card', value: 'Aadhaar Card' },
            { label: 'Pan Card', value: 'Pan Card' }
        ],
        'AOS': [
            { label: 'Upload Documents', value: 'Upload Documents' }
        ],
        'LOAN': [
            { label: 'Upload Documents', value: 'Upload Documents' }
        ],
        'Sales Deed': [
            { label: 'Upload Documents', value: 'Upload Documents' }
        ],
        'BR': [
            { label: 'Upload Documents', value: 'Upload Documents' }
        ]
    };

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId;
            this.checkContactTagged();
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
    }

    handleSubTypeChange(event) {
        this.selectedSubType = event.detail.value;
        this.aadhaarFileId = false;
        if (this.contactId) {
            this.isContactTagged = false
        }
    }
    

    
    async validateFileSize(fileId, fileType) {
        try {
            console.log('filetype-->',fileType);
            
            const fileSize = await checkFileSize({ contentDocumentId: fileId, maxSize: this.maxFileSize, fileType: fileType});

            if (fileSize > this.maxFileSize) {
                this.showToast('Error', `${fileType} file size exceeds the limit of 25MB.`, 'error');
                return false; // File is too large
            }

            this.showToast('Success', `${fileType} uploaded successfully!`, 'success');
            return true; // File is valid
        } catch (error) {
            this.showToast('Error', `Failed to validate ${fileType} file size.`, 'error');
            return false;
        }
    }
    
    // Handle Aadhaar Upload
    async handleAadhaarUploadFinished(event) {
        this.fileStatus = `${this.selectedSubType || this.selectedDocumentType} uploaded successfully!`
        const uploadedFiles = event.detail.files;
        if (uploadedFiles.length > 0) {
            for (let index = 0; index < uploadedFiles.length; index++) {
                const file = uploadedFiles[index];
                const fileId = file.documentId;
                // If it's the first file (index 0), keep the name as is; otherwise, append the index number
                const fileType = index === 0 
                                    ? `${this.selectedSubType || this.selectedDocumentType}` 
                                    : `${this.selectedSubType || this.selectedDocumentType}${index}`;
                const isValid = await this.validateFileSize(fileId, fileType);
                if (isValid) {
                    this.aadhaarFileId = fileId;
                }
            }
        }
    }

    // Handle PAN Upload
    handlePanUploadFinished(event) {
        // if (!this.isContactTagged) return;
        // const uploadedFiles = event.detail.files;
        // this.panFileId = uploadedFiles[0].documentId;
        // this.showToast('Success', 'PAN uploaded successfully!', 'success');
        const file = event.target.files[0];
        if (file && file.size <= this.maxFileSize) {
            this.otherDocFile = file;
            this.panFileId = true
        } else {
            this.showToast('Error', 'Other document file size exceeds the limit of 25MB.', 'error');
        }
        
    }

    // Handle Other Document Upload
    handleOtherDocUploadFinished(event) {
        // if (!this.isContactTagged) return;
        const file = event.target.files[0];
        // this.otherDocFileId = uploadedFiles[0].documentId;
        // this.showToast('Success', 'Other document uploaded successfully!', 'success');
        
        if (file && file.size <= this.maxFileSize) {
            this.aadhaarFile = file;
            this.otherDocFileId = true
        } else {
            this.showToast('Error', 'Aadhaar file size exceeds the limit of 4 MB.', 'error');
        }
    }

    

    // Handle Save Button Click
    async handleSave() {
        this.isLoading = true;
        if (!this.aadhaarFileId || !this.panFileId) {
            this.showToast('Error', 'Please upload all required documents.', 'error');
            this.isLoading = false;
            return;
        }

        // try {
        //     await updateOpportunityKYCStatus({ opportunityId: this.recordId, contactId: this.contactId });
        //     this.showToast('Success', 'KYC Verification is in Progress.', 'success');
        //     window.location.reload();
        //     this.handleCancel();
        // } catch (error) {
        //     console.log("106 "+error);
        //     this.showToast('Error', error?.body?.message, 'error');
        // }
        try {
            // Upload Aadhaar File
            if (this.aadhaarFile) {
                await this.uploadFile(this.aadhaarFile, 'Aadhaar');
            }
    
            // Upload PAN File
            if (this.panFile) {
                await this.uploadFile(this.panFile, 'PAN');
            }
    
            // Upload Other Document File
            if (this.otherDocFile) {
                await this.uploadFile(this.otherDocFile, 'Other Document');
            }
    
            // Update Opportunity KYC Status
            await updateOpportunityKYCStatus({ opportunityId: this.recordId, contactId: this.contactId });
            this.isLoading = false;
            this.handleCancel();
            this.showToast('Success', 'KYC Verification is in Progress.', 'success');
            // window.location.reload();
        } catch (error) {
            this.isLoading = false;
            this.showToast('Error', error?.body?.message, 'error');
        }
    }
    
    // Upload File to Salesforce
    async uploadFile(file, documentType) {
        const base64 = await this.readFileAsBase64(file);
        await uploadFile({ base64Data: base64, fileName: file.name, recordId: this.contactId, documentType });
    }

    // Read File as Base64
    readFileAsBase64(file) {
        return new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.onload = () => {
                const base64 = reader.result.split(',')[1];
                resolve(base64);
            };
            reader.onerror = (error) => {
                reject(error);
            };
            reader.readAsDataURL(file);
        });
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