/**
 * Created by MZC01-DGCHOI on 2023-09-22.
 */

import { LightningElement } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';

import copyRecord from '@salesforce/apex/ct_BizPlanCopy.copyRecord';

export default class BizPlanCopyForm extends LightningElement {

    value = '';
    noticeMessage = '';
    thisYear = new Date().getFullYear();

    get options() {
        return [
            { label: 'choose one...', value: '' },
            { label: (this.thisYear - 1).toString(), value: (this.thisYear - 1).toString() },
            { label: (this.thisYear).toString(), value: (this.thisYear).toString() },
            { label: (this.thisYear + 1).toString(), value: (this.thisYear + 1).toString() },
        ]
    }

    handleChange(event) {
        this.value = event.detail.value;
    }

    closeAction() {
        this.template.querySelector(".uploadModal").style.visibility = 'hidden';
        this.template.querySelector(".noticeBox").style.visibility = 'visible';
    }

    uploadRecord() {
        copyRecord({
            baseYear: this.value
        }).then(() => {
            this.error = undefined;
            this.noticeMessage = '복제 진행 중입니다. 완료 시 이메일이 발송됩니다.';
        }).catch((error) => {
            this.error = error;
        });
        this.closeAction();
    }
}