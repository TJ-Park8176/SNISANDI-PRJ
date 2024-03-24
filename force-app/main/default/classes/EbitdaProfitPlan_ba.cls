/**
 * Created by MZC01-DGCHOI on 2023-02-27.
 */

public with sharing class EbitdaProfitPlan_ba implements Database.Batchable<SObject>, Database.Stateful{

    /*
        EbitdaPerformance_ba
        - ProfitandLoss_Plan__c : 사업계획(손익) : EBITDA 금액 계산
     */

    public Boolean isFailed = false;
    public String ERROR_MSG = '';

    public List<ProfitandLoss_Plan__c> start(Database.BatchableContext context) {
        List<ProfitandLoss_Plan__c> returnList = [
                SELECT Id, WBS__c, Calculate_month__c
                FROM ProfitandLoss_Plan__c
                WHERE AccountSubjectCodea__c = 'A5' //EBITDA
                AND WBS__r.Check_WBS_CC_ZF__c IN ('WBS', 'CC')
                AND Calculate_month__c = THIS_YEAR
        ];

        return returnList;
    }

    public void execute(Database.BatchableContext context, List<ProfitandLoss_Plan__c> scope) {
        try {
            Set<Id> wbsIdSet = new Set<Id>();

            for(ProfitandLoss_Plan__c pp : scope) {
                wbsIdSet.add(pp.WBS__c);
            }

            Map<String, Double> salesMap = getSalesProfitPlan(wbsIdSet); //WBS ID - 영업이익2 금액
            Map<String, Double> costMap = getEbitdaCostMap(wbsIdSet); //매입 -감가삼각비, 무형자산상각, 산업재산권상각

            for(ProfitandLoss_Plan__c pp : scope) {
                String mapKey = pp.WBS__c + '-' + pp.Calculate_month__c.month();

                Double salesAmt = salesMap.containsKey(mapKey) ? salesMap.get(mapKey) : 0;
                Double costAmt  = costMap.containsKey(mapKey) ? costMap.get(mapKey) : 0;

                pp.Amount__c = salesAmt + costAmt;
            }

            update scope;
        } catch (Exception e) {
            System.debug(e.getMessage());
            System.debug(e.getLineNumber());

            this.isFailed = true;
            this.ERROR_MSG = e.getMessage();
        }
    }

    public void finish(Database.BatchableContext context) {
        System.debug('---------------finish---------------');
        String title = '';
        String body = '';

        if(isFailed) {
            title = 'S&I: [사업계획(손익)] EBITDA 업데이트 실패';
            body = this.ERROR_MSG;
        } else {
            title = 'S&I: [사업계획(손익)] EBITDA 업데이트 완료';
            body = '[사업계획(손익)] EBITDA 업데이트 되었습니다.';
        }

        EmailController.sendEmail(title, body);
    }

    //지난달 영업이익2 실적
    private Map<String, Double> getSalesProfitPlan(Set<Id> wbsIdSet) {
        List<AggregateResult> aggList = [
                SELECT WBS__c, SUM(Amount__c) SUM_AMOUNT, CALENDAR_MONTH(Calculate_month__c) CAL_MONTH
                FROM ProfitandLoss_Plan__c
                WHERE AccountSubjectCodea__c = 'A4' //영업이익2
                AND Calculate_month__c = THIS_YEAR
                AND WBS__c IN :wbsIdSet
                GROUP BY WBS__c, CALENDAR_MONTH(Calculate_month__c)
        ];

        return aggToMap(aggList);
    }

    //지난달 매입 계산 Map
    private Map<String, Double> getEbitdaCostMap(Set<Id> wbsIdSet) {
        List<AggregateResult> aggList = [
                SELECT WBS__c, SUM(PlanPurchaseAmount__c) SUM_AMOUNT, CALENDAR_MONTH(CalculateDate__c) CAL_MONTH
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
                AND CalculateDate__c = THIS_YEAR
                AND Real_Data_check__c = TRUE
                AND WBS__c IN :wbsIdSet
                GROUP BY WBS__c, CALENDAR_MONTH(CalculateDate__c)
        ];

        return aggToMap(aggList);
    }

    private static Map<String, Double> aggToMap(List<AggregateResult> aggList) {
        System.debug('---------aggToMap()---------');
        Map<String, Double> returnMap = new Map<String, Double>();

        for(AggregateResult agg : aggList) {
            //키 매핑 (wbs)
            String aggKey = String.valueOf(agg.get('WBS__c')) + '-' + String.valueOf(agg.get('CAL_MONTH'));
            Double aggSum = agg.get('SUM_AMOUNT') != null ? Double.valueOf(agg.get('SUM_AMOUNT')) : 0;
            returnMap.put(aggKey, aggSum);
        }

        System.debug('@returnMap: ' + returnMap);
        return returnMap;
    }


}