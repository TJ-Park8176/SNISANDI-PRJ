/**
 * Created by MZC01-DGCHOI on 2023-10-18.
 */

/**
 * @description 호출 : Database.executeBatch(new UpdateProfitLossPrice_CC_ba(), 10);
 */
public with sharing class UpdateProfitLossPlanPrice_CC_ba implements Database.Batchable<SObject>, Database.Stateful {

    public String baseYear = '';

    public Boolean isFailed = false;
    public String ERROR_MSG = '';

    public UpdateProfitLossPlanPrice_CC_ba(String baseYear) {
        this.baseYear = baseYear;
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        //어제자 WBS 생성된거 있으면 껍데기 생성
        return Database.getQueryLocator(
                ' SELECT Id, Name, Check_WBS_CC_ZF__c, Ebitda_target__c, General__c, OperationsHeadquarters__c, Team__c, AccountSubjectSort__c, WBS_Code__c ' +
                ' FROM WBSandCC__c ' +
                ' WHERE Check_WBS_CC_ZF__c = \'CC\' '
        );
    }

    public void execute(Database.BatchableContext context, List<WBSandCC__c> scope) {
        try {

            IF_ProfitLossPlan.makeNewRecord('CC', scope, Integer.valueOf(this.baseYear));

            System.debug('scope: ' + scope);

            Set<Id> wbsIdSet = new Set<Id>();
    
            for(WBSandCC__c wbs : scope) {
                wbsIdSet.add(wbs.Id);
            }
    
            System.debug('wbsIdSet: ' + wbsIdSet);
    
            List<ProfitandLoss_Plan__c> plList   = getProfitLossListByWBS(wbsIdSet);
            Map<String, Decimal> ebitdaCostMap_Y = getEbitdaCostMapByWBS_Y(wbsIdSet);
            Map<String, Decimal> ebitdaCostMap_P = getEbitdaCostMapByWBS_P(wbsIdSet);
    
            System.debug('ebitdaCostMap_Y: ' + ebitdaCostMap_Y);
            System.debug('ebitdaCostMap_P: ' + ebitdaCostMap_P);
    
    
    
            for(ProfitandLoss_Plan__c p : plList) {
                String plKey = p.WBS__c + '-' + p.Profit_Calculate_month__c;
                if(p.WBS__r.AccountSubjectSort__c == '용') {
                    p.Amount__c = ebitdaCostMap_Y.containsKey(plKey) ? convertValue(ebitdaCostMap_Y.get(plKey)) : 0;
                } else if(p.WBS__r.AccountSubjectSort__c == '판') {
                    p.Amount__c = ebitdaCostMap_P.containsKey(plKey) ? convertValue(ebitdaCostMap_P.get(plKey)) : 0;
                }
            }
    
            System.debug('updateList: ' + plList);
            if(plList.size() > 0) update plList;
        } catch (Exception e) {
            System.debug(e.getMessage());
            System.debug(e.getLineNumber());

            this.isFailed = true;
            this.ERROR_MSG = e.getMessage();
        }
        
    }

    public void finish(Database.BatchableContext context) {
        System.debug(':::::::: UpdateProfitLossPrice_CC_ba finish ::::::::');

        if(!isFailed) {
            String title = 'S&I: [사업계획(손익)] 계산 완료';
            String body = '사업계획(손익) 금액 업데이트가 완료되었습니다.';

            EmailController.sendEmail(title, body);
        } else {
            String title = 'S&I: [사업계획(손익)] 계산 실패';
            String body = 'UpdateProfitLossPlanPrice_CC_ba :::::: ' + this.ERROR_MSG;

            EmailController.sendEmail(title, body);
        }
    }

    /**
     * @return 손익계산 List
     */
    public List<ProfitandLoss_Plan__c> getProfitLossListByWBS(Set<Id> wbsIdSet) { //wbs-정산월

        for(Id wbsId : wbsIdSet) {
            System.debug(wbsId);
        }

        List<ProfitandLoss_Plan__c> plList = [
                SELECT Id,
                       Profit_Calculate_month__c,
                       WBS__c,
                       AccountSubjectselect__r.Name,
                       ProfitandLoss_Type__c,
                       WBS__r.AccountSubjectSort__c
                FROM ProfitandLoss_Plan__c
                WHERE WBS__c IN :wbsIdSet
                AND BaseYear__c = :this.baseYear
        ];
        return plList;
    }

    /**
     * @return EBITDA 계산 Map - 용
     */
    public Map<String, Decimal> getEbitdaCostMapByWBS_Y(Set<Id> wbsIdSet) {
        List<AggregateResult> ebitdaAggList = [
                SELECT WBS__c,
                       CALENDAR_MONTH(CalculateDate__c) CAL_MONTH,
                       SUM(PlanPurchaseAmount__c) SUM_AMOUNT
                FROM Cost_Plan__c
                WHERE LowerSorta__c IN ('(용)감가상각비', '(용)무형자산상각', '(용)산업재산권상각')
                AND BaseYear__c = :this.baseYear
                AND WBS__c IN :wbsIdSet
                GROUP BY WBS__c, CALENDAR_MONTH(CalculateDate__c)
                ORDER BY WBS__c, CALENDAR_MONTH(CalculateDate__c)
        ];
        System.debug('매입 : 용 ' + ebitdaAggList);
        return aggToMap(ebitdaAggList);
    }

    /**
     * @return EBITDA 계산 Map - 판
     */
    public Map<String, Decimal> getEbitdaCostMapByWBS_P(Set<Id> wbsIdSet) {
        List<AggregateResult> ebitdaAggList = [
                SELECT WBS__c,
                       CALENDAR_MONTH(CalculateDate__c) CAL_MONTH,
                       SUM(PlanPurchaseAmount__c) SUM_AMOUNT
                FROM Cost_Plan__c
                WHERE LowerSorta__c IN ('(판)감가상각비', '(판)무형자산상각', '(판)산업재산권상각')
                AND BaseYear__c = :this.baseYear
                AND WBS__c IN :wbsIdSet
                GROUP BY WBS__c, CALENDAR_MONTH(CalculateDate__c)
                ORDER BY WBS__c, CALENDAR_MONTH(CalculateDate__c)
        ];
        return aggToMap(ebitdaAggList);
    }

    public static Map<String, Decimal> aggToMap(List<AggregateResult> aggList) {
        System.debug('---------aggToMap()---------');
        Map<String, Decimal> returnMap = new Map<String, Decimal>();

        for(AggregateResult agg : aggList) {
            //키 매핑 (wbs - 계정과목 - 실적일자)
            String aggKey = agg.get('WBS__c') + '-' + agg.get('CAL_MONTH'); //WBS-월
            if(!returnMap.containsKey(aggKey)) { //가장 최근 시점데이터 기준으로 가져올때 유효....
                Decimal aggSum = (Decimal) agg.get('SUM_AMOUNT');
                returnMap.put(aggKey, aggSum);
            }
        }

        System.debug('@returnMap: ' + returnMap);
        return returnMap;
    }

    public Decimal convertValue(Decimal value) {
        return value.setScale(0);
    }


}