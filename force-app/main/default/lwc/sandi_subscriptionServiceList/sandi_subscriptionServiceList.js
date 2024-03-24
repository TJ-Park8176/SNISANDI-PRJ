import { LightningElement, track , api } from 'lwc';
import utils from 'c/sandi_utils';
import subscriptionServiceModal from 'c/sandi_subscriptionServiceDetail';
export default class Sandi_subscriptionServiceList extends LightningElement {
    connectedCallback(){
        this.setInit();
    }
    disconnectedCallback(){

    }

    setInit(){
        this.filterDetail = {
            options : {
                state : [{label : '상태1', value : '상태1'}]
            }
            , defaultValue : {
                // contractDate : {
                //     start : '2024-03-10'
                //     , end : '2024-03-21'
                // }
            }
        };
    }

    searchCondition(event){
        console.log("필터 컴포넌트 =>", event.detail);
    }

    async handleDetail(){
        const result = await subscriptionServiceModal.open({
            size: 'medium',
            description: '구독서비스 상세 모달'
        });
        
        console.log(result);
    }

}