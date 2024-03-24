trigger RealCatchUpPlanTrigger on Real_catch_up_plan__c (before insert, before update) {
    new RealCatchUpPlan_tr().run();
}