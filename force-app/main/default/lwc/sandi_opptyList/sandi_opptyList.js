import { LightningElement, track } from 'lwc';
import caseRequestModal from 'c/sandi_caseRequestForm';
import utils from 'c/sandi_utils';
//sandi_caseRequestForm
export default class Sandi_opptyList extends LightningElement {
       async handleCase(){
        const result = await caseRequestModal.open({
            size: 'small',
            description: '고객문의 신청 모달'
        });
        console.log(result);
    }

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

    
    
}