import { LightningElement, api, wire, track } from 'lwc';
import { getObjectInfos } from 'lightning/uiObjectInfoApi';
import { getRecord } from 'lightning/uiRecordApi';


export default class PartnerCOrderTab extends LightningElement {


    connectedCallback() {
       
    }
    /*
     * 주문탭으로 변경시 초기화 시켜주는 함수
     */
    ordertabClick(){ 
        const orderComponent = this.template.querySelector('c-partner-c-order');
        if (orderComponent) {
            orderComponent.inintsetingdate(); 
        }
    }
}