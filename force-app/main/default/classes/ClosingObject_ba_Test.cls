/**
 * Created by MZC01-DGCHOI on 2023-03-02.
 */

@IsTest
public with sharing class ClosingObject_ba_Test {

    @TestSetup
    static void makeData(){
        //ZF 생성
        WBSandCC__c zf = new WBSandCC__c();
        zf.Name = 'testZF';
        zf.WBS_Code__c = 'ZF00001';
        zf.Check_WBS_CC_ZF__c = 'ZF';
        zf.WBSType__c = 'FM운영';
        zf.WBSType2__c = 'ZF수주';
        zf.Business_Management__c = true;
        insert zf;

        //수주 생성
        Opportunity oppty = new Opportunity();
        oppty.Name = '수주';
        oppty.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('FM수주').getRecordTypeId();
        oppty.WBS_CC__c = zf.Id;
        oppty.Possibility_of_closed_won__c = '높음';
        oppty.StageName = '영업진행';
        oppty.Type2__c = '단일';
        oppty.Expect_date_of_closed__c = Date.newInstance(Date.today().year(), 1, 1);
        oppty.contract_closingdate__c = Date.newInstance(Date.today().year(), Date.today().month(), 1);
        oppty.CloseDate = Date.newInstance(Date.today().year(), 1, 1);
        oppty.General_p__c = '사업총괄';
        insert oppty;

        //수주 매출 생성
        Opportunity_amount__c opptyAmount = new Opportunity_amount__c();
        opptyAmount.Opportunityname__c = oppty.Id;
        opptyAmount.CalculateDate__c = Date.today();
        opptyAmount.Monthly_amount__c = 100;
        opptyAmount.OpportunityCheck__c = true;
        insert opptyAmount;

        WBSandCC__c wbscc = new WBSandCC__c();
        wbscc.Name = 'wbs';
        wbscc.WBS_Code__c = 'F000001';
        wbscc.Check_WBS_CC_ZF__c = 'WBS';
        insert wbscc;

        ItemManagement__c itemManagement = new ItemManagement__c();
        itemManagement.Name = '아이템관리';
        itemManagement.Base_Year__c = String.valueOf(Date.today().year());
        itemManagement.WBS_CC__c = wbscc.Id;
        insert itemManagement;
    }

    @IsTest
    static void test() {
        Test.startTest();

        Database.executeBatch(new ClosingObjectCopy_ba('Opportunity'));
        Database.executeBatch(new ClosingObjectCopy_ba('Opportunity_amount__c'));

        Test.stopTest();
    }
}