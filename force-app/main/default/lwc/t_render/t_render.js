import { LightningElement, api, track } from 'lwc';

export default class T_render extends LightningElement {
    @track _searchDesc;
    @api 
    get searchDesc(){
        return this._searchDesc
    }
    set searchDesc(value){
        this._searchDesc = value;
        this.changeTerms();
    }

    changeTerms(){
        if(this._searchDesc) console.log("changeTerms",this._searchDesc);
    }
}