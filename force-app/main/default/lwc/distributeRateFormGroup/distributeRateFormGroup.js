/**
 * Created by MZC01-DGCHOI on 2023-09-25.
 */

import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getGroupList from '@salesforce/apex/DistributeRateController.getGroupList';
import updateRatio from '@salesforce/apex/DistributeRateController.updateGroupDistributionRatio';
import getPickListValue from '@salesforce/apex/DistributeRateController.getPickListValue';

export default class DistributeRateFormGroup extends LightningElement {
    versionOptions          = [];
    result                  = [];
    versionSelectedValue    = '';
    latestVersion           = false;

    connectedCallback() {
        Promise.all([
            getPickListValue()
        ]).then((data) => {
            if(data) {
                this.versionSelectedValue = data[0][0]; 
                this.versionOptions = data[0].map(e => {
                    return {
                        label: e,
                        value: e
                    }
                })
            }
            return getGroupList({versionName: this.versionSelectedValue})
        }).then((result) => {
            this.result         = result;
            console.log('this.result: ', this.result);
            this.latestVersion  = this.result[0].latestVersion;  
            if(result[0].returnWrapper.CODE == 'ERROR'){
                this.showToastMessage(result[0].returnWrapper.CODE, result[0].returnWrapper.MESSAGE, 'error', 'dismissable');
            }
        }).catch(error => {
            console.log(error);
        })
    }

    /* year 버전 선택할 때 */
    handleVersionOption(event) {
        this.versionSelectedValue = event.target.value; 
        getGroupList({versionName: this.versionSelectedValue})
        .then((result) => {
            this.result         = result;
            this.latestVersion  = this.result[0].latestVersion;  
            if(result[0].returnWrapper.CODE == 'ERROR'){
                this.showToastMessage(result[0].returnWrapper.CODE, result[0].returnWrapper.MESSAGE, 'error', 'dismissable');
            }
        })
    }

    calculateButton(){
        updateRatio({ versionName: this.versionSelectedValue })
        .then((result) => {
            if(result.CODE == 'SUCCESS'){
                this.showToastMessage(
                    result.CODE,
                    result.MESSAGE,
                    'success',
                    'dismissable'
                );
                
                setTimeout(() => {
                    window.location.reload();
                }, 2000);
            }else{
                this.showToastMessage(
                    result.CODE,
                    result.MESSAGE,
                    'error',
                    'dismissable'
                );
            }
        }).then(() => {

        }).catch((error) => {
            console.log(error);
        })
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


}