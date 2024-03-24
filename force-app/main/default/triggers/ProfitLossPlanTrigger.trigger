/**
 * Created by MZC01-DGCHOI on 2023-01-18.
 */

trigger ProfitLossPlanTrigger on ProfitandLoss_Plan__c (before insert, after insert) {
    new ProfitLossPlan_tr().run();
}