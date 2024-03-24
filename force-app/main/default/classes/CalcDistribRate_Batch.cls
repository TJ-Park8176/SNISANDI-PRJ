/**
 * Created by MZC01-DGCHOI on 2022-12-21.
 */

public with sharing class CalcDistribRate_Batch implements Database.Batchable<sObject>, Database.Stateful { //실적 배부 비율 업데이트

    public List<String> GENERAL_NAME_ARR = new List<String> {
            '사업총괄', '리노베이션총괄', '영업총괄'
    };
    public String batchGeneralName;
    public Integer batchIndex = 0; //배치 타입(총괄별(GENERAL_NAME_ARR)) 실행 index
    public Integer chunkNum = 1; //배치 실행 순서

    //실패 처리
    public List<String> errorMsgArr = new List<String>();

    //실적 배부 비율 산출
    public List<WBSandCC__c> start(Database.BatchableContext context) {

        //어제자 WBS의 실적 배부비율 생성
        if (this.batchIndex == 0) {
            //처음 배치 실행시 어제자 신규 WBS있는지 체크
            List<WBSandCC__c> newWBSList = getNewWBSList();

            if (newWBSList.size() > 0) {
                createNewPDRList(newWBSList); //이번달 이후 실적배부비율만 생성됨
            }
        }

        this.batchGeneralName = GENERAL_NAME_ARR[batchIndex];

        System.debug(this.batchGeneralName + ' START');

        //업데이트 할 실적 배부 비율
        List<WBSandCC__c> wbsList = new List<WBSandCC__c>();

        switch on this.batchGeneralName {
            when '사업총괄' {
                wbsList = [
                        SELECT Id, Name, General__c, OperationsHeadquarters__c
                        FROM WBSandCC__c
                        WHERE Check_WBS_CC_ZF__c = 'WBS'
                        AND General__c = :batchGeneralName
                        AND (
                                OperationsHeadquarters__c IN (
                                '남부1본부', '남부2본부', 
                                '서울1본부', '서울2본부', '서울3본부', '서울4본부', '서울5본부', '서울6본부', 
                                '중부1본부', '중부2본부',
                                '해외사업본부'
                            )
                            OR
                            (
                                Team__c IN (
                                    'FM기술팀', 'U+KAM', '보안사업TF', '통신서비스팀', '프로젝트대기(사업)', '한국타이어KAM'
                                )
                            )
                        )
                ];
            }
            when '리노베이션총괄' {
                wbsList = [
                        SELECT Id, Name, General__c, Team__c
                        FROM WBSandCC__c
                        WHERE Check_WBS_CC_ZF__c = 'WBS'
                        AND General__c = :batchGeneralName
                        AND Team__c IN (
                            '공장보전공사팀', '리노베이션팀', '연구보전공사팀', '프로젝트대기(공사)'
                        )
                ];
            }
            when '영업총괄' {
                wbsList = [
                        SELECT Id, Name, General__c, Team__c
                        FROM WBSandCC__c
                        WHERE Check_WBS_CC_ZF__c = 'WBS'
                        AND General__c = :batchGeneralName
                        AND (
                            Team__c IN ('기업부동산팀', '영업1팀', '영업2팀', '영업3팀')
                            OR
                            (
                                OperationsHeadquarters__c = 'PM사업본부'
                                AND 
                                Team__c IN ('PM사업1팀', 'PM사업2팀')
                            )
                        )
                ];
            }
        }

        System.debug('@wbsList: ' + wbsList);
        return wbsList;
    }

    public void execute(Database.BatchableContext context, List<WBSandCC__c> scope) {
        try {
            Set<Id> wbsIdSet = new Set<Id>();

            for (WBSandCC__c wbs : scope) {
                wbsIdSet.add(wbs.Id);
            }

            System.debug(wbsIdSet);

            List<Performance_Distribute_Rate__c> updateList = [
                    SELECT Id, Calculate_month__c, Calculate_month_F__c, Name,
                            WBS_CC__c, WBS_CC__r.OperationsHeadquarters__c, WBS_CC__r.Team__c
                    FROM Performance_Distribute_Rate__c
                    WHERE WBS_CC__c IN :wbsIdSet
                    AND Calculate_month__c = THIS_YEAR
            ];
            System.debug('@before updateList: ' + updateList);

            //총괄 별 WBS
            switch on this.batchGeneralName {
                when '사업총괄' {
                    //매출액 - WBS
                    Map<String, Double> wbsAmountMap = aggToMap_WBS(getAmountByWBS(wbsIdSet)); //key: WBS-정산월
                    //매출액 - 운영본부(OC)
                    Map<String, Double> ocAmountMap = aggToMap_OC(getAmountByOC(wbsIdSet)); //key: 운영본부-정산월
                    //급여와임금 - WBS
                    Map<String, Double> wbsCostMap = aggToMap_WBS(getCostByWBS(wbsIdSet)); //key: WBS-정산월
                    //급여와임금 - 운영본부(OC)
                    Map<String, Double> ocCostMap = aggToMap_OC(getCostByOC(wbsIdSet)); //key: 운영본부-정산월

                    //                System.debug('매출액 - WBS: ' + wbsAmountMap.get('a060w000003my7UAAQ-12'));
                    //                System.debug('매출액 - 운영본부: ' + ocAmountMap.get('서울1본부-12'));
                    //                System.debug('급여와임금 - WBS: ' + wbsCostMap.get('a060w000003my7UAAQ-12'));
                    //                System.debug('급여와임금 - 운영본부: ' + ocCostMap.get('서울1본부-12'));

                    for (Performance_Distribute_Rate__c pdr : updateList) {
                        String wbsKey = pdr.WBS_CC__c + '-' + pdr.Calculate_month_F__c;
                        String ocKey = pdr.WBS_CC__r.OperationsHeadquarters__c + '-' + pdr.Calculate_month_F__c;

                        //null Check
                        Double amount_price = (wbsAmountMap.get(wbsKey) != null) ? wbsAmountMap.get(wbsKey) : 0;
                        Double amount_total_price = (ocAmountMap.get(ocKey) != null) ? ocAmountMap.get(ocKey) : 0;
                        Double cost_price = (wbsCostMap.get(wbsKey) != null) ? wbsCostMap.get(wbsKey) : 0;
                        Double cost_total_price = (ocCostMap.get(ocKey) != null) ? ocCostMap.get(ocKey) : 0;

                        pdr.Month_Amount__c = amount_price; //매출액
                        pdr.Wages_salaries__c = cost_price; //급여와임금

                        Decimal amount_rate_calc = (amount_total_price == 0) ? 0 : amount_price / amount_total_price * 100; //매출비
                        pdr.Amount_rate__c = amount_rate_calc.setScale(2);

                        Decimal wages_salaries_rate_calc = (cost_total_price == 0) ? 0 : cost_price / cost_total_price * 100; //금여와임금비
                        pdr.Wages_salaries_rate__c = wages_salaries_rate_calc.setScale(2);
                        pdr.Allocation_rate__c = 50; //할당비
                        //실적배부비율 : formula

                        System.debug(pdr);
                    }
                }
                when '리노베이션총괄', '영업총괄' {
                    //매출액 - WBS
                    Map<String, Double> wbsAmountMap = aggToMap_WBS(getAmountByWBS(wbsIdSet));
                    //매출액 - 팀
                    Map<String, Double> teamAmountMap = aggToMap_Team(getAmountByTeam(wbsIdSet));
                    //급여와임금 - WBS
                    Map<String, Double> wbsCostMap = aggToMap_WBS(getCostByWBS(wbsIdSet));
                    //급여와임금 - 팀
                    Map<String, Double> teamCostMap = aggToMap_Team(getCostByTeam(wbsIdSet));

                    for (Performance_Distribute_Rate__c pdr : updateList) {
                        String wbsKey = pdr.WBS_CC__c + '-' + pdr.Calculate_month_F__c;
                        String teamKey = pdr.WBS_CC__r.Team__c + '-' + pdr.Calculate_month_F__c;

                        //null Check
                        Double amount_price = (wbsAmountMap.get(wbsKey) != null) ? wbsAmountMap.get(wbsKey) : 0;
                        Double amount_total_price = (teamAmountMap.get(teamKey) != null) ? teamAmountMap.get(teamKey) : 0;
                        Double cost_price = (wbsCostMap.get(wbsKey) != null) ? wbsCostMap.get(wbsKey) : 0;
                        Double cost_total_price = (teamCostMap.get(teamKey) != null) ? teamCostMap.get(teamKey) : 0;

                        pdr.Month_Amount__c = amount_price; //매출액
                        pdr.Wages_salaries__c = cost_price; //급여와임금
                        pdr.Amount_rate__c = (amount_total_price == 0) ? 0 : amount_price / amount_total_price * 100; //매출비
                        pdr.Wages_salaries_rate__c = (cost_total_price == 0) ? 0 : cost_price / cost_total_price * 100; //금여와임금비
                        pdr.Allocation_rate__c = 50; //할당비
                        //실적배부비율 : formula
                    }
                }
            }

            System.debug('@after updateList: ' + updateList);
            if (updateList.size() > 0) update updateList;
        } catch (Exception e) {
            errorMsgArr.add(chunkNum + '번째 배치 ::: ' + e.getMessage());
        }

        this.chunkNum++;
    }

    public void finish(Database.BatchableContext context) {
        System.debug('--------------finish----------');

        if (this.batchIndex < GENERAL_NAME_ARR.size() - 1) { //0,1
            CalcDistribRate_Batch batch = new CalcDistribRate_Batch();
            batch.batchIndex  = this.batchIndex + 1;
            batch.chunkNum    = this.chunkNum + 1;
            batch.errorMsgArr = this.errorMsgArr;
            
            Database.executeBatch(batch, 10);
        } else { //마지막 인덱스(2)
            if(errorMsgArr.size() > 0) {
                //메일전송
                EmailController.sendEmail(
                'S&I: [실적 배부 비율] 업데이트 실패',
                'CalcDistribRate_Batch ::::::: '
                    + String.join(errorMsgArr, ', ')
                );
            } else {
                Database.executeBatch(new SenderPrice_ba(), 10); //그룹 10개씩 잘라서 계산
            }

            /*
            //간접비 배부액 업데이트
            CalcDistribOHE calcOHE = new CalcDistribOHE();
            calcOHE.calcEnterpriseCost();
            calcOHE.calcChargeCost();
            calcOHE.calcTeamCost();

            //손익계산-WBS 배치
            CalcEBITDA_WBS_Batch wbsBatch = new CalcEBITDA_WBS_Batch();
            Database.executeBatch(wbsBatch, 10); //10개정도씩....
            */
        }
    }

    //매출액 - WBS
    public List<AggregateResult> getAmountByWBS(Set<Id> wbsIdSet) {
        List<AggregateResult> aggList = [
                SELECT WBS__c,
                        CALENDAR_MONTH(CalculateDate__c) CAL_MONTH, SUM(PredictAmount__c) SUM_AMOUNT
                FROM Amount__c
                WHERE UpperSorta__c = '매출액'
                AND WBS__c IN :wbsIdSet
                AND WBS__r.Check_WBS_CC_ZF__c = 'WBS'
                AND CalculateDate__c = THIS_YEAR
                GROUP BY WBS__c, CALENDAR_MONTH(CalculateDate__c)
                ORDER BY WBS__c, CALENDAR_MONTH(CalculateDate__c)
        ];
        return aggList;
    }

    //매출액 - OC
    public List<AggregateResult> getAmountByOC(Set<Id> wbsIdSet) {
        List<AggregateResult> aggList = [
                SELECT WBS__r.OperationsHeadquarters__c,
                        CALENDAR_MONTH(CalculateDate__c) CAL_MONTH, SUM(PredictAmount__c) SUM_AMOUNT
                FROM Amount__c
                WHERE UpperSorta__c = '매출액'
                AND WBS__r.Check_WBS_CC_ZF__c = 'WBS'
                AND CalculateDate__c = THIS_YEAR
                AND WBS__r.OperationsHeadquarters__c != null
                GROUP BY WBS__r.OperationsHeadquarters__c, CALENDAR_MONTH(CalculateDate__c)
        ];
        return aggList;
    }

    //매출액 - Team
    public List<AggregateResult> getAmountByTeam(Set<Id> wbsIdSet) {
        List<AggregateResult> aggList = [
                SELECT WBS__r.Team__c,
                        CALENDAR_MONTH(CalculateDate__c) CAL_MONTH, SUM(PredictAmount__c) SUM_AMOUNT
                FROM Amount__c
                WHERE UpperSorta__c = '매출액'
                AND WBS__r.Check_WBS_CC_ZF__c = 'WBS'
                AND CalculateDate__c = THIS_YEAR
                AND WBS__r.Team__c != null
                GROUP BY WBS__r.Team__c, CALENDAR_MONTH(CalculateDate__c)
        ];
        return aggList;
    }

    //급여와임금 - WBS
    public List<AggregateResult> getCostByWBS(Set<Id> wbsIdSet) {
        List<AggregateResult> aggList = [
                SELECT WBS__c,
                        CALENDAR_MONTH(CalculateDate__c) CAL_MONTH, SUM(PurchaseAmount__c) SUM_AMOUNT
                FROM Cost__c
                WHERE LowerSorta__c = '(용)급여와임금'
                AND WBS__c IN :wbsIdSet
                AND WBS__r.Check_WBS_CC_ZF__c = 'WBS'
                AND CalculateDate__c = THIS_YEAR
                GROUP BY WBS__c, CALENDAR_MONTH(CalculateDate__c)
                ORDER BY WBS__c, CALENDAR_MONTH(CalculateDate__c)
        ];
        return aggList;
    }

    //급여와임금 - OC
    public List<AggregateResult> getCostByOC(Set<Id> wbsIdSet) {
        List<AggregateResult> aggList = [
                SELECT WBS__r.OperationsHeadquarters__c,
                        CALENDAR_MONTH(CalculateDate__c) CAL_MONTH, SUM(PurchaseAmount__c) SUM_AMOUNT
                FROM Cost__c
                WHERE LowerSorta__c = '(용)급여와임금'
                AND WBS__r.Check_WBS_CC_ZF__c = 'WBS'
                AND CalculateDate__c = THIS_YEAR
                AND WBS__r.OperationsHeadquarters__c != null
                GROUP BY WBS__r.OperationsHeadquarters__c, CALENDAR_MONTH(CalculateDate__c)
        ];
        return aggList;
    }

    //급여와임금 - Team
    public List<AggregateResult> getCostByTeam(Set<Id> wbsIdSet) {
        List<AggregateResult> aggList = [
                SELECT WBS__r.Team__c,
                        CALENDAR_MONTH(CalculateDate__c) CAL_MONTH, SUM(PurchaseAmount__c) SUM_AMOUNT
                FROM Cost__c
                WHERE LowerSorta__c = '(용)급여와임금'
                AND WBS__r.Check_WBS_CC_ZF__c = 'WBS'
                AND CalculateDate__c = THIS_YEAR
                AND WBS__r.Team__c != null
                GROUP BY WBS__r.Team__c, CALENDAR_MONTH(CalculateDate__c)
        ];
        return aggList;
    }

    public Map<String, Double> aggToMap_WBS(List<AggregateResult> aggList) { //WBS별 금액 매핑
        Map<String, Double> returnMap = new Map<String, Double>();

        for (AggregateResult agg : aggList) {
            String aggKey = agg.get('WBS__c') + '-' + agg.get('CAL_MONTH'); //WBS - 정산월
            Double aggSum = Double.valueOf(agg.get('SUM_AMOUNT'));
            returnMap.put(aggKey, aggSum);
        }

        System.debug('@returnMap: ' + returnMap);
        return returnMap;
    }

    public Map<String, Double> aggToMap_OC(List<AggregateResult> aggList) { //운영본부별 금액 매핑
        Map<String, Double> returnMap = new Map<String, Double>();

        for (AggregateResult agg : aggList) {
            String aggKey = agg.get('OperationsHeadquarters__c') + '-' + agg.get('CAL_MONTH'); //WBS - 정산월
            Double aggSum = Double.valueOf(agg.get('SUM_AMOUNT'));
            returnMap.put(aggKey, aggSum);
        }

        System.debug('@returnMap: ' + returnMap);
        return returnMap;
    }

    public Map<String, Double> aggToMap_Team(List<AggregateResult> aggList) { //팀별 금액 매핑
        Map<String, Double> returnMap = new Map<String, Double>();

        for (Aggregateresult agg : aggList) {
            String aggKey = agg.get('Team__c') + '-' + agg.get('CAL_MONTH'); //WBS - 정산월
            Double aggSum = Double.valueOf(agg.get('SUM_AMOUNT'));
            returnMap.put(aggKey, aggSum);
        }

        System.debug('@returnMap: ' + returnMap);
        return returnMap;
    }

    public List<WBSandCC__c> getNewWBSList() {
        List<WBSandCC__c> newWBSList = new List<WBSandCC__c>();

        List<WBSandCC__c> lastWBSList = [
                SELECT Id, Name
                FROM WBSandCC__c
                WHERE CreatedDate = YESTERDAY //YESTERDAY
                AND Check_WBS_CC_ZF__c = 'WBS'
        ];

        if (lastWBSList.size() > 0) {

            Set<Id> lastWBSIdSet = new Set<Id>();
            Set<Id> existWBSIdSet = new Set<Id>();

            List<AggregateResult> existWBSList = [
                    SELECT WBS_CC__c
                    FROM Performance_Distribute_Rate__c
                    GROUP BY WBS_CC__c
            ];

            for (WBSandCC__c wbs : lastWBSList) {
                lastWBSIdSet.add(wbs.Id);
            }
            for (AggregateResult agg : existWBSList) {
                existWBSIdSet.add((Id)agg.get('WBS_CC__c'));
            }

            lastWBSIdSet.removeAll(existWBSIdSet);

            newWBSList = [
                    SELECT Id, Name
                    FROM WBSandCC__c
                    WHERE Id IN :lastWBSIdSet
            ];
        }

        return newWBSList;
    }

    public void createNewPDRList(List<WBSandCC__c> newWBSList) {
        List<Performance_Distribute_Rate__c> insertList = new List<Performance_Distribute_Rate__c>();

        for (WBSandCC__c wbs : newWBSList) {
            for (Integer i = Date.today().month(); i <= 12; i++) {
                Performance_Distribute_Rate__c pdr = new Performance_Distribute_Rate__c();
                pdr.Name = i + '월_' + wbs.Name;
                pdr.Calculate_month__c = Date.newInstance(Date.today().year(), i, 1);
                pdr.WBS_CC__c = wbs.Id;
                insertList.add(pdr);
            }
        }

        System.debug('@insertList: ' + insertList);
        if (insertList.size() > 0) insert insertList;
    }

}