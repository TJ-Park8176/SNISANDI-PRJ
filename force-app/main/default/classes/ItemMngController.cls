/**
 * Created by MZC01-DGCHOI on 2022-12-12.
 */

public without sharing class ItemMngController {
////매출 아이템 - 매출버튼
    @AuraEnabled(Cacheable=true)
    public static List<Amount__c> getAmountList(String itemId) {
        System.debug('@itemId: ' + itemId);
        List<Amount__c> returnList = [
                SELECT Id, PredictAmount__c, Status__c, CalculateDate__c
                FROM Amount__c
                WHERE Itemmanagement__c =: itemId
                ORDER BY CalculateDate__c
        ];

        if(returnList.isEmpty()) {
            returnList = new List<Amount__c>();
        }

        System.debug('@returnList: ' + returnList);
        return returnList;
    }

    @AuraEnabled(Cacheable=true)
    public static ItemManagement__c getItemInfo(String itemId) {
        ItemManagement__c returnItem = [
                SELECT Id, WBS_CC__c, AccountSubjectselect__c,
                       AccountSubjectselect__r.Name,
                       AmountType__c, AmountDivision__c,
                       SalesSort__c, Account__c, Owner__c, RecordTypeId, //RecordTypeID 추가 (23.01.27)
                       AccountSubjectSort__c //용/판구분테스트 추가(23.03.23)
                FROM ItemManagement__c
                WHERE Id =: itemId
                LIMIT 1
        ];

        System.debug('@returnItem: ' + returnItem);
        return returnItem;
    }

    @AuraEnabled(Cacheable=true)
    public static Amount__c getAmountInfo(String itemId) {
        Amount__c returnAmount = new Amount__c();

        List<Amount__c> amtList = [
                SELECT Id, Account__c, User__c
                FROM Amount__c
                WHERE Itemmanagement__c =: itemId
                ORDER BY CalculateDate__c
        ];

        if(amtList.size() > 0) {
            returnAmount = amtList[0];
        } else {
            returnAmount = new Amount__c();
        }
        System.debug('@returnAmount: ' + returnAmount);
        return returnAmount;
    }

    @AuraEnabled
    public static void updateAmountList(String itemId, String infoMapString, String monthListString) {
        System.debug('@@infoMapString: ' + infoMapString);

        //2023.06.07 dgchoi 필드 조회 추가 : Owner.isActive , 24.03.11 Sanghee Base_Year__c 필드 추가
        ItemManagement__c target = [
                SELECT Id, Name, AccountSubjecta__c, OwnerId, Owner.isActive,
                       WBS_CC__c, AccountSubjectselect__c, Base_Year__c
                       //AmountType__c
                FROM ItemManagement__c
                WHERE Id =: itemId
                LIMIT 1
        ];
        Integer Base_Year = Integer.valueOf(target.Base_Year__c);

        System.now();

        List<Map<String, String>> infoList  = (List<Map<String, String>>) JSON.deserialize(infoMapString, List<Map<String, String>>.class);
        List<Map<String, String>> monthList = (List<Map<String, String>>) JSON.deserialize(monthListString, List<Map<String, String>>.class);

        Map<String, String> infoMap = new Map<String, String>();
        for(Map<String, String> info : infoList) {
            infoMap.put(info.get('key'), info.get('value'));
        }
        System.debug('@@infoMap: ' + infoMap);

        List<Amount__c> upsertList = getAmountList(itemId);

        if(upsertList.size() > 0) {
            for(Integer i=0; i<upsertList.size(); i++) {
                //infoMap
                for(String tmpKey : infoMap.keySet()) {
                    if(tmpKey != 'Itemmanagement__c') {
                        upsertList[i].put(tmpKey, infoMap.get(tmpKey));
                    }

                }

                upsertList[i].Name = (i+1) + '월_' + target.Name + '_' + target.AccountSubjecta__c; //N월_아이템관리Name_계정과목Name
                //monthList
                upsertList[i].PredictAmount__c = Decimal.valueOf(monthList[i].get('price')).round(System.RoundingMode.HALF_UP);
                upsertList[i].Status__c = monthList[i].get('status');
                upsertList[i].Itemmanagementcheck__c = true;
                if(target.OwnerId != null && target.Owner.isActive == true) upsertList[i].User__c = target.OwnerId; //2023.06.07 dgchoi 조건 추가 : Active된 유저만 복제
            }
        } else {
            for(Integer i=0; i<12; i++) {
                Amount__c amt = new Amount__c();
                for(String tmpKey : infoMap.keySet()) {
                    amt.put(tmpKey, infoMap.get(tmpKey));
                }
                amt.Name = i+1 + '월_' + target.Name + '_' + target.AccountSubjecta__c; //N월_아이템관리Name_계정과목Name
                amt.CalculateDate__c = Date.newInstance(Base_Year, i+1, 1);
                amt.PredictAmount__c = Decimal.valueOf(monthList[i].get('price')).round(System.RoundingMode.HALF_UP);
                amt.Status__c = monthList[i].get('status');
                amt.Itemmanagementcheck__c = true;
                if(target.OwnerId != null && target.Owner.isActive == true) amt.User__c = target.OwnerId; //2023.06.07 dgchoi 조건 추가 : Active된 유저만 복제

                upsertList.add(amt);
            }
        }

        System.debug('@upsertList: ' + upsertList);
        if(upsertList.size()>0) upsert upsertList;
    }


////매출 아이템 - 매입버튼
    @AuraEnabled(Cacheable=true)
    public static String getCostList(String itemId) {
        List<Cost__c> costList = [
                SELECT Id, AccountSubjectselect__c, AccountSubjecta__c,
                     CalculateDate__c, PurchaseAmount__c
                FROM Cost__c
                WHERE Itemmanagement__c =: itemId
                ORDER BY AccountSubjectselect__c, CalculateDate__c
        ];

        List<Amount__c> amtList = getAmountList(itemId);

        Map<Integer, Double> amtMap = new Map<Integer, Double>(); //정산월 - 매출금액

        for(Amount__c a : amtList) {
            amtMap.put(a.CalculateDate__c.month(), a.PredictAmount__c);
        }

        Map<String, String> subjectMap = new Map<String, String>(); //Id - name
        for(Cost__c  c : costList) {
            subjectMap.put(c.AccountSubjectselect__c, c.AccountSubjecta__c);
        }
        subjectMap.put(null, '계정 과목 선택');

        Map<String, List<CostSectionClass>> costMap = new Map<String, List<CostSectionClass>>();

        if(costList.size()>0) {
            for(Cost__c c : costList) {
                List<CostSectionClass> tmpList = new List<CostSectionClass>();
                if(costMap.containsKey(c.AccountSubjectselect__c)) {
                    tmpList = costMap.get(c.AccountSubjectselect__c);
                }
                CostSectionClass sc = new CostSectionClass();
                //sc.amountPrice = 0;
                sc.cno  = c.CalculateDate__c.month();
                sc.data = c;

                tmpList.add(sc);

                costMap.put(c.AccountSubjectselect__c, tmpList);
            }
        } else {
            List<CostSectionClass> tmpList = new List<CostSectionClass>();
            for(Integer i=1; i<=12; i++) {
                Cost__c c = new Cost__c();
                c.Name              = 'test';
                c.CalculateDate__c  = Date.newInstance(2023, i, 1);
                c.Itemmanagement__c = itemId;
                c.PurchaseAmount__c = 0;

                CostSectionClass sc = new CostSectionClass();
                sc.cno  = i;
                sc.data = c;
                tmpList.add(sc);
            }
            costMap.put(null, tmpList);
        }

        //매출 값 업데이트
        for(String tmpKey : costMap.keySet()) {
            List<CostSectionClass> tmpList = costMap.get(tmpKey);
            for(Integer i=0; i<tmpList.size(); i++) {
                tmpList[i].amountPrice = amtMap.containsKey(i+1) ? amtMap.get(i+1) : 0; //정산월로 판매액 조회
            }
            costMap.put(tmpKey, tmpList);
        }


        List<CostClass> returnList = new List<CostClass>();

        Integer tmpIndex = 1;
        for(String tmpKey : costMap.keySet()) {
            CostClass cc = new CostClass();
            cc.sno         = tmpIndex;
            cc.subjectId   = tmpKey;
            cc.subjectName = subjectMap.get(tmpKey);
            cc.data        = costMap.get(tmpKey);
            cc.isSaved     = (tmpKey != null ? true : false);
            returnList.add(cc);
        }

        System.debug('@returnList: ' + returnList);
        return JSON.serialize(returnList);
    }

    @AuraEnabled
    public static Map<String, String> updateCostList(String itemId, String infoMapString) {
        System.debug(itemId);
        System.debug(infoMapString);

        Map<String, String> returnMap = new Map<String, String>();

        //2023.0
        try {
            //2023.06.07 dgchoi 필드 조회 추가 : Owner.isActive , 24.03.11 Sanghee Base_Year__c 필드 추가
            ItemManagement__c target = [
                    SELECT Id, Name, AccountSubjecta__c, OwnerId, Owner.isActive,
                            WBS_CC__c, AccountSubjectselect__c, Base_Year__c,
                            AmountType__c
                    FROM ItemManagement__c
                    WHERE Id = :itemId
                    LIMIT 1
            ];
            Integer Base_Year = Integer.valueOf(target.Base_Year__c);

            List<Cost__c> costList = [
                    SELECT Id, AccountSubjectselect__c, AccountSubjecta__c,
                           CalculateDate__c, PurchaseAmount__c
                    FROM Cost__c
                    WHERE Itemmanagement__c = :itemId
                    ORDER BY AccountSubjectselect__c, CalculateDate__c
            ];

            Map<String, List<Cost__c>> costMap = new Map<String, List<Cost__c>>();

            for (Cost__c c : costList) {
                List<Cost__c> tmpList = new List<Cost__c>();
                if (costMap.containsKey(c.AccountSubjectselect__c)) {
                    tmpList = costMap.get(c.AccountSubjectselect__c);
                }
                tmpList.add(c);

                costMap.put(c.AccountSubjectselect__c, tmpList);
            }

            Map<String, List<Decimal>> newInfoMap = new Map<String, List<Decimal>>();
            Map<String, List<Decimal>> oldInfoMap = new Map<String, List<Decimal>>();
            Map<String, String> infoIdMap         = new Map<String, String>();
            List<InfoClass> infoList              = (List<InfoClass>) JSON.deserialize(infoMapString, List<InfoClass>.class);

            String wbsId = infoList[0].wbsId;

            for (InfoClass info : infoList) {
                infoIdMap.put(info.afterSubjectId, info.beforeSubjectId); //key:after, value:before
                oldInfoMap.put(info.beforeSubjectId, info.data);

                System.debug('info afterSubjectId :::: ' + info.afterSubjectId);

                if(newInfoMap.containsKey(info.afterSubjectId)) { //같은 계정과목 중복 입력시
                    returnMap.put('status', 'E');
                    returnMap.put('message', '계정 과목을 중복 선택했습니다.');

                    return returnMap;
                } else if(info.afterSubjectId == null || info.afterSubjectId == '') { //계정과목 미입력시
                    returnMap.put('status', 'E');
                    returnMap.put('message', '매입 등록 시, 계정 과목은 필수 선택입니다. 계정 과목을 선택하거나 삭제를 눌러 해당 레코드를 삭제해주세요');

                    return returnMap;
                }
                newInfoMap.put(info.afterSubjectId, info.data);
            }

            List<AccountSubject__c> subList = [
                    SELECT Id, Name
                    FROM AccountSubject__c
                    WHERE Id IN :newInfoMap.keySet()
            ];
            Map<String, String> subMap = new Map<String, String>();
            for (AccountSubject__c s : subList) {
                subMap.put(s.Id, s.Name);
            }
            System.debug('@subMap: ' + subMap);


            List<Cost__c> upsertList = new List<Cost__c>();

            if (costList.size() > 0) { //매입 레코드 있을때
                System.debug('oldInfoMap: ' + oldInfoMap);
                for (String newKey : newInfoMap.keySet()) {
                    String oldKey = infoIdMap.get(newKey);
                    List<Decimal> priceList = newInfoMap.get(newKey);

                    List<Cost__c> tmpList = new List<Cost__c>();

                    System.debug('oldKey :::: ' + oldKey);
                    System.debug('newKey :::: ' + oldKey);

                    if (costMap.containsKey(oldKey)) {
                        tmpList = costMap.get(oldKey);
                        for (Integer i = 0; i < tmpList.size(); i++) {
                            tmpList[i].Name                    = (i + 1) + '월_' + target.Name + '_' + subMap.get(newKey);
                            tmpList[i].AccountSubjectselect__c = newKey;
                            tmpList[i].PurchaseAmount__c       = priceList[i].round(System.RoundingMode.HALF_UP);
                            tmpList[i].Itemmanagementcheck__c  = true; //매출/매입은 커스텀페이지에서 생성할땐 무조건 True 해줌(False면 트리거에서 걸려)
                            if(target.OwnerId != null && target.Owner.isActive == true) tmpList[i].Owner__c = target.OwnerId; //2023.06.07 dgchoi 필드 조회 추가 : Owner.isActive
                        }
                    } else {
                        for (Integer i = 0; i < priceList.size(); i++) {
                            Cost__c cost = new Cost__c();
                            cost.Name                    = (i + 1) + '월_' + target.Name + '_' + subMap.get(newKey);
                            cost.Itemmanagement__c       = itemId;
                            cost.WBS__c                  = wbsId;
                            cost.AccountSubjectselect__c = newKey;
                            cost.PurchaseAmount__c       = priceList[i].round(System.RoundingMode.HALF_UP);
                            cost.CalculateDate__c        = Date.newInstance(Base_Year, i + 1, 1);
                            cost.Itemmanagementcheck__c  = true;
                            if(target.OwnerId != null && target.Owner.isActive == true) cost.Owner__c = target.OwnerId; //2023.06.07 dgchoi 필드 조회 추가 : Owner.isActive
                            tmpList.add(cost);
                        }
                    }
                    System.debug('@tmpList: ' + tmpList);
                    upsertList.addAll(tmpList);
                }
            } else { //처음 insert 할때 (매입 레코드 없을때)
                for (String newKey : newInfoMap.keySet()) {
                    List<Cost__c> tmpList   = new List<Cost__c>();
                    List<Decimal> priceList = newInfoMap.get(newKey);

                    for (Integer i = 0; i < priceList.size(); i++) {
                        Cost__c cost                 = new Cost__c();
                        cost.Name                    = i + 1 + '월_' + target.Name + '_' + subMap.get(newKey);
                        cost.Itemmanagement__c       = itemId;
                        cost.WBS__c                  = wbsId;
                        cost.AccountSubjectselect__c = newKey;
                        cost.PurchaseAmount__c       = priceList[i].round(System.RoundingMode.HALF_UP);
                        cost.CalculateDate__c        = Date.newInstance(Base_Year, i + 1, 1);
                        cost.Itemmanagementcheck__c  = true;
                        if(target.OwnerId != null && target.Owner.isActive == true) cost.Owner__c = target.OwnerId; //2023.06.07 dgchoi 필드 조회 추가 : Owner.isActive
                        tmpList.add(cost);
                    }
                    upsertList.addAll(tmpList);
                }
            }

            System.debug('@upsertList - Cost: ' + upsertList);
            if (upsertList.size() > 0) upsert upsertList;

            returnMap.put('status', 'S');
            returnMap.put('message', 'success');
        } catch (Exception e) {
            returnMap.put('status', 'E');
            returnMap.put('message', e.getMessage());
        }

        return returnMap;
    }

    @AuraEnabled
    public static void deleteCostList(String itemId, String subjectId) {
        List<Cost__c> costList = [
                SELECT Id FROM Cost__c
                WHERE Itemmanagement__c =: itemId
                AND AccountSubjectselect__c =: subjectId
        ];

        System.debug('@deleteCostList: ' + costList);

        for(Cost__c cost : costList) {
            cost.Itemmanagementcheck__c = true;
        }
        if(costList.size() > 0) delete costList;
    }

////매입아이템 - 매입버튼
    @AuraEnabled(Cacheable=true)
    public static List<Cost__c> getSingleCostList(String itemId) {
        System.debug('@itemId: ' + itemId);
        List<Cost__c> returnList = [
                SELECT Id, PurchaseAmount__c, CalculateDate__c, AccountSubjectselect__c
                FROM Cost__c
                WHERE Itemmanagement__c =: itemId
                ORDER BY CalculateDate__c
        ];

        if(returnList.isEmpty()) {
            returnList = new List<Cost__c>();
        }

        System.debug('@returnList: ' + returnList);
        return returnList;
    }

    /*
    @AuraEnabled
    public static void updateSingleCostList(String itemId, String infoMapString, String monthListString) {
        System.debug('@@infoMapString: ' + infoMapString);

        ItemManagement__c target = [SELECT Id, Name, AccountSubjecta__c,
                                           WBS_CC__c, AccountSubjectselect__c,
                                           AmountType__c
                                    FROM ItemManagement__c
                                    WHERE Id =: itemId
                                    LIMIT 1];

        List<Map<String, String>> infoList = (List<Map<String, String>>) JSON.deserialize(infoMapString, List<Map<String, String>>.class);
        List<Map<String, String>> monthList = (List<Map<String, String>>) JSON.deserialize(monthListString, List<Map<String, String>>.class);

        Map<String, String> infoMap = new Map<String, String>();
        for(Map<String, String> info : infoList) {
            infoMap.put(info.get('key'), info.get('value'));
        }
        System.debug(infoMap);

        List<Cost__c> upsertList = getSingleCostList(itemId);

        if(upsertList.size() > 0) {
            for(Integer i=0; i<upsertList.size(); i++) {
                //infoMap
                for(String tmpKey : infoMap.keySet()) {
                    if(tmpKey != 'Itemmanagement__c') upsertList[i].put(tmpKey, infoMap.get(tmpKey));
                }

                //monthList
                upsertList[i].PurchaseAmount__c = Decimal.valueOf(monthList[i].get('price'));
            }
        } else {
            for(Integer i=0; i<12; i++) {
                Cost__c cost = new Cost__c();
                for(String tmpKey : infoMap.keySet()) {
                    cost.put(tmpKey, infoMap.get(tmpKey));
                }
                cost.Name = i+1 + '월_' + target.Name + '_' + target.AccountSubjecta__c; //N월_아이템관리Name_계정과목Name
                cost.CalculateDate__c  = Date.newInstance(Date.today().year(), i+1, 1);
                cost.PurchaseAmount__c = Decimal.valueOf(monthList[i].get('price'));
                cost.Itemmanagementcheck__c = true;

                upsertList.add(cost);
            }
        }

        System.debug('@upsertList: ' + upsertList);
        if(upsertList.size()>0) upsert upsertList;
    }
     */

    //매출아이템이면? TRUE
    @AuraEnabled(Cacheable=true)
    public static Boolean isAmountItem(String itemId) {
        ItemManagement__c itemMng = getItemInfo(itemId);

        Id amountRecordTypeId = Schema.SObjectType.ItemManagement__c.getRecordTypeInfosByName().get('매출아이템').getRecordTypeId();

        if(itemMng.RecordTypeId == amountRecordTypeId) {
            return true;
        }
        return false;
    }



    //class
    public class CostClass{
        public Integer sno; //sectionNumber
        public String subjectId;
        public String subjectName;
        public boolean isSaved;
        public List<CostSectionClass> data;
    }

    public class CostSectionClass {
        public Double amountPrice; //매출 금액
        public Integer cno;
        public Cost__c data;
    }

    public class InfoClass {
        public List<Double> data;
        public String beforeSubjectId; // 수정전, 수정후 가져오는거 필요! beforeSubjectId, afterSubjectId
        public String afterSubjectId;
        public String wbsId;
    }

}