trigger CostPlanTrigger on Cost_Plan__c (before insert, after insert, before update) {
    new CostPlan_tr().run();
}