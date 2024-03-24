/**
 * Created by MZC01-DGCHOI on 2022-12-30.
 */

/**
 * 손익현황 업데이트 - CC
 */
public without sharing class CalcEBITDA_CC_Batch implements Database.Batchable<sObject>, Database.Stateful {

    public Set<Id> wbsIdSet;

    public Boolean isMonday = false;
    public Boolean isThirdMonday = false;

    public CalcEBITDA_CC_Batch() {
        this.wbsIdSet = new Set<Id>();

        /*
        Batch_Setting__mdt settingMdt = [
                SELECT Label, stdDate__c
                FROM Batch_Setting__mdt
                WHERE Label = 'test'
                LIMIT 1
        ];

        Date stdDate = settingMdt.stdDate__c;
         */

        Date stdDate = Date.today();
        checkMonday(stdDate);
    }

    public List<WBSandCC__c> start(Database.BatchableContext context) {
        //어제자 WBS 생성된거 있으면 껍데기 생성
        List<WBSandCC__c> newList = IF_ProfitLoss.getNewCC();
        if(newList.size() > 0) {
            IF_ProfitLoss.makeNewRecord('CC');
        }

        List<WBSandCC__c> wbsList = [
                SELECT Id, Name, Check_WBS_CC_ZF__c, Ebitda_target__c, General__c, OperationsHeadquarters__c, Team__c, AccountSubjectSort__c
                FROM WBSandCC__c
                WHERE Check_WBS_CC_ZF__c = 'CC'
        ];

        return wbsList;
    }

    public void execute(Database.BatchableContext context, List<WBSandCC__c> scope) {

        for(WBSandCC__c wbs : scope) {
            this.wbsIdSet.add(wbs.Id);
        }

        //손익계산
        List<ProfitandLoss__c> plList = getProfitLossList();

        Map<String, Decimal> ebitdaCostMap_Y = getEbitdaCostMap_Y();
        Map<String, Decimal> ebitdaCostMap_P = getEbitdaCostMap_P();

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
    }

    /**
     * @description
     *     월요일일 경우 3개 Batch 동시 실행됨
     *     (마감, 주간예상, 실행계획)
     *
     *     1)월요일 : 마감 복제, 주간예상 복제
     *     2)3주차 월요일 : 마감 복제, 주간예상 복제, 실행계획 복제
     */
    public void finish(Database.BatchableContext context) {
        System.debug('--------------finish----------');

        if(!Test.isRunningTest() && this.isMonday) {
            //마감
            Database.executeBatch(new ClosingObjectCopy_ba('Opportunity'), 2000);

            //주간예상
            ct_ObjectCopy.copyObject('weeklyExpect', 'Amount__c');

            //실행계획(수주/수주매출) - 23.07.12 dgchoi
            ct_ObjectCopy.copyObject('actionPlan', 'Opportunity');

            if(this.isThirdMonday) {
                //실행계획(매출/매입/손익)
                ct_ObjectCopy.copyObject('actionPlan', 'Amount__c');
            }
        }
    }

    /**
     * @return 손익계산 List
     */
    public List<ProfitandLoss__c> getProfitLossList() { //wbs-정산월
        List<ProfitandLoss__c> plList = [
                SELECT id, Profit_Calculate_month__c, WBS__c,
                       AccountSubjectSelect__r.Name, ProfitandLoss_Type__c,
                       WBS__r.AccountSubjectSort__c
                FROM ProfitandLoss__c
                WHERE WBS__c IN :this.wbsIdSet
                AND Calculate_month__c = THIS_YEAR
        ];
        return plList;
    }

    /**
     * @return EBITDA 계산 Map - 용
     */
    public Map<String, Decimal> getEbitdaCostMap_Y() {
        List<AggregateResult> ebitdaAggList = [
                SELECT WBS__c, CALENDAR_MONTH(CalculateDate__c) CAL_MONTH, SUM(PurchaseAmount__c) SUM_AMOUNT
                FROM Cost__c
                WHERE LowerSorta__c IN ('(용)감가상각비', '(용)무형자산상각', '(용)산업재산권상각')
                AND CalculateDate__c = THIS_YEAR
                AND WBS__c IN :this.wbsIdSet
                GROUP BY WBS__c, CALENDAR_MONTH(CalculateDate__c)
                ORDER BY WBS__c, CALENDAR_MONTH(CalculateDate__c)
        ];
        System.debug('매입 : 용 ' + ebitdaAggList);
        return aggToMap(ebitdaAggList);
    }

    /**
     * @return EBITDA 계산 Map - 판
     */
    public Map<String, Decimal> getEbitdaCostMap_P() {
        List<AggregateResult> ebitdaAggList = [
                SELECT WBS__c, CALENDAR_MONTH(CalculateDate__c) CAL_MONTH, SUM(PurchaseAmount__c) SUM_AMOUNT
                FROM Cost__c
                WHERE LowerSorta__c IN ('(판)감가상각비', '(판)무형자산상각', '(판)산업재산권상각')
                AND CalculateDate__c = THIS_YEAR
                AND WBS__c IN :this.wbsIdSet
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

        DateTime stdDateTime = DateTime.newInstance(stdDate.year(), stdDate.month(), stdDate.day());
        String dayOfWeek = stdDateTime.format('E');

        if(dayOfWeek == 'Mon') { //월요일
            this.isMonday = true;
            if(weekNumber.batchWeekOfMonth == 3) { //3주차
                this.isThirdMonday = true;
            }
        }
    }
}