/**
 * Created by MZC01-DGCHOI on 2023-03-23.
 */

@IsTest
public with sharing class Amount_tr_Test {

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

        Amount__c amount = new Amount__c();
        amount.Name = 'amount';
        amount.WBS__c = wbs.Id;
        amount.CalculateDate__c = Date.newInstance(Date.today().year(), 1, 1);
        amount.PredictAmount__c = 0;
        amount.Itemmanagementcheck__c = true;
        amount.Itemmanagement__c = itemManagement.Id;
        insert amount;

        amount.Itemmanagementcheck__c = true;
        update amount;

        Test.stopTest();
    }
}