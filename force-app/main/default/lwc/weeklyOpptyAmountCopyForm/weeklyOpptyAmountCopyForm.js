/**
 * Created by MZC01-DGCHOI on 2023-01-13.
 */

import { LightningElement } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';

import copyObject from '@salesforce/apex/ct_ObjectCopy.copyObject';

export default class WeeklyOpptyAmountCopyForm extends LightningElement {
    noticeMessage = '';

    closeAction() {
        this.template.querySelector(".uploadModal").style.visibility = 'hidden';
        this.template.querySelector(".noticeBox").style.visibility = 'visible';
    }

    uploadObject() {
        copyObject({
            type : 'weeklyExpect',
            targetAPIKey : 'Opportunity_amount__c'
        }).then(() => {
            this.error = undefined;
            this.noticeMessage = '업로드 진행 중입니다. 완료 시 이메일이 발송됩니다.';
        }).catch((error) => {
            this.error = error;
        });
        this.closeAction();
    }
}