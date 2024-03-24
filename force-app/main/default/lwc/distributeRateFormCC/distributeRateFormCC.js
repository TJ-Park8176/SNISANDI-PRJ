/**
 * Created by MZC01-DGCHOI on 2023-09-25.
 */

import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getWBSCCList from '@salesforce/apex/DistributeRateController.getWBSCCList';
import updateRatio from '@salesforce/apex/DistributeRateController.updateRatio';

export default class DistributeRateFormCc extends LightningElement {
    result;

    @wire(getWBSCCList)
    wiredWBSCCList({ data, error }) {
        if(data) {
            if(data.length > 0) {
                this.result = data.map((data, index) => {
                    return {
                        cc_id              : data.cc_id,
                        cc_code            : data.cc_code,
                        cc_name            : data.cc_name,
                        cc_distribute_rate : data.cc_distribute_rate,
                        cc_link            : '/lightning/r/' + data.cc_id + '/view'
                    };
                });
            }
        } else if(error) {
            console.log(error);
        }
    }

    getRatio(){
        for(var index = 0; index < this.result.length; index++){
            const input_ratio   = this.template.querySelectorAll('.input-ratio');
            const ratio         = input_ratio[index].value;
            
            if(ratio === '' || ratio === null || ratio === undefined){
                this.result[index].cc_distribute_rate = 0;
            }else{
                this.result[index].cc_distribute_rate = parseFloat(ratio);
            }
        }
    }

    async handleSubmit(){
        await this.getRatio();
        console.log(this.result);

        if(!this.areAllIntegers(this.result)) {
            this.showToastMessage('ERROR', '비율은 정수여야 합니다.' , 'error', 'dismissable');
        } else if(!this.isSum100(this.result)) {
            this.showToastMessage('ERROR', '비율의 합은 100이여야 합니다.' , 'error', 'dismissable');
        } else {
            updateRatio({
                jsonData: JSON.stringify(this.result)
            }).then((data) => {
                console.log('data: ', data);
                if(data.CODE == 'SUCCESS') {
                    this.showToastMessage(data.CODE, data.MESSAGE, 'success', 'dismissable');
                } else if(data.CODE == 'ERROR') {
                    this.showToastMessage(data.CODE, data.MESSAGE, 'error', 'dismissable');
                }
            }).catch(error => {
                console.log(error);
                let errorMsg = error.body.message ? error.body.message : error.body.pageErrors[0].message;
                // this.showToastMessage('매입 등록 실패', errorMsg , 'error', 'dismissable');
            });
        }
    }
 
    showToastMessage(title, message, variant, mode) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: mode
        });
        this.dispatchEvent(event);
    }

    areAllIntegers(arr) {
       return arr.every( x => Number.isInteger(x.cc_distribute_rate));
    }

    isSum100(arr) {
        const sum = arr.reduce((acc, current) => acc + current.cc_distribute_rate, 0);
        console.log('비율합 : ' + sum);
        return sum === 100;
    }

}