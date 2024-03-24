/**
 * Created by MZC01-DGCHOI on 2024-03-07.
 */

import { LightningElement, api, track } from 'lwc';

export default class SandiProductReviewCard extends LightningElement {

    @api reviewData;

    star_one;
    star_two;
    star_three;
    star_four;
    star_five;

    connectedCallback() {
        this.star_one   = this.reviewData.Rating__c === '1';
        this.star_two   = this.reviewData.Rating__c === '2';
        this.star_three = this.reviewData.Rating__c === '3';
        this.star_four  = this.reviewData.Rating__c === '4';
        this.star_five  = this.reviewData.Rating__c === '5';
    }

    get writeDate() {
        return this.reviewData.CreatedDate.slice(0, 10);
    }
}