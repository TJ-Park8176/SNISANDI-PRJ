/**
 * Created by MZC01-DGCHOI on 2023-03-23.
 */

@IsTest
public with sharing class Cost_tr_Test {

    @IsTest
    static void test() {
        Test.startTest();

        WBSandCC__c wbs = new WBSandCC__c();
        wbs.Name = 'wbs';
        wbs.WBS_Code__c = 'F00001';
        wbs.Check_WBS_CC_ZF__c = 'WBS';
        insert wbs;

        ItemManagement__c itemManagement = new ItemManagement__c();
        itemManagement.Name = '아이템관리';
        itemManagement.Base_Year__c = String.valueOf(Date.today().year());
        itemManagement.WBS_CC__c = wbs.Id;
        insert itemManagement;

        Cost__c cost = new Cost__c();
        cost.Name = 'test';
        cost.WBS__c = wbs.Id;
        cost.CalculateDate__c = Date.newInstance(Date.today().year(), 1, 1);
        cost.Itemmanagement__c = itemManagement.Id;
        cost.PurchaseAmount__c = 0;
        cost.Itemmanagementcheck__c = true;
        cost.AccountSubjectsort__c = '용';
        insert cost;

        cost.Itemmanagementcheck__c = true;
        cost.AccountSubjectsort__c = '판';
        update cost;

        Test.stopTest();

    }
}