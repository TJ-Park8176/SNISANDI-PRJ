/**
 * Created by MZC01-DGCHOI on 2023-08-03.
 */

@IsTest
public with sharing class CCGAPController_ts {

    @IsTest
    static void test() {
        Test.startTest();

        WBSandCC__c cc = new WBSandCC__c();
        cc.Name = 'test CC';
        cc.WBS_Code__c = 'F00002';
        cc.Check_WBS_CC_ZF__c = 'CC';
        insert cc;

        CCGAP__c ccgap = new CCGAP__c();
        ccgap.Name = 'test';
        ccgap.Start_Date__c = Date.today().addMonths(-1);
        ccgap.End_Date__c = Date.today();
        ccgap.WBS_CC__c = cc.Id;
        ccgap.Create_Month__c = Date.today();
        insert ccgap;

        CCGAPController.createDetails(ccgap.Id);

        Test.stopTest();
    }
}