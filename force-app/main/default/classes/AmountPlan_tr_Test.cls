@isTest
public with sharing class AmountPlan_tr_Test {
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
        
        Amount_plan__c ap = new Amount_plan__c();
        ap.Name = '매출계획';
        ap.ItemManagement_Plan__c = itemMng.Id;
        ap.WBS_Code_hidden__c = wbs.WBS_Code__c;
        ap.Itemmanagementcheck__c = true;
        insert ap;

        Test.stopTest();
    }
}