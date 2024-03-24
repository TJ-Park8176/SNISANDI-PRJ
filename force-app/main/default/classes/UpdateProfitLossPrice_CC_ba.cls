/**
 * Created by MZC01-DGCHOI on 2023-10-18.
 */

/**
 * @description 호출 : Database.executeBatch(new UpdateProfitLossPrice_CC_ba(), 10);
 */
public with sharing class UpdateProfitLossPrice_CC_ba implements Database.Batchable<SObject>, Database.Stateful {

    public Boolean isMonday      = false;
    public Boolean isThirdMonday = false;

    public Boolean isFailed = false;
    public String ERROR_MSG = '';

    public UpdateProfitLossPrice_CC_ba() {
        Date stdDate = Date.today();
        checkMonday(stdDate);
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator(
                ' SELECT Id, Name, Check_WBS_CC_ZF__c, Ebitda_target__c, General__c, OperationsHeadquarters__c, Team__c, AccountSubjectSort__c, WBS_Code__c ' +
                ' FROM WBSandCC__c ' +
                ' WHERE Check_WBS_CC_ZF__c = \'CC\' '
        );
    }

    public void execute(Database.BatchableContext context, List<WBSandCC__c> scope) {
        try {
            IF_ProfitLoss.makeNewRecord('CC', scope);

            System.debug('scope: ' + scope);

            Set<Id> wbsIdSet = new Set<Id>();
    
            for(WBSandCC__c wbs : scope) {
                wbsIdSet.add(wbs.Id);
            }
    
            System.debug('wbsIdSet: ' + wbsIdSet);
    
            List<ProfitandLoss__c> plList        = getProfitLossListByWBS(wbsIdSet);
            Map<String, Decimal> ebitdaCostMap_Y = getEbitdaCostMapByWBS_Y(wbsIdSet);
            Map<String, Decimal> ebitdaCostMap_P = getEbitdaCostMapByWBS_P(wbsIdSet);
    
            System.debug('ebitdaCostMap_Y: ' + ebitdaCostMap_Y);
            System.debug('ebitdaCostMap_P: ' + ebitdaCostMap_P);
    
            for(ProfitandLoss__c p : plList) {
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
            if(!Test.isRunningTest() && this.isMonday) {
                //마감
                Database.executeBatch(new ClosingObjectCopy_ba('Opportunity'), 2000);

                //주간예상
                ct_ObjectCopy.copyObject('weeklyExpect', 'Amount__c');

                //실행계획(매출~수주매출) - 24.01.21 dgchoi
                ct_ObjectCopy.copyObject('actionPlan', 'Amount__c');

                /*
                //실행계획(수주/수주매출) - 23.07.12 dgchoi
                ct_ObjectCopy.copyObject('actionPlan', 'Opportunity');

                if(this.isThirdMonday) {
                    //실행계획(매출/매입/손익)
                    ct_ObjectCopy.copyObject('actionPlan', 'Amount__c');
                }
                */                
            }
        } else {
            String title = 'S&I: [손익현황-CC] 계산 실패';
            String body = 'UpdateProfitLossPrice_CC_ba :::::: ' + this.ERROR_MSG;

            EmailController.sendEmail(title, body);
        }
    }

    /**
     * @return 손익계산 List
     */
    public List<ProfitandLoss__c> getProfitLossListByWBS(Set<Id> wbsIdSet) { //wbs-정산월

        for(Id wbsId : wbsIdSet) {
            System.debug(wbsId);
        }

        List<ProfitandLoss__c> plList = [
                SELECT Id,
                       Profit_Calculate_month__c,
                       WBS__c,
                       AccountSubjectSelect__r.Name,
                       ProfitandLoss_Type__c,
                       WBS__r.AccountSubjectSort__c
                FROM ProfitandLoss__c
                WHERE WBS__c IN :wbsIdSet
                AND Calculate_month__c = THIS_YEAR
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
                       SUM(PurchaseAmount__c) SUM_AMOUNT
                FROM Cost__c
                WHERE LowerSorta__c IN ('(용)감가상각비', '(용)무형자산상각', '(용)산업재산권상각')
                AND CalculateDate__c = THIS_YEAR
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
                       SUM(PurchaseAmount__c) SUM_AMOUNT
                FROM Cost__c
                WHERE LowerSorta__c IN ('(판)감가상각비', '(판)무형자산상각', '(판)산업재산권상각')
                AND CalculateDate__c = THIS_YEAR
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

    private void checkMonday(Date stdDate) {
        WeekNumber weekNumber = new WeekNumber(stdDate);

        Datetime stdDateTime = Datetime.newInstance(stdDate.year(), stdDate.month(), stdDate.day());
        String dayOfWeek = stdDateTime.format('E');

        if(dayOfWeek == 'Mon') { //월요일
            this.isMonday = true;
            if(weekNumber.batchWeekOfMonth == 3) { //3주차
                this.isThirdMonday = true;
            }
        }
    }

}