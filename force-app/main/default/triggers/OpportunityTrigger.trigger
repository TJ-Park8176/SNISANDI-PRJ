trigger OpportunityTrigger on Opportunity (before insert, after insert, before update, after update, after delete) {
    new Opportunity_tr().run();
}