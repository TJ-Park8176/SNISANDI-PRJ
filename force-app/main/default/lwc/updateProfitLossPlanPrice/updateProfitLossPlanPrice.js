import { LightningElement } from 'lwc';

import updatePrice from '@salesforce/apex/ct_UpdateProfitLossPlanPrice.updatePrice';

export default class UpdateProfitLossPlanPrice extends LightningElement {

    value = '';
    noticeMessage = '';
    thisYear = new Date().getFullYear();

    get options() {
        return [
            { label: 'choose one...', value: '' },
            { label: (this.thisYear - 1).toString(), value: (this.thisYear - 1).toString() },
            { label: (this.thisYear).toString(), value: (this.thisYear).toString() },
            { label: (this.thisYear + 1).toString(), value: (this.thisYear + 1).toString() },
        ];
    }

    handleChange(event) {
        this.value = event.detail.value;
    }

    updatePlanPrice() {
        console.log('updatePlanPrice()');

        updatePrice({
            baseYear: this.value
        }).then((data) => {
            console.log('then...', data);
            this.noticeMessage = '사업계획(손익) 계산 진행중입니다. 완료 시 이메일이 발송됩니다.';
        }).catch((error) => {
            console.log('error', error);
            this.noticeMessage = error;
        });

        this.closeAction(); //메소드 호출 시 this 필요
    }

    closeAction() {
        this.template.querySelector(".uploadModal").style.visibility = 'hidden';
        this.template.querySelector(".noticeBox").style.visibility = 'visible';
    }
}