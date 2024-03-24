import { LightningElement, track , api } from 'lwc';
import utils from 'c/sandi_utils';
import contractModal from 'c/sandi_contractDetail';

export default class Sandi_contractList extends LightningElement {
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
        const result = await contractModal.open({
            size: 'medium',
            description: '계약 상세 모달'
        });
        
        console.log(result);
    }
}