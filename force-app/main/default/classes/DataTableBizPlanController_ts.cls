/**
 * Created by MZC01-DGCHOI on 2023-09-22.
 */

@IsTest
public with sharing class DataTableBizPlanController_ts {

    @TestSetup
    static void makeData() {
        Date currDate   = Date.newInstance(2022,12,1);

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

        //사업계획(아이템관리)
        ItemManagement_Plan__c itemMng = new ItemManagement_Plan__c();
        itemMng.Name = '아이템관리 TEST';
        itemMng.WBS_CC__c = wbs.id;
        insert itemMng;

        //사업계획(매출)
        Amount_plan__c amtPlan = new Amount_plan__c();
        amtPlan.WBS__c                  = wbs.Id;
        amtPlan.AccountSubjectselect__c = accSub.Id;
        amtPlan.Itemmanagement__c       = item.Id;
        amtPlan.ItemManagement_Plan__c  = itemMng.Id;
        amtPlan.PlanAmount__c           = 100;
        amtPlan.calculateDate__c        = currDate;
        amtPlan.Itemmanagementcheck__c  = true;
        insert amtPlan;

        //사업계획(매입)
        Cost_Plan__c cstPlan = new Cost_Plan__c();
        cstPlan.WBS__c                  = wbs.Id;
        cstPlan.AccountSubjectselect__c = accSub.Id;
        cstPlan.Itemmanagement__c       = item.Id;
        cstPlan.ItemManagement_Plan__c  = itemMng.Id;
        cstPlan.PlanPurchaseAmount__c   = 100;
        cstPlan.CalculateDate__c        = currDate;
        cstPlan.Itemmanagementcheck__c  = true;
        insert cstPlan;

    }

    @isTest
    static void test() {
        WBSandCC__c wbs = [SELECT Id FROM WBSandCC__c LIMIT 1];

        Test.startTest();

        DataTableBizPlanController.getWBSList();
        DataTableBizPlanController.getAmountInfo(wbs.Id);
        DataTableBizPlanController.getSumAmount(wbs.Id);

        Test.stopTest();
    }
}