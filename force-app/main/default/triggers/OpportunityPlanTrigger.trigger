/**
 * Created by MZC01-DGCHOI on 2023-12-01.
 */

trigger OpportunityPlanTrigger on Opportunity_plan__c (before insert, before update, after insert, after update, after delete) {
    new OpportunityPlan_tr().run();
}