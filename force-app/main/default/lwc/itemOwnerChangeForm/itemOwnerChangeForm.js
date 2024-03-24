/**
 * Created by MZC01-DGCHOI on 2023-10-30.
 */

import { LightningElement, api } from 'lwc';
import updateOwner from '@salesforce/apex/OwnerChangeController.updateOwnerWithItem'
import isNoRunning from '@salesforce/apex/OwnerChangeController.isNoApexJobRunning'
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

export default class ItemOwnerChangeForm extends NavigationMixin(LightningElement) {
    @api recordId;
    @api objectApiName;

    handleClick = async () => {
        let isNoRunningResult = false;

        await isNoRunning()
        .then((result) => {
            isNoRunningResult = result;
        }).catch((error) => {
            this.showToastMessage('error', error, 'error', 'dismissable');
        });

        if(isNoRunningResult) {
             updateOwner({
                recordId: this.recordId
             }).then((result) => {
                this.showToastMessage('하위 소유자 변경 진행 중', '완료 시 이메일로 알림 드리겠습니다.', 'success', 'dismissable');
             }).then(() => {
                setTimeout(() => {
                    this.handleParentClose();
                }, 1000);
             }).catch((error) => {
                //console.log("🚀 ~ error", error);
                this.showToastMessage('실패', error, 'error', 'dismissable');
             });
        } else {
            this.showToastMessage('error', '이미 하위 소유자 변경 작업이 진행중입니다. 10분 뒤에 요청부탁드립니다.', 'error', 'dismissable');
        }
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

    handleParentClose = () => {
        // 작업을 닫기 위한 네비게이션
        console.log('handleParentClose()');
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: this.objectApiName, // 작업이 연결된 개체의 API 이름
                actionName: 'view'
            },
        });
    }

}