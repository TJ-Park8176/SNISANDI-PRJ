/**
 * Created by MZC01-DGCHOI on 2023-07-26.
 */

@IsTest
public with sharing class CCGap_tr_ts
{

    @IsTest
    static void test() {
        Test.startTest();

        Date currDate   = Date.newInstance(2023, 8, 1);
        Date prevDate   = currDate.addMonths(-1);
        Date futureDate = currDate.addMonths(1);

        //CC
        WBSandCC__c cc = new WBSandCC__c();
        cc.Name = 'test CC';
        cc.WBS_Code__c = 'F00002';
        cc.Check_WBS_CC_ZF__c = 'CC';
        insert cc;

        //계정과목
        AccountSubject__c accSub = new AccountSubject__c();
        accSub.Name = '(판)지급수수료-채용경비';
        accSub.UpperSort__c = '매출액';
        accSub.MiddleSort__c = '기타경비계';
        accSub.LowerSort__c = '(판)지급수수료';
        insert accSub;

        //매출 아이템
        ItemManagement__c item = new ItemManagement__c();
        item.Name = 'test item';
        item.WBS_CC__c = cc.Id;
        item.AccountSubjectselect__c = accSub.Id;
        insert item;

        //사업계획(매입)
        Cost_Plan__c costPlan = new Cost_Plan__c();
        costPlan.WBS__c = cc.Id;
        costPlan.AccountSubjectselect__c = accSub.Id;
        costPlan.Itemmanagement__c = item.Id;
        costPlan.PlanPurchaseAmount__c = 100;
        costPlan.CalculateDate__c = currDate;
        insert costPlan;

        //실적
        Performance__c performance = new Performance__c();
        performance.WBS__c = cc.Id;
        performance.PerformanceMonth__c = prevDate;
        performance.AccountSubjectSelect__c = accSub.Id;
        performance.PerformanceAmount__c = 100;
        insert performance;

        //주간예상(매입)
        Weekly_cost_expect__c weekCst = new Weekly_cost_expect__c();
        weekCst.WBS__c = cc.Id;
        weekCst.AccountSubjectselect__c = accSub.Id;
        weekCst.Itemmanagement__c = item.Id;
        weekCst.CalculateDate__c = currDate;
        weekCst.Weekly_date__c = currDate;
        weekCst.Weekly__c = 1;
        weekCst.Latest_Data_Check__c = true;
        weekCst.Real_Data_check__c = true;
        weekCst.PurchaseAmount__c = 100;
        insert weekCst;

        weekly_amount_expect__c weekAmt = new weekly_amount_expect__c();
        weekAmt.WBS__c = cc.Id;
        weekAmt.AccountSubjectselect__c = accSub.Id;
        weekAmt.Itemmanagement__c = item.Id;
        weekAmt.CalculateDate__c = currDate;
        weekAmt.Weekly_date__c = currDate;
        weekAmt.Weekly__c = 1;
        weekAmt.Latest_Data_Check__c = true;
        weekAmt.Real_Data_check__c = true;
        weekAmt.PredictAmount__c = 100;
        insert weekAmt;

        //실행계획(매입)
        Cost_Action_Plan__c costActionPlan = new Cost_Action_Plan__c();
        costActionPlan.WBS__c = cc.Id;
        costActionPlan.Itemmanagement__c = item.Id;
        costActionPlan.CalculateDate__c = futureDate;
        costActionPlan.TimeDate__c = currDate;
        costActionPlan.AccountSubjectselect__c = accSub.Id;
        costActionPlan.ActionPlanPurchaseAmount__c = 100;
        costActionPlan.Real_Data_check__c = true;
        costActionPlan.Latest_Data_Check__c = true;
        insert costActionPlan;

        CCGAP__c ccgap = new CCGAP__c();
        ccgap.Name = 'test';
        ccgap.Start_Date__c = prevDate;
        ccgap.End_Date__c = futureDate;
        ccgap.WBS_CC__c = cc.Id;
        ccgap.Create_Month__c = Date.today();
        insert ccgap;

        Test.stopTest();
    }
}