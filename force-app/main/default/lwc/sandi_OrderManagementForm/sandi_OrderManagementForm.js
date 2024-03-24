/**
 * @description       : OrderSummary 화면에서 주문취소, 반품, 교환 버튼을 눌렀을 때, 수량과 사유를 선택하는 화면
 * @author            : jisoolee@mz.co.kr
 * @group             : 
 * @last modified on  : 2024-03-20
 * @last modified by  : jisoolee@mz.co.kr
**/

import { api, track, wire } from 'lwc';
import LightningModal from 'lightning/modal';
// import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LightningAlert from 'lightning/alert';
/* Confirmed Order List와 연결 */
import { CurrentPageReference } from 'lightning/navigation';
/* Flow */
import { FlowAttributeChangeEvent, FlowNavigationNextEvent } from 'lightning/flowSupport';
/* Apex Class */
import getSelectedConfirmedOrder from '@salesforce/apex/Sandi_OrderManagementFormController.getSelectedConfirmedOrder';
import getPicklistValue from '@salesforce/apex/Sandi_OrderManagementFormController.getPicklistValues';
/* Custom Label */
import instructionLabel from '@salesforce/label/c.ReturnInstructions';

export default class Sandi_OrderManagementForm extends LightningModal {
    // sandi_ConfirmedOrderList 전달 값
    @api flagValue;
    @api confirmedOrderId;
    flagLabel;
    
    // 안내 사항
    @track instruction  = instructionLabel;

    // Flow 관련 변수
    @api flowName;
    @api inputVariables;
    @api finalQuantity;
    @api finalReason;
    @api orderItemSummaryId;    // 확정 주문의 Order Item Summary Id


    @api descriptionField
    @api productField
    @api ratingField

    renderFlow = false;

    // loading
    loading = true;

    // 선택한 확정 주문
    confirmedOrderList;

    // 사유 옵션
    reasonOptions;

    // 접수 화면 구분
    isFirstPage = true;

    // 선택한 수량, 사유
    selectedQuantity;
    selectedReason; 

    // 취소/반품/교환 가능 수량
    availableQuantity;
    
    @wire(CurrentPageReference) pageRef;
    connectedCallback() {
        if(this.flagValue == 'Cancel'){
            this.flagLabel = '취소'
        } 
        else if(this.flagValue == 'Reship'){
            this.flagLabel = '교환'
        }else{
            this.flagLabel = '반품'
        }
        this.loading = false;
    }
    
    get modalLabel() {
        return this.flagLabel+' 접수';
    }

    // Get Selected Confirmed Order
    @wire(getSelectedConfirmedOrder, { currentStatus: '$flagValue', confirmedOrderId: '$confirmedOrderId' })
    wiredConfirmedOrder({data, error}) {
        if(data) {
            console.log(data);
            if(data.code == 'SUCCESS'){
                if(data.selectedConfirmedOrder == null){
                    this.confirmedOrderList = null;
                }else{
                    this.availableQuantity  = data.selectedConfirmedOrder.availableQuantity;
                    this.orderItemSummaryId = data.selectedConfirmedOrder.orderItemSummary;
                    this.confirmedOrderList = data.selectedConfirmedOrder;
                }
            }else{
                this.handleAlertClick(data.message, 'error', '에러: 관리자에게 문의하세요.');
            }
        }
    } 

    // Get Confirmed Order-Reason picklist
    @wire(getPicklistValue, { objectApiName: 'ConfirmedOrder__c', fieldApiName: 'Reason__c' })
    wiredPicklistValue({data, error}) {
        if(data) {
            let returnPicklistValue=[];
            for (let picklistValue of data) {
                returnPicklistValue.push({  
                    label: picklistValue,
                    value: picklistValue
                });
            }
            this.reasonOptions = returnPicklistValue;
        }
    }

    // quantity input event
    handleQuantityChange(event){
        if(parseInt(event.detail.value, 10) > parseInt(this.availableQuantity, 10)){
            this.showToastMessage('주의', '입력 가능한 수량을 초과했습니다.', 'warning', 'dismissable'); 
        } 
    }

    // '다음' 버튼
    clickNext(){
        if(this.requiredInputCheck() == 'success'){
            this.isFirstPage = false;
        } 
    }

    // '이전' 버튼
    clickPrevious(){
        const previousValue = this.template.querySelector('.inputReasonCls');
        if (previousValue) {
            previousValue.value = this.selectedReason;
        }
        this.isFirstPage = true;
    }

    // '접수' 버튼
    createConfirmedOrder(){
        this.finalQuantity = this.template.querySelector('.finalInputQuantityCls').value;
        console.log('finalQuantity: ', this.finalQuantity);
        this.finalReason = this.template.querySelector('.finalInputReasonCls').value;
        console.log('finalReason: ', this.finalReason);

        // this.inputVariables = {
        //     recordId: this.orderItemSummaryId,
        //     quantity: this.finalQuantity,
        //     reason: this.finalReason
        // };

        this.inputVariables = [
            {
                name: 'flag',
                type: 'String',
                value: this.flagValue
            },
            {
                name: 'confirmedOrderId',
                type: 'String',
                value: this.confirmedOrderId
            },
            {
                name: 'quantity',
                type: 'Number',
                value: this.finalQuantity
            },
            {
                name: 'reason',
                type: 'String',
                value: this.finalReason
            },
        ];
        console.log('this.inputVariables: ', this.inputVariables);
        this.renderFlow = true;

        // if(this.flagValue == 'Cancel'){
            
        // }else if(this.flagValue == 'Return'){

        // }else{

        // }
    }

    // 수량, 사유 입력 check
    requiredInputCheck(){
        const inputQuantity = this.template.querySelector('.inputQuantityCls').value;
        const inputReason   = this.template.querySelector('.inputReasonCls').value;

        if(inputQuantity == null || inputQuantity == undefined || inputQuantity == '' || inputQuantity == 0){
            // this.showToastMessage('주의', this.flagLabel+' 수량을 입력하세요.', 'warning', 'dismissable');
            this.handleAlertClick(this.flagLabel+' 수량을 입력하세요.', 'warning', '주의');
            return 'error';
        }else{
            this.selectedQuantity = inputQuantity;
        }

        if(inputReason == null || inputReason == undefined || inputReason == '' || inputReason == '사유 선택'){
            // this.showToastMessage('주의', this.flagLabel+' 사유를 선택하세요.', 'warning', 'dismissable');
            this.handleAlertClick(this.flagLabel+' 사유를 입력하세요.', 'warning', '주의');
            return 'error';
        }else{
            this.selectedReason = inputReason;
            return 'success';
        }
    }

    // alert message
    async handleAlertClick(message, theme, label) {
        await LightningAlert.open({
            message: message,
            theme: theme,
            label: label
        });
    }

    handleStatusChange(event){
		try{
            console.log('event.detail.status: ', event.detail.status);

            if (event.detail.status === 'FINISHED_SCREEN') {
                console.log('flow success');
                
                // 20240315 여기부터 보면됨
                //Hide the Flow again
                this.renderFlow = false;

                const { target } = event;
                const { id } = target.dataset;
                this.close(id);
            }else{
            console.log('Flow execution encountered an unexpected status.');
            }
        }catch(e){
            console.log('error message: ', e.message);
        }
    }
}




// // toast message
// showToastMessage(title, message, variant, mode) {
//     const event = new ShowToastEvent({
//         title: title,
//         message: message,
//         variant: variant,
//         mode: mode
//     });
//     this.dispatchEvent(event);
// }