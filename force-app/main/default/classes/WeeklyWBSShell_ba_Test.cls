/**
 * Created by MZC01-DGCHOI on 2023-02-20.
 */

@IsTest
public with sharing class WeeklyWBSShell_ba_Test {

    @TestSetup
    static void makeData() {
        WBSandCC__c wbs = new WBSandCC__c();
        wbs.Name = 'WBS';
        wbs.Check_WBS_CC_ZF__c = 'WBS';
        wbs.WBS_Code__c = 'F00001';
        insert wbs;

        WBSandCC__c ccy = new WBSandCC__c();
        ccy.Name = 'CCY';
        ccy.Check_WBS_CC_ZF__c = 'CC';
        ccy.AccountSubjectSort__c = '용';
        ccy.WBS_Code__c = 'F00002';
        insert ccy;

        WBSandCC__c ccp = new WBSandCC__c();
        ccp.Name = 'CCY';
        ccp.Check_WBS_CC_ZF__c = 'CC';
        ccp.AccountSubjectSort__c = '판';
        ccp.WBS_Code__c = 'F00003';
        insert ccp;
    }

    @IsTest
    static void test() {
        Test.startTest();

        WeeklyWBSShell_ba batchCost = new WeeklyWBSShell_ba('Weekly_Cost_Expect__c');
        Database.executeBatch(batchCost);

        WeeklyWBSShell_ba batchAmount = new WeeklyWBSShell_ba('Weekly_Amount_Expect__c');
        Database.executeBatch(batchAmount);

        Test.stopTest();
    }
}