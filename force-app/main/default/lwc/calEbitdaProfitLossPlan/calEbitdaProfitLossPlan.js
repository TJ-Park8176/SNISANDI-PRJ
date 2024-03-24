/**
 * Created by MZC01-DGCHOI on 2023-02-27.
 */

import { LightningElement, wire } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';

import createObject from '@salesforce/apex/ct_ObjectEBITDA.createObject';
import isSystemAdmin from '@salesforce/apex/UserRoleController.isSystemAdmin';

export default class CalEbitdaProfitLossPlan extends LightningElement {
    noticeMessage = '';
    alertMessage = '';

    isAdmin = false;

    @wire(isSystemAdmin)
    async wiredAdminToggle({data, error}) {
        console.log(data);
        if(data == true) {
            this.isAdmin = true;
        } else if(data == false) {
            this.isAdmin = false;
            this.alertMessage = '시스템 관리자만 접근 가능합니다';
        }
    }

    closeAction() {
        this.template.querySelector(".uploadModal").style.visibility = 'hidden';
        this.template.querySelector(".noticeBox").style.visibility = 'visible';
    }

    uploadObject() {
        createObject({
            targetAPIKey : 'ProfitandLoss_Plan__c'
        })
        .then(() => {
            this.error = undefined;
            this.noticeMessage = '업데이트 중입니다. 완료 시 이메일이 발송됩니다.';
        }).catch((error) => {
            this.error = error;
            console.log(error);
        });
        this.closeAction(); //메소드 호출 시 this 필요
    }
}