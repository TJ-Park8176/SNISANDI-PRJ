/**
 * Created by MZC01-DGCHOI on 2023-12-08.
 */

@IsTest
public with sharing class OpportunityPlan_tr_Test {

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
    }

    @IsTest
    static void test() {
        Test.startTest();

        WBSandCC__c zf = [
                SELECT Id
                FROM WBSandCC__c
                LIMIT 1
        ];

        Opportunity_plan__c oppPlan = new Opportunity_plan__c();
        oppPlan.Name = '수주 TEST';
        oppPlan.General_p__c = '사업총괄';
        oppPlan.WBS_CC__c = zf.Id;
        oppPlan.RecordTypeId = Schema.SObjectType.Opportunity_plan__c.getRecordTypeInfosByName().get('FM수주').getRecordTypeId();
        oppPlan.Possibility_of_closed_won__c = '높음';
        oppPlan.StageName__c = '잠재고객';
        oppPlan.Type2__c = '통합';
        oppPlan.Status__c = '신규';
        oppPlan.Expect_date_of_closed__c = Date.today();
        oppPlan.contract_closingdate__c = Date.today();
        oppPlan.CloseDate__c = Date.today();
        insert oppPlan;

        Opportunity_plan__c childOppPlan = new Opportunity_plan__c();
        childOppPlan.Name = '수주 TEST';
        childOppPlan.General_p__c = '사업총괄';
        childOppPlan.WBS_CC__c = zf.Id;
        childOppPlan.RecordTypeId = Schema.SObjectType.Opportunity_plan__c.getRecordTypeInfosByName().get('FM수주').getRecordTypeId();
        childOppPlan.parent_Opportunity__c = oppPlan.Id;
        childOppPlan.Possibility_of_closed_won__c = '높음';
        childOppPlan.StageName__c = '잠재고객';
        childOppPlan.Type2__c = '지점';
        childOppPlan.Status__c = '신규';
        childOppPlan.Expect_date_of_closed__c = Date.today();
        childOppPlan.contract_closingdate__c = Date.today();
        childOppPlan.CloseDate__c = Date.today();
        insert childOppPlan;

        Opportunity_plan__c dummyOppPlan = new Opportunity_plan__c();
        dummyOppPlan.Name = '수주 TEST';
        dummyOppPlan.General_p__c = '사업총괄';
        dummyOppPlan.WBS_CC__c = zf.Id;
        dummyOppPlan.RecordTypeId = Schema.SObjectType.Opportunity_plan__c.getRecordTypeInfosByName().get('FM수주').getRecordTypeId();
        dummyOppPlan.WBS_CC__c = zf.Id;
        dummyOppPlan.parent_Opportunity__c = oppPlan.Id;
        dummyOppPlan.Possibility_of_closed_won__c = '높음';
        dummyOppPlan.StageName__c = '잠재고객';
        dummyOppPlan.Type2__c = '지점';
        dummyOppPlan.Status__c = '신규';
        dummyOppPlan.Expect_date_of_closed__c = Date.today().addMonths(1);
        dummyOppPlan.contract_closingdate__c = Date.today().addMonths(1);
        dummyOppPlan.CloseDate__c = Date.today().addMonths(1);
        dummyOppPlan.Real_Data_check__c = false;
        insert dummyOppPlan;

        List<opportunity_amount_plan__c> amtPlanList = new List<opportunity_amount_plan__c>();
        for(Integer i=1; i<=12; i++) {
            opportunity_amount_plan__c amtPlan = new opportunity_amount_plan__c();
            amtPlan.Opportunityplan_name__c = childOppPlan.Id;
            amtPlan.Name = i + '월_' + childOppPlan.Name + '_accountName';
            amtPlan.CalculateDate__c = Date.newInstance(Date.today().year(), i, 1);
            amtPlan.Monthly_amount__c = 100;
            amtPlan.OpportunityCheck__c = true;

            amtPlanList.add(amtPlan);
        }
        insert amtPlanList;

        update childOppPlan;
        delete childOppPlan;

        Test.stopTest();
    }

}