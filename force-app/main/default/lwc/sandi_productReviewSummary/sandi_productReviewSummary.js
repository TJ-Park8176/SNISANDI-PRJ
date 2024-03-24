/**
 * Created by MZC01-DGCHOI on 2024-03-07.
 */

import { LightningElement, api, wire } from 'lwc';
import getProductReviewSummary from '@salesforce/apex/Sandi_ProductReviewController.getProductReviewSummary'

export default class SandiProductReviewSummary extends LightningElement {

    @api
    productId;

    summaryInfo = {};

    @wire(getProductReviewSummary, {productId : '$productId'})
    wiredSummaryInfo({error, data}) {
        if(error) {
            console.log('summaryInfo error', error);
        } else if(data) {
            console.log('summaryInfo data', data);
            this.summaryInfo = data;

            this.updateRatingBarPercentage();
        } else {
            console.log('summaryInfo else', data);
        }
    }

    renderedCallback() {
        this.updateRatingBarPercentage();
    }

    updateRatingBarPercentage() {
        try {
            const bars = this.template.querySelectorAll('.rating-bar-highlight');
            bars.forEach((e) => {
                e.style.height = e.dataset.percent + 'px';
            });
        } catch(error) {
            console.log('error', error);
        }

    }


}