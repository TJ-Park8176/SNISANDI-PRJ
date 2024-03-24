/**
 * Created by MZC01-DGCHOI on 2023-03-08.
 */

trigger WBSCCZFTrigger on WBSandCC__c (after insert, before delete) {
    new WBSCCZF_tr().run();
}