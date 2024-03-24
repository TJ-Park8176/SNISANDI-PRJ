/**
 * Created by MZC01-DGCHOI on 2024-03-07.
 */

import { LightningElement, api, wire } from 'lwc';
import getProductReviews from '@salesforce/apex/Sandi_ProductReviewController.getProductReviews'

export default class SandiProductReviewCards extends LightningElement {

    @api productId;

    productReviews;

    options = [
        { value: '0', label: '전체' },
        { value: '5', label: '5점' },
        { value: '4', label: '4점' },
        { value: '3', label: '3점' },
        { value: '2', label: '2잠' },
        { value: '1', label: '1점' }
    ];

    @wire(getProductReviews, {productId: '$productId'})
    wiredProductReviews({error, data}) {
        if(error) {
            console.log('SandiProductReviewCards error', error);
        } else if(data) {
            console.log('SandiProductReviewCards data', data);
            this.productReviews = data;
        } else {
            console.log('??SandiProductReviewCards data', data);
        }
    }

}