/**
 * Created by MZC01-DGCHOI on 2023-01-25.
 */

@IsTest
public with sharing class ItemMngController_Test {

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
        ItemManagement__c itemMng = new ItemManagement__c();
        itemMng.Name = '아이템관리 TEST';
        itemMng.WBS_CC__c = wbs.Id;
        itemMng.AccountSubjectselect__c = accSub.Id;
        insert itemMng;



//        Amount__c a = new Amount__c();
//        a.Name = '매출 TEST';
//        a.WBS__c = wbs.Id;
//        a.Itemmanagement__c = itemMng.Id;
//        a.CalculateDate__c = Date.newInstance(Date.today().year(), 3, 1);
//        a.Itemmanagementcheck__c = true;
//        insert a;
//
//        Cost__c c = new Cost__c();
//        c.Name = '매입 TEST';
//        c.WBS__c = wbs.Id;
//        c.AccountSubjectselect__c = accSub.Id;
//        c.Itemmanagement__c = itemMng.Id;
//        c.CalculateDate__c = Date.newInstance(Date.today().year(), 3, 1);
//        c.Itemmanagementcheck__c = true;
//        insert c;

    }

    @IsTest
    static void test() {
        Test.startTest();

        ItemManagement__c itemMng = [SELECT Id FROM ItemManagement__c LIMIT 1];
        AccountSubject__c accSub = [SELECT Id FROM AccountSubject__c LIMIT 1];
        WBSandCC__c wbs = [SELECT Id FROM WBSandCC__c LIMIT 1];

        List<Map<String, String>> infoList = new List<Map<String, String>>();
        Map<String, String> infoMap_item = new Map<String, String>();
        infoMap_item.put('key', 'ItemManagement__c');
        infoMap_item.put('value', itemMng.Id);
        infoList.add(infoMap_item);

        Map<String, String> infoMap_wbs = new Map<String, String>();
        infoMap_wbs.put('key', 'WBS__c');
        infoMap_wbs.put('value', wbs.Id);
        infoList.add(infoMap_wbs);

        List<Map<String, String>> monthList = new List<Map<String, String>>();
        Map<String, String> priceMap = new Map<String, String>();
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


        ItemMngController.getAmountList(itemMng.Id);
        ItemMngController.getItemInfo(itemMng.Id);
        ItemMngController.getAmountInfo(itemMng.Id);
        ItemMngController.getCostList(itemMng.Id);
        ItemMngController.getSingleCostList(itemMng.Id);

        //ItemMngController.updateSingleCostList(itemMng.Id, JSON.serialize(infoList), JSON.serialize(monthList));

        ItemMngController.updateAmountList(itemMng.Id, JSON.serialize(infoList), JSON.serialize(monthList));
        ItemMngController.updateAmountList(itemMng.Id, JSON.serialize(infoList), JSON.serialize(monthList));

        ItemMngController.updateCostList(itemMng.Id, JSON.serialize(costInfoList));
        ItemMngController.updateCostList(itemMng.Id, JSON.serialize(costInfoList));

        ItemMngController.deleteCostList(itemMng.Id, accSub.Id);
        ItemMngController.updateCostList(itemMng.Id, JSON.serialize(costInfoList));

        ItemMngController.isAmountItem(itemMng.Id);

        Test.stopTest();
    }
}