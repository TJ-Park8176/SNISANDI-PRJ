/**
 * Created by MZC01-DGCHOI on 2023-01-25.
 */

@IsTest
public with sharing class Opportunity_tr_Test {

    @TestSetup
    static void makeData() {
        WBSandCC__c zf = new WBSandCC__c();
        zf.Name = 'ZF';
        zf.WBS_Code__c = 'ZF00001';
        zf.Check_WBS_CC_ZF__c = 'ZF';
        zf.WBSType__c = 'FM운영';
        zf.WBSType2__c = 'ZF수주';
        zf.TrackingHeadQuarters__c = '지역미배정';
        zf.Business_Management__c = true;
        insert zf;
    }

    @IsTest
    static void test() {
        Test.startTest();

        List<WBSandCC__c> zfList = [
                SELECT Id
                FROM WBSandCC__c
        ];

        WBSandCC__c zf = zfList[0];

        Opportunity oppty = new Opportunity();
        oppty.Name = '수주 TEST';
        oppty.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('FM수주').getRecordTypeId();
        oppty.WBS_CC__c = zf.Id;
        oppty.Possibility_of_closed_won__c = '높음';
        oppty.StageName = '잠재고객';
        oppty.Type2__c = '통합';
        oppty.Status__c = '신규';
        oppty.Expect_date_of_closed__c = Date.today();
        oppty.contract_closingdate__c = Date.today();
        oppty.CloseDate = Date.today();
        oppty.General_p__c = '사업총괄';
        insert oppty;

        Opportunity childOppty = new Opportunity();
        childOppty.Name = '수주 TEST';
        childOppty.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('FM수주').getRecordTypeId();
        childOppty.WBS_CC__c = zf.Id;
        childOppty.parent_Opportunity__c = oppty.Id;
        childOppty.Possibility_of_closed_won__c = '높음';
        childOppty.StageName = '잠재고객';
        childOppty.Type2__c = '지점';
        childOppty.Status__c = '신규';
        childOppty.Expect_date_of_closed__c = Date.today();
        childOppty.contract_closingdate__c = Date.today();
        childOppty.CloseDate = Date.today();
        childOppty.General_p__c = '사업총괄';
        insert childOppty;

        Opportunity dummyOppty = new Opportunity();
        dummyOppty.Name = '수주 TEST';
        dummyOppty.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('FM수주').getRecordTypeId();
        dummyOppty.WBS_CC__c = zf.Id;
        dummyOppty.parent_Opportunity__c = oppty.Id;
        dummyOppty.Possibility_of_closed_won__c = '높음';
        dummyOppty.StageName = '잠재고객';
        dummyOppty.Type2__c = '지점';
        dummyOppty.Status__c = '신규';
        dummyOppty.Expect_date_of_closed__c = Date.today().addMonths(1);
        dummyOppty.contract_closingdate__c = Date.today().addMonths(1);
        dummyOppty.CloseDate = Date.today().addMonths(1);
        dummyOppty.Real_Data_check__c = false;
        dummyOppty.General_p__c = '사업총괄';
        insert dummyOppty;

        List<Opportunity_amount__c> amtList = new List<Opportunity_amount__c>();
        for(Integer i=1; i<=12; i++) {
            Opportunity_amount__c amt = new Opportunity_amount__c();
            amt.OpportunityName__c = childOppty.Id;
            amt.Name = i + '월_' + childOppty.Name + '_accountName';
            amt.CalculateDate__c = Date.newInstance(Date.today().year(), i, 1);
            amt.Monthly_amount__c = 100;
            amt.OpportunityCheck__c = true;

            amtList.add(amt);
        }
        insert amtList;

        update childOppty;
        delete childOppty;

        Test.stopTest();
    }
}