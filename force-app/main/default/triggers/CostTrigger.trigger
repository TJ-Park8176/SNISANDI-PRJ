/**
 * Created by MZC01-DGCHOI on 2022-12-12.
 */

trigger CostTrigger on Cost__c (before insert, before update, before delete) {
    new Cost_tr().run();
}