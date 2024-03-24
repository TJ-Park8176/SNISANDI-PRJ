/**
 * @description       : 
 * @author            : sungho.jo@mz.co.kr
 * @group             : 
 * @last modified on  : 2024-03-22
 * @last modified by  : sungho.jo@mz.co.kr
**/
import { LightningElement
    , wire
    , api
    , track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';

export default class NicepayAuthentication extends LightningElement {

    @track formRender = false;
    @track isOpenVfIframe = false;

    @wire(CurrentPageReference)
    getPageReferenceParameters(currentPageReference) {
    if (currentPageReference) {
        console.log('currentPageReference : ' , currentPageReference);
    }
    }

    connectedCallback(){
        window.addEventListener('message', (message) => {
            try{
                if((message.data !== null && message.data.event !== null) && message.data.event === 'nice-pay-result') {
                    this.paymentAuthResponse(message.data.result);
                }    
            }catch(excep){
                console.log(' excep : ', excep)
            }
        });
    }

    renderedCallback(){
    }

    paymentAuthRequest(e){
        console.log('# paymentAuthRequest');
        this.isOpenVfIframe = true;
    }

    paymentAuthResponse(authResponse){
        console.log('# paymentAuthResponse');
        console.log('# paymentAuthResponse.e : ' , e);

        if(e.AuthResultCode !== null) {

        }
    }

    paymentAuthSuccess(data){

    }

    paymentAuthFailed(data){

    }
}