import { LightningElement, api, wire } from 'lwc';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import LightningAlert from 'lightning/alert';
import { getRecord } from 'lightning/uiRecordApi';

import hasOpptyAmount from '@salesforce/apex/OpptyMngController.hasOpptyAmount';
import getOpptyAmount from '@salesforce/apex/OpptyMngController.getOpptyAmount';
import deleteOpptyAmount from '@salesforce/apex/OpptyMngController.deleteOpptyAmount';

export default class OpptyAmountDeleteModal extends LightningElement {
    @api recordId;

    showModal = false;

    // tableData = [];
    // tableColumns = [
    //     { label: 'Name', fieldName: 'Name' }
    // ];

    // @wire(getOpptyAmount, {opptyId: '$recordId'})
    // wiredTableData({data, error}) {
    //     if(data) {
    //         this.tableData = data;
    //     } else if(error) {
    //         console.log(error);
    //     }
    // }

//    @wire(hasOpptyAmount, {opptyId: '$recordId'})
//    wiredHasRecord({data, error}) {
//        if(data==false) {
//            LightningAlert.open({
//                message: '해당 수주에 연관된 수주 매출 레코드가 없습니다.',
//                theme: 'error', // a red theme intended for error states
//                label: 'Error', // this is the header text
//            }).then(() => {
//                this.closeAction();
//            });
//        } else if(data==true) {
//            this.showModal = true;
//        } else if(error){
//            console.log(error);
//            this.closeAction();
//        }
//    }

    async handleClick() {
        await deleteOpptyAmount({
            opptyId: this.recordId
        }).then((result) => {
            if(result == 'SUCCESS') {
                this.showToastMessage('수주 매출 삭제 성공', result , 'success', 'dismissable');
                this.closeAction();
                setTimeout(() => {
                    window.location.reload();
                }, 2000);
            } else if(result == 'NO DATA') {
                this.showToastMessage('삭제할 수주 매출 레코드가 없습니다.', result, 'error', 'dismissable');
            } else {
                this.showToastMessage('수주 매출 삭제 실패', result, 'error', 'dismissable');
            }
            this.closeAction();
        }).catch(error => {
            console.log(error);
            this.showToastMessage('수주 매출 삭제 실패', error, 'error', 'dismissable');
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