/**
 * Created by MZC01-DGCHOI on 2023-01-19.
 */

public with sharing class ProfitLossPlan_tr extends TriggerHandler { //사업계획(손익)

    private List<ProfitandLoss_Plan__c> listNew = (List<ProfitandLoss_Plan__c>) Trigger.new;

    public override void beforeInsert() {
        linkLookupField(); //hidden필드 Lookup
    }

    public override void afterInsert() {
        //updateEbitdaAmount(); //EBITDA 금액 업데이트
        //copyByProfitLoss(); //손익계산 복제
    }

    private void linkLookupField() {
        //사업계획(손익) Lookup
        Map<String, Id> wbsMap = getWbsCodeMap();
        Map<String, Id> accSubMap = getAccSubCodeMap();

        for(ProfitandLoss_Plan__c pp : listNew) {
            //WBS
            if(pp.WBS_Code_Hidden__c != null && pp.WBS__c == null)
                pp.WBS__c = wbsMap.get(pp.WBS_Code_Hidden__c);

            //계정과목
            if(pp.AccountSubjectCode_hidden__c != null && pp.AccountSubjectselect__c == null)
                pp.AccountSubjectselect__c = accSubMap.get(pp.AccountSubjectCode_hidden__c);
        }
        System.debug('beforeInsert END listNew: ' + listNew);

    }

    /*
    private void updateEbitdaAmount() {
        Set<Id> idSet = new Set<Id>();

        for(ProfitandLoss_Plan__c pp : listNew) {
            idSet.add(pp.Id);
        }

        Map<String, Double> salesMap = getSalesProfitPlan(); //WBS ID - 영업이익2 금액
        Map<String, Double> costMap = getEbitdaCostMap(); //매입 -감가삼각비, 무형자산상각, 산업재산권상각

        List<ProfitandLoss_Plan__c> targetList = getEbitdaProfitPlan(idSet);

        if(targetList.size()>0)  {
            for(ProfitandLoss_Plan__c target : targetList) {
                String mapKey = target.WBS__c;

                Double salesAmt = salesMap.containsKey(mapKey) ? salesMap.get(mapKey) : 0;
                Double costAmt  = costMap.containsKey(mapKey) ? costMap.get(mapKey) : 0;

                target.Amount__c = salesAmt + costAmt;
            }
            update targetList;
        }
    }
    */

    /*
    private void copyByProfitLoss() {
        //손익계산 복제
        List<ProfitandLoss__c> insertList = new List<ProfitandLoss__c>();

        for(ProfitandLoss_Plan__c pp : listNew) {
            ProfitandLoss__c p = new ProfitandLoss__c();

            //Lookup
            if(pp.WBS__c != null)                  p.WBS__c                  = pp.WBS__c;
            if(pp.AccountSubjectselect__c != null) p.AccountSubjectselect__c = pp.AccountSubjectselect__c;
            if(pp.OwnerId != null)                 p.OwnerId                 = pp.OwnerId;

            //그외 필드
            if(pp.Amount__c != null)               p.Amount__c               = pp.Amount__c;
            if(pp.Name != null)                    p.Name                    = pp.Name;
            if(pp.Calculate_month__c != null)      p.Calculate_month__c      = pp.Calculate_month__c;
            if(pp.ProfitandLoss_Type__c != null)   p.ProfitandLoss_Type__c   = pp.ProfitandLoss_Type__c;

            insertList.add(p);
        }

        System.debug('@insertList SIZE: ' + insertList.size());
        System.debug('@insertList: ' + insertList);

        if(insertList.size() > 0) insert insertList;
    }
    */

    private Map<String, Id> getWBSCodeMap() {
        Set<String> wbsCodeSet = new Set<String>();
        for(ProfitandLoss_Plan__c pp : listNew) {
            wbsCodeSet.add(pp.WBS_Code_Hidden__c);
        }

        List<WBSandCC__c> wbsList = [
                SELECT id, WBS_Code__c
                FROM WBSandCC__c
                WHERE WBS_Code__c IN: wbsCodeSet
        ];

        Map<String, Id> returnMap = new Map<String, Id>();
        for(WBSandCC__c w : wbsList) {
            returnMap.put(w.WBS_Code__c, w.Id);
        }

        return returnMap;
    }

    private Map<String, Id> getAccSubCodeMap() {
        Set<String> accSubCodeSet = new Set<String>();
        for(ProfitandLoss_Plan__c ap : listNew) {
            accSubCodeSet.add(ap.AccountSubjectCode_hidden__c);
        }

        List<AccountSubject__c> accSubList = [
                SELECT Id, AccountSubjectCode__c
                FROM AccountSubject__c
                WHERE AccountSubjectCode__c IN: accSubCodeSet
        ];

        Map<String, Id> returnMap = new Map<String, Id>();
        for(AccountSubject__c a : accSubList) {
            returnMap.put(a.AccountSubjectCode__c, a.Id);
        }

        return returnMap;
    }

    /*
    private List<ProfitandLoss_Plan__c> getEbitdaProfitPlan(Set<Id> idSet) {
        List<ProfitandLoss_Plan__c> returnList = [
                SELECT Id, WBS__c
                FROM ProfitandLoss_Plan__c
                WHERE Id IN :idSet
                AND WBS__r.Check_WBS_CC_ZF__c IN ('WBS', 'CC')
                AND AccountSubjectCodea__c = 'A5' //계정과목 EBITDA
        ];
        return returnList;
    }

    //지난달 영업이익2 실적
    private Map<String, Double> getSalesProfitPlan() {
        List<AggregateResult> aggList = [
                SELECT WBS__c, SUM(Amount__c) SUM_AMOUNT
                FROM ProfitandLoss_Plan__c
                WHERE AccountSubjectCodea__c = 'A4' //영업이익2
                AND Calculate_month__c = LAST_MONTH //달 어떻게 들어오나?
                AND WBS__r.Check_WBS_CC_ZF__c IN ('WBS', 'CC')
                GROUP BY WBS__c
        ];

        return aggToMap(aggList);
    }

     */


    /*
    //지난달 매입 계산 Map
    private Map<String, Double> getEbitdaCostMap() {
        List<AggregateResult> aggList = [
                SELECT WBS__c, SUM(PlanPurchaseAmount__c) SUM_AMOUNT
                FROM Cost_Plan__c
                WHERE (
                        (
                                LowerSorta__c IN ('(용)감가상각비', '(용)무형자산상각', '(용)산업재산권상각')
                                AND
                                (
                                        WBS__r.Check_WBS_CC_ZF__c = 'WBS'
                                        OR
                                        (WBS__r.Check_WBS_CC_ZF__c = 'CC' AND WBS__r.AccountSubjectSort__c = '용')
                                )
                        )
                        OR
                        (
                                LowerSorta__c IN ('(판)감가상각비', '(판)무형자산상각', '(판)산업재산권상각')
                                AND
                                (WBS__r.Check_WBS_CC_ZF__c = 'CC' AND WBS__r.AccountSubjectSort__c = '판')
                        )
                )
                AND CalculateDate__c = LAST_MONTH
                AND Real_Data_check__c = true
                GROUP BY WBS__c
        ];

        return aggToMap(aggList);
    }
    */

    /*
    private static Map<String, Double> aggToMap(List<AggregateResult> aggList) {
        System.debug('---------aggToMap()---------');
        Map<String, Double> returnMap = new Map<String, Double>();

        for(AggregateResult agg : aggList) {
            //키 매핑 (wbs)
            String aggKey = String.valueOf(agg.get('WBS__c'));
            Double aggSum = agg.get('SUM_AMOUNT') != null ? Double.valueOf(agg.get('SUM_AMOUNT')) : 0;
            returnMap.put(aggKey, aggSum);
        }

        System.debug('@returnMap: ' + returnMap);
        return returnMap;
    }

     */

}