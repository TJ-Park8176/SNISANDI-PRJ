/**
 * Created by MZC01-DGCHOI on 2023-11-27.
 */

public with sharing class OpptyMngPlanController {
    @AuraEnabled(Cacheable=true)
    public static Opportunity_plan__c getOpptyInfo(String opptyPlanId) {
        Opportunity_plan__c returnOpptyPlan = [
                SELECT Id, WBS_CC__c, Parent_Opportunity__c,
                       OwnerId, AccountId__c, Possibility_of_closed_won__c, Type2__c
                FROM Opportunity_plan__c
                WHERE Id =: opptyPlanId
                LIMIT 1
        ];

        if(returnOpptyPlan == null) {
            returnOpptyPlan = new Opportunity_plan__c();
        }

        return returnOpptyPlan;
    }

    @AuraEnabled(Cacheable=true)
    public static List<opportunity_amount_plan__c> getAmountList(String opptyPlanId) {
        System.debug('@opptyPlanId: ' + opptyPlanId);
        List<opportunity_amount_plan__c> returnList = [
                SELECT Id, Monthly_amount__c, CalculateDate__c
                FROM opportunity_amount_plan__c
                WHERE Opportunityplan_name__c =: opptyPlanId
                ORDER BY CalculateDate__c
        ];

        if(returnList.isEmpty()) {
            returnList = new List<opportunity_amount_plan__c>();
        }

        System.debug('@returnList: ' + returnList);
        return returnList;
    }

    @AuraEnabled
    public static void updateAmountList(String opptyPlanId, String infoMapString, String monthListString) {
        System.debug('@@infoMapString: ' + infoMapString);

        Opportunity_plan__c target = [
                SELECT Id, Name, WBS_CC__c, Parent_Opportunity__c, BaseYear__c, //2024.01.08 dgchoi BaseYear__c 조회 추가
                       OwnerId, AccountId__c, AccountId__r.Name, Owner.isActive
                FROM Opportunity_plan__c
                WHERE Id =: opptyPlanId
                LIMIT 1
        ];

        Integer baseYear = Integer.valueOf(target.BaseYear__c); //2024.01.08 dgchoi 정산일자 년도 BaseYear로 수정

        List<Map<String, String>> infoList  = (List<Map<String, String>>) JSON.deserialize(infoMapString, List<Map<String, String>>.class);
        List<Map<String, String>> monthList = (List<Map<String, String>>) JSON.deserialize(monthListString, List<Map<String, String>>.class);

        Map<String, String> infoMap = new Map<String, String>();
        for(Map<String, String> info : infoList) {
            infoMap.put(info.get('key'), info.get('value'));
        }
        System.debug(infoMap);

        List<opportunity_amount_plan__c> upsertList = getAmountList(opptyPlanId);

        if(upsertList.size() > 0) {
            for(Integer i=0; i<upsertList.size(); i++) {
                //infoMap
                for(String tmpKey : infoMap.keySet()) {
                    if(tmpKey != 'Opportunityplan_name__c') upsertList[i].put(tmpKey, infoMap.get(tmpKey));
                }

                //monthList
                upsertList[i].Monthly_amount__c   = Decimal.valueOf(monthList[i].get('price'));
                upsertList[i].OpportunityCheck__c = true;
                if(target.OwnerId != null && target.Owner.IsActive == true) upsertList[i].OwnerId__c = target.OwnerId; //2023.06.07 dgchoi 조건 추가 : Active된 유저만 복제
            }
        } else { //처음 생성 시
            for(Integer i=0; i<12; i++) {
                opportunity_amount_plan__c amt = new opportunity_amount_plan__c();
                for(String tmpKey : infoMap.keySet()) {
                    amt.put(tmpKey, infoMap.get(tmpKey));
                }
                amt.Opportunityplan_name__c = opptyPlanId;
                amt.Name                    = i+1 + '월_' + target.Name + '_' + target.AccountId__r.Name; //N월_아이템관리Name_계정Name
                amt.CalculateDate__c        = Date.newInstance(baseYear, i+1, 1);
                amt.Monthly_amount__c       = Decimal.valueOf(monthList[i].get('price'));
                amt.OpportunityCheck__c     = true;
                if(target.OwnerId != null && target.Owner.IsActive == true) amt.OwnerId__c = target.OwnerId; //2023.06.07 dgchoi 조건 추가 : Active된 유저만 복제

                upsertList.add(amt);
            }
        }

        System.debug('@upsertList: ' + upsertList);
        if(upsertList.size()>0) upsert upsertList;
    }

    @AuraEnabled(cacheable=true)
    public static boolean hasOpptyAmount(String opptyPlanId){
        List<opportunity_amount_plan__c> checkList = getOpptyAmount(opptyPlanId);

        if(checkList.isEmpty()) {
            return false;
        }
        return true;
    }

    @AuraEnabled
    public static String deleteOpptyAmount(String opptyPlanId){
        try {
            List<opportunity_amount_plan__c> deleteList = getOpptyAmount(opptyPlanId);

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
    public static List<opportunity_amount_plan__c> getOpptyAmount(String opptyPlanId) {
        List<opportunity_amount_plan__c> returnList = [
                SELECT Id, Name, WBS_CC__c, AccountId__c,
                        StageName__c, CalculateDate__c,
                        Monthly_amount__c, Opportunityplan_name__c, Parent_Opportunity__c
                FROM opportunity_amount_plan__c
                WHERE Opportunityplan_name__c =: opptyPlanId
        ];

        System.debug('@opptyId: ' + opptyPlanId);
        System.debug('@returnList[Opportunity_Amount]: ' +returnList);
        System.debug('@returnList isEmpty?: ' + returnList.isEmpty());

        if(returnList.isEmpty()) {
            returnList = new List<opportunity_amount_plan__c>();
        }
        return returnList;
    }
}