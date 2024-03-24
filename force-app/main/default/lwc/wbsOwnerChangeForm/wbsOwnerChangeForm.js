/**
 * Created by MZC01-DGCHOI on 2023-10-30.
 */

import { LightningElement, api, wire } from 'lwc';
import updateOwner from '@salesforce/apex/OwnerChangeController.updateOwnerWithWBS'
import isRoleCOC from '@salesforce/apex/UserRoleController.isUserRoleCOC';
import isNoRunning from '@salesforce/apex/OwnerChangeController.isNoApexJobRunning'
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import LightningAlert from 'lightning/alert';

export default class WbsOwnerChangeForm extends NavigationMixin(LightningElement) {
    @api recordId;
    @api objectApiName;

    showModal = false;
    childComponentRef;

    renderedCallback() {
        if(this.recordId) {
            console.log('renderedCallback()');
            isRoleCOC()
            .then((data) => {
                if(data === false) { //false
                    LightningAlert.open({
                        message: '하위 Data 소유자 변경 권한이 없습니다. 관리자(COC팀)만 변경 가능합니다.',
                        theme: 'shade',
                        label: '권한 없음',
                    }).then(() => {
                        this.handleParentClose();
                    }).catch(error => {
                        console.log("🚀 ~ error", error);
                    })
                } else if(data === true) { //true
                    this.showModal = true;
                }
            }).catch((error) => {
                this.showToastMessage('error', error, 'error', 'dismissable');
            })
        }
    }

    handleClick = async (event) => {
        let isNoRunningResult = false;

        await isNoRunning()
        .then((result) => {
            console.log('isNoRunning result', result);
            isNoRunningResult = result;
        }).catch((error) => {
            console.log('isNoRunning error', error);
            this.showToastMessage('error', error, 'error', 'dismissable');
        });

        if(isNoRunningResult) {
            updateOwner({
                recordId: this.recordId
            }).then((result) => {
                console.log("🚀 ~ updateOwner result", result);
                this.showToastMessage('하위 소유자 변경 진행 중', '완료 시 이메일로 알림 드리겠습니다.', 'success', 'dismissable');
            }).then(() => {
                setTimeout(() => {
                    //window.location.reload();
                    this.handleParentClose();
                }, 1000);
            }).catch((error) => {
                console.log("🚀 ~ updateOwner error", error);
                this.showToastMessage('실패', error, 'error', 'dismissable');
            });
        } else {
            this.showToastMessage('error', '이미 하위 소유자 변경 작업이 진행중입니다. 10분 뒤에 요청부탁드립니다.', 'error', 'dismissable');
        }
    }

    handleParentClose = () => {
        // 작업을 닫기 위한 네비게이션
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: this.objectApiName, // 작업이 연결된 개체의 API 이름
                actionName: 'view'
            }
        });
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