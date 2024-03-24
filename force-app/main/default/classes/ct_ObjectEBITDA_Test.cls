/**
 * Created by MZC01-DGCHOI on 2023-02-27.
 */

@IsTest
public with sharing class ct_ObjectEBITDA_Test {

    @TestSetup
    static void makeData() {
        AccountSubject__c ebitda = new AccountSubject__c();
        ebitda.Name = 'EBITDA';
        ebitda.AccountSubjectCode__c = 'A5';
        ebitda.UpperSort__c = 'EBITDA';
        insert ebitda;

        AccountSubject__c salesProfit = new AccountSubject__c(); //영업이익2
        salesProfit.Name = '영업이익2';
        salesProfit.UpperSort__c = '영업이익2';
        salesProfit.AccountSubjectCode__c = 'A4';
        insert salesProfit;

        WBSandCC__c wbs = new WBSandCC__c();
        wbs.Name = 'testWBS';
        wbs.WBS_Code__c = 'F00001';
        wbs.Check_WBS_CC_ZF__c = 'WBS';
        insert wbs;

        Performance__c performance = new Performance__c();
        performance.PerformanceMonth__c = Date.newInstance(Date.today().year(), Date.today().month()-1, 1);
        performance.Real_Data_check__c = true;
        performance.WBS__c = wbs.Id;
        performance.AccountSubjectSelect__c = salesProfit.Id;
        insert performance;

        ProfitandLoss_Plan__c pp = new ProfitandLoss_Plan__c();
        pp.AccountSubjectselect__c = ebitda.Id;
        pp.WBS__c = wbs.Id;
        pp.Calculate_month__c = Date.newInstance(Date.today().year(), Date.today().month(), 1);
        pp.ProfitandLoss_Type__c = 'EBITDA';
        insert pp;

    }

    @IsTest
    static void test() {
        ct_ObjectEBITDA.createObject('Performance__c');
        ct_ObjectEBITDA.createObject('ProfitandLoss_Plan__c');
    }

}