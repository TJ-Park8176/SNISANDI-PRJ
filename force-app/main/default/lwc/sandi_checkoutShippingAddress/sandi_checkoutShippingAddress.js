/**
 * Created by MZC01-DGCHOI on 2024-03-20.
 */

import { LightningElement, api, track, wire } from 'lwc';
import {
    updateDeliveryMethod,
    updateShippingAddress,
    createContactPointAddress
} from 'commerce/checkoutApi';

export default class SandiCheckoutShippingAddress extends LightningElement {

    @api checkoutDetails;
    @api deliveryGroupItems;
    @api checkoutId;

    // Delivery Method 변경
    async changeDeliveryMethod() {
        console.log('cartDetails',        this.checkoutDetails);
        console.log('deliveryGroupItems', this.deliveryGroupItems);
//        console.log('checkoutId',         this.checkoutId);

//        const result = await updateDeliveryMethod({deliveryMethodId : ''});
//
//        console.log(result);

    }

    async createAddress() {
         const address = {
           "city": "서울특별시",
           "country": "Korea, Republic of",
           "postalCode": "07807",
           "street": "도로명주소"
         };

        const result = await createContactPointAddress(address);

        console.log(result);
    }


    async changeDeliveryAddress() {
        try {
            const deliveryGroup = {
                deliveryAddress: {
                    id: "8lW1y000000TYYFEA4", //S&I 회사
                },
                desiredDeliveryDate: "2024-04-20T05:38:06.433Z",
            };
            const result = updateShippingAddress(deliveryGroup);
        } catch(error) {

        }
    }

}