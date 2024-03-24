/*
 * Copyright (c) 2023, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 * For full license text, see the LICENSE file in the repo
 * root or https://opensource.org/licenses/apache-2-0/
 */
import { LightningElement, api, track, wire } from 'lwc';
import { navigate, NavigationContext, CurrentPageReference } from 'lightning/navigation';
import { createCartItemAddAction, createSearchFiltersUpdateAction, dispatchAction } from 'commerce/actionApi';
import CommonModal from 'c/commonModal';
import { Labels } from './labels';
import updateTerm from '@salesforce/apex/Sandi_PopularSearchTermController.updateTerm';

/**
 * @typedef {import('../searchResults/searchResults').ProductSearchResultSummary} ProductSearchResultSummary
 */

/**
 * @typedef {import('../searchResults/searchResults').CardContentMappingItem} CardContentMappingItem
 */

/**
 * Component that displays products for search and category page.
 */
export default class BuilderSearchResults extends LightningElement {
    static renderMode = 'light';

    @wire(NavigationContext)
    navContext;

    /**
     * Results returned from the Search Data Provider
     * @type {?ProductSearchResultSummary}
     */
    @api
    searchResults;

    /**
     * Default field to show in results
     * @type {?string}
     */
    @api
    searchResultsFields;

    /**
     * The layout of the results tiles.
     * @type {?('grid' | 'list')}
     */
    @api
    resultsLayout;

    /**
     * The size of the spacing between the grid columns.
     * @type {?('small' | 'medium' | 'large'| 'none')}
     */
    @api
    gridColumnSpacing;

    /**
     * The size of the spacing between the grid rows.
     * @type {?('small' | 'medium' | 'large'| 'none')}
     */
    @api
    gridRowSpacing;

    /**
     * The maximum number of grid columns to be displayed.
     * Accepted values are between 1 and 8.
     * @type {?number}
     */
    @api
    gridMaxColumnsDisplayed;

    /**
     * The size of the spacing between the list rows.
     * @type {?('small' | 'medium' | 'large'| 'none')}
     */
    @api
    listRowSpacing;

    /**
     * Font color for the card background field, as 'rgb', 'rgba' or 'hex' CSS value.
     * @type {?string}
     */
    @api
    cardBackgroundColor;

    /**
     * The alignment of the results cards.
     * @type {?('right' | 'center' | 'left')}
     */
    @api
    cardAlignment;

    /**
     * Font color for the card border field, as 'rgb', 'rgba' or 'hex' CSS value.
     * @type {?string}
     */
    @api
    cardBorderColor;

    /**
     * The value of the border radius for the results card.
     * @type {?string}
     */
    @api
    cardBorderRadius;

    /**
     * Font color for the card divider field, as 'rgb', 'rgba' or 'hex' CSS value.
     * @type {?string}
     */
    @api
    cardDividerColor;

    /**
     * The font size of the negotiated price.
     * @type {?('small' | 'medium' | 'large')}
     */
    @api
    negotiatedPriceTextSize;

    /**
     * Whether to display the negotiated price.
     * @type {boolean}
     * @default false
     */
    @api
    showNegotiatedPrice = false;

    /**
     * Font color for the negotiated price text field, as 'rgb', 'rgba' or 'hex' CSS value.
     * @type {?string}
     */
    @api
    negotiatedPriceTextColor;

    /**
     * Whether to display the original price.
     * @type {boolean}
     * @default false
     */
    @api
    showOriginalPrice = false;

    /**
     * The font size of the original price.
     * @type {?('small' | 'medium' | 'large')}
     */
    @api
    originalPriceTextSize;

    /**
     * Font color for the original price text field, as 'rgb', 'rgba' or 'hex' CSS value.
     * @type {?string}
     */
    @api
    originalPriceTextColor;

    /**
     * Whether to display the product image.
     * @type {boolean}
     * @default false
     */
    @api
    showProductImage = false;

    /**
     * The product fields to display in the productCard cmp.
     * @type {string}
     */
    @api
    cardContentMapping;

    /**
     * Whether to display the action button.
     * @type {boolean}
     * @default false
     */
    @api
    showCallToActionButton = false;

    /**
     * The text for the add to cart button
     * @type {?string}
     */
    @api
    addToCartButtonText;

    /**
     * The button style for add to cart button
     * Accepted values primary, secondary, tertiary
     * @type {?('primary' | 'secondary' | 'tertiary')}
     */
    @api
    addToCartButtonStyle;

    /**
     * The text for the add to cart button when cart is processing
     * @type {?string}
     */
    @api
    addToCartButtonProcessingText;

    /**CUSTOM
     * The text for the add to wish button
     * @type {?string}
     */
    @api
    addToWishButtonText;

    /**CUSTOM
     * The text for the add to wish button when cart is processing
     * @type {?string}
     */
    @api
    addToWishButtonProcessingText;


    /**
     * The text for the view options button
     * @type {?string}
     */
    @api
    viewOptionsButtonText;

    @track
    currentUrl = '';

    /**
     * The current page number of the results.
     * @type {?string}
     */
    @api
    currentPage;

    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        try {
            if (localStorage.getItem('isChecked') == 'true') {
                this.currentPageReference = currentPageReference;

                if (this.currentPageReference?.state?.term) { //검색어가 있을 때
                    //localStorage 저장
                    let term = this.currentPageReference.state.term;
                    let his = localStorage.getItem('searchHistory');
                    let hisSet = new Set();
                    if (his) {
                        let parsedHis = JSON.parse(his);
                        let parsedHisValue = parsedHis.setval;
                        parsedHisValue.unshift(term);
                        //hisSet = new Set(parsedHisValue);
                        hisSet = new Set(parsedHisValue.slice(0, 10));
                    }

                    localStorage.setItem('searchHistory', JSON.stringify({ setval: [...hisSet] }));

                    this.handleUrlChange();

                    /*updateTerm({
                        term: term
                    }).then(data => {
                        console.log('updateTerm data', data);
                    }).catch(error => {
                        console.log('updateTerm error', error);
                    });*/
                }
            }
        } catch (error) {
            console.log(error);
        }
    }

    connectedCallback() {
        //URL 변경 이벤트를 감지하는 핸들러 등록
        window.addEventListener('hashchange', this.handleUrlChange);
    }

    disconnectedCallback() {
        // 컴포넌트가 파괴될 때 이벤트 핸들러 제거
        window.removeEventListener('hashchange', this.handleUrlChange);
    }

    handleUrlChange() { //handleUrlChange(event) {
        const checkUrl = window.location.href;
        if(this.currentUrl !== checkUrl) { //checkUrl.contains('global-search')
            //addTerms
            console.log('addTerms event!!!');
            updateTerm({
                term: this.currentPageReference?.state?.term
            }).then(data => {
                console.log('updateTerm data', data);
            }).catch(error => {
                console.log('updateTerm error', error);
            });
            this.currentUrl = checkUrl;
        }
    }

    /*connectedCallback() {
        if (this.currentPageReference?.state?.term) {
            //addTerms
            updateTerm({
                term: this.currentPageReference?.state?.term
            }).then(data => {
                console.log('updateTerm data', data);
            }).catch(error => {
                console.log('updateTerm error', error);
            });
        }
    }*/

    /**
     * @type {CardContentMappingItem[]}
     * @readonly
     * @private
     */
    get normalizedCardContentMapping() {
        return JSON.parse(this.cardContentMapping ?? '[]');
    }

    /**
     * Handles the 'addproducttocart' event.
     * Adds the product to the cart and then on success opens the add to cart modal.
     * @param {CustomEvent<{ productId: string; quantity: number }>} event The event object
     * @private
     */
    handleAddToCart(event) {
        event.stopPropagation();
        const { productId, quantity } = event.detail;
        dispatchAction(this, createCartItemAddAction(productId, quantity), {
            onSuccess: () => {
                CommonModal.open({
                    label: Labels.messageSuccessfullyAddedToCart,
                    size: 'small',
                    secondaryActionLabel: Labels.actionContinueShopping,
                    primaryActionLabel: Labels.actionViewCart,
                    onprimaryactionclick: () => this.navigateToCart(),
                });
            },
        });
    }

    /**
     * Navigates to the cart page when the primary button is clicked
     * from the modal after adding an item to the cart
     * @private
     */
    navigateToCart() {
        this.navContext &&
            navigate(this.navContext, {
                type: 'comm__namedPage',
                attributes: {
                    name: 'Current_Cart',
                },
            });
    }

    /**
     * Handles navigating to the product detail page from the search results page.
     * @param {CustomEvent<{productId: string; productName: string}>} event The event object
     */
    handleNavigateToProductPage(event) {
        event.stopPropagation();
        const urlName = this.searchResults?.cardCollection.find((card) => card.id === event.detail.productId)?.urlName;
        this.navContext &&
            navigate(this.navContext, {
                type: 'standard__recordPage',
                attributes: {
                    objectApiName: 'Product2',
                    recordId: event.detail.productId,
                    actionName: 'view',
                    urlName: urlName ?? undefined,
                },
                state: {
                    recordName: event.detail.productName,
                },
            });
    }

    /**
     * Trigger an update of the page number at the closest `SearchDataProvider`
     * @param {CustomEvent<{newPageNumber: number}>} event The event object
     * @private
     */
    handleUpdateCurrentPage(event) {
        event.stopPropagation();
        dispatchAction(this, createSearchFiltersUpdateAction({ page: event.detail.newPageNumber }));
    }
}