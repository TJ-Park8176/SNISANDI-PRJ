/**
 * Created by MZC01-DGCHOI on 2024-03-11.
 */

public with sharing class Sandi_WishlistController {

    @AuraEnabled
    public static ConnectApi.ErrorResponse addToWishlist(String productId) {
        ConnectApi.WishlistItemInput wishlistItemInput = new ConnectApi.WishlistItemInput();
        wishlistItemInput.productId = productId;

        ConnectApi.WishlistItem wishlistItem = ConnectApi.CommerceWishlist.addItemToWishlist(
                '0ZE1y00000002zBGAQ', //webSotreId
                '3or1y0000008OJhAAM', //wishlistId
                wishlistItemInput
        );

        return wishlistItem.error;
    }

}