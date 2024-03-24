/**
 * Created by MZC01-DGCHOI on 2024-03-06.
 */

import { LightningElement, wire, track } from 'lwc';
import basePath from '@salesforce/community/basePath'
import getPopularSearchTerms from '@salesforce/apex/Sandi_PopularSearchTermController.getPopularSearchTerms';

export default class SandiSearchMenu extends LightningElement {
    showModal = false;
    checkedValue = false;
    popularSearchTerms = [];
    @track searchHistory;

    @wire(getPopularSearchTerms)
    wiredPopularSearchTerms({ error, data }) {
        if (error) {
            console.log("🚀 ~ error", error);
        } else if (data) {
            this.popularSearchTerms = data.map((e, index) => {
                return {
                    ...e,
                    Rank__c : (e.Rank__c || (index+1))
                }
            })
        }
    }

    renderedCallback() {
        this.searchHistory = localStorage.getItem('searchHistory');
        console.log('renderedCallback searchHistory', this.searchHistory);
        this.setRecentlySearchTerms();

        const isChecked = localStorage.getItem('isChecked');

        if (isChecked != null) {
            console.log('isChecked', isChecked, ', type', typeof isChecked);
            console.log(typeof isChecked);
            this.checkedValue = isChecked === 'true';
            console.log(this.checkedValue);
        }
    }

    setRecentlySearchTerms() {
        if (this.searchHistory) {
            let parsedHistory = JSON.parse(this.searchHistory);
            console.log('parsedHistory', parsedHistory);

            this.recentlySearchTerms =
                parsedHistory &&
                parsedHistory.setval?.map((term, index) => {
                    return { index: index, term: term };
                });
        }
    }

    disconnectedCallback() {
        this.showModal = false;
    }

    handleSearchButtonClick() {
        this.showModal = !this.showModal;
    }

    handleCloseButtonClick() {
        this.showModal = false;
    }

    handleSearchTermClick(event) {
        const searchTerm = event.target.innerHTML;
        console.log(basePath + '/global-search/' + searchTerm);
        window.location.href = basePath + '/global-search/' + searchTerm;
    }

    /**
     * 최근 검색어 삭제 이벤트
     */
    handleSearchTermDeleteClick(event) {
        const targetTerm = event.target.dataset.term;

        try {
            //localStorage 필터링
            if (this.searchHistory) {
                console.log('this.searchHistory', this.searchHistory);
                let parsedHistory = JSON.parse(this.searchHistory);
                parsedHistory = parsedHistory?.setval?.filter(e => {
                    return e !== targetTerm
                });

                this.searchHistory = JSON.stringify({ setval: parsedHistory });
                localStorage.setItem('searchHistory', this.searchHistory);
                event.target.parentElement.style.display = "none";
            }
        } catch (error) {
            console.log('error', error);
        }
    }

    handleToggleChange(event) {
        const checked = event.target.checked;
        localStorage.setItem('isChecked', checked);
    }
}