/**
 * Created by MZC01-DGCHOI on 2022-12-12.
 */

trigger AmountTrigger on Amount__c (before insert, before update, before delete) {
    new Amount_tr().run();
}