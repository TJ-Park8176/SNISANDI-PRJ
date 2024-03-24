/**
 * Created by MZC01-DGCHOI on 2023-10-17.
 */

/**
 * @description 호출 : Database.executeBatch(new UpdateProfitLossPrice_WBS_ba(), 10);
 */
public with sharing class UpdateProfitLossPlanPrice_WBS_ba implements Database.Batchable<SObject>, Database.Stateful {

    public Boolean isFailed = false;
    public String ERROR_MSG = '';

    public String baseYear = '';

    public UpdateProfitLossPlanPrice_WBS_ba(String baseYear) {
        this.baseYear = baseYear;
    }

    /**
     * @param context
     *
     * @return WBS 10개씩 리턴해야함
     */
    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator(
                ' SELECT Id, Name, Check_WBS_CC_ZF__c, Ebitda_target__c, General__c, OperationsHeadquarters__c, Team__c, WBS_Code__c ' +
                ' FROM WBSandCC__c ' +
                ' WHERE Check_WBS_CC_ZF__c = \'WBS\' ' +
                ' AND (Team__c != null OR OperationsHeadquarters__c != null) '
        );
    }

    public void execute(Database.BatchableContext context, List<WBSandCC__c> scope) {

        IF_ProfitLossPlan.makeNewRecord('WBS', scope, Integer.valueOf(this.baseYear));

        //추가 계정과목 (3) dgchoi 23.12.29 - Group의 계정과목이자, 손익의 Type
        //추가1. 사업간지원비_배부(용)
        //추가2. (판)사업전담지원비
        //추가3. (판)사업간지원비

        // 1.법인지원비(기타) : Group - 법인(기타) - Receiver Team
        /*
        1. 간접비 배부액 - (WBS - 법인지원비(기타) - N월)
        2. 실적 배부 비율 - (WBS - N월)
        -업데이트 대상
        손익계산 레코드 - (N월 - WBS - 법인지원비-기타_배부(판))   //계정과목 코드 : 9100002
        */

        // 2.법인지원비(안전)
        /*
        1. 간접비 배부액 - (WBS - 법인지원비(안전) - N월)
        2. 실적 배부 비율 - (WBS - N월)
        -업데이트 대상
        손익계산 레코드 - (N월 - WBS - 법인지원비-안전보건관리비_배부(판))   //계정과목 코드 : 9100011
        */

        // 3.담당지원비
        /*
        1. 간접비 배부액 - (WBS - 담당지원비 - N월)
        2. 실적 배부 비율(동일)
        -업데이트 대상
        손익계산 레코드 - (N월 - WBS - 담당지원비)   // 계정과목 코드 : 9100008
         */

        // 4.팀지원비
        /*
        -준비물
        1. 간접비 배부액 - (WBS - 팀지원비 - N월)
        2. 실적 배부 비율(동일)
        -업데이트 대상
        손익계산 레코드 - (N월 - WBS - 팀지원비_배부(용))    // 계정과목 코드 : 9100007
         */

        // 5.매출총이익1
        /*
        매출(WBS-N월) 키로 매출액(상위구분) Mapping
        - 매입(WBS-N월) 키로 총매출원가(상위구분) Mapping
         */

        // 6.매출총이익2  //로직변경 23.12.29
        /*
        매총1 - (담당지원비 + 팀지원비 + 사업간지원비_배부(용)) 
         */

        // 7.영업이익1   //로직변경 23.12.29
        /*
        매총2 - ((판)사업전담지원비 + (판)사업간지원비)
         */

        // 8.영업이익2
        /*
        영업이익1 - 전사지원비
         */

        // 9.EBITDA
        /*
        영업이익2 - 매입(WBS-N월) 키로 '(용)감가상각비'(하위구분) Mapping
         */

        try {
            // WBS - 조직키 Map
            Map<Id, String> wbsOrgMap = new Map<Id, String>();
            Set<Id> wbsIdSet          = new Set<Id>();
            Set<String> operationSet  = new Set<String>();
            Set<String> teamSet       = new Set<String>();
            String orgKey             = '';

            for(WBSandCC__c wbs : scope) {
                System.debug('::::::: execute scope :::::::');
                System.debug('::::::: id ::::::::::' + wbs.Id); //a060w000003nXUgAAM
                System.debug('::::::: 총괄 :::::::::' + wbs.General__c);
                System.debug('::::::: 운영 본부 ::::' + wbs.OperationsHeadquarters__c);
                System.debug('::::::: 팀 ::::::::::' + wbs.Team__c);

                //소속 구분 기준
                if(wbs.OperationsHeadquarters__c != null) {
                    orgKey = '본부-' + wbs.OperationsHeadquarters__c;
                    operationSet.add(wbs.OperationsHeadquarters__c);
                } else if(wbs.Team__c != null) {
                    orgKey = '팀-' + wbs.Team__c;
                    teamSet.add(wbs.Team__c);
                } else {
                    continue;
                }

                wbsOrgMap.put(wbs.Id, orgKey);
                wbsIdSet.add(wbs.Id);
            }

            // 실적 배부 비율 Map - key:WBS-정산월
            Map<String, Decimal> distributeRateMap = getDistributeRateMapByWBS(wbsIdSet);

            // 손익현황 Map
            // key1: wbs-정산월, key2: 손익계산유형(지원비)
            Map<String, Map<String, ProfitandLoss_Plan__c>> plMap = getProfitLossMapByWBS(wbsIdSet);

            //조직키 - ccId Map
            Map<String, Id> orgCcMap = new Map<String, Id>();

            List<WBSandCC__c> ccList = [
                    SELECT Id, OperationsHeadquarters__c, Team__c
                    FROM WBSandCC__c
                    WHERE Check_WBS_CC_ZF__c = 'CC'
                    AND (
                            OperationsHeadquarters__c IN: operationSet
                            OR
                            Team__c IN: teamSet
                    )
                    AND Team_OperationsHeadquarters__c = true //Receiver Team Member에 있는 CC들
            ];

            System.debug('operationSet : ' + operationSet);
            System.debug('teamSet : ' + teamSet);
            System.debug('ccList : ' + ccList);

            for(WBSandCC__c cc : ccList) {
                String key = '';
                if(cc.OperationsHeadquarters__c != null) {
                    key = '본부-' + cc.OperationsHeadquarters__c;
                } else if(cc.Team__c != null) {
                    key = '팀-' + cc.Team__c;
                }
                orgCcMap.put(key, cc.Id);
            }

            System.debug('wbsOrgMap : ' + wbsOrgMap);
            System.debug('orgCcMap : ' + orgCcMap);

            //wbsId - ccId Map
            Map<Id, Id> wbsCcMap = new Map<Id, Id>();

            for(Id wbsId : wbsOrgMap.keySet()) {
                orgKey      = wbsOrgMap.get(wbsId);
                String ccId = orgCcMap.get(orgKey);

                wbsCcMap.put(wbsId, ccId);
            }

            //Receiver Price
            Map<String, Decimal> ccReceiverPriceMap = new Map<String, Decimal>();

            Set<Id> ccIdSet = new Set<Id>(wbsCcMap.values());
            ccIdSet.remove(null);

/*        List<Receiver_Price__c> receiverPrices = [
                SELECT Id, Receiver_Team_Member__r.CC__c, Calculate_Month__c, Price__c, Group__r.AccountSubject__c
                FROM Receiver_Price__c
                WHERE Receiver_Team_Member__r.CC__c IN: ccIdSet
                AND Latest_Version__c = TRUE
        ];*/

            List<AggregateResult> receiverPrices = [
                    SELECT Receiver_Team_Member__r.CC__c CC,
                           Group__r.AccountSubject__c ACC_SUB,
                           Calculate_Month__c MON,
                           SUM(Price__c) SUM_PRICE
                    FROM Plan_Receiver_Price__c
                    GROUP BY Receiver_Team_Member__r.CC__c, Group__r.AccountSubject__c, Calculate_Month__c
            ];

            System.debug('wbsCcMap : ' + wbsCcMap);
            System.debug('wbsCcMap.values() : ' + wbsCcMap.values());
            System.debug('receiverPrices : ' + receiverPrices);

/*        for(Receiver_Price__c r : receiverPrices) {
            ccReceiverPriceMap.put(
                    r.Receiver_Team_Member__r.CC__c + '-' + r.Group__r.AccountSubject__c + '-' + r.Calculate_Month__c, //ccId-계정과목-정산월
                    r.Price__c
            );
        }*/
            for(AggregateResult agg : receiverPrices) {
                ccReceiverPriceMap.put(
                        agg.get('CC') + '-' + agg.get('ACC_SUB') + '-' + agg.get('MON'),
                        Decimal.valueOf(String.valueOf(agg.get('SUM_PRICE')))
                );
            }

            System.debug('ccReceiverPriceMap :::: ' + ccReceiverPriceMap);

            //매출총이익 Map
            Map<String, Decimal> amount1Map    = getAmount1MapByWBS(wbsIdSet);
            //ebitda 계산 Map
            Map<String, Decimal> ebitdaCostMap = getEbitdaCostMapByWBS(wbsIdSet);

            //wbs-계정과목-정산월
            for(String plKey : plMap.keySet()) {
                Map<String, ProfitandLoss_Plan__c> innerMap = plMap.get(plKey);

                System.debug('plKey ::: ' + plKey);

                ProfitandLoss_Plan__c pl_enterprise_etc      = innerMap.get('법인지원비(기타)');
                ProfitandLoss_Plan__c pl_enterprise_safe     = innerMap.get('법인지원비(안전)');
                ProfitandLoss_Plan__c pl_charge              = innerMap.get('담당지원비');
                ProfitandLoss_Plan__c pl_team                = innerMap.get('팀지원비');
                ProfitandLoss_Plan__c pl_interBizSupportY    = innerMap.get('사업간지원비_배부(용)'); //추가 계정과목 23.12.29
                ProfitandLoss_Plan__c pl_dedicateBizSupportP = innerMap.get('(판)사업전담지원비');    //추가 계정과목 23.12.29
                ProfitandLoss_Plan__c pl_interBizSupportP    = innerMap.get('(판)사업간지원비');      //추가 계정과목 23.12.29
                ProfitandLoss_Plan__c pl_amount1             = innerMap.get('매출총이익1');
                ProfitandLoss_Plan__c pl_amount2             = innerMap.get('매출총이익2');
                ProfitandLoss_Plan__c pl_sales1              = innerMap.get('영업이익1');
                ProfitandLoss_Plan__c pl_sales2              = innerMap.get('영업이익2');
                ProfitandLoss_Plan__c pl_ebitda              = innerMap.get('EBITDA');

                Decimal stdRate = distributeRateMap.containsKey(plKey) ? distributeRateMap.get(plKey) : 0; //실적 배부 비율
                System.debug('@@stdRate: ' + stdRate);

                String stdWBS   = plKey.split('-')[0];
                String stdMonth = plKey.split('-')[1];
                String stdCC    = wbsCcMap.get(stdWBS);

                System.debug('@@stdWBS : ' + stdWBS);
                System.debug('@@stdMonth : ' + stdMonth);
                System.debug('@@stdCC : ' + stdWBS);

                //법인지원비(기타)
                String mapKey   = stdCC + '-법인지원비(기타)-' + stdMonth; //ccReceiverPriceMap Key
                Decimal ohePrice = ccReceiverPriceMap.containsKey(mapKey) ? ccReceiverPriceMap.get(mapKey) : 0.0; //간접비 배부액
                pl_enterprise_etc.Amount__c = convertValue(ohePrice * stdRate);
                System.debug('mapKey : ' + mapKey);
                System.debug('법인지원비(기타) ohePrice : ' + ohePrice);

                //전사지원비 - 법인지원비(안전)
                mapKey   = stdCC + '-법인지원비(안전)-' + stdMonth;
                ohePrice = ccReceiverPriceMap.containsKey(mapKey) ? ccReceiverPriceMap.get(mapKey) : 0.0; //간접비 배부액
                pl_enterprise_safe.Amount__c = convertValue(ohePrice * stdRate);
                
                //담당지원비
                mapKey   = stdCC + '-담당지원비-' + stdMonth;
                ohePrice = ccReceiverPriceMap.containsKey(mapKey) ? ccReceiverPriceMap.get(mapKey) : 0.0;
                pl_charge.Amount__c = convertValue(ohePrice * stdRate);

                //팀지원비
                mapKey   = stdCC + '-팀지원비-' + stdMonth;
                ohePrice = ccReceiverPriceMap.containsKey(mapKey) ? ccReceiverPriceMap.get(mapKey) : 0.0;
                pl_team.Amount__c = convertValue(ohePrice * stdRate);

                //사업간지원비_배부(용)  //추가 계정과목 23.12.29
                mapKey   = stdCC + '-사업간지원비_배부(용)-' + stdMonth;
                ohePrice = ccReceiverPriceMap.containsKey(mapKey) ? ccReceiverPriceMap.get(mapKey) : 0.0;
                pl_interBizSupportY.Amount__c = convertValue(ohePrice * stdRate);

                //(판)사업전담지원비    //추가 계정과목 23.12.29
                mapKey   = stdCC + '-(판)사업전담지원비-' + stdMonth;
                ohePrice = ccReceiverPriceMap.containsKey(mapKey) ? ccReceiverPriceMap.get(mapKey) : 0.0;
                pl_dedicateBizSupportP.Amount__c = convertValue(ohePrice * stdRate);

                //(판)사업간지원비     //추가 계정과목 23.12.29
                mapKey   = stdCC + '-(판)사업간지원비-' + stdMonth;
                ohePrice = ccReceiverPriceMap.containsKey(mapKey) ? ccReceiverPriceMap.get(mapKey) : 0.0;
                pl_interBizSupportP.Amount__c = convertValue(ohePrice * stdRate);

                //매출총이익1
                pl_amount1.Amount__c = amount1Map.containsKey(plKey) ? convertValue(amount1Map.get(plKey)) : 0;

                //매출총이익2  //로직변경 23.12.29
                pl_amount2.Amount__c = convertValue( //매총1 - (담당지원비 + 팀지원비 + 사업간지원비_배부(용))
                                            pl_amount1.Amount__c - 
                                            (pl_charge.Amount__c + pl_team.Amount__c + pl_interBizSupportY.Amount__c)
                                    ); 
                //영업이익1   //로직변경 23.12.29
                pl_sales1.Amount__c  = convertValue( //매총2 - ((판)사업전담지원비 + (판)사업간지원비)
                                            pl_amount2.Amount__c -
                                            (pl_dedicateBizSupportP.Amount__c + pl_interBizSupportP.Amount__c)
                                       );
                //영업이익2
                pl_sales2.Amount__c  = convertValue(pl_sales1.Amount__c - (pl_enterprise_etc.Amount__c + pl_enterprise_safe.Amount__c));
                //EBITDA
                pl_ebitda.Amount__c  = convertValue(pl_sales2.Amount__c + (ebitdaCostMap.containsKey(plKey) ? ebitdaCostMap.get(plKey) : 0));

                innerMap.put('법인지원비(기타)', pl_enterprise_etc);
                innerMap.put('법인지원비(안전)', pl_enterprise_safe);
                innerMap.put('담당지원비', pl_charge);
                innerMap.put('팀지원비', pl_team);
                innerMap.put('사업간지원비_배부(용)', pl_interBizSupportY); //추가 계정과목 23.12.29
                innerMap.put('(판)사업전담지원비', pl_dedicateBizSupportP); //추가 계정과목 23.12.29
                innerMap.put('(판)사업간지원비', pl_interBizSupportP);     //추가 계정과목 23.12.29
                innerMap.put('매출총이익1', pl_amount1);
                innerMap.put('매출총이익2', pl_amount2);
                innerMap.put('영업이익1', pl_sales1);
                innerMap.put('영업이익2', pl_sales2);
                innerMap.put('EBITDA', pl_ebitda);

                plMap.put(plKey, innerMap);
            }

            List<ProfitandLoss_Plan__c> updateList = new List<ProfitandLoss_Plan__c>();
            for(String plKey : plMap.keySet()) {
                Map<String, ProfitandLoss_Plan__c> innerMap = plMap.get(plKey);

                updateList.addAll(innerMap.values());
            }

            System.debug('updateList: ' + updateList);
            if(updateList.size() > 0) update updateList;
        } catch (Exception e) {
            System.debug(e.getMessage());
            System.debug(e.getLineNumber());

            this.isFailed = true;
            this.ERROR_MSG = e.getMessage();
        }

    }

    public void finish(Database.BatchableContext context) {
        System.debug(':::::::: UpdateProfitLossPlanPrice_WBS_ba finish ::::::::');
        if(!isFailed) {
            Database.executeBatch(new UpdateProfitLossPlanPrice_CC_ba(this.baseYear), 10);
        } else {
            String title = 'S&I: [사업계획(손익)] 계산 실패';
            String body = 'UpdateProfitLossPlanPrice_WBS_ba :::::: ' + this.ERROR_MSG;

            EmailController.sendEmail(title, body);
        }
    }

    /**
     * @return 실적 배부 비율 Map :::: key:WBS-정산월, value:실적배부비율(Percent):0.XX
     * @description 실적 배부 비율 조회&매핑
     */
    //실적 배부 비율 조회&매핑
    public Map<String, Decimal> getDistributeRateMapByWBS(Set<Id> wbsIdSet) {
        List<Performance_Distribute_Rate__c> distributeRates = [
                SELECT Id, WBS_CC__c, Calculate_month_F__c, Performance_Distribute_Rate__c
                FROM Performance_Distribute_Rate__c
                WHERE WBS_CC__c IN :wbsIdSet
                AND CALENDAR_MONTH(Calculate_month__c) =: Integer.valueOf(this.baseYear)
        ];

        Map<String, Decimal> returnMap = new Map<String, Decimal>();
        for(Performance_Distribute_Rate__c pdr : distributeRates) {
            String mapKey = pdr.WBS_CC__c + '-' + pdr.Calculate_month_F__c;
            Decimal mapValue = (pdr.Performance_Distribute_Rate__c!=null) ? pdr.Performance_Distribute_Rate__c / 100 : 0;
            returnMap.put(mapKey, mapValue);
        }

        return returnMap;
    }

    /**
     * @return 손익계산 Map :::: key1:손익계산 구분 필드, key2: WBS-정산월
     * @description 손익계산 조회
     */
    public Map<String, Map<String, ProfitandLoss_Plan__c>> getProfitLossMapByWBS(Set<Id> wbsIdSet) {
        System.debug(':::::::: getProfitLossMap() ::::::::');

        List<ProfitandLoss_Plan__c> plList = [
                SELECT Id, Profit_Calculate_month__c, WBS__c, AccountSubjectselect__r.Name, ProfitandLoss_Type__c
                FROM ProfitandLoss_Plan__c
                WHERE WBS__c IN :wbsIdSet
                AND baseYear__c = :this.baseYear
        ];

        System.debug('wbsIdSet SIZE: ' + wbsIdSet.size());
        System.debug('wbsIdSet: ' + wbsIdSet);

        System.debug('plList SIZE: ' + plList.size());
        System.debug('plList: ' + plList);

        Map<String, Map<String, ProfitandLoss_Plan__c>> returnMap = new Map<String, Map<String, ProfitandLoss_Plan__c>>();

        for(ProfitandLoss_Plan__c p : plList) {
            Map<String, ProfitandLoss_Plan__c> innerMap = new Map<String, ProfitandLoss_Plan__c>();
            String plKey = p.WBS__c + '-' + p.Profit_Calculate_month__c;

            if(returnMap.containsKey(plKey)) {
                innerMap = returnMap.get(plKey);
            }
            innerMap.put(p.ProfitandLoss_Type__c, p);
            returnMap.put(plKey, innerMap);
        }

        return returnMap;
    }

    /**
     * @return 매출총이익 계산 Map
     */
    public Map<String, Decimal> getAmount1MapByWBS(Set<Id> wbsIdSet) {
        List<AggregateResult> amountAggList = [
                SELECT WBS__c, CALENDAR_MONTH(calculateDate__c) CAL_MONTH, SUM(PlanAmount__c) SUM_AMOUNT
                FROM Amount_plan__c
                WHERE UpperSorta__c = '매출액'
                AND BaseYear__c = :this.baseYear
                AND WBS__c IN :wbsIdSet
                GROUP BY WBS__c, CALENDAR_MONTH(calculateDate__c)
                ORDER BY WBS__c, CALENDAR_MONTH(calculateDate__c)
        ];

        List<AggregateResult> costAggList = [
                SELECT WBS__c, CALENDAR_MONTH(CalculateDate__c) CAL_MONTH, SUM(PlanPurchaseAmount__c) SUM_AMOUNT
                FROM Cost_Plan__c
                WHERE UpperSorta__c = '총매출원가'
                AND BaseYear__c = :this.baseYear
                AND WBS__c IN :wbsIdSet
                GROUP BY WBS__c, CALENDAR_MONTH(CalculateDate__c)
                ORDER BY WBS__c, CALENDAR_MONTH(CalculateDate__c)
        ];

        return subAToB(aggToMap(amountAggList), aggToMap(costAggList));
    }

    /**
     * @return EBITDA 계산 Map
     */
    public Map<String, Decimal> getEbitdaCostMapByWBS(Set<Id> wbsIdSet) {
        List<AggregateResult> ebitdaAggList = [
                SELECT WBS__c, CALENDAR_MONTH(CalculateDate__c) CAL_MONTH, SUM(PlanPurchaseAmount__c) SUM_AMOUNT
                FROM Cost_Plan__c
                WHERE LowerSorta__c IN ('(용)감가상각비', '(용)무형자산상각', '(용)산업재산권상각')
                AND BaseYear__c = :this.baseYear
                AND WBS__c IN :wbsIdSet
                GROUP BY WBS__c, CALENDAR_MONTH(CalculateDate__c)
                ORDER BY WBS__c, CALENDAR_MONTH(CalculateDate__c)
        ];

        return aggToMap(ebitdaAggList);
    }

    private static Map<String, Decimal> aggToMap(List<AggregateResult> aggList) {
        Map<String, Decimal> returnMap = new Map<String, Decimal>();

        for(AggregateResult agg : aggList) {
            //키 매핑 (wbs - 계정과목 - 실적일자)
            String aggKey = agg.get('WBS__c') + '-' + agg.get('CAL_MONTH'); //WBS-월
            if(!returnMap.containsKey(aggKey)) { //가장 최근 시점데이터 기준으로 가져올때 유효....
                Decimal aggSum = agg.get('SUM_AMOUNT') != null ? Decimal.valueOf(String.valueOf(agg.get('SUM_AMOUNT'))) : 0;
                returnMap.put(aggKey, aggSum);
            }
        }

        System.debug('@returnMap: ' + returnMap);
        return returnMap;
    }

    private static Map<String, Decimal> subAToB(Map<String, Decimal> aMap, Map<String, Decimal> bMap) {
        Map<String, Decimal> returnMap = new Map<String, Decimal>();

        for(String key : aMap.keySet()) {

            Decimal value = aMap.get(key);
            if(bMap.containsKey(key)) {
                value -= bMap.get(key);
            }

            returnMap.put(key, value);
        }

        for(String key : bMap.keySet()) {
            if(!aMap.containsKey(key)) { //aMap에 없을 때
                returnMap.put(key, -bMap.get(key));
            }
        }

        System.debug('@returnMap: ' + returnMap);
        return returnMap;
    }

    private Decimal convertValue(Double value) {
        return Decimal.valueOf(value).setScale(0);
    }

    private Decimal convertValue(Decimal value) {
        return value.setScale(0);
    }
}