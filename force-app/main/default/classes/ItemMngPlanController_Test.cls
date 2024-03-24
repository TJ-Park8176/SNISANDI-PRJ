/**
 * @description       : 
 * @author            : jisoolee@mz.co.kr
 * @group             : 
 * @last modified on  : 2023-09-26
 * @last modified by  : jisoolee@mz.co.kr
**/

@IsTest
public with sharing class ItemMngPlanController_Test {

    @TestSetup
    static void makeData() {
        //WBS 생성
        WBSandCC__c wbs = new WBSandCC__c();
        wbs.Name = 'test';
        wbs.WBS_Code__c = 'F00001';
        wbs.Check_WBS_CC_ZF__c = 'WBS';
        wbs.AccountSubjectSort__c = '용';
        insert wbs;

        //계정 과목
        AccountSubject__c accSub = new AccountSubject__c();
        accSub.Name = '건설형매출';
        accSub.UpperSort__c = '매출액';
        accSub.MiddleSort__c = '매출';
        accSub.LowerSort__c = '건설형매출';
        insert accSub;

        //아이템관리
        ItemManagement_Plan__c itemMng = new ItemManagement_Plan__c();
        itemMng.Name = '아이템관리 TEST';
        itemMng.WBS_CC__c = wbs.id;
        itemMng.AccountSubjectselect__c = accSub.Id;
        insert itemMng;


    }

    @IsTest
    static void test() {
        Test.startTest();

        ItemManagement_Plan__c itemMng 	= [SELECT Id FROM ItemManagement_Plan__c LIMIT 1];
        AccountSubject__c accSub 		= [SELECT Id FROM AccountSubject__c LIMIT 1];
        WBSandCC__c wbs 				= [SELECT Id FROM WBSandCC__c LIMIT 1];

        List<Map<String, String>> infoList 	= new List<Map<String, String>>();
        Map<String, String> infoMap_item 	= new Map<String, String>();
        infoMap_item.put('key', 'ItemManagement_Plan__c');
        infoMap_item.put('value', itemMng.Id);
        infoList.add(infoMap_item);

        Map<String, String> infoMap_wbs = new Map<String, String>();
        infoMap_wbs.put('key', 'WBS__c');
        infoMap_wbs.put('value', wbs.Id);
        infoList.add(infoMap_wbs);

        List<Map<String, String>> monthList = new List<Map<String, String>>();
        Map<String, String> priceMap 		= new Map<String, String>();
        priceMap.put('price', '0');
        for(Integer i=0; i<12; i++) {
            monthList.add(priceMap);
        }

        List<Map<String, Object>> costInfoList = new List<Map<String, Object>>();
        Map<String, Object> costInfoMap = new Map<String, Object>();
        costInfoMap.put('data', new List<Integer> {0});
        costInfoMap.put('beforeSubjectId', accSub.Id);
        costInfoMap.put('afterSubjectId', accSub.Id);
        costInfoMap.put('wbsId', wbs.Id);
        costInfoList.add(costInfoMap);


        ItemMngPlanController.getAmountPlanList(itemMng.Id);
        ItemMngPlanController.getItemInfo(itemMng.Id);
        ItemMngPlanController.getAmountInfo(itemMng.Id);
        ItemMngPlanController.getCostList(itemMng.Id);
        ItemMngPlanController.getSingleCostList(itemMng.Id);

        ItemMngPlanController.updateAmountPlanList(itemMng.Id, JSON.serialize(infoList), JSON.serialize(monthList));
        ItemMngPlanController.updateAmountPlanList(itemMng.Id, JSON.serialize(infoList), JSON.serialize(monthList));

        ItemMngPlanController.updateCostList(itemMng.Id, JSON.serialize(costInfoList));
        ItemMngPlanController.updateCostList(itemMng.Id, JSON.serialize(costInfoList));

        ItemMngPlanController.deleteCostList(itemMng.Id, accSub.Id);
        ItemMngPlanController.updateCostList(itemMng.Id, JSON.serialize(costInfoList));

        ItemMngPlanController.isAmountItem(itemMng.Id);

        Test.stopTest();
    }
}