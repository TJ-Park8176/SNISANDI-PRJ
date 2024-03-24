/**
 * Created by MZC01-DGCHOI on 2023-04-17.
 */

@IsTest
public with sharing class BATCH_UpdateOwner_Test {

    @TestSetup
    static void makeData() {
        WBSandCC__c wbs = new WBSandCC__c();
        wbs.Name = 'testWBS';
        wbs.WBS_Code__c = 'F00001';
        wbs.Check_WBS_CC_ZF__c = 'WBS';
        wbs.General__c = '사업총괄';
        wbs.OperationsHeadquarters__c = '서울1본부';
        insert wbs;

        Amount_plan__c amountPlan = new Amount_plan__c();
        amountPlan.Name = '실행계획-매출';
        amountPlan.WBS__c = wbs.Id;
        insert amountPlan;
    }

    @IsTest
    static void test() {
        BATCH_UpdateOwner batch = new BATCH_UpdateOwner('Amount_plan__c');
        Database.executeBatch(batch);
    }
}