/**
 * Created by MZC01-DGCHOI on 2024-02-27.
 */

import { LightningElement } from 'lwc';
import basePath from '@salesforce/community/basePath'

export default class SandiFloatingMenu extends LightningElement {
    IMAGE_PATH = basePath + '/sfsites/c/cms/delivery/media/';

    image_url_cart;
    image_url_wishlist;
    image_url_recent;
    image_url_go_top;

    connectedCallback() {
        try {
            this.image_url_cart     = this.IMAGE_PATH + "MC7TEUGIT4JFE3BKOSSKLZM66JEU";
            this.image_url_wishlist = this.IMAGE_PATH + "MC7ZTTQI6HNVHOHIR7U3FOIMRJYM";
            this.image_url_recent   = this.IMAGE_PATH + "MCMD5DP6DY4FFFRO6CY23ZRQBOVQ";
            this.image_url_go_top   = this.IMAGE_PATH + "MCQLOF427MY5C5XNGVYJ5PM5I7MU";
        } catch(error) {
            console.log('error', error);
        }
    }

    handleFoldCheckboxClick(event) {
        const menu     = this.template.querySelector('.floating_side_menu');
        const foldText = this.template.querySelector('.fold_checkbox_text');
        const isFolded = !menu.classList.toggle('floating_side_menu_folded');

        foldText.innerHTML = isFolded ? '&lt;' : '&gt;';
    }

    handleGoTopButtonClick(event) {
        //href 기능 제어
        event.preventDefault();

        //스크롤 맨 위로 이동
        window.scrollTo({
            top: 0,
            behavior: 'smooth' // 부드러운 스크롤 효과 사용
        });
    }
}