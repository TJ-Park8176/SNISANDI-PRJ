/**
 * Created by MZC01-DGCHOI on 2024-01-24.
 */

import { LightningElement, api, wire } from 'lwc';

export default class ProductListTest extends LightningElement {

    connectedCallback() {
        const url = 'https://mindful-badger-801ahx-dev-ed.trailblaze.my.salesforce.com/cms/delivery/v59.0/0ap5g000000pMqJAAU/contents/20Y5g000000qEGYEA2?oid=00D5g00000LL03bEAD&language=de';
        this.funcRequest(url);

       /* this.image = {
            url: 'https://mindful-badger-801ahx-dev-ed.trailblaze.my.salesforce.com/cms/delivery/v59.0/0ap5g000000pMqJAAU/contents/20Y5g000000qEGYEA2?oid=00D5g00000LL03bEAD&language=de',
            alt: '',
            title: '',
          }*/
    }

    async funcRequest(url){
     await fetch(url)
        .then((response) => {
            console.log(response);
          return response.json(); // data into json
        })
        .then((data) => {
          // Here we can use the response Data
        })
        .catch(function(error) {
          console.log(error);
        });
    }
}