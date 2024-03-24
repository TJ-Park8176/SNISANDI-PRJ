/**
 * Created by MZC01-DGCHOI on 2023-02-28.
 */

@isTest
public with sharing class ct_OpptyPerformanceCopy_Test {

    @TestSetup
    static void makeData() {
        WBSandCC__c zf = new WBSandCC__c();
        zf.Name = 'ZF';
        zf.WBS_Code__c = 'ZF00001';
        zf.Check_WBS_CC_ZF__c = 'ZF';
        zf.WBSType__c = 'FM운영';
        zf.WBSType2__c = 'ZF수주';
        zf.Business_Management__c = true;
        zf.TrackingHeadQuarters__c = '지역미배정';
        insert zf;

        Opportunity oppty = new Opportunity();
        oppty.Name = '수주';
        oppty.General_p__c = '사업총괄';
        oppty.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('FM수주').getRecordTypeId();
        oppty.WBS_CC__c = zf.Id;
        oppty.contract_closingdate__c = Date.newInstance(Date.today().year(), Date.today().month()-1, 1); //예상수주시기 전월
        oppty.amount_occur_date__c = Date.newInstance(Date.today().year(), Date.today().month()-1, 1); //매출발생시기 전월
        oppty.closeDate = Date.today();
        oppty.StageName = 'Closed Won';
        oppty.Status__c = '신규';
        oppty.Type2__c = '단일';
        oppty.VRB_2__c = 'Pass';
        insert oppty;

        Opportunity_amount__c opptyAmt = new Opportunity_amount__c();
        opptyAmt.Name = '수주매출';
        opptyAmt.CalculateDate__c = Date.newInstance(Date.today().year(), Date.today().month()-1, 1);
        opptyAmt.Real_Data_check__c = true;
        opptyAmt.Opportunityname__c = oppty.Id;
        opptyAmt.OpportunityCheck__c = true;
        insert opptyAmt;
    }

    @IsTest
    static void test() {
        ct_OpptyPerformanceCopy.copyObject('Opportunity');
        ct_OpptyPerformanceCopy.copyObject('Opportunity_Amount__c');

    }
}