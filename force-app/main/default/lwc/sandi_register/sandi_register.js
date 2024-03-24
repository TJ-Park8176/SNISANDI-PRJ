import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { subscribe, unsubscribe, onError, setDebugFlag, isEmpEnabled } from 'lightning/empApi';
import { getObjectInfo, getPicklistValues } from "lightning/uiObjectInfoApi";
import utils from 'c/sandi_utils';
import communityBasePath from '@salesforce/community/basePath';
import Toast from 'lightning/toast';
import REGISTRATION_OBJECT from "@salesforce/schema/SANDI_Registration__c";
import CALL_FIELD from "@salesforce/schema/SANDI_Registration__c.CountryCallingCode__c";

import checkDuplicateEmail from '@salesforce/apex/Sandi_RegisterController.checkDuplicateEmail';

import DEFAULT_VIEW from "./sandi_register.html";
import COMPLETE_VIEW from "./sandi_registerComplete.html";

/**
 * 1. 간편회원가입 api (네이버, 카카오톡) : 상세 정의 필요. 5월
 * 
 * [논의]
 * 1. 인풋 에러 표시 시점(입력시 / 버튼클릭시)
 * 2. 전화번호 형식 정의 (숫자만 / '-' 포함)
 * 
 * - 이메일 중복 확인 시 게스트 일때 
 */
export default class Sandi_register extends NavigationMixin(LightningElement) {
    @track detailStyle = 'pointer-events:none;';
    @track isDisabledRegistBtn = true; // 회원가입 버튼
    @track isDisabledAuthtBtn = true; //  인증하기 버튼
    @track isRequiredForCompany = false; // 기업회원 시 필수값 변경
    @track isLoadedForm = false; // 레코드 에딧 폼 로드
    @track isAuthurizeMail = false; // 메일 인증 여부
    @track showCompleteView = false; // 가입완료 화면
    @track isSpinner = true;

    @api channelName = '/event/Search_Address__e';
    @track addressTarget;
    @track addressValue;
    @track shippingValue;
    subscription = {};
    msg = '';

    get visualforceSrc() {
        return 'https://snicorp--dev--c.sandbox.vf.force.com/apex/SearchAddressRegistration';
    }

    recordTypeId;
    countryCodeList = [];

    @wire(getObjectInfo, { objectApiName: REGISTRATION_OBJECT })
    results({ error, data }) {
        if (data) {
        this.recordTypeId = data.defaultRecordTypeId;
        this.error = undefined;
        } else if (error) {
        this.error = error;
        this.recordTypeId = undefined;
        }
    }

    @wire(getPicklistValues, { recordTypeId: "$recordTypeId", fieldApiName: CALL_FIELD })
    picklistResults({ error, data }) {
        if (data) {
        this.countryCodeList = data.values;
        this.error = undefined;
        console.log("data.values", data.values);
        } else if (error) {
        this.error = error;
        this.countryCodeList = [];
        }
    }
    



    @track customStyle = {
        css : `
        .country-code_input{
            width: 100px;
            margin: 0;
            position: absolute;
            left: 33%;
            top: 4px;
            z-index:10;
        }
        .phone_input .slds-form-element__control{
            padding-left: calc(33% + 110px);
        }
        .slds-form-element_horizontal .slds-form-element__label{
            max-width:unset;
        }
        .country-code_input .slds-dropdown-trigger_click .slds-dropdown{
            max-height:15rem;
        }
        .slds-spinner_container{
            position:fixed;
        }



        .list_wrap .slds-form-element__help {
            display: none;
        }
        .list_wrap .slds-has-error{
            --slds-c-input-color-border: var(--slds-g-color-error-base-40, inherit);
            --slds-c-input-shadow: none;
        }
        .slds-has-error .slds-input,
        .slds-has-error .slds-input:active, 
        .slds-has-error .slds-input:focus,
        .slds-has-error .slds-checkbox [type=checkbox]+.slds-checkbox_faux,
        .slds-has-error .slds-checkbox [type=checkbox]~.slds-checkbox_faux{
            border-color: var(--sds-c-input-color-border, var(--dxp-s-form-element-color-border, var(--dxp-g-neutral-3)));
            box-shadow: none;
        }

        `
        , id : 'custom_registerStyle'
    }

    
    render() {
        return this.showCompleteView ? COMPLETE_VIEW : DEFAULT_VIEW;
    }
    
    connectedCallback(){
        utils.setCustomStyle(this.customStyle.css, this.customStyle.id);
        //console.log("time zone", Intl.DateTimeFormat().resolvedOptions().timeZone);

        window.addEventListener("message", this.handleVFResponse.bind(this));
        this.handleSubscribe();

    }

    disconnectedCallback(){
        utils.removeCustomStyle(this.customStyle.id);
    }

   

    moveToHome(event){
        event.preventDefault();
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: communityBasePath
            },
        });
    }

    // lightning edit form load
    loadForm(){
        this.isLoadedForm = true;
        this.isSpinner = false;
    }

    // Account type handler
    handleAccType(event){
        const value = event.detail.value;
        const _this = this;
        let isCompany;
        isCompany = value === '기업';

        this.isRequiredForCompany = isCompany;

        setTimeout(()=>{
            _this.checkRequired();
        }, 100)
        
    }

    checkRequired(){
        const inputFields = this.template.querySelectorAll(
            'lightning-input-field'
        );
        let isPass = true;
        if (inputFields) {
            inputFields.forEach(field => {
                if(!field.reportValidity()){
                    isPass = false;
                }
            });
        }

        this.isDisabledRegistBtn = !(isPass && this.isAuthurizeMail);
    }

    // "인증하기" 검증 후 디테일 아코디언 펼치기
    handleAuth(){
        this.isSpinner = true;
        checkDuplicateEmail({
            email :  this.refs.emailInput.value
        })
        .then(result => {
            console.log("checkDuplicateEmail => ", result);
            this.isAuthurizeMail = !result;
            this.checkRequired();
            this.isSpinner = false;
            if(result) {// 중복
                this.showToastMessage("이미 사용중인 이메일 입니다.", '다른 이메일을 입력해 주세요' , 'error' , 'dismissible');
                this.refs.emailInput.reset();
            } else{
                this.detailStyle = '';
                this.template.querySelector(".js-detail_company").open = true;
            }
            
        })
        .catch(error => {
            console.log('checkDuplicateEmail error msg : ', error);
        })



        
    }

    showToastMessage(title, message, variant, mode) {
        Toast.show({
            label: title,
            message: message,
            mode: mode,
            variant: variant
        }, this);

    }


    // 기본정보 이메일 검증
    handleEmailValidation(event){
        const emailInp = this.template.querySelector('.email-input');
        let isDisabled = true;
        if(emailInp.value && emailInp.reportValidity()){
            isDisabled = false;
        }
        this.isDisabledAuthtBtn = isDisabled;

        this.checkRequired();
    }

    

    // lightning-record-edit-form 제출
    handleOnSubmit(event){

        event.preventDefault();  
        const fields = event.detail.fields;
        let MobilePhone = fields.MobilePhone__c;
        let CompanyPhone = fields.CompanyPhone__c;
        let addressValue, shippingValue;
        if(this.addressValue?.street){
            addressValue  = `${this.addressValue.street} ${this.refs.addressDetail.value}`;
        }
        if(this.shippingValue?.street){
            shippingValue  = `${this.shippingValue.street} ${this.refs.shippingDetail.value}`;
        }

        
        
        fields.MobilePhone__c = MobilePhone ? this.template.querySelector(".js-country-mobile").value + MobilePhone : null;
        fields.CompanyPhone__c = CompanyPhone ? this.template.querySelector(".js-country-company").value + CompanyPhone : null;
        fields.Address__Street__s = addressValue; 
        fields.Address__PostalCode__s = this.addressValue?.zipCode; 
        fields.Address__City__s = this.addressValue?.city; 

        fields.ShippingAddress__Street__s = shippingValue; 
        fields.ShippingAddress__PostalCode__s = this.shippingValue?.zipCode; 
        fields.ShippingAddress__City__s = this.shippingValue?.city; 

        this.template.querySelector('lightning-record-edit-form').submit(fields);
        this.isSpinner = true;

        console.log("fields => ", fields);


    }

    // lightning-record-edit-form 성공
    handleSuccess(event) {
        console.log("record success", event.detail);
        this.isSpinner = false;
        this.showCompleteView = true;
    }

    //lightning-record-edit-form 에러
    handleError(event){
        console.log("error", event.detail);
    }


    changeTel(event){
        let isRemoveZero = false;
        if(event.target.classList.contains("js-phone-company")){
            if(this.template.querySelector(".js-country-company").value  === '+82'){
                isRemoveZero = true
            }
        } else {
            if(this.template.querySelector(".js-country-mobile").value  === '+82'){
                isRemoveZero = true
            }
        }

        this.checkRequired();
        if(!isRemoveZero) return false;
        let value = event.detail.value;
        let target = event.target;
        this.editPhoneNumber(target, value);
    }

    changeCountryCode(event){
        let targetTelValue;
        let target;
        if(event.target.classList.contains("js-country-company")){
            target = this.template.querySelector(".js-phone-company");
            targetTelValue = this.template.querySelector(".js-phone-company").value;
        } else {
            target = this.template.querySelector(".js-phone");
            targetTelValue = this.template.querySelector(".js-phone").value;
        }

        this.editPhoneNumber(target, targetTelValue);
    }


    editPhoneNumber(target, value){
        if(!value) return false
        let str = value.replace(/^0+/, "");
        target.value = str;
    }

    // vf
    

    onLoad() { //로딩 완료시
        console.log("-- vf loaded");
    }

    handleVFResponse(message) {
        console.log("handleVFResponse ==>", message.data);
        if(message?.data?.zipCode){
            const msg = message.data;
            const fullAddress = `${msg?.state} ${msg?.city} ${msg?.street}`;
            if(this.addressTarget === 'Address'){
                
                this.template.querySelector(".js-address").value = fullAddress;
                this.template.querySelector(".js-address-postal").value = msg.zipCode;

                this.addressValue = {
                    ...msg
                };

            } else if(this.addressTarget === 'ShippingAddress'){
                this.template.querySelector(".js-shipping").value = fullAddress;
                this.template.querySelector(".js-shipping-postal").value = msg.zipCode;

                this.shippingValue = {
                    ...msg
                };
            }

            this.addressTarget = null;
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


    // vf 주소검색 띄우기
    searchAddress(event){
        const target = event.currentTarget;
        const type = target.dataset.type;
        this.addressTarget = type;

        console.log("searchAddress");
        this.template.querySelector("iframe").contentWindow.postMessage(type, '*');
    }


}