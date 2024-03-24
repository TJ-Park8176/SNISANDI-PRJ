/**
 * Created by MZC01-DGCHOI on 2023-02-27.
 */

public with sharing class EbitdaPerformance_ba implements Database.Batchable<SObject>, Database.Stateful {

    /*
        EbitdaPerformance_ba
        - Performance__c : 실적 : EBITDA 데이터셋 생성 & 금액 계산

        TestCode : ct_ObjectEBITDA_Test
    */

    public AccountSubject__c accSubEbitda;

    public Boolean isFailed = false;
    public String ERROR_MSG = '';
    public Date batchDate = Date.newInstance(Date.today().year(), Date.today().month()-1, 1);

    public EbitdaPerformance_ba() {
        this.accSubEbitda = getAccountSubjectEbitda();
    }

    public List<WBSandCC__c> start(Database.BatchableContext context) {
        //A: 전월 실적의 전체 WBS/CC Id Set (EBITDA 제외)
        List<AggregateResult> totalAgg = [
                SELECT WBS__c
                FROM Performance__c
                WHERE Performance_Month__c = :batchDate.month() //LAST_MONTH
                AND CALENDAR_YEAR(PerformanceMonth__c) = :batchDate.year()
                AND Real_Data_check__c = TRUE
                AND WBS__r.Check_WBS_CC_ZF__c IN ('WBS','CC')
                AND AccountSubjectCodea__c != 'A5'
                GROUP BY WBS__c
        ];

        System.debug('totalAgg::::' + totalAgg.size());
        System.debug('totalAgg::::' + totalAgg);

        //B: 전월 실적에서 EBITDA 있는 WBS/CC Id Set
        List<AggregateResult> ebitdaAgg = [
                SELECT WBS__c
                FROM Performance__c
                WHERE Performance_Month__c = :batchDate.month() //LAST_MONTH
                AND CALENDAR_YEAR(PerformanceMonth__c) = :batchDate.year()
                AND Real_Data_check__c = TRUE
                AND WBS__r.Check_WBS_CC_ZF__c IN ('WBS','CC')
                AND AccountSubjectCodea__c = 'A5'
                GROUP BY WBS__c
        ];

        System.debug('ebitdaAgg::::' + ebitdaAgg.size());
        System.debug('ebitdaAgg::::' + ebitdaAgg);

        //A-B WBS/CC Id EBITDA return....
        Set<Id> totalWBSSet = new Set<Id>();
        Set<Id> ebitdaWBSSet = new Set<Id>();

        for(AggregateResult agg : totalAgg) {
            totalWBSSet.add((Id) agg.get('WBS__c'));
        }

        for(AggregateResult agg : ebitdaAgg) {
            ebitdaWBSSet.add((Id) agg.get('WBS__c'));
        }

        totalWBSSet.removeAll(ebitdaWBSSet);

        List<WBSandCC__c> returnList = [
                SELECT Id, Name, WBS_Code__c
                FROM WBSandCC__c
                WHERE Id IN :totalWBSSet
        ];

        System.debug('returnList size :::: ' + returnList.size());
        return returnList;
    }

    public void execute(Database.BatchableContext context, List<WBSandCC__c> scope) {
        try {
            Map<String, Double> salesMap = getSalesProfitPerformance(); //WBS ID - 영업이익2 금액
            Map<String, Double> costMap  = getEbitdaCostMap(); //WBS ID - 감가삼각비, 무형자산상각, 산업재산권상각 금액

            List<Performance__c> upsertList = new List<Performance__c>();

            for(WBSandCC__c wbs : scope) {
                Performance__c p = new Performance__c();

                String mapKey = wbs.Id;
                Double salesAmt = salesMap.containsKey(mapKey) ? salesMap.get(mapKey) : 0;
                Double costAmt  = costMap.containsKey(mapKey) ? costMap.get(mapKey) : 0;

                //p.Name = tmpDate.month() + '월_' + wbs.Name;
                p.Name = 'EBITDA';
                p.PerformanceMonth__c = this.batchDate;
                p.AccountSubjectSelect__c = accSubEbitda.Id;
                p.WBS__c = wbs.Id;
                p.PerformanceAmount__c = salesAmt + costAmt;
                p.Performance_External_ID__c = wbs.WBS_Code__c + '-' +
                                             + accSubEbitda.AccountSubjectCode__c + '-' +
                                             + this.batchDate.year() + '-' +
                                             + this.batchDate.month();
                upsertList.add(p);
            }

            System.debug('upsertList SIZE: ' + upsertList.size());
            System.debug('@upsertList: ' + upsertList);
            if(upsertList.size() > 0) upsert upsertList;
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
            title = 'S&I: [실적] EBITDA 업로드 실패';
            body = this.ERROR_MSG;
        } else {
            title = 'S&I: [실적] EBITDA 업로드 완료';
            body = '[실적] EBITDA 업로드 되었습니다.';
        }

        EmailController.sendEmail(title, body);
    }


    private AccountSubject__c getAccountSubjectEbitda() {
        AccountSubject__c accSub = [
                SELECT Id, AccountSubjectCode__c
                FROM AccountSubject__c
                WHERE AccountSubjectCode__c = 'A5'
                LIMIT 1
        ];
        return accSub;
    }

    //지난달 영업이익2 실적
    private Map<String, Double> getSalesProfitPerformance() {
        List<AggregateResult> aggList = [
                SELECT WBS__c, SUM(PerformanceAmount__c) SUM_AMOUNT
                FROM Performance__c
                WHERE AccountSubjectCodea__c = 'A4' //영업이익2
                AND Performance_Month__c = :batchDate.month() //LAST_MONTH
                AND CALENDAR_YEAR(PerformanceMonth__c) = :batchDate.year()
                AND WBS__r.Check_WBS_CC_ZF__c IN ('WBS', 'CC')
                GROUP BY WBS__c
        ];

        return aggToMap(aggList);
    }

    //EBITDA 계산 Map
    private Map<String, Double> getEbitdaCostMap() {
        List<AggregateResult> aggList = [
                SELECT WBS__c, SUM(PerformanceAmount__c) SUM_AMOUNT
                FROM Performance__c
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
                AND Performance_Month__c = :batchDate.month() //LAST_MONTH
                AND CALENDAR_YEAR(PerformanceMonth__c) = :batchDate.year()
                GROUP BY WBS__c
        ];

        return aggToMap(aggList);
    }

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
}