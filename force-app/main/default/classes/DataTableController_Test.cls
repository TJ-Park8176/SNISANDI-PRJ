/**
 * Created by MZC01-DGCHOI on 2022-12-06.
 */

@isTest
public with sharing class DataTableController_Test {
    @TestSetup
    static void makeData() {
        Date prevDate   = Date.newInstance(2023, 11, 1);
        Date currDate   = Date.newInstance(2023,12,1);
        Date futureDate = Date.newInstance(2024,1,1);

        //WBS
        WBSandCC__c wbs = new WBSandCC__c();
        wbs.Name = 'testWBS';
        wbs.WBS_Code__c = 'F00001';
        wbs.Check_WBS_CC_ZF__c = 'WBS';
        wbs.AccountSubjectSort__c = '용';
        insert wbs;

        //계정 과목
        AccountSubject__c accSub = new AccountSubject__c();
        accSub.Name = '건설형매출';
        accSub.UpperSort__c = '매출액';
        accSub.MiddleSort__c = '매출';
        accSub.LowerSort__c = '건설형매출';
        insert accSub;

        AccountSubject__c accSub2 = new AccountSubject__c();
        accSub2.AccountSubjectCode__c = 'A5';
        accSub2.Name = 'EBITDA';
        insert accSub2;



        //매출 아이템
        ItemManagement__c item = new ItemManagement__c();
        item.Name = 'test item';
        item.WBS_CC__c = wbs.Id;
        item.AccountSubjectselect__c = accSub.Id;
        insert item;

        ItemManagement_Plan__c itemPlan = new ItemManagement_Plan__c();
        itemPlan.Name = '아이템관리(사업계획) Test';
        itemPlan.WBS_CC__c = wbs.Id;
        itemPlan.AccountSubjectselect__c = accSub.Id;
        itemPlan.BaseYear__c = '2024';
        insert itemPlan;

        //매출 계획
        Amount_plan__c amtPlan = new Amount_plan__c();
        amtPlan.Name = '매출계획';
        amtPlan.ItemManagement_Plan__c = itemPlan.Id;
        amtPlan.AccountSubjectselect__c = accSub.Id;
        amtPlan.WBS_Code_hidden__c = wbs.Id;
        amtPlan.Itemmanagementcheck__c = true;
        amtPlan.PlanAmount__c = 100;
        amtPlan.calculateDate__c = prevDate;
        insert amtPlan;


        //매입 계획
        Cost_Plan__c cstPlan = new Cost_Plan__c();
        cstPlan.WBS__c = wbs.Id;
        cstPlan.AccountSubjectselect__c = accSub.Id;
        cstPlan.ItemManagement_Plan__c = itemPlan.Id;
        cstPlan.PlanPurchaseAmount__c = 100;
        cstPlan.calculateDate__c = prevDate;
        cstPlan.Itemmanagementcheck__c = true;
        insert cstPlan;

        //실적
        Performance__c performance = new Performance__c();
        performance.WBS__c = wbs.Id;
        performance.PerformanceMonth__c = prevDate;
        performance.AccountSubjectSelect__c = accSub.Id;
        performance.PerformanceAmount__c = 100;
        insert performance;
//
//        //매출
//        Amount__c amt = new Amount__c();
//        amt.WBS__c = wbs.Id;
//        amt.AccountSubjectselect__c = accSub.Id;
//        amt.Itemmanagement__c = item.Id;
//        amt.CalculateDate__c = prevDate;
//        amt.PredictAmount__c = 100;
//        amt.Itemmanagementcheck__c = true;
//        insert amt;
//
//        //매입
//        Cost__c cst = new Cost__c();
//        cst.WBS__c = wbs.Id;
//        cst.CalculateDate__c = currDate;
//        cst.AccountSubjectselect__c = accSub.Id;
//        cst.Itemmanagement__c = item.Id;
//        cst.PurchaseAmount__c = 100;
//        cst.Itemmanagementcheck__c = true;
//        insert cst;

        //매출 실행 계획
        Amount_Action_Plan__c aap = new Amount_Action_Plan__c();
        aap.WBS__c = wbs.Id;
        aap.Itemmanagement__c = item.Id;
        aap.CalculateDate__c = futureDate;
        aap.TimeDate__c = currDate;
        aap.AccountSubjectselect__c = accSub.Id;
        aap.ActionPlanAmount__c = 100;
        insert aap;

        //매입 실행 계획
        Cost_Action_Plan__c cap = new Cost_Action_Plan__c();
        cap.WBS__c = wbs.Id;
        cap.Itemmanagement__c = item.Id;
        cap.CalculateDate__c = futureDate;
        cap.TimeDate__c = currDate;
        cap.AccountSubjectselect__c = accSub.Id;
        cap.ActionPlanPurchaseAmount__c = 100;
        insert cap;

        //주차별 매출 예상
        Weekly_amount_expect__c weekAmt = new weekly_amount_expect__c();
        weekAmt.WBS__c = wbs.Id;
        weekAmt.Itemmanagement__c = item.Id;
        weekAmt.AccountSubjectselect__c = accSub.Id;
        weekAmt.CalculateDate__c = currDate;
        weekAmt.Weekly_date__c = currDate;
        weekAmt.Weekly__c = 1;
        weekAmt.PredictAmount__c = 100;
        insert weekAmt;

        //주차별 매입 예상
        Weekly_cost_expect__c weekCst = new Weekly_cost_expect__c();
        weekCst.WBS__c = wbs.Id;
        weekCst.AccountSubjectselect__c = accSub.Id;
        weekCst.Itemmanagement__c = item.Id;
        weekCst.CalculateDate__c = currDate;
        weekCst.Weekly_date__c = currDate;
        weekCst.Weekly__c = 1;
        weekCst.PurchaseAmount__c = 100;
        insert weekCst;


    }

    @isTest
    static void test() {
        WBSandCC__c wbs = [SELECT id FROM WBSandCC__c LIMIT 1];

        Test.startTest();

        DataTableController.getWBSList();
        DataTableController.getAmountInfo(wbs.Id, '현장', '2024');
        DataTableController.getAmountInfo(wbs.Id, '운영', '2024');
        DataTableController.getSumAmount(wbs.Id, '현장', '2024');

        Test.stopTest();
    }
}