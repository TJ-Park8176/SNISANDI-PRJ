public with sharing class ct_UpdateProfitLossPlanPrice {

    @AuraEnabled
    public static void updatePrice(String baseYear) {
        try {
            Database.executeBatch(new SenderPricePlan_ba(baseYear), 10);
        } catch(Exception e) { throw new AuraHandledException(e.getMessage()); }
    }
}