/**
 * Created by MZC01-DGCHOI on 2024-03-21.
 */
import {  LightningElement, api, track, wire } from 'lwc';
//import LightningModal from 'lightning/modal';

import { subscribe, unsubscribe, onError, setDebugFlag, isEmpEnabled } from 'lightning/empApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import userId from '@salesforce/user/Id'
import createContactPointAddress from '@salesforce/apex/Sandi_ContactPointAddressController.createContactPointAddress'



export default class SandiShippingAddressModal extends LightningElement {

    @api channelName = '/event/Search_Address__e';

    @track fullAddress;
    @track postalCode;
    @track addressDetail;
    @track addressName;

    subscription = {};
    addressInfoMap = {};

    loading = false;
    msg = '';



    get visualforceSrc() {
        return 'https://snicorp--dev--c.sandbox.vf.force.com/apex/sandi_shippingAddressCheckout';
    }

    connectedCallback() {
        window.addEventListener("message", this.handleVFResponse.bind(this));

        this.checkReload();
        this.handleSubscribe();
    }

    handleVFResponse(message) {
        if(message?.data?.postalCode){
            console.log('vf message', message);

            const msg         = message.data;
            const fullAddress = `${msg?.state} ${msg?.city} ${msg?.street}`;

            this.addressInfoMap = msg;
            this.fullAddress    = fullAddress;
            this.postalCode     = msg.postalCode;
        }
    }

    handleSubscribe() {
        console.log('--handleSubscribe() start--');
        const messageCallback = function (response) {
            console.log('New message received 1: ', JSON.stringify(response));
            var obj = JSON.parse(JSON.stringify(response));
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
            let status  = sessionStorage.getItem("status");
            console.log(this);
            this.showToastMessage('Search Address Event', message, status, 'dismissable');

            sessionStorage.removeItem("reloading");
            sessionStorage.removeItem("message");
            sessionStorage.removeItem("status");
        }
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

    searchAddress(event){
        console.log('--handleFiretoVF() start--');
        this.template.querySelector("iframe").contentWindow.postMessage(this.msg, '*');
    }

    handleAddressDetailChange(event) {
        this.addressDetail = event.target.value;
    }

    handleAddressName(event) {
        this.addressName = event.target.value;
    }

    addAddress() {
        this.addressInfoMap.street += ' ' + this.addressDetail;
        this.addressInfoMap.name = this.addressName;

        createContactPointAddress({
            userId : userId,
            addressInfoMap: this.addressInfoMap
        }).then((data) => {
            console.log('data', data);
        }).catch((error) => {
            console.log('error', error);
        });
    }

}