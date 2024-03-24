/**
 * Created by MZC01-DGCHOI on 2024-03-04.
 */

/**
 * 장바구니에서 정보 조회 및 업데이트
 */
public with sharing class Sandi_CartItemController {

    /**
     * @param cartItemId 카트 아이템 Id
     * @param selectedStatus 카트 아이템별 선택 여부
     */
    @AuraEnabled
    public static void updateCartItemSelectedStatus(String cartItemId, Boolean selectedStatus) {
        CartItem item            = new CartItem();
        item.Id                  = cartItemId;
        item.IsSelected_SANDI__c = selectedStatus;
        update item;
    }

    @AuraEnabled
    public static void updateCartItemSpecialOfferStatus(String cartItemId, Boolean selectedStatus) {
        CartItem item                = new CartItem();
        item.Id                      = cartItemId;
        item.IsSpecialOffer_SANDI__c = selectedStatus;
        update item;
    }

    /**
     * @param cartId 카트 Id
     * @return Id별 카트정보 Map
     */
    @AuraEnabled(cacheable=false) //항상 최신의 데이터를 반환
    public static Map<String, CartItem> getCartItemInfoByCartId(String cartId) {
        Map<String, CartItem> returnMap = new Map<String, CartItem>();

        List<CartItem> cartItems = [
                SELECT
                        Id,
                        IsSelected_SANDI__c,
                        SalesType_SANDI__c,
                        Product2.ProductClass,
                        Product2.QuoteProduct_SANDI__c,
                        IsRequestQuote_SANDI__c, //견적 요청 여부
                        IsSpecialOffer_SANDI__c  //스페셜오더 여부
                FROM CartItem
                WHERE CartId =: cartId
        ];

        for(CartItem cartItem : cartItems) {
            returnMap.put(cartItem.Id, cartItem);
        }

        return returnMap;
    }
}