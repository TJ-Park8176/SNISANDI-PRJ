/**
 * Created by MZC01-DGCHOI on 2023-01-30.
 */

trigger OpportunityAmountTrigger on Opportunity_amount__c (before insert) {
    new OpportunityAmount_tr().run();
}