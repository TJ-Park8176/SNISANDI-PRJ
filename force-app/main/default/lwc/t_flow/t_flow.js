/**
 * Created by MZC01-DGCHOI on 2024-03-15.
 */

import { LightningElement, wire } from 'lwc';
import { Flow } from 'lightning/flow';


export default class TFlow extends LightningElement {

    renderInsertFlow;
    renderOneReviewFlow;
    renderMultiReviewFlow;

    get inputInsertVariables() {
        return [
            {
                name: 'descriptionField',
                type: 'String',
                value: '플로우테스트'
            },
            {
                name: 'productField',
                type: 'String',
                value: '01t1y0000060oHxAAI'
            },
            {
                name: 'ratingField',
                type: 'String',
                value: '5'
            }
        ];
    }

    get inputOneReviewVariables() {
        return [
            {
                name: 'ratingField',
                type: 'String',
                value: '3'
            }
        ];
    }


    get renderMultiReviewFlow() {
        return [
            {
                name: 'ratingField',
                type: 'String',
                value: '5'
            }
        ];
    }

    handleInsertClick() {
        this.renderInsertFlow = true;
    }

    handleOneReviewClick() {
        this.renderOneReviewFlow = true;
    }

    handleMultiReviewClick() {
        this.renderMultiReviewFlow = true;
    }

    handleInsertStatusChange(event) {
        if (event.detail.status === 'FINISHED_SCREEN') {
            console.log('FINISHED_SCREEN');
            this.renderInsertFlow = false;
        }
    }

    handleOneReviewStatusChange(event) {
        if (event.detail.status === 'FINISHED_SCREEN') {
            console.log('FINISHED_SCREEN');
            this.renderMultiReviewFlow = false;
            console.log(event.detail.outputVariables[1].value);
        }
    }

    handleMultiReviewClick(event) {
        console.log(event);
        if (event.detail.status === 'FINISHED_SCREEN') {
            console.log('FINISHED_SCREEN');
            this.renderMultiReviewFlow = false;
            console.log(event);
        }
    }
}