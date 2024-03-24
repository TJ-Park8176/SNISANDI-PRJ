/**
 * Created by MZC01-DGCHOI on 2023-12-04.
 */

import { LightningElement, api, wire } from 'lwc';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import LightningAlert from 'lightning/alert';
import { getRecord } from 'lightning/uiRecordApi';

import hasOpptyAmount from '@salesforce/apex/OpptyMngPlanController.hasOpptyAmount';
import getOpptyAmount from '@salesforce/apex/OpptyMngPlanController.getOpptyAmount';
import deleteOpptyAmount from '@salesforce/apex/OpptyMngPlanController.deleteOpptyAmount';

export default class OpptyPlanAmountDeleteModal extends LightningElement {
    @api recordId;

    showModal = false;

    async handleClick() {
        await deleteOpptyAmount({
            opptyPlanId: this.recordId
        }).then((result) => {
            if(result == 'SUCCESS') {
                sessionStorage.removeItem('amountPlanOpptyList_'+this.recordId);
                this.showToastMessage('사업계획(영업매출) 삭제 성공', result , 'success', 'dismissable');
                this.closeAction();
                setTimeout(() => {
                    window.location.reload();
                }, 2000);
            } else if(result == 'NO DATA') {
                this.showToastMessage('삭제할 사업계획(영업매출) 레코드가 없습니다.', result, 'error', 'dismissable');
            } else {
                this.showToastMessage('사업계획(영업매출) 삭제 실패', result, 'error', 'dismissable');
            }
            this.closeAction();
        }).catch(error => {
            console.log(error);
            this.showToastMessage('사업계획(영업매출) 삭제 실패', error, 'error', 'dismissable');
            this.closeAction();
        })
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