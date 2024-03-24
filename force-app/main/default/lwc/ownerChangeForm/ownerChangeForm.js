/**
 * Created by MZC01-DGCHOI on 2023-10-30.
 */

import { LightningElement, api } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin } from 'lightning/navigation';

export default class OwnerChangeForm extends NavigationMixin(LightningElement) {
    @api label; //WBS, 아이템관리
    @api parentClickHandler;
    @api parentObjectApiName;
    @api parentRecordId;
    @api showModal;

    handleClick() {
        this.parentClickHandler();
    }

    handleClose() {
        // 작업을 닫기 위한 네비게이션
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.parentRecordId,
                objectApiName: this.parentObjectApiName, // 작업이 연결된 개체의 API 이름
                actionName: 'view'
            },
        });
    }

}