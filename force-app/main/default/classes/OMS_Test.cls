public with sharing class OMS_Test {
    // @AuraEnabled annotation exposes the methods to Lightning Components and Flows
    @AuraEnabled
    public String itemId;
    @AuraEnabled
    public Integer quantity;
    @AuraEnabled
    public String reason;
    @AuraEnabled
    public boolean shippingReductionFlag;
}