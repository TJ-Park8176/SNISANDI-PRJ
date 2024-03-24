/**
 * Created by MZC01-DGCHOI on 2022-12-16.
 */

import { LightningElement, api, wire} from 'lwc';

import costManageFormItemCSS from '@salesforce/resourceUrl/costManageFormItemCSS';
import { loadStyle } from 'lightning/platformResourceLoader';

import getSingleCostList from '@salesforce/apex/ItemMngController.getSingleCostList';
import getItemInfo from '@salesforce/apex/ItemMngController.getItemInfo';
import updateSingleCostList from '@salesforce/apex/ItemMngController.updateSingleCostList';

import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LightningConfirm from "lightning/confirm";
import { CloseActionScreenEvent } from 'lightning/actions';

export default class CostManageSingleFormItem extends LightningElement {
    @api recordId;

    costList = [];
    itemInfo;

    /****Field List****/
    itemField;
    wbsField;
    subjectField;

    infoList = [];
    monthList = [];

    showCostList = false;

    @wire(getItemInfo, {itemId: '$recordId'})
    wiredItemInfo({data, error}) {
        if(data) {
            this.itemInfo = data;
            this.itemField = data.Id;
            this.wbsField = data.WBS_CC__c;
            console.log(data);
        }
    }

    @wire(getSingleCostList, {itemId: '$recordId'})
    wiredCostList({ data, error }) {
        if(data) {
            console.log(data);
            if(data.length > 0) {
                console.log('data length > 0');
                this.costList = data;
                this.subjectField = data[0].AccountSubjectselect__c;
                this.costList = this.costList.map((data, index) => {
                    return { data, ano: index + 1 };
                });
            } else {
                console.log('data length = 0');
                for(let i=1; i<=12; i++) {
                    this.costList.push({
                        data:{PurchaseAmount__c:0},
                        ano:i
                    });
                }
            }
            console.log(this.costList);
            this.showCostList = true;
        } else if(error) {
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

    async handleClick(event) {
        console.log('handleClick()');

        const result = await LightningConfirm.open({
            message: "",
            theme: "success",
            label: "매입을 등록 하시겠습니까?"
        });
        console.log("🚀 ~ result", result);
        //true: OK, false: Cancel

        if(result) {
            await this.setInfoList();

            await this.setMonthList();

            await updateSingleCostList({
                itemId: this.recordId,
                infoMapString:   JSON.stringify(this.infoList),
                monthListString: JSON.stringify(this.monthList)
            }).then(result => {
                console.log('updateAmount SUCCESS');
            }).then(() => {
                this.showToastMessage('매입 등록 SUCCESS', '성공', 'success', 'dismissable');
                this.closeAction();
                //sessionStorage.setItem("isReload", true);
            }).then(() => {
                setTimeout(() => {
                    window.location.reload();
                   //window.location.href = window.location.href.split('/action/')[0] + '/r/ItemManagement__c/'+ this.recordId +'/view';
                }, 2000);
            }).catch(error => {
                console.log(error);
                this.showToastMessage('매입 등록 실패', error, 'error', 'dismissable');
            });
        }
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