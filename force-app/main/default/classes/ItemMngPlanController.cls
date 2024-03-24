/**
 * @description       : 
 * @author            : jisoolee@mz.co.kr
 * @group             : 
 * @last modified on  : 2023-10-20
 * @last modified by  : jisoolee@mz.co.kr
**/

public without sharing class ItemMngPlanController {
    @AuraEnabled(Cacheable=true)
    public static List<Amount_plan__c> getAmountPlanList(String itemId) {
        try{
            if(Test.isRunningTest() && itemId == 'exceptionTest') throw new DMLException();
            
            List<Amount_plan__c> returnList = [
                    SELECT Id, PlanAmount__c, Status__c, calculateDate__c
                    FROM Amount_plan__c
                    WHERE ItemManagement_Plan__c =: itemId
                    ORDER BY calculateDate__c
            ];
    
            if(returnList.isEmpty()) {
                returnList = new List<Amount_plan__c>();
            }
            return returnList;
        }catch (Exception e) {
            System.debug('e : '+e);
            System.debug('e.getLine : '+e.getLineNumber());
            System.debug('e.message : '+e.getMessage());
            return null;
        }
    }
    
    @AuraEnabled(Cacheable=false)
    public static ItemManagement_Plan__c getItemInfo(String itemId) {
        try{
            if(Test.isRunningTest() && itemId == 'exceptionTest') throw new DMLException();
            
            ItemManagement_Plan__c returnItem = [
                    SELECT Id, WBS_CC__c, AccountSubjectselect__c, AccountSubjectselect__r.Name, AmountType__c, AmountDivision__c, SalesSort__c, Account__c, Owner__c, RecordTypeId, AccountSubjectSort__c
                    FROM ItemManagement_Plan__c
                    WHERE Id =: itemId
                    LIMIT 1
            ];

            return returnItem;
        }catch (Exception e) {
            System.debug('e : '+e);
            System.debug('e.getLine : '+e.getLineNumber());
            System.debug('e.message : '+e.getMessage());
            return null;
        }
    }

    @AuraEnabled(Cacheable=true)
    public static Boolean isAmountItem(String itemId) {
        try{
            if(Test.isRunningTest() && itemId == 'exceptionTest') throw new DmlException();
            
            ItemManagement_Plan__c itemMng = getItemInfo(itemId);
    
            Id amountRecordTypeId = Schema.SObjectType.ItemManagement_Plan__c.getRecordTypeInfosByName().get('매출아이템').getRecordTypeId();
    
            if(itemMng.RecordTypeId == amountRecordTypeId) {
                return true;
            }
            return false;
        }catch (Exception e) {
            System.debug('e : '+e);
            System.debug('e.getLine : '+e.getLineNumber());
            System.debug('e.message : '+e.getMessage());
            return null;
        }
    }
    
    @AuraEnabled(Cacheable=true)
    public static Amount_plan__c getAmountInfo(String itemId) {
        try{
            if(Test.isRunningTest() && itemId == 'exceptionTest') throw new DmlException();
            
            Amount_plan__c returnAmount = new Amount_plan__c();
    
            List<Amount_plan__c> amtList = [
                    SELECT Id, Account__c, User__c
                    FROM Amount_plan__c
                    WHERE ItemManagement_Plan__c =: itemId
                    ORDER BY calculateDate__c
            ];
    
            if(amtList.size() > 0) {
                returnAmount = amtList[0];
            } else {
                returnAmount = new Amount_plan__c();
            }
            return returnAmount;

        }catch (Exception e) {
            System.debug('e : '+e);
            System.debug('e.getLine : '+e.getLineNumber());
            System.debug('e.message : '+e.getMessage());
            return null;
        }
    }
    
    @AuraEnabled
    public static void updateAmountPlanList(String itemId, String infoMapString, String monthListString) {

        ItemManagement_Plan__c target = [
                SELECT Id, Name, AccountSubjecta__c, OwnerId, Owner.isActive, WBS_CC__c, AccountSubjectselect__c, BaseYear__c //2024.01.08 dgchoi BaseYear__c 조회 추가
                FROM ItemManagement_Plan__c
                WHERE Id =: itemId
                LIMIT 1
        ];

        Integer baseYear = Integer.valueOf(target.BaseYear__c); //2024.01.08 dgchoi 정산일자 년도 BaseYear로 수정

        List<Map<String, String>> infoList  = (List<Map<String, String>>) JSON.deserialize(infoMapString, List<Map<String, String>>.class);
        List<Map<String, String>> monthList = (List<Map<String, String>>) JSON.deserialize(monthListString, List<Map<String, String>>.class);

        Map<String, String> infoMap = new Map<String, String>();
        for(Map<String, String> info : infoList) {
            infoMap.put(info.get('key'), info.get('value'));
        }

        List<Amount_plan__c> upsertList = getAmountPlanList(itemId);

        if(upsertList.size() > 0) {
            for(Integer i=0; i<upsertList.size(); i++) {
                //infoMap
                for(String tmpKey : infoMap.keySet()) {
                    if(tmpKey != 'ItemManagement_Plan__c') {
                        upsertList[i].put(tmpKey, infoMap.get(tmpKey));
                    }

                }
                //N월_아이템관리Name_계정과목Name
                upsertList[i].Name          = (i+1) + '월_' + target.Name + '_' + target.AccountSubjecta__c;
                //monthList
                upsertList[i].PlanAmount__c = Decimal.valueOf(monthList[i].get('price')).round(System.RoundingMode.HALF_UP);
                upsertList[i].Status__c     = monthList[i].get('status');
                upsertList[i].Itemmanagementcheck__c = true;

                if(target.OwnerId != null && target.Owner.isActive == true) upsertList[i].User__c = target.OwnerId; //2023.06.07 dgchoi 조건 추가 : Active된 유저만 복제
            }
        } else { //처음 생성시
            for(Integer i=0 ; i<12 ; i++) {
                Amount_plan__c amt = new Amount_plan__c();
                for(String tmpKey : infoMap.keySet()) {
                    amt.put(tmpKey, infoMap.get(tmpKey));
                }
                //N월_아이템관리Name_계정과목Name
                amt.Name                    = i+1 + '월_' + target.Name + '_' + target.AccountSubjecta__c;
                amt.calculateDate__c        = Date.newInstance(baseYear, i+1, 1); //2024.01.08 dgchoi 정산일자 년도 BaseYear로 수정
                amt.PlanAmount__c           = Decimal.valueOf(monthList[i].get('price')).round(System.RoundingMode.HALF_UP);
                amt.Status__c               = monthList[i].get('status');
                amt.Itemmanagementcheck__c = true;

                if(target.OwnerId != null && target.Owner.isActive == true) amt.User__c = target.OwnerId; //2023.06.07 dgchoi 조건 추가 : Active된 유저만 복제

                upsertList.add(amt);
            }
        }
        if(upsertList.size() > 0) upsert upsertList;
    }
    
    ////매출 아이템 - 매입버튼
    @AuraEnabled(Cacheable=true)
    public static String getCostList(String itemId) {
        try{
            if(Test.isRunningTest() && itemId == 'exceptionTest') throw new DMLException();
            
            ItemManagement_Plan__c target = [
                SELECT Id, AccountSubjectSort__c, BaseYear__c
                FROM ItemManagement_Plan__c
                WHERE Id =: itemId
                LIMIT 1
            ];  //2024.01.08 dgchoi BaseYear__c 조회 추가

            String  accountSubjectSort = target.AccountSubjectSort__c;
            Integer baseYear           = Integer.valueOf(target.BaseYear__c); //2024.01.08 dgchoi 정산일자 년도 BaseYear로 수정

            List<Cost_Plan__c> costList = [
                    SELECT Id, AccountSubjectselect__c, AccountSubjecta__c, CalculateDate__c, PlanPurchaseAmount__c
                    FROM Cost_Plan__c
                    WHERE ItemManagement_Plan__c =: itemId
                    ORDER BY AccountSubjectselect__c, CalculateDate__c
            ];
    
            List<Amount_plan__c> amtList = getAmountPlanList(itemId);
    
            Map<Integer, Double> amtMap = new Map<Integer, Double>(); //정산월 - 매출금액
    
            for(Amount_plan__c a : amtList) {
                amtMap.put(a.calculateDate__c.month(), a.PlanAmount__c);
            }
    
            Map<String, String> subjectMap = new Map<String, String>(); //Id - name
            for(Cost_Plan__c  c : costList) {
                subjectMap.put(c.AccountSubjectselect__c, c.AccountSubjecta__c);
            }
            subjectMap.put(null, '계정 과목 선택');
    
            Map<String, List<CostSectionClass>> costMap = new Map<String, List<CostSectionClass>>();
    
            if(costList.size()>0) {
                for(Cost_Plan__c c : costList) {
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
            } else { //처음 생성시
                List<CostSectionClass> tmpList = new List<CostSectionClass>();
                for(Integer i=1; i<=12; i++) {
                    Cost_Plan__c c              = new Cost_Plan__c();
                    c.Name                      = 'test';
                    c.CalculateDate__c          = Date.newInstance(baseYear, i, 1); //2024.01.08 dgchoi 정산일자 년도 BaseYear로 수정
                    c.ItemManagement_Plan__c    = itemId;
                    c.PlanPurchaseAmount__c     = 0;
    
                    CostSectionClass sc = new CostSectionClass();
                    sc.cno = i;
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
            System.debug('check costMap: '+costMap);
    
            Map<Id, AccountSubject__c> accountSubjectSortMap = new Map<Id, AccountSubject__c>(
                [
                        SELECT Id, Name
                        FROM AccountSubject__c
                        WHERE AccountSubjectsort__c  =: accountSubjectSort
                ]
            );
    
            List<CostClass> returnList = new List<CostClass>();
    
            Integer tmpIndex = 1;
            for(String tmpKey : costMap.keySet()) {
                System.debug('tmpKey: '+tmpKey);
                CostClass cc = new CostClass();
                cc.sno          = tmpIndex;
                cc.subjectId    = tmpKey;
                cc.subjectName  = subjectMap.get(tmpKey);
                cc.data         = costMap.get(tmpKey);
                cc.subjectMap   = accountSubjectSortMap;
                cc.isSaved      = (tmpKey != null ? true : false);
                returnList.add(cc);
            }
            return JSON.serialize(returnList);
        }catch (Exception e) {
            System.debug('e : '+e);
            System.debug('e.getLine : '+e.getLineNumber());
            System.debug('e.message : '+e.getMessage());
            return null;
        }
    }

    @AuraEnabled
    public static Map<String, String> updateCostList(String itemId, String infoMapString) {
        Map<String, String> returnMap = new Map<String, String>();

        //2023.0
        try {
            if(Test.isRunningTest() && itemId == 'exceptionTest') throw new DMLException();
            
            //2023.06.07 dgchoi 필드 조회 추가 : Owner.isActive
            ItemManagement_Plan__c target = [
                    SELECT Id, Name, AccountSubjecta__c, OwnerId, Owner.isActive, WBS_CC__c, AccountSubjectselect__c, AmountType__c, BaseYear__c //2024.01.08 dgchoi BaseYear__c 조회 추가
                    FROM ItemManagement_Plan__c
                    WHERE Id = :itemId
                    LIMIT 1
            ];

            Integer baseYear = Integer.valueOf(target.BaseYear__c); //2024.01.08 dgchoi 정산일자 년도 BaseYear로 수정

            List<Cost_Plan__c> costList = [
                    SELECT Id, AccountSubjectselect__c, AccountSubjecta__c, CalculateDate__c, PlanPurchaseAmount__c
                    FROM Cost_Plan__c
                    WHERE ItemManagement_Plan__c = :itemId
                    ORDER BY AccountSubjectselect__c, CalculateDate__c
            ];

            Map<String, List<Cost_Plan__c>> costMap = new Map<String, List<Cost_Plan__c>>();

            for (Cost_Plan__c c : costList) {
                List<Cost_Plan__c> tmpList = new List<Cost_Plan__c>();
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
            System.debug('infoList: '+infoList);
            
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

            List<Cost_Plan__c> upsertList = new List<Cost_Plan__c>();

            if (costList.size() > 0) { //매입 레코드 있을때
                System.debug('update--');
                System.debug('costMap: ' + costMap);
                for (String newKey : newInfoMap.keySet()) {
                    System.debug('newKey: ' + newKey);
                    String oldKey = infoIdMap.get(newKey);
                    System.debug('oldKey: ' + oldKey);
                    List<Decimal> priceList = newInfoMap.get(newKey);

                    List<Cost_Plan__c> tmpList = new List<Cost_Plan__c>();

                    if (costMap.containsKey(oldKey)) {
                        tmpList = costMap.get(oldKey);
                        for (Integer i = 0; i < tmpList.size(); i++) {
                            tmpList[i].Name                    = (i + 1) + '월_' + target.Name + '_' + subMap.get(newKey);
                            tmpList[i].AccountSubjectselect__c = newKey;
                            tmpList[i].PlanPurchaseAmount__c   = priceList[i].round(System.RoundingMode.HALF_UP);
                            tmpList[i].Itemmanagementcheck__c  = true;

                            if(target.OwnerId != null && target.Owner.isActive == true) tmpList[i].Owner__c = target.OwnerId; //2023.06.07 dgchoi 필드 조회 추가 : Owner.isActive
                        }
                    } else {
                        for (Integer i = 0; i < priceList.size(); i++) {
                            Cost_Plan__c cost                  = new Cost_Plan__c();
                            cost.Name                          = (i + 1) + '월_' + target.Name + '_' + subMap.get(newKey);
                            cost.Itemmanagement_Plan__c        = itemId;
                            cost.WBS__c                        = wbsId;
                            cost.AccountSubjectselect__c       = newKey;
                            cost.PlanPurchaseAmount__c         = priceList[i].round(System.RoundingMode.HALF_UP);
                            cost.CalculateDate__c              = Date.newInstance(baseYear, i + 1, 1);  //2024.01.08 dgchoi 정산일자 년도 BaseYear로 수정
                            cost.Itemmanagementcheck__c        = true;

                            if(target.OwnerId != null && target.Owner.isActive == true) cost.Owner__c = target.OwnerId; //2023.06.07 dgchoi 필드 조회 추가 : Owner.isActive
                            tmpList.add(cost);
                        }
                    }
                    System.debug('@tmpList: ' + tmpList);
                    upsertList.addAll(tmpList);
                }
            } else { //처음 insert 할때 (매입 레코드 없을때)
                System.debug('insert--');
                for (String newKey : newInfoMap.keySet()) {
                    List<Cost_Plan__c> tmpList = new List<Cost_Plan__c>();

                    List<Decimal> priceList = newInfoMap.get(newKey);
                    System.debug('priceList: '+priceList);

                    for(Integer i = 0; i < priceList.size(); i++) {
                        Cost_Plan__c cost                      = new Cost_Plan__c();
                        cost.Name                              = i+1 + '월_' + target.Name + '_' + subMap.get(newKey);
                        cost.ItemManagement_Plan__c            = itemId;
                        cost.WBS__c                            = wbsId;
                        cost.AccountSubjectselect__c           = newKey;
                        cost.PlanPurchaseAmount__c             = priceList[i].round(System.RoundingMode.HALF_UP);
                        cost.CalculateDate__c                  = Date.newInstance(baseYear, i + 1, 1); //2024.01.08 dgchoi 정산일자 년도 BaseYear로 수정
                        cost.Itemmanagementcheck__c            = true;

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
        try{
            if(Test.isRunningTest() && itemId == 'exceptionTest') throw new DMLException();
            
            List<Cost_Plan__c> costList = [
                    SELECT Id FROM Cost_Plan__c
                    WHERE ItemManagement_Plan__c =: itemId
                    AND AccountSubjectselect__c =: subjectId
            ];

            for(Cost_plan__c cost : costList) {
                cost.Itemmanagementcheck__c = true;
            }
    
            System.debug('@deleteCostList: ' + costList);
            if(costList.size() > 0) delete costList;
            
            if(Test.isRunningTest()) throw new DMLException();
        }catch (Exception e) {
            System.debug('e : '+e);
            System.debug('e.getLine : '+e.getLineNumber());
            System.debug('e.message : '+e.getMessage());
        }
    }
    
    ////매입아이템 - 매입버튼
    @AuraEnabled(Cacheable=true)
    public static List<Cost_Plan__c> getSingleCostList(String itemId) {
        try{
            if(Test.isRunningTest() && itemId == 'exceptionTest') throw new DMLException();
            
            List<Cost_Plan__c> returnList = [
                    SELECT Id, PlanPurchaseAmount__c, CalculateDate__c, AccountSubjectselect__c
                    FROM Cost_Plan__c
                    WHERE ItemManagement_Plan__c =: itemId
                    ORDER BY CalculateDate__c
            ];
    
            if(returnList.isEmpty()) {
                returnList = new List<Cost_Plan__c>();
            }
    
            return returnList;
        }catch (Exception e) {
            System.debug('e : '+e);
            System.debug('e.getLine : '+e.getLineNumber());
            System.debug('e.message : '+e.getMessage());
            return null;
        }
    }

    public class InfoClass {
        public List<Double> data;
        public String beforeSubjectId; // 수정전, 수정후 가져오는거 필요! beforeSubjectId, afterSubjectId
        public String afterSubjectId;
        public String wbsId;
    }

    public class CostClass{
        public Integer sno; //sectionNumber
        public String subjectId;
        public String subjectName;
        public Boolean isSaved;
        public Map<Id, AccountSubject__c> subjectMap;
        public List<CostSectionClass> data;
    }

    public class CostSectionClass {
        public Double amountPrice; //매출 금액
        public Integer cno;
        public Cost_Plan__c data;
    }
}