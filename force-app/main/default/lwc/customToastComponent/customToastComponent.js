import { api, LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
export default class CustomToastComponent extends LightningElement {
    @api title;
    @api message;
    @api variant;
    @api iconName;
    @api delay; 
    @api recordName;
    @api url;
    @api actionLabel;
    connectedCallback(){
        this.showToastMessage();
    }
    showToastMessage = () => {
        let toastMessage = {
            title: this.title,
            message: this.message,
            variant: this.variant?this.variant:'info'
        };
        if(this.recordName && this.url){
            toastMessage.messageData = [
                this.recordName,
                {
                    url: this.url,
                    label: this.actionLabel,
                },
            ]
        }
        if(this.delay){
            setTimeout(() => {
                this.fireToastMessage(toastMessage);
            } , this.delay);
        }else{
            this.fireToastMessage(toastMessage);
        }
    }
    fireToastMessage = (toastMessage) => {
        this.dispatchEvent(new ShowToastEvent(toastMessage) );
    }
}