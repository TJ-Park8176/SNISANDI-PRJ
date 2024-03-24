/**
 * Created by MZC01-DGCHOI on 2023-12-04.
 */

trigger OpportunityPlanAmountTrigger on opportunity_amount_plan__c (before insert) {
    new OpportunityPlanAmount_tr().run();
}