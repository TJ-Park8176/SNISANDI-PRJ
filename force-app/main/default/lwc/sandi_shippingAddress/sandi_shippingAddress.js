import { wire, api, track } from "lwc";
import { subscribe, unsubscribe, onError, setDebugFlag, isEmpEnabled } from 'lightning/empApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CheckoutInformationAdapter, CheckoutComponentBase } from 'commerce/checkoutApi';
import { mockedAddressData } from './shippingAddressMock';
import userId from "@salesforce/user/Id";
import shippingAddressModal from 'c/sandi_shippingAddressModal';
//Apex
import getContactPointAddressesByUserId from '@salesforce/apex/Sandi_ContactPointAddressController.getContactPointAddressesByUserId';
import createContactPointAddress from '@salesforce/apex/Sandi_ContactPointAddressController.createContactPointAddress'
import updateCartDeliveryGroup from '@salesforce/apex/Sandi_CartDeliveryGroupController.updateCartDeliveryGroup';


const CheckoutStage = {
  CHECK_VALIDITY_UPDATE : 'CHECK_VALIDITY_UPDATE',
  REPORT_VALIDITY_SAVE  : 'REPORT_VALIDITY_SAVE',
  BEFORE_PAYMENT        : 'BEFORE_PAYMENT',
  PAYMENT               : 'PAYMENT',
  BEFORE_PLACE_ORDER    : 'BEFORE_PLACE_ORDER',
  PLACE_ORDER           : 'PLACE_ORDER'
};


export default class ShippingAddress extends CheckoutComponentBase {
    shippingAddress = {};
    @track shippingAddresses = [];
    @track name;
    @track firstName;
    @track lastName;
    @track newAddress = {
        validity: false
    };
    @track deliveryAddress = {};
    @track addressPicked;

    isNewAddress = false;
    @track isDisabled = false;
    @track isSummary = false;

    cartData;
    isPreview;

    @track showError = false;
    @track error;

    @api noShippingMessage = '';

    @api checkoutDetails;
    @track checkoutId;

    /////////// 우편번호 찾기 ///////////
    @api channelName = '/event/Search_Address__e';
    @track fullAddress;
    @track postalCode;
    @track addressDetail;
    @track addressName;

    subscription = {};
    addressInfoMap = {};

    loading = false;
    msg = '';

    /**
     * 
     * Get the CheckoutData from the standard salesforce adapter
     * Response is expected to be 202 while checkout is starting
     * Response will be 200 when checkout start is complete and we can being processing checkout data 
     * 
     */

    /*@wire(CheckoutInformationAdapter, { })
    checkoutInfo({ error, data }) {
      this.isPreview = this.isInSitePreview();
      this.showError = false;
      if (!this.isPreview) {
          console.log('shippingAddress checkoutInfo');
          if (data) {
              console.log('CheckoutInformationAdapter data', data);
              console.log('shippingAddress checkoutInfo data : '+ JSON.stringify(data));
              if(data.checkoutStatus === 200){
                    console.log('shippingAddress checkoutInfo checkoutInfo 200');
                    this.deliveryAddress = data.deliveryGroups.items[0].deliveryAddress;
                    this.getAddressData();
              }
          } else if (error) {
                console.log('##shippingAddress checkoutInfo Error: '+error);
                this.showError = true;
                this.error = "Checkout encountered an error, please reload the page and try again. If this issue persists, please contact your administrator and provide this error. "+error;
          }
      } else {
        this.isLoading = false;
        this.shippingAddress = mockedAddressData;
        this.shippingAddresses.push(this.shippingAddress);
      }
    }*/

    @wire(getContactPointAddressesByUserId, { userId: userId })
    wiredShippingAddresses({ error, data }) {
        console.log('checkoutId : ', this.checkoutDetails?.checkoutId);
        this.isPreview = this.isInSitePreview();
        this.showError = false;
        if (!this.isPreview) {
          console.log('shippingAddress checkoutInfo');
          if (data) {
              console.log('@wiredShippingAddresses data', data);
              //this.deliveryAddress = data.deliveryGroups.items[0].deliveryAddress;
              this.setAddressData(data);
          } else if (error) {
                console.log('@wiredShippingAddresses error', error);
                this.showError = true;
                this.error = "Checkout encountered an error, please reload the page and try again. If this issue persists, please contact your administrator and provide this error. "+error;
          }
        } else {
        this.isLoading = false;
        /*this.shippingAddress = mockedAddressData;
        this.shippingAddresses.push(this.shippingAddress);*/
        }
    }

    /**
     * handles the aspects changing on the site.
     */
    setAspect(newAspect) {
        console.log('shippingAddress: inside setAspect'+ JSON.stringify(newAspect));
        // If the aspect is a summary, we disable the form
        if(newAspect.summary){
            this.isDisabled = true;
            this.isSummary = true;
        }else {
            this.isDisabled = false;
            this.isSummary = false;
        }
    }

    /**
     * get the contact point / address data to show to the user
     */
    setAddressData(data) {
        if (!this.isPreview) {
            // currently this example is just pushing in mocked data, this would be where you plug in your own data
            /*this.shippingAddresses = data.map((e) => {

            });*/
            this.shippingAddresses = data;
            //this.shippingAddresses.push();
        } else {
            this.shippingAddresses = mockedAddressData;
        }
    }

    /**
     * handles when an address is picked from the address list
     */
    handleAddressPick(event){
        updateCartDeliveryGroup({
            checkoutId : this.checkoutDetails.checkoutId,
            cpaId      : event.target.value
        }).then(data => {
            console.log('data', data);
        }).catch(error => {
            console.log('error', error);
        })
    }

    /**
     * update form when our container asks us to
     */
    stageAction(checkoutStage /*CheckoutStage*/) {
        switch (checkoutStage) {
            case CheckoutStage.CHECK_VALIDITY_UPDATE:
                return Promise.resolve(this.checkValidity());
            case CheckoutStage.REPORT_VALIDITY_SAVE:
                return Promise.resolve(this.reportValidity());
            default:
                return Promise.resolve(true);
        }
    }

    /**
     * Return true 
     */
    checkValidity() {
        console.log('shippingAddress checkValidity');
        return true;
    }

    /**
     * Return true when at least one address exists
     */
    reportValidity() {
        console.log('shippingAddress reportValidity');
        let isValid = false;
        if(this.shippingAddresses.length > 0){
            isValid = true;
        }else{
            this.dispatchUpdateErrorAsync({
                groupId: 'ShippingAddress',
                type: '/commerce/errors/checkout-failure',
                exception: 'An Address must be filled in.',
            });
            isValid = false;
        }

        return isValid;
    }

    /**
     * helper class that checks if we are in site preview mode
     */
    isInSitePreview() {
        let url = document.URL;
        
        return (url.indexOf('sitepreview') > 0 
            || url.indexOf('livepreview') > 0
            || url.indexOf('live-preview') > 0 
            || url.indexOf('live.') > 0
            || url.indexOf('.builder.') > 0);
    }

    createNewAddress(event) {
        this.isNewAddress = true;
       /*shippingAddressModal.open({
           size: 'small',
           description: '새 주소 입력 모달'
       }).then((result)=>{
           // 모달 닫은 뒤 이벤트
           console.log('모달 닫음');
       });*/
    }

    handleNewAddressClose(event) {
        this.isNewAddress = false;
    }

    handleAddressPickClick(event) {
        console.log('handleAddressPickClick ==>');

        const pickerElement = event.target;
        console.log('pickerElement key : ' + pickerElement?.key);
        console.log('pickerElement cpaid : ' + pickerElement?.dataset.cpaid);

/*
        updateCartDeliveryGroup({
            checkoutId: this.checkoutDetails.checkoutId,
            cpaId:
        }).then(data => {
            console.log('data', data);
        }).catch(error => {
            console.log('error', error);
        })*/
    }

    //////////////// 우편번호 ////////////////
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
        if(this.addressInfoMap && this.addressDetail && this.addressName) {
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
}