/**
 * Created by MZC01-DGCHOI on 2022-12-12.
 */

trigger ItemManagementTrigger on ItemManagement__c (before insert, after insert) {
    new ItemManagement_tr().run();
}