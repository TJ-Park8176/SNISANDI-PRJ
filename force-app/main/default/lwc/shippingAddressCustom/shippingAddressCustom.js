import { LightningElement, api, track, wire } from 'lwc';

import { subscribe, unsubscribe, onError, setDebugFlag, isEmpEnabled } from 'lightning/empApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getVFOrigin from '@salesforce/apex/BillingAddressController.getVFOrigin';
import getCurrentObj from '@salesforce/apex/BillingAddressController.getCurrentObject';
import getFieldList from '@salesforce/apex/BillingAddressController.getFieldList';


export default class BillingAddress extends LightningElement {
    @api recordId;
    @api flexipageRegionWidth;

    @api channelName = '/event/Search_Address__e';
    subscription = {};

    loading = false;

    @wire(getVFOrigin) vfOrigin;
    @wire(getCurrentObj, {recId: '$recordId'}) objName;
    @wire(getFieldList, {recId: '$recordId'}) fieldList;

    accountValue='';
    msg = '';

    // get accountOptions() {
    //     return [
    //         { label: 'Billing Address', value: 'billing' },
    //         { label: 'Shipping Address', value: 'shipping' },
    //     ];
    // }

    get accountOptions() {
        console.log('-----accountOptions()-----');
        console.log(this.fieldList.data);
        return this.fieldList.data;
    }

    get isAccount() {
        return this.objName.data === 'Account';
    }

    get isCustom() {
        return this.objName != 'Account' && this.objName != 'Contact' && this.objName !='Lead';
    }

    get visualforceSrc() {
        //return '/apex/searchAddress?recordId=' + this.recordId;
        //return '/apex/searchAddress?recordId=0011y00000liPY8AAM';
        return 'https://snicorp--dev--c.sandbox.vf.force.com/apex/searchAddress?recordId=0011y00000liPY8AAM';
    }

    connectedCallback() {
        window.addEventListener("message", this.handleVFResponse.bind(this));

        this.checkReload();

        this.handleSubscribe();
    }

    handleVFResponse(message) {
        if (message.origin === this.vfOrigin.data) {
            this.receivedMessage = message.data;
        }
    }

    handleSubscribe() {
        console.log('--handleSubscribe() start--');
        const self = this;
        const messageCallback = function (response) {
            console.log('New message received 1: ', JSON.stringify(response));
            console.log('New message received 2: ', response);
            var obj = JSON.parse(JSON.stringify(response));

            let objData = obj.data.payload;
            let message = objData.message__c;
            let status  = objData.status__c;

            console.log(objData);
            console.log('message: ' + message);
            console.log('status: ' + status);
            console.log('channelName: ' + this.channelName);

            if(status == 'error') { //에러 시 reload X
                self.showToastMessage('Search Address Event', message, status, 'dismissable');
            } else {
                sessionStorage.setItem("reloading", true);
                sessionStorage.setItem("message", message);
                sessionStorage.setItem("status", status);
                window.location.reload();
            }
        };

        // Invoke subscribe method of empApi. Pass reference to messageCallback
        subscribe(this.channelName, -1, messageCallback).then(response => {
            // Response contains the subscription information on subscribe call
            console.log('Subscription request sent to: ', JSON.stringify(response.channel));
            this.subscription = response;
        });
    }

    //handle Error
    registerErrorListener() {
        onError(error => {
            console.log('Received error from server: ', JSON.stringify(error));
        });
    }

    checkReload() {
        let reloading = sessionStorage.getItem("reloading");
        console.log('reloading: ' + reloading);
        if(reloading) {
            let message = sessionStorage.getItem("message");
            let status = sessionStorage.getItem("status");
            console.log(this);
            this.showToastMessage('Search Address Event', message, status, 'dismissable');

            sessionStorage.removeItem("reloading");
            sessionStorage.removeItem("message");
            sessionStorage.removeItem("status");
        }
    }

    handleChangeAcc(event) {
        console.log('--handleChangeAcc() start--');
        this.msg = event.detail.value;
        console.log('@@msg: ' + this.msg);
        this.handleFiretoVF();
    }

    onLoad() { //로딩 완료시
        this.loading = true;
    }

    showToastMessage(title, message, variant, mode) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: mode
        });
        this.dispatchEvent(event);
    }

    handleFiretoVF() {
        console.log('--handleFiretoVF() start--');
        console.log(this.msg);
        console.log(this.vfOrigin.data);
        this.template.querySelector("iframe").contentWindow.postMessage(this.msg, this.vfOrigin.data);
    }

}