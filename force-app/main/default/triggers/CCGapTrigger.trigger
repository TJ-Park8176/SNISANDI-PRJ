/**
 * Created by MZC01-DGCHOI on 2023-07-10.
 */

trigger CCGapTrigger on CCGAP__c (before insert) {
    new CCGap_tr().run();
}