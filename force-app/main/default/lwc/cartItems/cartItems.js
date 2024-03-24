import { LightningElement, api, track, wire } from 'lwc';
import { navigate, NavigationContext } from 'lightning/navigation';
import { getSessionContext } from 'commerce/contextApi';
import { createCartItemsLoadAction, dispatchActionAsync } from 'commerce/actionApi';
import { previewData } from './mockData';
import getCartItemInfoByCartId from '@salesforce/apex/Sandi_CartItemController.getCartItemInfoByCartId';

/**
 * UI component that displays current cart items
 */
export default class CartItems extends LightningElement {
    /**
     * @description Enable the component to render as light DOM
     */
    static renderMode = 'light';

    /**
     * @description UI labels, to be replaced by Custom Labels and their translations
     */
    labels = {
        showMore: 'Show More',
        minQty: 'Min Qty',
        maxQty: 'Max Qty',
        incrementStep: 'Increment step',
        sku: 'SKU',
        item: 'item',
        decrease: 'Decrease',
        increase: 'Increase',
        delete: 'Delete',
        saved: 'Saved'
    }

    /**
     * @description Custom page size for items to display
     */
    @api pageSize;

    /**
     * @description Show the "Delete" button
     */
    @api showRemoveItemOption;

    /**
     * @description Show Line Item Total
     */
    @api showLineItemTotal;

    /**
     * @description Show the "Show More" button
     */
    @api showMoreItemsOption;

    /**
     * @description Show Original Price
     */
    @api showOriginalPrice;

    /**
     * @description Show Product SKU
     */
    @api showSKU;

    /**
     * @description Show Product Thumbnail Image
     */
    @api showProductImage;

    /**
     * @description List of fields (Api Names) to display for each Item
     */
    @api productFields;

    /**
     * @description Show Price per Unit
     */
    @api showPricePerUnit;

    /**
     * @description Show Actual Price
     */
    @api showActualPrice;

    /**
     * @description Hide/Show the Quantity Selector
     */
    @api hideQuantitySelector;

    /**
     * @description Show Promotions per Item
     */
    @api showPromotions;

    /**
     * @description Current Cart Id
     */
    @api cart;
    @api cartId;

    /**
     * @description Cart Items provided by the Cart Data Expression
     */
    @api cartItems;
    copyCartItems = [];
    
    /**
     * @description Total Count of Items in the cart (provided by the Cart Data Expression)
     */
    @api uniqueProductCount;
    
    /**
     * @description Cart Items data to show in UI, handles pagination against pageSize property
     */

    @track cartItemsToShow = [];

    @wire(NavigationContext)
    navContext;

    cartInfoMap;

    async wiredCartItemSelectInfo() {
        console.log('wiredCartItemSelectInfo() -->');
        console.log('this.cartId', this.cartId);

        await getCartItemInfoByCartId({
            cartId: this.cartId
        }).then((data) => {
            this.cartInfoMap = data;
            console.log('🚀 ~ data', data);
        }).catch((error) => {
            console.log("🚀 ~ error", error);
        });
    }

    /**
     * @description Preview mode if component is rendered in the Builder
     */
    isPreview;

    /**
     * @description Number of current pages displayed (custom pagination)
     */
    pages = 0;

    /**
     * @description Shows mock data if component is displayed in the Builder
     * or real data from the Cart Data Expressions (with custom pagination handling)
     * @async
     */

    activeSections = ['P', 'S'];

    async connectedCallback() {
        console.log('♨♨♨ init() --> ')
        //this.handleBackButton(); //뒤로가기 버튼을 통해 접근했을때도 refresh

        console.log('this.cart', this.cart);
        const sessionContext = await getSessionContext();
        this.isPreview = sessionContext.isPreview;
        this.cartItems.map((e) => {
            this.copyCartItems.push({...e});
        });
        if (this.isPreview) {
            this.cartItemsToShow = previewData;
            return;
        } else if (this.copyCartItems.length !== 0) {
            await this.wiredCartItemSelectInfo();
            this.mappingCartItemSelectedInfo();
            this.requestMoreCartItems();
        }
    }

    async disconnectedCallback() {

    }

    handleBackButton() {
        window.addEventListener('popstate', () => {
            // 뒤로가기 버튼을 눌렀을 때 페이지를 새로고침
            location.reload(true);
        })
    }

    refreshPage() {
        location.reload(true);
    }

    mappingCartItemSelectedInfo() {
        try {
            console.log('mappingCartItemSelectedInfo() --->');
            console.log('this.cartInfoMap', this.cartInfoMap);
            console.log('this.copyCartItems', this.copyCartItems);
            if(this.cartInfoMap) {
                this.copyCartItems = this.copyCartItems.map((e) => {
                    const cartInfo      = this.cartInfoMap[e.id];
                    const itemSalesType = cartInfo.SalesType_SANDI__c;
                    let   itemSelected  = cartInfo.IsSelected_SANDI__c;
                    const productClass  = cartInfo.Product2.ProductClass;
                    const quoteProduct  = cartInfo.Product2.QuoteProduct_SANDI__c;

                    if(itemSelected === undefined) itemSelected = true; //장바구니에 방금 넣은 경우
                    console.log('♡ e.id'         , e.id);
                    console.log('♡ itemSelected' , itemSelected);
                    console.log('♡ itemSalesType', itemSalesType);

                    return {
                        ...e,
                        IsSelected_SANDI__c     : itemSelected,
                        SalesType_SANDI__c      : itemSalesType,
                        ProductClass            : productClass,
                        isQuoteProduct          : quoteProduct === 'Request a quote',
                        isSpecialOfferProduct   : quoteProduct === 'Request a special offer',
                        IsRequestQuote_SANDI__c : cartInfo.IsRequestQuote_SANDI__c,
                        IsSpecialOffer_SANDI__c : cartInfo.IsSpecialOffer_SANDI__c,
                    };
                });
            }

            console.log('after copyCartItems :::' , this.copyCartItems);
        } catch(error) {
            console.log("🚀 ~ error", error);
        }
    }

    /**
     * @description Triggers a 'Load More Cart Items' action at the CartItemsAdapter
     * @async
     */
    async requestMoreCartItems() {
        // increase current pages count
        this.pages++;
        // while current items are less than what should be displayed && less than the total items in the cart
        // ==> request more items from the API
        while (this.copyCartItems.length < (this.pages*this.pageSize)
                && this.copyCartItems.length < this.uniqueProductCount) {
            await dispatchActionAsync(this, createCartItemsLoadAction());
        }
        // show only the necessary items (from 1st item in 1st page to latest in last page)
        this.cartItemsToShow = this.copyCartItems.slice(0, this.pages*this.pageSize);
    }

    /**
     * @description Show or hide "Show More" button, based on configuration or pagination state
     * @returns {boolean}
     */
    get needsToShowMore() {
        return this.showMoreItemsOption 
            && (this.isPreview || this.cartItemsToShow.length < this.uniqueProductCount);
    }

    get generalCartItemsToShow() {
        const returnCartItems =
            this.copyCartItems.filter((e) => {
                return e.SalesType_SANDI__c != '구독형';
            });;
        console.log('generalCartItemsToShow', returnCartItems);
        return returnCartItems;
    }

    get subCartItemsToShow() {
        const returnCartItems =
            this.copyCartItems.filter((e) => {
                return e.SalesType_SANDI__c == '구독형';
            });
        console.log('subCartItemsToShow', returnCartItems);
        return returnCartItems;
    }

    /**
     * @description Requests more cart items either from the cache or CartItemsAdapter
     */
    handleShowMoreButton() {
        if (!this.isPreview) {
            this.requestMoreCartItems();
        }
    }

    /**
     * @description Removes the deleted item from the current list
     * @param {CustomEvent} e
     */
    handleDeleteCartItem(e) {
        e.stopPropagation();
        const cartItemId = e.detail;
        this.cartItemsToShow = this.cartItemsToShow.filter(item => item.id !== cartItemId);
    }

    /**
     * @description Handles navigation to selected cart item's product
     * @param {CustomEvent} e
     */
    handleProductNavigation(e) {
        navigate(this.navContext, {
            type: 'standard__recordPage',
            attributes: {
                objectApiName: 'Product2',
                recordId: e.detail.id,
                recordName: e.detail.name,
                actionName: 'view',
            },
        });
    }

    //custom accordion
    handleSectionToggle(event) {
        const openSections = event.detail.openSections;

        if (openSections.length === 0) {
            this.activeSectionsMessage = 'All sections are closed';
        } else {
            this.activeSectionsMessage =
                'Open sections: ' + openSections.join(', ');
        }
    }
}