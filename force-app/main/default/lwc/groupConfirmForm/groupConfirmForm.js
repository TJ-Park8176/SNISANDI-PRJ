import { LightningElement, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import isSystemAdmin from '@salesforce/apex/UserRoleController.isSystemAdmin';
import groupConfirm from '@salesforce/apex/DistributeRateController.groupConfirm';

export default class GroupResetForm extends LightningElement {
    isAdmin = false;

    @wire(isSystemAdmin)
    async wiredAdminToggle({data, error}) {
        if(data) {
            this.isAdmin = true;
        } else if(data == false) {
            this.isAdmin = false;
            this.alertMessage = '시스템 관리자만 접근 가능합니다';
        }
    }

    confirmObject() {
        groupConfirm({ })
        .then((result) => {
            console.log('result: ', result);
            if(result.CODE == 'SUCCESS') {
                this.showToastMessage(result.CODE, result.MESSAGE, 'success', 'dismissable');
            } else if(result.CODE == 'ERROR') {
                this.showToastMessage(result.CODE, result.MESSAGE, 'error', 'dismissable');
            }
        }).catch((error) => {
            this.error = error;
            this.showToastMessage('ERROR', this.error, 'error', 'dismissable');
        });
        // this.closeAction(); 
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