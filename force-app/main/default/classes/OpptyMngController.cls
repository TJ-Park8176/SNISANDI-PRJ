/**
 * Created by MZC01-DGCHOI on 2022-12-16.
 */

public with sharing class OpptyMngController {

    @AuraEnabled(Cacheable=true)
    public static Opportunity getOpptyInfo(String opptyId) {
        Opportunity returnOppty = [
                SELECT Id, WBS_CC__c, parent_Opportunity__c,
                       OwnerId, AccountId, Possibility_of_closed_won__c, Type2__c
                FROM Opportunity
                WHERE Id =: opptyId
                LIMIT 1
        ];

        if(returnOppty == null) {
            returnOppty = new Opportunity();
        }

        return returnOppty;
    }

    @AuraEnabled(Cacheable=true)
    public static List<Opportunity_amount__c> getAmountList(String opptyId) {
        System.debug('@opptyId: ' + opptyId);
        List<Opportunity_amount__c> returnList = [
                SELECT Id, Monthly_amount__c, CalculateDate__c
                FROM Opportunity_amount__c
                WHERE Opportunityname__c =: opptyId
                ORDER BY CalculateDate__c
        ];

        if(returnList.isEmpty()) {
            returnList = new List<Opportunity_amount__c>();
        }

        System.debug('@returnList: ' + returnList);
        return returnList;
    }

    @AuraEnabled
    public static void updateAmountList(String opptyId, String infoMapString, String monthListString) {
        System.debug('@@infoMapString: ' + infoMapString);

        //2023.06.07 dgchoi 필드 조회 추가 : Owner.isActive + 24.03.21 Sanghee 영업물건 매출발생시기 기준 영업매출 등록 및 업데이트 필드 추가 amount_occur_date__c
        Opportunity target = [
                SELECT Id, Name, WBS_CC__c, parent_Opportunity__c,
                       OwnerId, AccountId, Account.Name, Owner.isActive, amount_occur_date__c
                FROM Opportunity
                WHERE Id =: opptyId
                LIMIT 1
        ];

        List<Map<String, String>> infoList = (List<Map<String, String>>) JSON.deserialize(infoMapString, List<Map<String, String>>.class);
        List<Map<String, String>> monthList = (List<Map<String, String>>) JSON.deserialize(monthListString, List<Map<String, String>>.class);

        Map<String, String> infoMap = new Map<String, String>();
        for(Map<String, String> info : infoList) {
            infoMap.put(info.get('key'), info.get('value'));
        }
        System.debug(infoMap);

        List<Opportunity_amount__c> upsertList = getAmountList(opptyId);

        if(upsertList.size() > 0) {
            for(Integer i=0; i<upsertList.size(); i++) {
                //infoMap
                for(String tmpKey : infoMap.keySet()) {
                    if(tmpKey != 'Opportunityname__c') upsertList[i].put(tmpKey, infoMap.get(tmpKey));
                }

                //monthList
                upsertList[i].Monthly_amount__c = Decimal.valueOf(monthList[i].get('price'));
                if(target.amount_occur_date__c != null) upsertList[i].CalculateDate__c = Date.newInstance(target.amount_occur_date__c.year(), i+1, 1); //24.03.21 Sanghee 영업물건 매출발생시기 기준 영업매출 등록 및 업데이트
                if(target.OwnerId != null && target.Owner.isActive == true) upsertList[i].OwnerId__c = target.OwnerId; //2023.06.07 dgchoi 조건 추가 : Active된 유저만 복제
            }
        } else {
            for(Integer i=0; i<12; i++) {
                Opportunity_amount__c amt = new Opportunity_amount__c();
                for(String tmpKey : infoMap.keySet()) {
                    amt.put(tmpKey, infoMap.get(tmpKey));
                }
                amt.Name = i+1 + '월_' + target.Name + '_' + target.Account.Name; //N월_아이템관리Name_계정Name
                //amt.CalculateDate__c = Date.newInstance(Date.today().year(), i+1, 1);
                if (target.amount_occur_date__c == null) amt.CalculateDate__c = Date.newInstance(Date.today().year(), i+1, 1);
                else amt.CalculateDate__c = Date.newInstance(target.amount_occur_date__c.year(), i+1, 1); //24.03.21 Sanghee 영업물건 매출발생시기 기준 영업매출 등록 및 업데이트
                amt.Monthly_amount__c = Decimal.valueOf(monthList[i].get('price'));
                amt.OpportunityCheck__c = true;
                if(target.OwnerId != null && target.Owner.isActive == true) amt.OwnerId__c = target.OwnerId; //2023.06.07 dgchoi 조건 추가 : Active된 유저만 복제

                upsertList.add(amt);
            }
        }

        System.debug('@upsertList: ' + upsertList);
        if(upsertList.size()>0) upsert upsertList;
    }

    @AuraEnabled(cacheable=true)
    public static boolean hasOpptyAmount(String opptyId){
        List<Opportunity_Amount__c> checkList = getOpptyAmount(opptyId);

        if(checkList.isEmpty()) {
            return false;
        }
        return true;
    }

    @AuraEnabled
    public static String deleteOpptyAmount(String opptyId){
        try {
            List<Opportunity_amount__c> deleteList = getOpptyAmount(opptyId);

            if(deleteList.size() > 0) {
                delete deleteList;
            } else {
                return 'NO DATA';
            }
        } catch(Exception e) {
            return e.getMessage();
        }

        return 'SUCCESS';
    }

    @AuraEnabled(cacheable=true)
    public static List<Opportunity_amount__c> getOpptyAmount(String opptyId) {
        List<Opportunity_amount__c> returnList = [
                SELECT Id, Name, WBS_CC__c, AccountId__c,
                       StageName__c, CalculateDate__c,
                       Monthly_amount__c, Opportunityname__c, Parent_Opportunity__c
                FROM Opportunity_amount__c
                WHERE Opportunityname__c =: opptyId
        ];

        System.debug('@opptyId: ' + opptyId);
        System.debug('@returnList[Opportunity_Amount]: ' +returnList);
        System.debug('@returnList isEmpty?: ' + returnList.isEmpty());

        if(returnList.isEmpty()) {
            returnList = new List<Opportunity_amount__c>();
        }
        return returnList;
    }


}