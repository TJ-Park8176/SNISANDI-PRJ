import { LightningElement } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';

import copyObject from '@salesforce/apex/ct_ObjectCopy.copyObject';

export default class CostCopyForm extends LightningElement {

    noticeMessage = '';

    closeAction() {
        this.template.querySelector(".uploadModal").style.visibility = 'hidden';
        this.template.querySelector(".noticeBox").style.visibility = 'visible';
    }

    uploadObject() {
        copyObject({
            type : 'actionPlan',
            targetAPIKey : 'Cost__c'
        }).then(() => {
            this.error = undefined;
            this.noticeMessage = '업로드 진행 중입니다. 완료 시 이메일이 발송됩니다.';
        }).catch((error) => {
            this.error = error;
        });
        this.closeAction(); //메소드 호출 시 this 필요
    }
}