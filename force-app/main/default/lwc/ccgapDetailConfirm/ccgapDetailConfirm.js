/**
 * Created by MZC01-DGCHOI on 2023-07-31.
 */

import { LightningElement, api } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createDetails from '@salesforce/apex/CCGAPController.createDetails';

export default class CcgapDetailConfirm extends LightningElement {

    @api recordId;

    createDetail() {
        createDetails({
            ccGapId : this.recordId
        }).then(result => {
            if(result == 'SUCCESS') {
                this.showToastMessage('저장 완료', 'CCGAP Detail 정보 저장 완료했습니다.', 'success', 'dismissable');
            } else {
                this.showToastMessage('저장 실패', result, 'error', 'dismissable');
            }
        }).then(() => {
            this.closeAction();
        }).catch(error => {
            this.showToastMessage('저장 오류', error, 'error', 'dismissable');
        });
    }

    closeAction() {
        this.dispatchEvent(new CloseActionScreenEvent);
    }

    showToastMessage(title, message, variant, mode) {
        const event = new ShowToastEvent({
            title : title,
            message : message,
            variant : variant,
            mode : mode
        });
        this.dispatchEvent(event);
    }

}