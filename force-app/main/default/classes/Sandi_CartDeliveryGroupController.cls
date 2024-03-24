/**
 * Created by MZC01-DGCHOI on 2024-03-21.
 */

public with sharing class Sandi_CartDeliveryGroupController {

    /**
     * @param checkoutId
     *
     * @return Checkout 카트 배송 정보
     */
    @AuraEnabled(cacheable=false)
    public static CartDeliveryGroup getCartDeliveryGroup(String checkoutId) {
        Id cartId = [
                SELECT Id, WebCartId
                FROM CartCheckoutSession
                WHERE Id =: checkoutId
                LIMIT 1
        ].WebCartId;

        CartDeliveryGroup cdg = [
                SELECT Id, DeliverToAddress
                FROM CartDeliveryGroup
                WHERE CartId =: cartId
                LIMIT 1
        ];

        return cdg;
    }

    /**
     * 카트 배송지 정보 업데이트
     */
    @AuraEnabled
    public static void updateCartDeliveryGroup(String checkoutId, String cpaId) {
        CartDeliveryGroup cdg = getCartDeliveryGroup(checkoutId);
        ContactPointAddress cpa = [
                SELECT Id, Name, Address, City, Country, CountryCode, PostalCode, State, StateCode, Street
                FROM ContactPointAddress
                WHERE Id =: cpaId
        ];

        cdg.DeliverToCity        = cpa.City;
        cdg.DeliverToCountry     = cpa.Country;
        cdg.DeliverToCountryCode = cpa.CountryCode;
        cdg.DeliverToName        = cpa.Name;
        cdg.DeliverToPostalCode  = cpa.PostalCode;
        cdg.DeliverToState       = cpa.State;
        cdg.DeliverToStateCode   = cpa.StateCode;
        cdg.DeliverToStreet      = cpa.Street;
        cdg.Contact_Point_Address_SANDI__c = cpa.Id;

        update cdg;
    }


}