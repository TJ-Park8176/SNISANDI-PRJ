/**
 * Created by MZC01-DGCHOI on 2023-12-08.
 */

@IsTest
public with sharing class OpptyMngPlanController_Test {

    @TestSetup
    static void makeData() {
        //ZF 생성
        WBSandCC__c zf = new WBSandCC__c();
        zf.Name = 'ZF';
        zf.WBS_Code__c = 'ZF00001';
        zf.Check_WBS_CC_ZF__c = 'ZF';
        zf.WBSType__c = 'FM운영';
        zf.WBSType2__c = 'ZF수주';
        zf.Business_Management__c = true;
        zf.TrackingHeadQuarters__c = '지역미배정';
        insert zf;

        Opportunity_plan__c oppPlan = new Opportunity_plan__c();
        oppPlan.Name = '수주 TEST';
        oppPlan.General_p__c = '사업총괄';
        oppPlan.RecordTypeId = Schema.SObjectType.Opportunity_plan__c.getRecordTypeInfosByName().get('FM수주').getRecordTypeId();
        oppPlan.WBS_CC__c = zf.Id;
        oppPlan.Possibility_of_closed_won__c = '높음';
        oppPlan.StageName__c = '잠재고객';
        oppPlan.Type2__c = '단일';
        oppPlan.Status__c = '신규';
        oppPlan.Expect_date_of_closed__c = Date.newInstance(Date.today().year()+1, 1, 1);
        oppPlan.contract_closingdate__c = Date.newInstance(Date.today().year()+1, 1, 1);
        oppPlan.CloseDate__c = Date.newInstance(Date.today().year()+1, 1, 1);
        oppPlan.Plan_GrossProfit_Percent__c = 20;
        insert oppPlan;

        opportunity_amount_plan__c oppAmtPlan = new opportunity_amount_plan__c();
        oppAmtPlan.Opportunityplan_name__c = oppPlan.Id;
        oppAmtPlan.CalculateDate__c = Date.today().addYears(1);
        oppAmtPlan.Monthly_amount__c = 100;
        oppAmtPlan.OpportunityCheck__c = true;
        insert oppAmtPlan;

    }

    @IsTest
    static void test() {
        Test.startTest();

        Opportunity_plan__c oppPlan = [SELECT Id FROM Opportunity_plan__c LIMIT 1];

        List<Map<String, String>> infoList = new List<Map<String, String>>();
        Map<String, String> infoMap = new Map<String, String>();
        infoMap.put('key', 'Opportunityplan_name__c');
        infoMap.put('value', oppPlan.Id);
        infoList.add(infoMap);

        List<Map<String, String>> monthList = new List<Map<String, String>>();
        for(Integer i=0; i<12; i++) {
            Map<String, String> priceMap = new Map<String, String>();
            priceMap.put('price', '0');
            monthList.add(priceMap);
        }

        OpptyMngPlanController.getOpptyInfo(oppPlan.Id);
        OpptyMngPlanController.getAmountList(oppPlan.Id);
        OpptyMngPlanController.getOpptyAmount(oppPlan.Id);
        OpptyMngPlanController.hasOpptyAmount(oppPlan.Id);

        //OpptyMngController.updateAmountList(oppPlan.Id, JSON.serialize(infoList), JSON.serialize(monthList));

        OpptyMngPlanController.deleteOpptyAmount(oppPlan.Id);

        OpptyMngPlanController.updateAmountList(oppPlan.Id, JSON.serialize(infoList), JSON.serialize(monthList));

        Test.stopTest();
    }
}