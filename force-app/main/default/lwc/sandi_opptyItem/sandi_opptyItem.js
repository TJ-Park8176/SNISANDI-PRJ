import { LightningElement, api, track } from 'lwc';
import utils from 'c/sandi_utils';
import PAYMENT_VIEW from "./mode/sandi_paymentItem.html";
import CONTRACT_VIEW from "./mode/sandi_contractItem.html";

import detailModal from 'c/sandi_opptyItemDetail';
//import { createCartItemAddAction, createCartItemUpdateAction, dispatchAction } from 'commerce/actionApi';
import { addItemToCart } from 'commerce/cartApi';
import { createCartItemAddAction, createCartItemUpdateAction, dispatchAction } from 'commerce/actionApi';

export default class Sandi_opptyItem extends LightningElement {
    @api type;
    @track isContractView;
    render() {
        return this.isContractView ? CONTRACT_VIEW : PAYMENT_VIEW;
    }

    connectedCallback(){
        this.isContractView = this.type === 'contract';
    }

    async handleDetail(){
        const result = await detailModal.open({
            size: 'medium',
            description: '세부내역'
        });

        console.log(result);
    }

    /**
     * 
     * @param { productId: string; quantity: number } event 
     */
    handleAddToCart(event) {
        //event.stopPropagation();
        console.log("--handleAddToCart--");
        // const { productId, quantity } = event.detail;
       
        // dispatchAction(this, addItemToCart("01t1y0000060FagAAE", 1), {
        //     onSuccess: () => {
        //         // 1. 견적아이템 - 카트담기 노출 필드 비활성
        //         // 2. 카트아이템 - 견적id 
        //         // 3. 카트에서 아이템 삭제 시 견적 아이템의 카트담기 노출 필드 활성
        //         console.log("add to cart success!");
        //     },
        //     onError : (error) => {
        //         console.error(error);
        //     }
        // });

        addItemToCart('01t1y0000060FagAAE', 1).then((result) => {
            console.log("result", result);
          });

    }

}