/**
 * Created by MZC01-DGCHOI on 2023-01-25.
 */

@IsTest
public with sharing class Performance_tr_Test {

    @TestSetup
    static void makeData() {
        WBSandCC__c wbs = new WBSandCC__c();
        wbs.Check_WBS_CC_ZF__c = 'WBS';
        wbs.WBS_Code__c = 'Test01';
        wbs.Name = 'WBS TEST';
        insert wbs;

        WBSandCC__c zf = new WBSandCC__c();
        zf.Check_WBS_CC_ZF__c = 'ZF';
        zf.WBS_Code__c = 'Test02';
        zf.Name = 'ZF TEST';
        insert zf;

        AccountSubject__c accSub = new AccountSubject__c();
        accSub.AccountSubjectCode__c = '4105110';
        accSub.Name = '계정과목 TEST';
        insert accSub;

        AccountSubject__c accSub2 = new AccountSubject__c();
        accSub2.AccountSubjectCode__c = 'A5';
        accSub2.Name = 'EBITDA';
        insert accSub2;
    }

    @IsTest
    static void test() {
        Test.startTest();

        Performance__c perform_real = new Performance__c();
        perform_real.AccountSubjectCode_hidden__c = 'A01';
        perform_real.WBS_Code_Hidden__c = 'W01';
        perform_real.Name = 'real data';
        perform_real.Real_Data_check__c = true;
        perform_real.PerformanceMonth__c = Date.today();
        insert perform_real;

        Performance__c perform_dummy = new Performance__c();
        perform_dummy.AccountSubjectCode_hidden__c = 'A01';
        perform_dummy.WBS_Code_Hidden__c = 'W01';
        perform_dummy.Name = 'dummy';
        perform_dummy.Real_Data_check__c = false;
        perform_dummy.PerformanceMonth__c = Date.today();
        insert perform_dummy;

        perform_dummy.Name = 'updated dummy';
        update perform_dummy;

        Test.stopTest();
    }
}