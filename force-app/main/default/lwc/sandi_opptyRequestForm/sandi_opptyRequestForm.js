import { api , track, wire} from 'lwc';
import LightningModal from 'lightning/modal';
import getContactInfo from '@salesforce/apex/Sandi_OpptyRequestController.getContactInfo';
import { createCommonQuantityUpdateAction, dispatchAction } from 'commerce/actionApi';
import { getSessionContext, getAppContext } from 'commerce/contextApi';
import utils from 'c/sandi_utils';

import userId from "@salesforce/user/Id";
import isGuest from "@salesforce/user/isGuest";

import DEFAULT_VIEW from "./sandi_opptyRequestForm.html";
import GUEST_VIEW from "./sandi_opptyRequestGuest.html";

import { getRecord } from "lightning/uiRecordApi";
import ContactAccountFIELD from '@salesforce/schema/Contact.AccountId';
import ContactNameFIELD from '@salesforce/schema/Contact.Name';
import ContactEmailFIELD from '@salesforce/schema/Contact.Email';
import ContactPhoneFIELD from '@salesforce/schema/Contact.Phone';


export default class Sandi_opptyRequestForm extends LightningModal  {

    @api productId;
    @api pricebookEntryId;
    @api contactId;

    //@track loginInfo;
    @track _productDetail;
    @track productOption = [];
    @track selectedProductOptionValue;
    @track isReadonly;
    @track quantity = 1;
    @track webStoreId;
    @track accountId;
    @track isGuestView;
    //@track isLoaded;
    @track contactInfo;
    
    @api 
    get productDetail (){
        return this._productDetail
    }
    set productDetail(value){
        if(value?.variationInfo?.attributesToProductMappings?.length){
            let copyOpt = JSON.parse(JSON.stringify(value.variationInfo.attributesToProductMappings));
            copyOpt.map((item)=>{
                item.label = item.canonicalKey;
                item.value = item.canonicalKey;
            });
            this.productOption = copyOpt;
        }
        this._productDetail = value;
    }


    @wire(getRecord, { recordId: '$contactId', fields: [ContactAccountFIELD, ContactNameFIELD, ContactEmailFIELD, ContactPhoneFIELD]}) 
    currentUserInfo({error, data}) {
        if (data) {
            console.log("data", data);
            this.accountId = data.fields.AccountId.value;
            this.contactInfo = {
                name : data.fields.Name.value
                , email : data.fields.Email.value
                , phone : data.fields.Phone.value
            }
        } else if (error) {
            console.error(error);
        }
    }


    render() {
        return this.isGuestView ? GUEST_VIEW : DEFAULT_VIEW;
    }

    connectedCallback(){
        if(userId) this.callContactInfo();
        console.log("productDetail", this.productDetail);
        getSessionContext().then((sessionContext) => {
            console.log("sessionContext", sessionContext);
            getAppContext().then((appContext) => {
                console.log("appContext", appContext);
                this.webStoreId = appContext.webstoreId;
              });
        });



    }

    callContactInfo(){
        this.isGuestView = isGuest;
        //this.isLoaded = true;
        if(!isGuest){ // 로그인 일때
            this.isReadonly = true;
            //this.setAutoInfo();
        }
        
        // getContactInfo({
        //     userId :  userId
        // })
        // .then(result => {
        //     console.log("getContactInfo => ", result);
        //     this.isLoaded = true;
        //     if(!result?.isGuest) { // 로그인 일때
        //         this.loginInfo = result; 
        //         this.isReadonly = true;
        //         this.setAutoInfo();
        //     } 
        // })
        // .catch(error => {
        //     console.log('getContactInfo error msg : ', error);
        // })
    }

    

    setAutoInfo(){
        const name = this.refs.name;
        const email = this.refs.email;
        const phone = this.refs.phone;
        
        name.value = this.contactInfo ? this.contactInfo?.name : '';
        email.value = this.contactInfo ? this.contactInfo?.email : '';
        phone.value = this.contactInfo ? this.contactInfo?.phone : '';
    }

    validateContent(){
        return new Promise((resolve, reject)=>{
            const allValid = [
                ...this.template.querySelectorAll('.validate-target'),
            ].reduce((validSoFar, inputCmp) => {
                if(!inputCmp.value){
                    inputCmp.setCustomValidity('error');
                } else if(inputCmp.type === 'email' && inputCmp.value && !(/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(inputCmp.value))){
                    console.log("email")
                    inputCmp.setCustomValidity('error');
                } else if(inputCmp.type === 'tel' && inputCmp.value && !(/\+[0-9]/i.test(inputCmp.value))){
                    inputCmp.setCustomValidity('error');
                } else{
                    inputCmp.setCustomValidity('');
                }

                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity() && inputCmp.value;
            }, true);

            resolve(allValid);
        })
    }

    handleOption(event){
        this.selectedProductOptionValue = event.detail.value
    }
    async requestQuotes(){
        const result = await this.validateContent();

        if(!result) return false;

        let requestObj = new Object;
        const productOption = this.selectedProductOptionValue;
        const name = this.refs.name;
        const email = this.refs.email;
        const phone = this.refs.phone;
        const detail = this.refs.detail;

        requestObj.productId = this.productId || '';
        requestObj.productOption = productOption || '';
        requestObj.name = name?.value || '';
        requestObj.email = email?.value || '';
        requestObj.phone = phone?.value || '';
        requestObj.detail = detail?.value || '';
        
        console.log("견적신청 보내는 값 : ", requestObj);

        this.close();
    }





    get inputVariables() {
        console.log("inputVariables userId ==> ", userId);
        console.log("inputVariables accountId ==> ", this.accountId);
        console.log("inputVariables pricebookEntryId ==> ", this.pricebookEntryId);
        console.log("inputVariables productId ==> ", this.productId);

        return [
            
            {
                name: 'var_MallUser',
                type: 'String',
                value: userId
            },
            {
                name: 'var_Account',
                type: 'String',
                value: this.accountId
            },
            {
                name: 'var_PricebookEntry',
                type: 'String',
                value: this.pricebookEntryId
            },
            {
                name: 'var_Product2',
                type: 'String',
                value: this.productId
            },
            
            {
                name: 'var_Description',
                type: 'String',
                value: '<Quote.Description>'
            },
            
            {
                name: 'var_Quantity',
                type: 'String',
                value: '<Opportunity.Amount>'
            }
        ];
    }
    
    handleStatusChange(event) {
        if (event.detail.status === 'FINISHED') {
            // set behavior after a finished flow interview
        }
    }

    changeQuantity(event){
        const target = event.currentTarget;
        const type = target.dataset.type;
        let quantity = this.quantity;
  
        if(type === 'add'){
            quantity++;
        } else if(type === 'delete' && quantity){
            quantity--
        }

        this.quantity = quantity;

        dispatchAction(this, createCommonQuantityUpdateAction(quantity));
    }


    moveToLogin(){
        this.close('login');
        
    }



}