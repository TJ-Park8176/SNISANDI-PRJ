/**
 * Created by MZC01-DGCHOI on 2023-03-28.
 */


import search from '@salesforce/apex/CustomLookup.search';

import { api, LightningElement, track, wire } from 'lwc';


export default class CustomLookup extends LightningElement {

    @api objName;
    @api iconName;
    @api filter = '';
    @api value = '';
    @api selectedName;
    @api searchPlaceholder='Search';
    @api isValueSelected;
    @api isSaved;

    @track records;
    @track blurTimeout;

    searchTerm;

    //css
    @track boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus';
    @track inputClass = '';

    @wire(search, {searchTerm : '$searchTerm', myObject : '$objName', filter : '$filter'})
    wiredRecords({ error, data }) {
        if (data) {
            this.error = undefined;
            this.records = data;
        } else if (error) {
            this.error = error;
            this.records = undefined;
        }
    }

    handleClick() {
        this.searchTerm = '';
        this.inputClass = 'slds-has-focus';
        this.boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus slds-is-open';
    }

    onBlur() {
        this.blurTimeout = setTimeout(() =>  {this.boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus'}, 300);
    }

    onSelect(event) {
        console.log(event);
        let selectedId   = event.currentTarget.dataset.id;
        let selectedName = event.currentTarget.dataset.name;

        this.value           = selectedId;
        this.selectedName    = selectedName;
        this.isValueSelected = true;

        const valueSelectedEvent = new CustomEvent('lookupselected', {detail:  selectedId });
        this.dispatchEvent(valueSelectedEvent);

        if(this.blurTimeout) {
            clearTimeout(this.blurTimeout);
        }
        this.boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus';
    }

    handleRemovePill() {
        this.isValueSelected = false;
        this.value = null;
    }

    onChange(event) {
        this.searchTerm = event.target.value;
    }

}