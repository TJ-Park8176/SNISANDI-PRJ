/**
 * Created by MZC01-DGCHOI on 2023-01-18.
 */

public with sharing class Performance_tr extends TriggerHandler{

    private List<Performance__c> listNew = (List<Performance__c>) Trigger.new;

    private Set<Id> wbsIdSet = new Set<Id>();

    public override void beforeInsert() {
        setExternalID();
    }

    public override void beforeUpdate() {
        setExternalID();
    }

    public override void afterInsert() {
        System.debug('listNew SIZE:' + Trigger.new.size());

        if(checkWBSCC() && checkZFNone()) {
            //체크완료시 ZF, 계정과목 가져와서 insert
            System.debug('check TRUE');
            List<AccountSubject__c> accSubList = getAccountSubjectSet();
            List<WBSandCC__c> wbsList = getZFList();

            System.debug('계정과목 수 ' + accSubList.size());
            System.debug('wbs 수 : ' + wbsList.size());

            List<Performance__c> upsertList = new List<Performance__c>();
            for(WBSandCC__c wbs : wbsList) { //ZF
                for(AccountSubject__c accSub : accSubList) {
                    Date tmpDate = Date.newInstance(Date.today().year(), Date.today().month()-1, 1);

                    Performance__c performance = new Performance__c();
                    performance.Name = tmpDate.month() + '월_' + wbs.Name;
                    performance.PerformanceMonth__c = tmpDate;
                    performance.AccountSubjectSelect__c = accSub.Id;
                    performance.WBS__c = wbs.Id;
                    performance.PerformanceAmount__c = 0;
                    performance.Performance_External_ID__c
                            = wbs.WBS_Code__c + '-' +
                            + accSub.AccountSubjectCode__c + '-' +
                            + tmpDate.year() + '-' +
                            + tmpDate.month();

                    upsertList.add(performance);
                }
            }

            System.debug('upsertList SIZE: ' + upsertList.size());
            System.debug('@upsertList: ' + upsertList);
            if(upsertList.size() > 0) upsert upsertList;
        }

        for(Performance__c p : listNew) {
            this.wbsIdSet.add(p.WBS__c);
        }

        /*
        if(checkEBITDANone()) {
            //EBITDA 껍데기 없으면 생성
            List<WBSandCC__c> wbsList = getWBSList();

            AccountSubject__c accSub = getAccountSubjectEbitda();

            List<Performance__c> upsertList = new List<Performance__c>();

            for(WBSandCC__c wbs : wbsList) { //WBS,CC 껍데기 생성
                Date tmpDate = Date.newInstance(Date.today().year(), Date.today().month()-1, 1);

                Performance__c performance = new Performance__c();
                performance.Name = tmpDate.month() + '월_' + wbs.Name;
                performance.PerformanceMonth__c = tmpDate;
                performance.AccountSubjectSelect__c = accSub.Id;
                performance.WBS__c = wbs.Id;
                performance.PerformanceAmount__c = 0; //금액 값 산출
                performance.Performance_External_ID__c
                        = wbs.WBS_Code__c + '-' +
                        + accSub.AccountSubjectCode__c + '-' +
                        + tmpDate.year() + '-' +
                        + tmpDate.month();

                upsertList.add(performance);
            }

            System.debug('upsertList SIZE: ' + upsertList.size());
            System.debug('@upsertList: ' + upsertList);
            if(upsertList.size() > 0) upsert upsertList;
        }

        updateEbitdaAmount();
        */

    }

    /*
    private void updateEbitdaAmount() {

        Map<String, Double> salesMap = getSalesProfitPerformance(); //WBS ID - 영업이익2 금액
        Map<String, Double> costMap = getEbitdaCostMap(); //감가삼각비, 무형자산상각, 산업재산권상각

        List<Performance__c> targetList = getEbitdaPerformance();

        if(targetList.size() > 0) {
            for(Performance__c target : targetList) {
                String mapKey = target.WBS__c;

                Double salesAmt = salesMap.containsKey(mapKey) ? salesMap.get(mapKey) : 0;
                Double costAmt  = costMap.containsKey(mapKey) ? costMap.get(mapKey) : 0;

                target.PerformanceAmount__c = salesAmt + costAmt;
            }

            update targetList;
        }
    }

     */

    private Boolean checkWBSCC() { //ZF아니면 true
        //Trigger.new 의 WBS/CC구분값 체크
        if(listNew[0].WBS__r.Check_WBS_CC_ZF__c != 'ZF') { ////0번쨰 인덱스만 체크하면 되나????
            return true;
        }
        return false;
    }

    private Boolean checkZFNone() { //없으면 true
        //전체 실적 시점일자 이전 달 ZF 있는지 체크
        List<Performance__c> zfList = [SELECT Id FROM Performance__c
                                       WHERE PerformanceMonth__c = LAST_MONTH
                                       AND CreatedDate = THIS_MONTH
                                       AND WBS__r.Check_WBS_CC_ZF__c = 'ZF'];
        if(zfList.size() > 0) return false;
        return true;
    }

    /*
    private Boolean checkEBITDANone() { //업으면 true
        //전체 실적 시점일자 이전 달 EBITDA 있는지 체크
        List<Performance__c> ebitdaList = [SELECT Id FROM Performance__c
                                           WHERE PerformanceMonth__c = LAST_MONTH
                                           AND AccountSubjectCodea__c = 'A5'  //A5: EBITDA 계정과목 코드
                                           AND WBS__c IN: this.wbsIdSet];
        if(ebitdaList.size() > 0) return false;
        return true;
    }
     */

    /*
    private AccountSubject__c getAccountSubjectEbitda() {
        AccountSubject__c accSub = [
                SELECT Id, AccountSubjectCode__c
                FROM AccountSubject__c
                WHERE AccountSubjectCode__c = 'A5'
                LIMIT 1
        ];
        return accSub;
    }
     */

    private List<AccountSubject__c> getAccountSubjectSet() {
        List<AccountSubject__c> returnList = [
                SELECT Id, AccountSubjectCode__c
                FROM AccountSubject__c
                WHERE AccountSubjectCode__c IN ('4105110', 'A1', 'A5')
        ];
        //매출총이익1, 용역매출-관리용역료, EBITDA

        System.debug('getAccountSubject: ' + returnList);

        if(returnList.size() > 0) return returnList;

        return new List<AccountSubject__c>();
    }

    private List<WBSandCC__c> getZFList() {
        List<WBSandCC__c> returnList = [
                SELECT Id, Name, WBS_Code__c
                FROM WBSandCC__c
                WHERE Check_WBS_CC_ZF__c = 'ZF'
        ];

        if(returnList.size() > 0) return returnList;
        return new List<WBSandCC__c>();
    }

    /*
    private List<WBSandCC__c> getWBSList() {
        List<WBSandCC__c> returnList = [
                SELECT Id, Name, WBS_Code__c
                FROM WBSandCC__c
                WHERE Id IN :this.wbsIdSet
        ];

        return returnList;
    }
     */

    /*
    private List<Performance__c> getEbitdaPerformance() {
        List<Performance__c> returnList = [
                SELECT Id, WBS__c
                FROM Performance__c
                WHERE PerformanceMonth__c = LAST_MONTH
                AND WBS__c IN: this.wbsIdSet
                AND AccountSubjectCodea__c = 'A5' //EBITDA
        ];

        return returnList;
    }
     */

    /*
    //지난달 영업이익2 실적
    private Map<String, Double> getSalesProfitPerformance() {
        List<AggregateResult> aggList = [
                SELECT WBS__c, SUM(PerformanceAmount__c) SUM_AMOUNT
                FROM Performance__c
                WHERE AccountSubjectCodea__c = 'A4' //영업이익2
                AND PerformanceMonth__c = LAST_MONTH
                AND WBS__r.Check_WBS_CC_ZF__c IN ('WBS', 'CC')
                GROUP BY WBS__c
        ];

        return aggToMap(aggList);
    }
     */

    /*
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
                AND PerformanceMonth__c = LAST_MONTH
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

    private void setExternalID() {
        for(Performance__c p : listNew) {
            if(p.Real_Data_check__c) { //실제 데이터
                p.Performance_External_ID__c = p.Performance_External_ID_Hidden__c;
            } else if(p.Performance_External_ID__c == null){ //dummy중에 external ID 없으면 만들어주기....
                p.Performance_External_ID__c = p.Performance_External_ID_Hidden__c + '-dummy';
            }

        }
    }
}