/**
 * Created by MZC01-USER on 2023-11-15.
 */

trigger ItemManagementPlanTrigger on ItemManagement_Plan__c (before insert) {
    new ItemManagementPlan_tr().run();
}