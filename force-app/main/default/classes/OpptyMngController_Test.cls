/**
 * Created by MZC01-DGCHOI on 2023-01-26.
 */

@isTest
public with sharing class OpptyMngController_Test {
    @TestSetup
    static void makeData() {
        //ZF 생성
        WBSandCC__c zf = new WBSandCC__c();
        zf.Name = 'WBS TEST';
        zf.WBS_Code__c = 'F00001';
        zf.Check_WBS_CC_ZF__c = 'ZF';
        zf.TrackingHeadQuarters__c = '지역미배정';
        zf.Oppty_RecordType__c = 'FM수주'; // 24.03.21 Sanghee 필드 종속성 생성으로 테코 추가
        zf.General__c = '사업총괄'; // 24.03.21 Sanghee 필드 종속성 생성으로 테코 추가
        insert zf;

        Opportunity oppty = new Opportunity();
        oppty.Name = '수주 TEST';
        //oppty.WBS_CC__c = wbs.Id;
        oppty.Type2__c = '통합';
        oppty.StageName = '영업진행';
        oppty.CloseDate = Date.today();
        oppty.WBS_CC__c = zf.Id;
        oppty.p_RecordType__c = 'FM수주'; // 24.03.21 Sanghee 필드 종속성 생성으로 테코 추가
        oppty.General_p__c = '사업총괄'; // 24.03.21 Sanghee 필드 종속성 생성으로 테코 추가
        insert oppty;

        Opportunity_amount__c opptyAmount = new Opportunity_amount__c();
        opptyAmount.Opportunityname__c = oppty.Id;
        opptyAmount.CalculateDate__c = Date.today();
        opptyAmount.Monthly_amount__c = 100;
        opptyAmount.OpportunityCheck__c = true;
        insert opptyAmount;

    }

    @IsTest
    static void test() {
        Test.startTest();

        Opportunity oppty = [SELECT Id FROM Opportunity LIMIT 1];

        List<Map<String, String>> infoList = new List<Map<String, String>>();
        Map<String, String> infoMap = new Map<String, String>();
        infoMap.put('key', 'Opportunityname__c');
        infoMap.put('value', oppty.Id);
        infoList.add(infoMap);

        List<Map<String, String>> monthList = new List<Map<String, String>>();
        for(Integer i=0; i<12; i++) {
            Map<String, String> priceMap = new Map<String, String>();
            priceMap.put('price', '0');
            monthList.add(priceMap);
        }

        OpptyMngController.getOpptyInfo(oppty.Id);
        OpptyMngController.getAmountList(oppty.Id);
        OpptyMngController.getOpptyAmount(oppty.Id);
        OpptyMngController.hasOpptyAmount(oppty.Id);

        //OpptyMngController.updateAmountList(oppty.Id, JSON.serialize(infoList), JSON.serialize(monthList));

        OpptyMngController.deleteOpptyAmount(oppty.Id);

        OpptyMngController.updateAmountList(oppty.Id, JSON.serialize(infoList), JSON.serialize(monthList));

        Test.stopTest();
    }
}