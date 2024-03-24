@isTest
public with sharing class CostPlan_tr_Test {
    @isTest
    static void test(){
        Test.startTest();

        WBSandCC__c wbs = new WBSandCC__c();
        wbs.Name = 'test';
        wbs.WBS_Code__c = 'F00001';
        wbs.Check_WBS_CC_ZF__c = 'WBS';
        wbs.AccountSubjectSort__c = '용';
        insert wbs;

        ItemManagement_Plan__c itemMng = new ItemManagement_Plan__c();
        itemMng.Name = '아이템관리 TEST';
        itemMng.WBS_CC__c = wbs.Id;
        insert itemMng;
        
        Cost_Plan__c cp = new Cost_Plan__c();
        cp.Name = '매입계획';
        cp.WBS_Code_Hidden__c = wbs.WBS_Code__c;
        cp.ItemManagement_Plan__c = itemMng.Id;
        cp.Itemmanagementcheck__c = true;
        insert cp;

        Test.stopTest();
    }
}