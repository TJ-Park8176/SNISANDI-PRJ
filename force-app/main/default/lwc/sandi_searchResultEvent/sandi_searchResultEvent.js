/**
 * Created by MZC01-DGCHOI on 2024-03-08.
 */

import { LightningElement, api, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';

export default class SandiSearchResultEvent extends LightningElement {

    @track searchTerm;
    renderedCallbackCalled = false;

    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        try {
            if (currentPageReference?.state?.term) { //검색어가 있을 때
                this.searchTerm = currentPageReference?.state?.term;
            }
        } catch (error) {
            console.log(error);
        }
    }

    renderedCallback() {
        if (this.renderedCallbackCalled) {
            if(this.searchTerm) {
                console.log('hi');
            }
        }
    }
}