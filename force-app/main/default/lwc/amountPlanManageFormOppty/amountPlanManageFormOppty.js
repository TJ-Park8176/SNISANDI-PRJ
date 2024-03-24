/**
 * Created by MZC01-DGCHOI on 2023-11-27.
 */

import { LightningElement, api, wire } from 'lwc';

import costManageFormItemCSS from '@salesforce/resourceUrl/costManageFormItemCSS';
import { loadStyle } from 'lightning/platformResourceLoader';

import getAmountList from '@salesforce/apex/OpptyMngPlanController.getAmountList';
import getOpptyInfo from '@salesforce/apex/OpptyMngPlanController.getOpptyInfo';
import updateAmountList from '@salesforce/apex/OpptyMngPlanController.updateAmountList';

import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LightningConfirm from "lightning/confirm";
import LightningAlert from 'lightning/alert';
import { CloseActionScreenEvent } from 'lightning/actions';

const FIELDS = ['Opportunity_plan__c.Id',
                'Opportunity_plan__c.Possibility_of_closed_won__c',
                'Opportunity_plan__c.WBS_CC__c',
                'Opportunity_plan__c.Parent_Opportunity__c',
                'Opportunity_plan__c.OwnerId',
                'Opportunity_plan__c.AccountId__c',
                'Opportunity_plan__c.StageName__c',
                'Opportunity_plan__c.Type2__c',
                'Opportunity_plan__c.Totalmonthlyamount__c', //없음
                'Opportunity_plan__c.Child_opportunity_count__c', //없음
                'Opportunity_plan__c.Conversion_amount__c']; //없음

export default class AmountPlanManageFormOppty extends LightningElement {
    @api recordId;

    amountList = [];

    /****Field List****/
    opptyField;
    wbsField;
    parentOpptyField;
    ownerField;
    accountField;
    totalAmountField;
    monthAmountField;

    total = 0;
    infoList = [];
    monthList = [];

    showAmountList = false;
    inputPriceDisabled = false;


    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        console.log('this.recordId ::: ' + this.recordId);
        if(error) {
            console.log(error);
        } else if(data) {
            console.log(data);
            /*
            if(data.fields.StageName.value == 'Closed Won') {
                LightningAlert.open({
                    message: '마감된 수주는 수주매출을 수정할 수 없습니다.',
                    theme: 'error', // a red theme intended for error states
                    label: 'Error', // this is the header text
                }).then(() => {
                    this.closeAction();
                });
            } else { //if(data.fields.Possibility_of_closed_won__c.value == '높음' && data.fields.Type2__c.value != '통합') {
            */
            //매핑
            this.opptyField       = data.fields.Id?.value;
            this.wbsField         = data.fields.WBS_CC__c?.value;
            this.parentOpptyField = data.fields.Parent_Opportunity__c?.value;
            this.ownerField       = data.fields.OwnerId?.value;
            this.accountField     = data.fields.AccountId__c?.value;
            this.totalAmountField = data.fields.Totalmonthlyamount__c?.value;
            this.monthAmountField = data.fields.Conversion_amount__c?.value;

            if(data.fields.StageName__c.value == 'Closed Won' ||
               data.fields.StageName__c.value == 'Closed Lost' ||
               data.fields.StageName__c.value == 'Drop' ||
               (data.fields.Type2__c.value == '통합' && data.fields.Child_opportunity_count__c.value > 0)
            ) {
                this.inputPriceDisabled = true;
                this.template.querySelector('.btn-submit').style.display = 'none';
                //visibility hidden : 공간 존재
                //display none : 공간 존재X
            }
        }
    }

    @wire(getAmountList, {opptyPlanId: '$recordId'})
    wiredAmountList({ data, error }) {
        let sessionData = JSON.parse(sessionStorage.getItem('amountPlanOpptyList_'+this.recordId));

        console.log('data:', data);
        console.log('sessionData:', sessionData);

        if(sessionData) { // 세션O
            data.forEach((e,i) => {
                sessionData[i].data.savedAmount = e.Monthly_amount__c || 0;
            });

            this.amountList = sessionData;
            this.setTotal();
            this.showAmountList = true;
        } else if(data) { 
            if(data.length > 0) { //저장O
                console.log('data length > 0');
                this.amountList = data;
                this.amountList = this.amountList.map((data, index) => {
                    return { 
                        data: {
                            ...data, 
                            savedAmount: data.Monthly_amount__c
                        }, 
                        ano: index + 1 
                    };
                });
            } else { //저장X
                console.log('data length = 0');
                for(let i=1; i<=12; i++) {
                    this.amountList.push({
                        data:{
                            Monthly_amount__c : 0,
                            savedAmount: 0,
                        },
                        ano:i
                    });
                }
            }
            this.setTotal();
            this.showAmountList = true;
        } else if(error) {
            console.log(error);
        }
        console.log('done amountList:', this.amountList);
    }

    async handleClick(event) {
        console.log('handleClick()');

        const result = await LightningConfirm.open({
            message: "",
            theme: "success",
            label: "수주 매출을 등록 하시겠습니까?"
        });
        console.log("🚀 ~ result", result);
        //true: OK, false: Cancel

        if(result) {
            await this.setInfoList();
            await this.setMonthList();
            await updateAmountList({
                opptyPlanId:     this.recordId,
                infoMapString:   JSON.stringify(this.infoList),
                monthListString: JSON.stringify(this.monthList)
            }).then(result => {
                sessionStorage.removeItem('amountPlanOpptyList_'+this.recordId);
            }).then(() => {
                this.showToastMessage('매출 등록 성공', '', 'success', 'dismissable');
                this.closeAction();
                //sessionStorage.setItem("isReload", true);
            }).then(() => {
                setTimeout(() => {
                    window.location.reload();
                }, 2000);
            }).catch(error => {
                console.log(error);
                this.showToastMessage('매출 등록 실패', error.body.pageErrors[0].message, 'error', 'dismissable');
            });
        }
    }

    handleBlur(event) {
        let index        = event.target.dataset.index - 1;
        let savedValue   = event.target.dataset.savedValue;
        let changedValue = event.target.value;

        // 빈 값 처리
        if(changedValue === '' || changedValue === null){
            this.amountList[index].data = {
                ...this.amountList[index].data, 
                Monthly_amount__c: 0
            };
            event.target.value = 0;
        } else{
            this.amountList[index].data = {
                ...this.amountList[index].data, 
                Monthly_amount__c: changedValue
            };
        }

        //savedValue, changedValue 비교
        if(savedValue !== changedValue) {
            event.target.classList.add('input-changed');
        } else {
            event.target.classList.remove('input-changed');
        }

        sessionStorage.setItem('amountPlanOpptyList_'+this.recordId, JSON.stringify(this.amountList));

        this.setTotal();
    }

    setTotal() {
        this.total = 0;
        this.amountList.forEach(e => {
            this.total += parseFloat(e.data.Monthly_amount__c);
        });
    }

    async setInfoList() {
        let targets = this.template.querySelectorAll('.infoBox lightning-input-field');

        this.infoList = [];
        targets.forEach(e => {
            //console.log(e.field-names);
            console.log(e.fieldName, e.value);
            this.infoList.push({
                key: e.fieldName,
                value: (e.value==null ? '' : e.value)
            });
        });
        console.log(':::::infoList:::::');
        console.log(this.infoList);
    }

    async setMonthList() {
        let input_price = this.template.querySelectorAll('.monthTable .input-price');

        this.monthList = [];
        for(let i=0; i<12; i++) {
            this.monthList.push({
                price: (input_price[i].value==null||input_price[i].value=='' ? 0 : input_price[i].value)
            });
        }
        console.log(':::::::monthList::::::::');
        console.log(this.monthList);
    }

    connectedCallback() {
        Promise.all([
            loadStyle(this, costManageFormItemCSS)
        ]).then(() => {
            console.log('Static Resource Loaded');
        }).catch(error => {
            console.log(error);
        })
    }

    renderedCallback() {
        this.initInputChangedStatusUpdate();
    }

    initInputChangedStatusUpdate() {
        this.checkAllInputChanged('.input-price');
    }

    checkAllInputChanged(selector) {
        try {
            this.template.querySelectorAll(selector).forEach(e => {
                if(e.value != e.dataset.savedValue) {
                    e.classList.add('input-changed');
                }
            });
        } catch(err) {
            console.log(err);
        }
    }

    closeAction() {
       this.dispatchEvent(new CloseActionScreenEvent());
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

}