/**
 * Created by MZC01-DGCHOI on 2023-11-01.
 */

@IsTest
public with sharing class OwnerChangeController_Test {
    @TestSetup
    static void makeData() {
        Date currDate = Date.newInstance(Date.today().year(), 1, 1);

        //계정 과목
        AccountSubject__c accountSubject = new AccountSubject__c();
        accountSubject.Name = '매출액';
        accountSubject.UpperSort__c = '매출액';
        accountSubject.MiddleSort__c = '매출액';
        accountSubject.LowerSort__c = '매출액';
        insert accountSubject;

        //WBS
        WBSandCC__c wbs = new WBSandCC__c();
        wbs.Name = 'WBS';
        wbs.WBS_Code__c = 'F00001';
        wbs.Check_WBS_CC_ZF__c = 'WBS';
        insert wbs;

        //아이템관리
        ItemManagement__c itemManagement = new ItemManagement__c();
        itemManagement.Name = '아이템관리';
        itemManagement.WBS_CC__c = wbs.Id;
        insert itemManagement;

        //매출현황
        Amount__c amount = new Amount__c();
        amount.Name = 'amount';
        amount.WBS__c = wbs.Id;
        amount.CalculateDate__c = currDate;
        amount.PredictAmount__c = 0;
        amount.Itemmanagementcheck__c = true;
        amount.Itemmanagement__c = itemManagement.Id;
        insert amount;

        //매입현황
        Cost__c cost = new Cost__c();
        cost.Itemmanagementcheck__c = true;
        cost.Itemmanagement__c = itemManagement.Id;
        cost.WBS__c = wbs.Id;
        cost.CalculateDate__c = currDate;
        cost.AccountSubjectselect__c = accountSubject.Id;
        cost.PurchaseAmount__c = 100;
        cost.Name = '매입';
        insert cost;

        //주간예상(매출)
        weekly_amount_expect__c weekAmt = new weekly_amount_expect__c();
        weekAmt.WBS__c = wbs.Id;
        weekAmt.AccountSubjectselect__c = accountSubject.Id;
        weekAmt.Itemmanagement__c = itemManagement.Id;
        weekAmt.CalculateDate__c = currDate;
        weekAmt.Weekly_date__c = currDate;
        weekAmt.Weekly__c = 1;
        weekAmt.Latest_Data_Check__c = true;
        weekAmt.Real_Data_check__c = true;
        weekAmt.PredictAmount__c = 100;
        insert weekAmt;

        //주간예상(매입)
        Weekly_cost_expect__c weekCost = new Weekly_cost_expect__c();
        weekCost.WBS__c = wbs.Id;
        weekCost.AccountSubjectselect__c = accountSubject.Id;
        weekCost.Itemmanagement__c = itemManagement.Id;
        weekCost.CalculateDate__c = currDate;
        weekCost.Weekly_date__c = currDate;
        weekCost.Weekly__c = 1;
        weekCost.Latest_Data_Check__c = true;
        weekCost.Real_Data_check__c = true;
        weekCost.PurchaseAmount__c = 100;
        insert weekCost;

        //실행계획(매출)
        Amount_Action_Plan__c aap = new Amount_Action_Plan__c();
        aap.WBS__c = wbs.Id;
        aap.Itemmanagement__c = itemManagement.Id;
        aap.CalculateDate__c = currDate;
        aap.TimeDate__c = currDate;
        aap.AccountSubjectselect__c = accountSubject.Id;
        aap.ActionPlanAmount__c = 100;
        insert aap;

        //실행계획(매입)
        Cost_Action_Plan__c cap = new Cost_Action_Plan__c();
        cap.WBS__c = wbs.Id;
        cap.Itemmanagement__c = itemManagement.Id;
        cap.CalculateDate__c = currDate;
        cap.TimeDate__c = currDate;
        cap.AccountSubjectselect__c = accountSubject.Id;
        cap.ActionPlanPurchaseAmount__c = 100;
        insert cap;

        //사업계획(매출), 사업계획(매입)
    }

    @IsTest
    static void test() {
        Test.startTest();

        Id ownerId_item = [
                SELECT Id
                FROM ItemManagement__c
                LIMIT 1
        ].Id;

        Id ownerId_wbs = [
                SELECT Id
                FROM WBSandCC__c
                LIMIT 1
        ].Id;

        OwnerChangeController.updateOwnerWithItem(ownerId_item);
        OwnerChangeController.updateOwnerWithWBS(ownerId_wbs);
        OwnerChangeController.isNoApexJobRunning();

        Test.stopTest();
    }
}