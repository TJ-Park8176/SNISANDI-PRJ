import { LightningElement, api, track, wire } from 'lwc';
import utils from 'c/sandi_utils';
import quotesModal from 'c/sandi_opptyRequestForm';

import { NavigationMixin } from 'lightning/navigation';
import communityBasePath from '@salesforce/community/basePath';

import { getRecord } from "lightning/uiRecordApi";
import userId from "@salesforce/user/Id";
import UserContactFIELD from '@salesforce/schema/User.ContactId';

export default class Sandi_opptyRequestButton extends NavigationMixin(LightningElement) {
    
    /**
     * Product2
     * 판매유형 : SalesType_SANDI__c
     */
    @track _productDetail;
    @track _pricebookEntryId;
    @track isDisabeld;
    @track productId;
    @track contactId;

    @wire(getRecord, { recordId: userId, fields: [UserContactFIELD]}) 
    currentUserInfo({error, data}) {
        if (data) {
            this.contactId = data.fields.ContactId.value;
        } else if (error) {
            this.error = error ;
        }
    }
    


    @api
    get productDetail() {
        return this._productDetail;
    }
    set productDetail(value) {
        this._productDetail = value;
        this.productId = value?.id;
        this.callSalesType();
    }

    @api
    get pricebookEntryId() {
        return this._pricebookEntryId;
    }
    set pricebookEntryId(value) {
        this._pricebookEntryId = value;
        console.log("_pricebookEntryId", value);
    }

    callSalesType(){
        console.log("_productDetail", this._productDetail?.fields?.QuoteProduct_SANDI__c);
        if(!this.productId) return false;
        /**
         * 견적형일 경우 true 리턴
         */

        this.isDisabeld = this._productDetail?.fields?.QuoteProduct_SANDI__c ? true : false;
       
        // getSalesType({
        //     productId :  this.productId
        // })
        // .then(result => {
        //     this.isDisabeld = result;
        //     console.log("getSalesType => ", result);
        // })
        // .catch(error => {
        //     console.log('getSalesType error msg : ', error);
        // })
    }

    

    handleModal(){
        quotesModal.open({
            size: 'small',
            description: '견적 신청 모달',
            productId: this.productId,
            productDetail : this._productDetail,
            contactId : this.contactId,
            pricebookEntryId : this._pricebookEntryId
        }).then((result)=>{
            // 모달 닫은 뒤 이벤트
            if(result === 'login'){
                this[NavigationMixin.Navigate]({
                    type: 'standard__webPage',
                    attributes: {
                        url: `${communityBasePath}/login`
                    },
                });
            }
        });
    }

}