/**
* 사업계획 매입 소유주 변경 배치
*/


public with sharing class temp_CostPlan_ba implements Database.Batchable<sObject>, Database.Stateful {

    public Database.QueryLocator start(Database.BatchableContext BC) {
        System.debug('KDCE_ExpireCoupon_ba Start!!');

        // 오브젝트에 해당하는 전체 필드 가져오기
        //List<String> ExpireCouponType = new List<String>();
        //ExpireCouponType.add(KDCE_GlobalValue.COUPON_TYPE_CVS_DUO_CARE_49K);
        //ExpireCouponType.add(KDCE_GlobalValue.COUPON_TYPE_CVSMGM);
        String query = '';
        query += ' SELECT ';
        query += ' ItemManagement_Plan__c, ItemManagement_Plan__r.WBS_CC__c, wbs__r.TrackingHeadQuarters__c, id, WBS__c, Itemmanagementcheck__c';
        query += ' FROM Cost_Plan__c';
        query += ' WHERE calculateDate__c  = this_year';

        System.debug('query => ' + query);

        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<sObject> scopes) {
        if(!scopes.isEmpty()) {
            List<Cost_Plan__c> updateCost = new List<Cost_Plan__c>();
            for (Cost_Plan__c cs : (List<Cost_Plan__c>)scopes) {
                if(cs.ItemManagement_Plan__r.WBS_CC__c != cs.WBS__c) {
                    cs.Wbs__c = cs.ItemManagement_Plan__r.WBS_CC__c;
                    cs.Itemmanagementcheck__c = true;
                    updateCost.add(cs);
                }
            }
            if(!updateCost.isEmpty()) update updateCost;
        }

    }


    public void finish(Database.BatchableContext BC) {
    }
}