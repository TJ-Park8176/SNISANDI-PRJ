/**
 * Created by MZC01-DGCHOI on 2024-02-26.
 */

import { LightningElement } from 'lwc';
import { FlowNavigationNextEvent, FlowNavigationBackEvent, FlowAttributeChangeEvent } from 'lightning/flowSupport';

export default class SandiScreenflowTest extends LightningElement {

    inputVariablesInitialised = false;
    inputVariables = [];

    connectedCallback() {
        this.inputVariables = [
            { name: 'name', type: 'String', value: '스크린' },
            { name: 'mobile', type: 'Number', value: 11111111 },
            { name: 'accountId', type: 'String', value: '0011y00000liLBlAAM' }
        ];
//        this.inputVariablesInitialised = true;
    }

    handleStatusChange(event) {
        console.log(event);
        if(event.detail.status === 'FINISHED') {
            console.log('finished');
        }
    }

    handleClick() {
        try {
            console.log(this.template.querySelector('lightning-flow .flow-button__NEXT'));

            //this.template.querySelector('lightning-flow').startFlow('test_screenflow', this.inputVariables);
            this.template.querySelector('lightning-flow .flow-button__NEXT').click();
        } catch(error) {
            console.log('error', error);
        }

    }
}