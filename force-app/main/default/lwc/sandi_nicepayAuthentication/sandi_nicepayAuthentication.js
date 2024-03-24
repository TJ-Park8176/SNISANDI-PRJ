/**
 * @description       : NicepayAuthentication
 * @author            : sungho.jo@mz.co.kr
 * @group             : MegozoneCloud
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
    /**
     * @description visualforce iframe open 여부
     */
    @track isOpenVfIframe = false;

    @wire(CurrentPageReference)
    getPageReferenceParameters(currentPageReference) {
        if (currentPageReference) {
        }
    }

    connectedCallback(){
        window.addEventListener('message', (message) => {
            // visualforce에서 post된 데이터를 읽음.
            if((message.data !== null && message.data.event !== null) && message.data.event === 'nice-pay-result') {
                console.log(' message.data : ', message.data)
                console.log(' message.data.result :' , message.data.result);
                this.paymentAuthResponse(JSON.parse(JSON.stringify(message.data.result)));
            }    
        });
    }

    renderedCallback(){
    }

    /**
     * nicepay 인증 요청
     * @param {event} e 
     */
    paymentAuthRequest(e){
        console.log('# paymentAuthRequest');
        this.isOpenVfIframe = true;
    }

    paymentAuthResponse(authResponse){
        console.log('# paymentAuthResponse');
        console.log('# paymentAuthResponse.authResponse : ' , authResponse);
        if(authResponse.hasOwnProperty('AuthResultCode')) {
            switch (authResponse.AuthResultCode) {
                case '0000':
                    this.paymentAuthSuccess(authResponse);
                    break;
                default:
                    this.paymentAuthFailed(authResponse);
                    break;
            }
        }
    }


    paymentAuthSuccess(data){
        console.log('# paymentAuthSuccess ');
        this.isOpenVfIframe = false;
    }

    paymentAuthFailed(data){
        console.log('# paymentAuthFailed ');
        this.isOpenVfIframe = false;
    }
}