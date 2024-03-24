/**
 * Created by MZC01-DGCHOI on 2023-11-16.
 */

@IsTest
public with sharing class ItemManagementPlan_tr_Test {

    @TestSetup
    static void makeData() {
        //WBS
        WBSandCC__c wbs = new WBSandCC__c();
        wbs.Name = 'testWBS';
        wbs.WBS_Code__c = 'F00001';
        wbs.Check_WBS_CC_ZF__c = 'WBS';
        wbs.AccountSubjectSort__c = '용';
        insert wbs;
    }

    @IsTest
    static void test() {
        Test.startTest();

        Id wbsId = [SELECT Id FROM WBSandCC__c LIMIT 1].Id;
        //사업계획(아이템관리)
        ItemManagement_Plan__c itemMng = new ItemManagement_Plan__c();
        itemMng.Name = '아이템관리 TEST';
        itemMng.WBS_CC__c = wbsId;
        insert itemMng;

        Test.stopTest();
    }
}