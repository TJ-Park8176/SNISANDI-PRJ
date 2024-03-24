/**
 * Created by MZC01-DGCHOI on 2022-12-12.
 */

import { LightningElement, api, wire } from 'lwc';

import costManageFormItemCSS from '@salesforce/resourceUrl/costManageFormItemCSS';
import { loadStyle } from 'lightning/platformResourceLoader';

import getAmountPlanList from '@salesforce/apex/ItemMngPlanController.getAmountPlanList';
import getItemInfo from '@salesforce/apex/ItemMngPlanController.getItemInfo';
import getAmountInfo from '@salesforce/apex/ItemMngPlanController.getAmountInfo';
import updateAmountList from '@salesforce/apex/ItemMngPlanController.updateAmountPlanList';

import { getRecord, pdateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LightningConfirm from "lightning/confirm";
import { CloseActionScreenEvent } from 'lightning/actions';


const FIELDS = ['ItemManagement_Plan__c.Id',
    'ItemManagement_Plan__c.WBS_CC__c',
    'ItemManagement_Plan__c.AccountSubjectselect__c',
    'ItemManagement_Plan__c.AmountType__c',
    'ItemManagement_Plan__c.AmountDivision__c',
    'ItemManagement_Plan__c.SalesSort__c',
    'ItemManagement_Plan__c.Account__c',
    'ItemManagement_Plan__c.Owner__c'];

export default class AmountPlanManageFormItem extends LightningElement {
    @api recordId;

    itemInfo;

    /****Field List****/
    itemField;
    wbsField;
    subjectField;
    amountTypeField;
    amountDivisionField;
    salesSortField;

    accountField;
    userField;
    total = 0;

    infoList = [];
    monthList = [];
    amountList = [];

    showAmountList = false;


    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (error) {
            console.log(error);
        } else if (data) {
            this.itemField = data.fields.Id.value;
            this.wbsField = data.fields.WBS_CC__c.value;
            this.subjectField = data.fields.AccountSubjectselect__c.value;
            this.amountTypeField = data.fields.AmountType__c.value;
            this.amountDivisionField = data.fields.AmountDivision__c.value;
            this.salesSortField = data.fields.SalesSort__c.value;
            this.accountField = data.fields.Account__c.value;
            this.userField = data.fields.Owner__c.value;
        }
    }

    @wire(getAmountPlanList, { itemId: '$recordId' })
    wiredAmountList({ data, error }) {
        if (data) {
            let sessionData = JSON.parse(sessionStorage.getItem('amountPlanList_' + this.recordId));

            console.group('금액,진행상황 SET');
            console.log('sessionData: ', sessionData);
            console.log('data: ', data);

            //저장O
            if (data.length > 0) {
                if (sessionData) { //세션O

                    //savedValue 설정
                    data.forEach((e, i) => {
                        sessionData[i].data.savedAmount = e.PlanAmount__c || 0;
                        sessionData[i].data.savedStatus = e.Status__c || '';
                    })

                    this.amountList = sessionData;
                    this.showAmountList = true;
                } else { //세션X
                    this.amountList = data.map((data, index) => {
                        return {
                            data: {
                                ...data,
                                Status__c: data.Status__c || '',
                                savedAmount: data.PlanAmount__c || 0,
                                savedStatus: data.Status__c || '',
                            },
                            ano: parseInt(data.calculateDate__c.split('-')[1])
                        };
                    });

                    //console.log('set  후', this.amountList);
                }
                //저장X
            } else {
                if (sessionData) { //세션O
                    //savedValue 설정
                    sessionData.forEach((e, i) => {
                        e.data.savedAmount = 0;
                        e.data.savedStatus = '';
                    });

                    this.amountList = sessionData;
                    this.showAmountList = true;
                    console.log('this.amountList: ', this.amountList);
                } else { //세션X
                    for (let i = 1; i <= 12; i++) {
                        this.amountList.push({
                            data: {
                                PlanAmount__c: 0,
                                Status__c: '',
                                savedAmount: 0,
                                savedStatus: '',
                            },
                            ano: i
                        });
                    }
                }
            }
            this.showAmountList = true;
            this.setTotal();

            console.groupEnd();
        } else if (error) {
            console.log(error);
        }
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
        console.log('initInputChangedStatusUpdate() start');

        this.checkAllInputChanged('.input-price');
        this.checkAllInputChanged('.input-status');
    }

    checkAllInputChanged(selector) {
        try {
            this.template.querySelectorAll(selector).forEach(e => {
                if (e.value != e.dataset.savedValue) {
                    e.classList.add('input-changed');
                }
            });
        } catch (err) {
            console.log(err);
        }
    }

    async handleClick(event) {
        const result = await LightningConfirm.open({
            message: "",
            theme: "success",
            label: "매출을 등록 하시겠습니까?"
        });
        console.log("🚀 ~ result", result);
        //true: OK, false: Cancel

        if (result) {
            await this.setInfoList();
            await this.setMonthList();

            await updateAmountList({
                itemId: this.recordId,
                infoMapString: JSON.stringify(this.infoList),
                monthListString: JSON.stringify(this.monthList)
            }).then(result => {
                sessionStorage.removeItem('amountPlanList_' + this.recordId);
            }).then(() => {
                this.showToastMessage('매출 등록 SUCCESS', '성공', 'success', 'dismissable');
                this.closeAction();
            }).then(() => {
                setTimeout(() => {
                    window.location.reload();
                }, 2000);
            }).catch(error => {
                console.log(error);
                this.showToastMessage('매출 등록 실패', error, 'error', 'dismissable');
            });
        }
    }

    async setInfoList() {
        let targets = this.template.querySelectorAll('.infoBox lightning-input-field');

        this.infoList = [];
        targets.forEach(e => {
            this.infoList.push({
                key: e.fieldName,
                value: (e.value == null ? '' : e.value)
            });
        });
    }

    async setMonthList() {
        const input_price = this.template.querySelectorAll('.monthTable .input-price');
        const input_status = this.template.querySelectorAll('.monthTable .input-status');

        this.monthList = [];
        for (var i = 0; i < 12; i++) {
            this.monthList.push({
                price: (input_price[i].value == null || input_price[i].value == '' ? 0 : input_price[i].value),
                status: input_status[i].value
            });
        }
    }

    handleBlur(event) {
        try {
            let index = event.target.dataset.index - 1;
            let savedValue = event.target.dataset.savedValue;
            let changedValue = event.target.value;

            // 빈 값 처리
            if (changedValue === '' || changedValue === null) {
                this.amountList[index].data = { ...this.amountList[index].data, PlanAmount__c: 0 };
                event.target.value = 0;
            } else {
                this.amountList[index].data = { ...this.amountList[index].data, PlanAmount__c: changedValue };
            }

            // savedValue, changedValue 비교
            if (savedValue !== changedValue) {
                event.target.classList.add('input-changed');
            } else {
                event.target.classList.remove('input-changed');
            }

            sessionStorage.setItem('amountPlanList_' + this.recordId, JSON.stringify(this.amountList));

            this.setTotal();
        } catch (err) {
            console.log('🚀 ~ err', err);
        }
    }

    handleChangeTotalStatus(event) {
        console.log(event.target.value);
        this.template.querySelectorAll('.input-status').forEach((it) => {
            it.value = event.target.value;
        });
    }

    statusChange(event) {
        let index = event.target.dataset.index - 1;
        let savedValue = event.target.dataset.savedValue;
        let changedValue = event.target.value;

        // 빈 값 처리
        if (changedValue === '' || changedValue === null) {
            this.amountList[index].data.Status__c = '';
        } else {
            this.amountList[index].data = {
                ...this.amountList[index].data,
                Status__c: changedValue
            };
        }

        // savedValue, changedValue 비교
        if (savedValue != changedValue) {
            event.target.classList.add('input-changed')
        } else {
            event.target.classList.remove('input-changed');
        }

        sessionStorage.setItem('amountPlanList_' + this.recordId, JSON.stringify(this.amountList));
    }

    setTotal() {
        this.total = 0;
        this.amountList.forEach(e => {
            this.total += parseFloat(e.data.PlanAmount__c);
        });
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