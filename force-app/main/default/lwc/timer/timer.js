import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import ACTUAL_START_DATE from '@salesforce/schema/Quote.CreatedDate';
import TASK_END_DATE from '@salesforce/schema/Quote.Quote_End_Date_Time__c';


export default class CloseDateCountDown extends LightningElement {
    @track isExpired = false;
    @track actualStartDate;
    @track endDatetime;
    @api recordId;
    @track remainingTime;
    @track currentRemainingTime
    @track normalformate = true;
    @track aboutFinish = false;
    @track stopTimer = false
    @track continueTimer = true
    @track lastStopDateTime
    @track endDatetimeValue
    @track totalSeconds;
    @api progressColor;
    @api circleColor;

    @wire(getRecord, { recordId: '$recordId', fields: [TASK_END_DATE, ACTUAL_START_DATE] })
    taskRecord({ error, data }) {
        if (data) {
            this.actualStartDate = getFieldValue(data, ACTUAL_START_DATE);
            this.endDatetimeValue = getFieldValue(data, TASK_END_DATE);
            if (this.endDatetimeValue == null) {
                const semicircles = this.template.querySelectorAll('.semicircle');
                this.isExpired = true;
                this.aboutFinish = false;
                this.normalformate = false;
                this.remainingTime = '00:00:00';
                semicircles[0].style.display = 'none';
                semicircles[1].style.display = 'none';
                semicircles[2].style.display = 'none';
            } else {
                this.endDatetime = new Date(this.endDatetimeValue)
                if (this.actualStartDate && this.endDatetimeValue) {
                    const startDate = new Date(this.actualStartDate);
                    const endDate = new Date(this.endDatetimeValue);
                    const timeDifference = endDate.getTime() - startDate.getTime();
                    const totalSecond = Math.abs(Math.round(timeDifference / 1000));
                    this.totalSeconds = totalSecond;
                    this.startTimer();
                }
            }
        } else if (error) {
            console.error('Error retrieving record:', error);
        }
    }

    connectedCallback() {
        try {
            let circleColor = 'white';
            if (this.circleColor !== null && this.circleColor !== undefined) {
                circleColor = this.circleColor;
            }
            if (circleColor) {
                this.template.querySelector('.outermost-circle').style.backgroundColor = circleColor;
            }
        } catch (error) {
            console.error('Error retrieving record:', error);
        }
    }

    countDownTimer() {
        const semicircles = this.template.querySelectorAll('.semicircle');
        const currentSeconds = this.currentRemainingTime / 1000;
        const angle = (currentSeconds / this.totalSeconds) * 360;
        let progressColor = '#088b8b';
        let circleColor = 'white';
        if (this.progressColor !== null && this.progressColor !== undefined) {
            progressColor = this.progressColor;
        }
        if (this.circleColor !== null && this.circleColor !== undefined) {
            circleColor = this.circleColor;
        }
        if (angle > 180) {
            semicircles[2].style.display = 'none';
            semicircles[0].style.transform = `rotate(180deg)`;
            semicircles[1].style.transform = `rotate(${angle}deg)`;
        } else {
            semicircles[2].style.display = 'block';
            semicircles[0].style.transform = `rotate(${angle}deg)`;
            semicircles[1].style.transform = `rotate(${angle}deg)`;
        }
        if (currentSeconds <= 0) {
            semicircles[0].style.display = 'none';
            semicircles[1].style.display = 'none';
            semicircles[2].style.display = 'none';
        }
        if (progressColor) {
            semicircles[0].style.backgroundColor = progressColor;
            semicircles[1].style.backgroundColor = progressColor;
        }
        if (circleColor) {
            this.template.querySelector('.outermost-circle').style.backgroundColor = circleColor;
        }
    }

    startTimer() {
        const currentTime = new Date();
        if (currentTime < this.endDatetime) {
            // Calculate remaining time
            const timeDifference = this.endDatetime - currentTime;
            this.currentRemainingTime = timeDifference;

            // Convert remaining time to hh:mm:ss format
            const remainingHours = Math.floor(timeDifference / (1000 * 60 * 60));
            const remainingMinutes = Math.floor((timeDifference % (1000 * 60 * 60)) / (1000 * 60));
            const remainingSeconds = Math.floor((timeDifference % (1000 * 60)) / 1000);

            // Format remaining time as hh:mm:ss
            this.remainingTime = `${this.formatNumber(remainingHours)}:${this.formatNumber(remainingMinutes)}:${this.formatNumber(remainingSeconds)}`;

            if (timeDifference <= 3600089 && currentTime <= this.endDatetime) {
                this.isExpired = false;
                this.normalformate = false;
                this.aboutFinish = true;
            }
            // Update the UI or perform any necessary actions with the remaining time
        } else if (currentTime >= this.endDatetime) {
            // Countdown timer has ended, perform any necessary actions
            const semicircles = this.template.querySelectorAll('.semicircle');
            this.isExpired = true;
            this.aboutFinish = false;
            this.normalformate = false;
            this.remainingTime = '00:00:00';
            semicircles[0].style.display = 'none';
            semicircles[1].style.display = 'none';
            semicircles[2].style.display = 'none';
        }
        // Wait for the start datetime and check again
        const millisecondsToWait = 1000;

        if (this.stopTimer == false && this.continueTimer == true) {
            setTimeout(() => {
                this.startTimer();
                this.countDownTimer();
            }, millisecondsToWait);
        }
    }

    formatNumber(number) {
        return number.toString().padStart(2, '0');
    }
}