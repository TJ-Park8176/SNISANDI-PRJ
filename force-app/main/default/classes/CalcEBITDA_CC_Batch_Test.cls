/**
 * Created by user on 2023-01-02.
 */

@isTest
public with sharing class CalcEBITDA_CC_Batch_Test {
    @TestSetup
    static void makeData(){
        //WBS - 용
        WBSandCC__c wbs_y = new WBSandCC__c();
        wbs_y.Name = 'testCC';
        wbs_y.WBS_Code__c = 'F00001';
        wbs_y.Check_WBS_CC_ZF__c = 'CC';
        wbs_y.AccountSubjectSort__c = '용';
        insert wbs_y;

        //WBS - 판
        WBSandCC__c wbs_p = new WBSandCC__c();
        wbs_p.Name = 'testCC';
        wbs_p.WBS_Code__c = 'F00002';
        wbs_p.Check_WBS_CC_ZF__c = 'CC';
        wbs_p.AccountSubjectSort__c = '판';
        insert wbs_p;

        List<WBSandCC__c> wbsList = new List<WBSandCC__c>();
        wbsList.add(wbs_y);
        wbsList.add(wbs_p);

        //계정 과목
        AccountSubject__c accSub = new AccountSubject__c();
        accSub.Name = 'test';
        accSub.UpperSort__c = 'test';
        accSub.MiddleSort__c = 'test';
        accSub.LowerSort__c = '(용)감가상각비';
        insert accSub;

        //아이템관리
        ItemManagement__c item = new ItemManagement__c();
        item.Name = '아이템관리';
        item.WBS_CC__c = wbs_y.Id;
        item.AccountSubjectselect__c = accSub.Id;
        insert item;

        //매입
        Cost__c c = new Cost__c();
        c.Itemmanagement__c = item.Id;
        c.WBS__c = wbs_y.Id;
        c.CalculateDate__c = Date.newInstance(Date.today().year(), 1, 1);
        c.AccountSubjectselect__c = accSub.Id;
        c.PurchaseAmount__c = 100;
        c.Name = '매입';
        insert c;

        //손익계산 껍데기
        IF_ProfitLoss.makeBaseRecord_CC(wbsList);
    }

    @isTest
    static void test(){
        Test.startTest();

        Database.executeBatch(new CalcEBITDA_CC_Batch());

        Test.stopTest();
    }
}