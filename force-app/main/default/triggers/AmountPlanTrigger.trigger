trigger AmountPlanTrigger on Amount_plan__c (before insert, after insert, before update) {
    new AmountPlan_tr().run();
}