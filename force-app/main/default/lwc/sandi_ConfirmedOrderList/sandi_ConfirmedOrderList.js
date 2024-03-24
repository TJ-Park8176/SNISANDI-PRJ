/**
 * @description       : OrderSummary 화면에서 확정 주문 확인 및 주문취소, 반품, 교환을 처리할 수 있는 화면
 * @author            : jisoolee@mz.co.kr
 * @group             : 
 * @last modified on  : 2024-03-15
 * @last modified by  : jisoolee@mz.co.kr
**/

import { LightningElement, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
/* Apex Class */
import getConfirmedOrder from '@salesforce/apex/Sandi_OrderManagementFormController.getConfirmedOrder';
/* Open Modal Button */
import orderManagementForm from "c/sandi_OrderManagementForm";

export default class Sandi_ConfirmedOrderList extends LightningElement {
    // 현재 페이지 정보
    @wire(CurrentPageReference) pageRef;
    recordId;

    // 확정 주문 상세 내역 
    openDetail = false;

    // 조회된 확정 주문
    confirmedOrderList;
    confirmedOrderListLength;

    // 선택한 확정 주문
    confirmedOrderId;

    // recordId 가져오기
    connectedCallback() {
        if (this.pageRef) {
            this.recordId = this.pageRef.attributes.recordId;
        }
    }

    // Get Confirmed Order
    @wire(getConfirmedOrder, { OrderSummaryId: '$recordId' })
    wiredConfirmedOrder({data, error}) {
        if(data) {
            console.log('data.confirmedOrderList: ', data.confirmedOrderList);
            if(data.confirmedOrderList.length > 0){
                this.confirmedOrderList = data.confirmedOrderList;
                this.confirmedOrderListLength = data.confirmedOrderList.length;
            }else{
                this.confirmedOrderListLength = 0;
            }
        }
    } 

    // 확정 주문 상세 내용
    openAccordion(event){
        const confirmedOrderId  = event.currentTarget.dataset.item;
        const selectedItem      = this.confirmedOrderList.find(order => order.confirmedOrderId === confirmedOrderId);
        const dataId            = this.template.querySelector(`.${selectedItem.confirmedOrderId}`).getAttribute('data-item');

        if(selectedItem.confirmedOrderId == dataId){
            if(this.template.querySelector(`.${selectedItem.confirmedOrderId}`).style.display == ''){
                this.template.querySelector(`.${selectedItem.confirmedOrderId}`).style.display = 'none';
            }else{
                this.template.querySelector(`.${selectedItem.confirmedOrderId}`).style.display = '';
            }
        } else{
            this.template.querySelector(`.${selectedItem.confirmedOrderId}`).style.display = 'none';
        } 
    }
    
    // 주문 취소 button
    cancelOrder(event) {
        orderManagementForm.open({
            label: '취소 접수',
            flagValue: 'Cancel',
            confirmedOrderId: this.getDataId(event)
        }).then((result) => {
            console.log(result);
        });
    }

    // 교환 button
    reshipOrder(event) {
        orderManagementForm.open({
            label: '교환 접수',
            flagValue: 'Reship',
            confirmedOrderId: this.getDataId(event)
        }).then((result) => {
            console.log(result);
        });
    }

    // 반품 button
    returnOrder(event) {
        orderManagementForm.open({
            label: '반품 접수',
            flagValue: 'Return',
            confirmedOrderId: this.getDataId(event)
        }).then((result) => {
            console.log(result);
        });
    }

    getDataId(event){
        const eventConfirmedOrderId  = event.currentTarget.dataset.item;
        const eventSelectedItem      = this.confirmedOrderList.find(order => order.confirmedOrderId === eventConfirmedOrderId);
        const eventDataId            = this.template.querySelector(`.${eventSelectedItem.confirmedOrderId}`).getAttribute('data-item');
        return eventDataId;
    }
}