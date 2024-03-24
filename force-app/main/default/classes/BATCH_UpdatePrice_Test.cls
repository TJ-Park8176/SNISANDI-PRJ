/**
 * Created by MZC01-DGCHOI on 2023-04-26.
 */

@IsTest
public with sharing class BATCH_UpdatePrice_Test {

    @TestSetup
    static void makeData() {
        WBSandCC__c wbs = new WBSandCC__c();
        wbs.Name = 'testWBS';
        wbs.WBS_Code__c = 'F00001';
        wbs.Check_WBS_CC_ZF__c = 'WBS';
        wbs.General__c = '사업총괄';
        wbs.OperationsHeadquarters__c = '서울1본부';
        insert wbs;

        ItemManagement__c item = new ItemManagement__c();
        item.Name = '아이템관리';
        item.WBS_CC__c = wbs.Id;
        insert item;

        AccountSubject__c accountSubject = new AccountSubject__c();
        accountSubject.Name = '판매비와관리비';
        accountSubject.UpperSort__c = '판매비와관리비';
        insert accountSubject;

        Amount_plan__c amountPlan = new Amount_plan__c();
        amountPlan.Name = '사업계획(매출)';
        amountPlan.WBS__c = wbs.Id;
        amountPlan.Itemmanagement__c = item.Id;
        amountPlan.calculateDate__c = Date.today();
        amountPlan.AccountSubjectselect__c = accountSubject.Id;
        insert amountPlan;

        Cost_Plan__c costPlan = new Cost_Plan__c();
        costPlan.Name = '사업계획(매입)';
        costPlan.WBS__c = wbs.Id;
        costPlan.WBS__c = wbs.Id;
        costPlan.Itemmanagement__c = item.Id;
        costPlan.CalculateDate__c = Date.today();
        costPlan.AccountSubjectselect__c = accountSubject.Id;
        insert costPlan;
    }

    @IsTest
    static void test() {
        Test.startTest();

        BATCH_UpdatePrice batch_amount = new BATCH_UpdatePrice('Amount__c');
        Database.executeBatch(batch_amount);

        BATCH_UpdatePrice batch_cost = new BATCH_UpdatePrice('Cost__c');
        Database.executeBatch(batch_cost);

        Test.stopTest();
    }
}