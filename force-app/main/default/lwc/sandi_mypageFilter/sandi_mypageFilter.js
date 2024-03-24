import { LightningElement, track, api } from 'lwc';
import utils from 'c/sandi_utils';

export default class Sandi_mypageFilter extends LightningElement {
    @api 
    get detail (){
        return this._detail;
    }

    set detail(value){
        this._detail = value;
        if(value) this.initSetting();
    }

    @track startDate = '';
    @track endDate = '';
    @track startMax = '';
    @track endMin = '';
    @track isDisabledSearchBtn;

    @track filterDetail;
    @track stateOption = [];
    @track isLoaed;

    @track customStyle = {
        css : `
        .search_btn button{
            white-space: nowrap;
        }`
        , id : 'opptyList_style'
    };

    connectedCallback(){
        utils.setCustomStyle(this.customStyle.css, this.customStyle.id);
        //console.log("detail", this.detail);
        //this.initSetting();
    }
    disconnectedCallback(){
        utils.removeCustomStyle(this.customStyle.id);
    }


    initSetting(){
        return new Promise((resolve)=>{
            const contractStart = this._detail?.defaultValue?.contractDate?.start;
            const contractEnd = this._detail?.defaultValue?.contractDate?.end;
            const today = new Date(); 
            const weekValue = this.getWeekDate();

            this.startDate = contractStart ? contractStart : this.setDateToText(weekValue);
            this.endDate = contractEnd ? contractEnd : this.setDateToText(today);
            this.endMin = contractStart ? contractStart : this.setDateToText(weekValue);
            this.startMax = contractEnd ? contractEnd : this.setDateToText(today);
            this.stateOption = this._detail?.options?.state ? this._detail?.options?.state : [];
            this.isLoaed = true;
            resolve();
        })
    }

    handleDate(event){
        const value = event.detail.value;
        const name = event.target.name;

        if(name == 'start'){
            this.startDate = value;
            this.endMin = value;
        } else {
            this.endDate = value;
            this.startMax = value;
        }


        const allValid = [
            ...this.template.querySelectorAll(`.filter lightning-input.${name}-date`),
        ].reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);

        this.isDisabledSearchBtn = !allValid;


        console.log("startDate", this.startDate);
        console.log("endDate", this.endDate);
        console.log("startMax", this.startMax);
        console.log("endMin", this.endMin);
    }

    shotcutDate(event){
        const name = event.target.name;
        const _this = this;
        const today = new Date(); 
        const weekValue = this.getWeekDate();
        const firstMonthValue = this.getMonthDate();
        const thirdMonthValue = this.get3MonthDate();
        console.log("shotcut", name);

        switch(name){
            case 'today' : 
                
                _this.startDate = _this.setDateToText(today);
                _this.endDate = _this.setDateToText(today);
                _this.startMax = _this.setDateToText(today);
                _this.endMin = _this.setDateToText(today);

            break;
            case 'week' : 
                _this.startDate = _this.setDateToText(weekValue);
                _this.endDate = _this.setDateToText(today);
                _this.startMax = _this.setDateToText(weekValue);
                _this.endMin = _this.setDateToText(today);
            break;
            case '1month' : 
                _this.startDate = _this.setDateToText(firstMonthValue);
                _this.endDate = _this.setDateToText(today);
                _this.startMax = _this.setDateToText(firstMonthValue);
                _this.endMin = _this.setDateToText(today);
            break;
            case '3month' : 
                _this.startDate = _this.setDateToText(thirdMonthValue);
                _this.endDate = _this.setDateToText(today);
                _this.startMax = _this.setDateToText(thirdMonthValue);
                _this.endMin = _this.setDateToText(today);
            break;
            case 'all' : 
                _this.startDate = '';
                _this.endDate = '';
                _this.startMax = '';
                _this.endMin = '';
            break;
        }

    }

    getWeekDate(){
        let today = new Date();
        let week = new Date(today.setDate(today.getDate()-7));
        return week;
    }

    getMonthDate(){
        let today = new Date();
        let month = new Date(today.setMonth(today.getMonth()-1));
        return month;
    }

    get3MonthDate(){
        let today = new Date();
        let month = new Date(today.setMonth(today.getMonth()-3));
        return month;
    }

    setDateToText(dateValue){
        let year = dateValue.getFullYear(); // 년도
        let month = utils.pad(dateValue.getMonth() + 1);;  // 월
        let date = utils.pad(dateValue.getDate());  // 날짜

        return [year, month, date].join('-');
    }

    handleState(){

    }

    handleSearch(){
        const parameter = {
            start : this.startDate
            , end : this.endDate
        }
        const searchEvent = new CustomEvent("search", { detail: parameter});

        // Dispatches the event.
        this.dispatchEvent(searchEvent);
    }

}