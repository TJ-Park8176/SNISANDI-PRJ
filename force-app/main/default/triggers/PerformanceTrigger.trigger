/**
 * Created by MZC01-DGCHOI on 2023-01-18.
 */

trigger PerformanceTrigger on Performance__c (before insert, after insert, before update) {
    new Performance_tr().run();
}