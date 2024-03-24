/**
 * Created by MZC01-DGCHOI on 2022-12-12.
 */

import { LightningElement, api, wire } from 'lwc';

import JqueryResource from '@salesforce/resourceUrl/jQuery360';
import costManageFormItemCSS from '@salesforce/resourceUrl/costManageFormItemCSS';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';

import getItemInfo from '@salesforce/apex/ItemMngController.getItemInfo';
import getCostList from '@salesforce/apex/ItemMngController.getCostList';
import updateCostList from '@salesforce/apex/ItemMngController.updateCostList';
import deleteCostList from '@salesforce/apex/ItemMngController.deleteCostList';
import isAmountItem from '@salesforce/apex/ItemMngController.isAmountItem';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import LightningConfirm from "lightning/confirm";


export default class CostManageFormItem extends LightningElement {

    @api recordId;

    activeSection = [0];

    /***fieldList***/
    itemField;
    wbsField;
    accountSubjectSortField;

    showAmountItem;

    costList = [];
    showCostList = false;

    infoList = [];

    selectedItemValue;
    isValueSelected;
    total = 0;
    costTotal = 0;

    @wire(getItemInfo, { itemId: '$recordId' })
    wiredItemInfo({ data, error }) {
        if (data) {
            this.itemField = data.Id;
            this.wbsField = data.WBS_CC__c;
            this.AccountSubjectSortField = data.AccountSubjectSort__c;
        } else {
            console.log(error);
        }
    }

    @wire(isAmountItem, { itemId: '$recordId' })
    wiredAmountItem({ data, error }) {
        if (data) { //true,false
            this.showAmountItem = data;
        } else {
            console.log(error);
        }
    }

    @wire(getCostList, { itemId: '$recordId' })
    async wiredCostList({ data, error }) {
        if (data) {
            await this.setCostList(data);
        }
        this.costTotalSum();
        this.showCostList = true;
    }

    connectedCallback() {
        Promise.all([
            loadStyle(this, costManageFormItemCSS),
            loadScript(this, JqueryResource)
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

    async setCostList(data) {
        let sessionData = JSON.parse(sessionStorage.getItem('costList_' + this.recordId));
        let parseData   = JSON.parse(data);

        // 매입의 경우, 저장된 데이터가 없어도 뒤에서 뿌려줌
        if (parseData.length > 0) { // [] : 2
            console.log('저장된 데이터 있을 경우');
            console.log('sessionData: ', sessionData);

            if (sessionData) { // 세션 있을 경우
                console.log('세션 있을 경우');
                console.group('매입SessionGroup');
                
                sessionData.forEach((e, i) => {
                    e.isSaved = true;
                    // sessionData[i].data.savedAmount = parseData.i?.e.PredictAmount__c || 0;
                    // console.log('predictAmount :::: ', parseData.i?.e.PredictAmount__c);
                    // console.log('e.PredictAmount__c :::: ', e.PredictAmount__c);
                });
                console.groupEnd();

                this.costList = sessionData;
                console.log('parseData: ', parseData);
                console.log('costList: ', this.costList);

                /*for(var cost of this.costList){
                    cost['isSaved'] = true;
                }*/
            } else {
                console.log('세션 없을 경우');

                this.costList = parseData;
                console.log('parseData:', parseData);
                this.costList.forEach((cost, costIndex) => {
                    console.log('cost:', cost);
                    cost.data.forEach((e, i) => {
                        e.data.savedAmount = e.data.PurchaseAmount__c || 0;
                    });
                });
                console.log(this.costList);
            }

            //매출 setTotal
            for (var index = 0; index < 12; index++) {
                this.total += parseFloat(this.costList[0].data[index].amountPrice);
            }
        }
        /*
        else {
           console.log('저장된 데이터 없을 경우');
           //init Data Setting
           this.costList = [[]];
           for(let i=1; i<=12; i++) {
               this.costList[0].push({
                   data: {
                       PredictAmount__c: 0,
                       savedAmount: 0,
                   },
                   cno: i,
                   amountPrice: 0
               });
           }
           this.costList = this.costList.map((data, index) => {
               return {
                   ...data,
                   sno: index+1,
                   subjectName: '계정 과목 선택',
                   isSaved: false
               };
           });
       }

       this.showCostList = true;
       */
    }


    costTotalSum() {
        for (var num = 0; num < this.costList.length; num++) {
            let input_cost = this.template.querySelectorAll(`.input-cost[data-index="${num}"]`);
            this.costTotal = 0;

            for (var index = 0; index < 12; index++) {
                this.costTotal += parseFloat(this.costList[num].data[index].data.PurchaseAmount__c);
            }
            input_cost[0].value = this.costTotal;
        }
    }


    handleChangeSubject(event) {
        console.log(event.target);
    }

    async handleClick(event) {
        const result = await LightningConfirm.open({
            message: "",
            theme: "success",
            label: "매입을 등록 하시겠습니까?"
        });
        console.log("🚀 ~ result", result);

        if (result) {
            await this.setInfoList();
            await this.updateCost();
        }

    }

    async updateCost() {
        await updateCostList({
            itemId: this.recordId,
            infoMapString: JSON.stringify(this.infoList)
        }).then((result) => {
            if (result.status == 'S') {
                sessionStorage.removeItem('costList_' + this.recordId),

                    Promise.all([
                        this.showToastMessage('매입 등록 성공', '', 'success', 'dismissable'),
                        this.closeAction()
                    ]).then(() => {
                        setTimeout(() => {
                            window.location.reload();
                        }, 2000);
                    }).catch(error => {
                        console.log(error);
                    })
            } else if (result.status == 'E') {
                let errorMsg = result.message;
                console.log(errorMsg);
                this.showToastMessage('매입 등록 실패', errorMsg, 'error', 'dismissable');
            }
        }).catch(error => {
            console.log(error);
            let errorMsg = error.body.message ? error.body.message : error.body.pageErrors[0].message;
            this.showToastMessage('매입 등록 실패', errorMsg, 'error', 'dismissable');
        });
    }

    async setInfoList() {
        let input_subject = this.template.querySelectorAll('.input-subject');
        let itemValue = this.template.querySelector('.input-item').value;
        let wbsValue = this.template.querySelector('.input-wbs').value;

        this.infoList = [];
        input_subject.forEach(e => {
            //e.value: 계정과목 ID
            let afterSubjectId = e.value;
            let beforeSubjectId = e.dataset.id;
            let monthList = [];

            let eIndex = e.dataset.index;
            let input_price = this.template.querySelectorAll(`.input-price[data-index="${eIndex}"]`);
            input_price.forEach((ele, index) => {
                let tmpPrice = ele.value;
                if (tmpPrice == null || tmpPrice == '' || tmpPrice == undefined) {
                    tmpPrice = 0;
                }
                monthList.push(tmpPrice);
            });
            this.infoList.push({ data: monthList, beforeSubjectId: beforeSubjectId, afterSubjectId: afterSubjectId, wbsId: wbsValue });
        });
    }

    addTemplate() {
        this.showCostList = false;
        let tmpList = [[]];

        for (let i = 0; i < 12; i++) {
            tmpList[0].push({
                data: { PurchaseAmount__c: 0 },
                cno: i + 1,
                amountPrice: this.costList[0].data[i].amountPrice,
            });
        }

        let tmpIndex = this.costList.length;
        tmpList = tmpList.map((data, index) => {
            return { data, sno: tmpIndex++, subjectName: '[NEW]계정 과목 선택', isSaved: false };
        });

        this.costList.push(tmpList[0]);
        this.showCostList = true;
    }

    async handleOnSelect(event) {
        this.selectedItemValue = event.detail.value;

        let selectedItemIndex = event.currentTarget.dataset.index;

        //        if(this.selectedItemValue == 'Save') {
        //            this.setSingleInfoList(selectedItemIndex);
        //            this.updateCost();
        //        } else
        if (this.selectedItemValue == 'Delete') {
            this.showCostList = false;

            if (this.costList[selectedItemIndex].isSaved) { //저장되어있는 레코드면....
                //창 띄우기
                let subjectId = this.costList[selectedItemIndex].subjectId;
                let subjectName = this.costList[selectedItemIndex].subjectName;

                const result = await LightningConfirm.open({
                    message: subjectName,
                    theme: "success",
                    label: "해당 계정 과목의 매입리스트를 삭제 하시겠습니까?"
                });
                console.log("🚀 ~ result", result);

                if (result) {
                    await deleteCostList({
                        itemId: this.recordId,
                        subjectId: subjectId
                    }).then(() => {
                        sessionStorage.removeItem('costList_' + this.recordId);
                        this.showToastMessage('매입 삭제 성공', subjectName + ' 매입리스트 삭제 성공', 'success', 'dismissable');
                    }).then(() => {
                        setTimeout(() => {
                            window.location.reload();
                        }, 2000);
                    }).catch((error) => {
                        this.showToastMessage('매입 삭제 실패', error.body.message, 'error', 'dismissable');
                    })
                }
            } else {
                this.removeCostSectionItem(selectedItemIndex);
            }

            this.showCostList = true;
        }
    }

    removeCostSectionItem(index) {
        this.costList.splice(index, 1);

        if (this.costList.length == 0) {
            setTimeout(() => {
                window.location.reload();
            }, 2000);
        }

        sessionStorage.setItem(
            'costList_' + this.recordId,
            JSON.stringify(this.costList)
        );
    }

    async closeAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleBlur(event) {
        try {
            const eIndex = event.target.dataset.index;
            const savedValue = event.target.dataset.savedValue;
            let changedValue = event.target.value;

            this.costTotal = 0;

            // 빈 값 처리
            if (changedValue == null || changedValue == '' || changedValue == undefined) {
                changedValue = 0;
            }

            const input_subject = this.template.querySelector(`.input-subject[data-index="${eIndex}"]`);
            const subjectId = input_subject.value;
            const subjectName = input_subject.selectedName;

            //계정과목 validation check
            if (subjectId == undefined || subjectId == null || subjectId == '') {
                this.showToastMessage('주의', '계정 과목을 선택하세요', 'warning', 'dismissable');
                event.target.value = 0;

                return;
            }

            this.costList[eIndex].subjectId = subjectId;
            this.costList[eIndex].subjectName = subjectName;

            const input_cost = this.template.querySelector(`.input-cost[data-index="${eIndex}"]`);
            const input_price = this.template.querySelectorAll(`.input-price[data-index="${eIndex}"]`);

            input_price.forEach((ele, index) => {
                this.costTotal += parseFloat(ele.value);
                this.costList[eIndex].data[index].data.PurchaseAmount__c = parseFloat(ele.value);
                input_cost.value = this.costTotal
            });

            // savedValue, changedValue 비교 toggle
            if (savedValue !== changedValue) {
                event.target.classList.add('input-changed');
            } else {
                event.target.classList.remove('input-changed');
            }

            sessionStorage.setItem('costList_' + this.recordId, JSON.stringify(this.costList));

        } catch (error) {
            console.log(error);
        }
    }

    /*
    setTotal() {
        this.total = 0;
        this.costTotal = 0;
        
        this.costList.forEach(e => {
            for(var index = 0; index < 12 ; index++){
                this.total += parseFloat(e.data[index].amountPrice);
                this.costTotal += parseFloat(e.data[index].data.PurchaseAmount__c);
            }
        });
    }
    */

    showToastMessage(title, message, variant, mode) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: mode
        });
        this.dispatchEvent(event);
    }

    handleChangeSubject(event) {
        try {
            console.log("the selected record id is " + event.detail);
            this.isValueSelected = true;

            const eIndex = event.target.dataset.index;
            const input_subject = this.template.querySelector(`.input-subject[data-index="${eIndex}"]`);
            const subjectId = input_subject.value;
            const subjectName = input_subject.selectedName;

            console.log('input_subject: ', input_subject);
            console.log('eIndex : ', eIndex);
            console.log('subjectId : ', subjectId);
            console.log('subjectName : ', subjectName);

            this.costList[eIndex].subjectId = input_subject.value;
            this.costList[eIndex].subjectName = input_subject.selectedName;

            sessionStorage.setItem(
                'costList_' + this.recordId,
                JSON.stringify(this.costList)
            );

        } catch (err) {
            console.log(err);
        }
    }
}