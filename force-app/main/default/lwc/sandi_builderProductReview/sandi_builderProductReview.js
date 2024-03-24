/**
 * Created by MZC01-DGCHOI on 2024-03-07.
 */

import { LightningElement, api } from 'lwc';
import { getSessionContext } from 'commerce/contextApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';


export default class SandiBuilderProductReview extends LightningElement {
    productId;
    isPreview = false;

    connectedCallback() {
        getSessionContext()
        .then((sessionContext) => {
            console.log('sessionContext.isPreview?', sessionContext.isPreview);
            this.isPreview = sessionContext.isPreview;
        }).then(() => {
            if(this.isPreview) {
                this.productId = '01t1y0000060oHxAAI';
            } else {
                const url      = window.location.href;
                const urlSplit = url.split('/');
                this.productId = urlSplit[urlSplit.length - 1];
            }
        });
    }


}