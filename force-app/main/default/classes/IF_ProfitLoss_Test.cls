@isTest
public with sharing class IF_ProfitLoss_Test {
    @isTest
    static void test() {

        WBSandCC__c wbs = new WBSandCC__c();
        wbs.Name = 'test WBS';
        wbs.WBS_Code__c = 'F00001';
        wbs.Check_WBS_CC_ZF__c = 'WBS';


        WBSandCC__c cc = new WBSandCC__c();
        cc.Name = 'test CC';
        cc.WBS_Code__c = 'F00002';
        cc.Check_WBS_CC_ZF__c = 'CC';


        List<WBSandCC__c> wbsList = new List<WBSandCC__c>();
        wbsList.add(wbs);
        wbsList.add(cc);
        insert wbsList;

        //생성일자 Today -> YesterDay
        for(WBSandCC__c w : wbsList) {
            Test.setCreatedDate(w.Id, Datetime.now().addDays(-1));
        }

        Test.startTest();

        IF_ProfitLoss.makeNewRecord('WBS');
        IF_ProfitLoss.makeNewRecord('CC');

        Test.stopTest();

    } 
}