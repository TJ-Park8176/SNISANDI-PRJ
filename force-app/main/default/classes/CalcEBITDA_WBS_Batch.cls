/**
 * Created by MZC01-DGCHOI on 2022-12-21.
 */

/**
 * 손익현황 업데이트 - WBS
 */
public without sharing class CalcEBITDA_WBS_Batch implements Database.Batchable<sObject>, Database.Stateful {

    public Set<Id> wbsIdSet;

    public Map<String, String> teamAPIMap; //팀명 - 간접비배부액 팀필드 API

    public CalcEBITDA_WBS_Batch() {
        this.wbsIdSet = new Set<Id>();
        this.teamAPIMap = new Map<String, String>();
        setTeamAPIMap();
    }

    /**
     * @param context
     *
     * @return WBS 10개씩 리턴해야함
     */
    public List<WBSandCC__c> start(Database.BatchableContext context) {
        //어제자 WBS 생성된거 있으면 껍데기 생성
        List<WBSandCC__c> newList = IF_ProfitLoss.getNewWBS();
        if(newList.size() > 0) {
            IF_ProfitLoss.makeNewRecord('WBS');
        }

        List<WBSandCC__c> wbsList = [
                SELECT Id, Name, Check_WBS_CC_ZF__c, Ebitda_target__c, General__c, OperationsHeadquarters__c, Team__c
                FROM WBSandCC__c
                WHERE Check_WBS_CC_ZF__c = 'WBS'
                AND (Team__c != null OR OperationsHeadquarters__c != null)
        ];

        return wbsList;
    }

    public void execute(Database.BatchableContext context, List<WBSandCC__c> scope) {

        //전사지원비
        /*
        -준비물
        1. 간접비 배부액 - (N월 - WBS - 전사지원비)
        2. 실적 배부 비율 - (N월 - WBS)
        -업데이트 대상
        손익계산 레코드 - (N월 - WBS - 전사지원비_배부(판))   //계정과목 코드 : 9100001
        */

        //담당지원비
        /*
        -준비물
        1. 간접비 배부액 - (N월 - WBS - 담당지원비)
        2. 실적 배부 비율(동일)
        -업데이트 대상
        손익계산 레코드 - (N월 - WBS - 담당지원비_배부(용)   // 계정과목 코드 : 9100008
         */

        //팀지원비
        /*
        -준비물
        1. 간접비 배부액 - (N월 - WBS - 팀지원비)
        2. 실적 배부 비율(동일)
        -업데이트 대상
        손익계산 레코드 - (N월 - WBS - 팀지원비_배부(용)    // 계정과목 코드 : 9100007
         */

        //매출총이익1
        /*
        매출(WBS-N월) 키로 매출액(상위구분) Mapping
        - 매입(WBS-N월) 키로 총매출원가(상위구분) Mapping
         */

        //매출총이익2
        /*
        매출총이익1 - (담당지원비 + 팀지원비)
         */

        //영업이익1
        /*
        = 매출총이익2
         */

        //영업이익2
        /*
        영업이익1 - 전사지원비
         */

        //EBITDA
        /*
        영업이익2 - 매입(WBS-N월) 키로 '(용)감가상각비'(하위구분) Mapping
         */

        System.debug('WBSandCC scope SIZE: ' + scope.size());
        System.debug('WBSandCC scope: ' + scope);

        Map<String, String> wbsTeamMap = new Map<String, String>(); //key:WBS ID, value:Seoul1__c(API..)
        for(WBSandCC__c wbs : scope) {
            this.wbsIdSet.add(wbs.Id);

            System.debug('-------------------------');
            System.debug('Id: ' + wbs.Id); //a060w000003nXUgAAM
            System.debug('match Record ::: 총괄 ::::' + wbs.General__c);
            System.debug('match Record ::: 운영 본부 ::::' + wbs.OperationsHeadquarters__c);
            System.debug('match Record ::: 팀 ::::' + wbs.Team__c);

            if(wbs.General__c == '사업총괄') {
                String teamAPI = this.teamAPIMap.get(wbs.OperationsHeadquarters__c);
                wbsTeamMap.put(wbs.Id, teamAPI);
            } else if(wbs.General__c == '공사총괄' || wbs.General__c == '영업총괄') {
                String teamAPI = this.teamAPIMap.get(wbs.Team__c);
                wbsTeamMap.put(wbs.Id, teamAPI);
            }
        }

        System.debug('----------IN Execute----------');
        System.debug('wbsIdSet SIZE: ' + wbsIdSet.size());
        System.debug('wbsIdSet: ' + wbsIdSet);
        System.debug('wbsTeamMap SIZE: ' + wbsTeamMap.size());

        //실적 배부 비율 - key:WBS-정산월
        Map<String, Decimal> distribRateMap = getDistributeRateMap();
        System.debug('실적배부비율 Map: ' + distribRateMap);

        //간접비 배부액 - key:정산월
        Map<Integer, Ebitda_Tmp__c> ebitdaTmpMap_e_e = getEbitdaTmpMap('법인지원비(기타)');
        Map<Integer, Ebitda_Tmp__c> ebitdaTmpMap_e_s = getEbitdaTmpMap('법인지원비(안전)');
        Map<Integer, Ebitda_Tmp__c> ebitdaTmpMap_c = getEbitdaTmpMap('담당지원비');
        Map<Integer, Ebitda_Tmp__c> ebitdaTmpMap_t = getEbitdaTmpMap('팀지원비');

        //손익계산
        Map<String, Map<String, ProfitandLoss__c>> plMap = getProfitLossMap();  //key1: wbs-정산월, key2: 손익계산유형(XX지원비)

        //매출총이익 Map
        Map<String, Decimal> amount1Map = getAmount1Map();       
        System.debug('@@@@@@ amount1Map : ' + amount1Map);
        
        //Ebitda계산 Map
        Map<String, Decimal> ebitdaCostMap = getEbitdaCostMap();
        System.debug('ebitdaCostMap: ' + ebitdaCostMap);

        for(String plKey : plMap.keySet()) {
            Map<String, ProfitandLoss__c> innerMap = plMap.get(plKey);

            ProfitandLoss__c pl_enterprise_etc  = innerMap.get('법인지원비(기타)');
            ProfitandLoss__c pl_enterprise_safe = innerMap.get('법인지원비(안전)');
            ProfitandLoss__c pl_charge          = innerMap.get('담당지원비');
            ProfitandLoss__c pl_team            = innerMap.get('팀지원비');
            ProfitandLoss__c pl_amount1         = innerMap.get('매출총이익1');
            ProfitandLoss__c pl_amount2         = innerMap.get('매출총이익2');
            ProfitandLoss__c pl_sales1          = innerMap.get('영업이익1');
            ProfitandLoss__c pl_sales2          = innerMap.get('영업이익2');
            ProfitandLoss__c pl_ebitda          = innerMap.get('EBITDA');

            Decimal stdRate = distribRateMap.containsKey(plKey) ? distribRateMap.get(plKey) : 0; //실적 배부 비율

            String  stdWBS   = plKey.split('-')[0];
            String fieldName = wbsTeamMap.get(stdWBS);
            Integer stdMonth = Integer.valueOf(plKey.split('-')[1]);

            System.debug(plKey);
            System.debug('stdWBS: ' + stdWBS);
            System.debug('wbsTeamMap: ' + wbsTeamMap);
            System.debug('wbsTeamMap contains Key? : ' + wbsTeamMap.containsKey(stdWBS));
            System.debug('fieldName: ' + fieldName);

            //전사지원비 - 법인지원비(기타)
            Ebitda_Tmp__c ebitdaTmp = ebitdaTmpMap_e_e.get(stdMonth);
            System.debug('@@stdRate: ' + stdRate);

            Decimal ohePrice = ebitdaTmp.get(fieldName) != null ? (Decimal) ebitdaTmp.get(fieldName) : 0.0; //간접비 배부액
            System.debug('@@ohePrice: ' + ohePrice);
            pl_enterprise_etc.Amount__c = convertValue(ohePrice * stdRate);

            //전사지원비 - 법인지원비(안전)
            ebitdaTmp = ebitdaTmpMap_e_s.get(stdMonth);
            ohePrice = ebitdaTmp.get(fieldName) != null ? (Decimal) ebitdaTmp.get(fieldName) : 0.0;
            pl_enterprise_safe.Amount__c = convertValue(ohePrice * stdRate);

            //담당지원비
            ebitdaTmp = ebitdaTmpMap_c.get(stdMonth);
            System.debug('ebitdaTmp: ' + ebitdaTmp);
            System.debug('ebitdaTmpMap_c: ' + ebitdaTmpMap_c);
            System.debug('fieldName: ' + fieldName);

            ohePrice = ebitdaTmp.get(fieldName) != null ? (Decimal) ebitdaTmp.get(fieldName) : 0.0;
            pl_charge.Amount__c = convertValue(ohePrice * stdRate);

            //팀지원비
            ebitdaTmp = ebitdaTmpMap_t.get(stdMonth);
            ohePrice = ebitdaTmp.get(fieldName) != null ? (Decimal) ebitdaTmp.get(fieldName) : 0.0;
            pl_team.Amount__c = convertValue(ohePrice * stdRate);

            //매출총이익1
            pl_amount1.Amount__c = amount1Map.containsKey(plKey) ? convertValue(amount1Map.get(plKey)) : 0;

            //매출총이익2
            pl_amount2.Amount__c = convertValue(pl_amount1.Amount__c - (pl_charge.Amount__c + pl_team.Amount__c));

            //영업이익1
            pl_sales1.Amount__c = convertValue(pl_amount2.Amount__c);

            //영업이익2
            pl_sales2.Amount__c = convertValue(pl_sales1.Amount__c - (pl_enterprise_etc.Amount__c + pl_enterprise_safe.Amount__c));

            System.debug('ebitdaCostMap Value: ' + ebitdaCostMap.get(plKey));
            //EBITDA
            pl_ebitda.Amount__c = convertValue(pl_sales2.Amount__c + (ebitdaCostMap.containsKey(plKey) ? ebitdaCostMap.get(plKey) : 0));

            System.debug('pl_ebitda.Amount: ' + pl_ebitda.Amount__c);

            innerMap.put('법인지원비(기타)', pl_enterprise_etc);
            innerMap.put('법인지원비(안전)', pl_enterprise_safe);
            innerMap.put('담당지원비', pl_charge);
            innerMap.put('팀지원비', pl_team);
            innerMap.put('매출총이익1', pl_amount1);
            innerMap.put('매출총이익2', pl_amount2);
            innerMap.put('영업이익1', pl_sales1);
            innerMap.put('영업이익2', pl_sales2);
            innerMap.put('EBITDA', pl_ebitda);

            plMap.put(plKey, innerMap);
        }

        List<ProfitandLoss__c> updateList = new List<ProfitandLoss__c>();
        for(String plKey : plMap.keySet()) {
            Map<String, ProfitandLoss__c> innerMap = plMap.get(plKey);

            updateList.addAll(innerMap.values());
        }

        System.debug('updateList: ' + updateList);
        if(updateList.size() > 0) update updateList;

        this.wbsIdSet = new Set<Id>();
    }

    public void finish(Database.BatchableContext context) {
        System.debug('--------------finish----------');
        //손익계산-CC 배치 호출
        Database.executeBatch(new CalcEBITDA_CC_Batch(), 10);
    }

    /**
     * @return 실적 배부 비율 Map :::: key:WBS-정산월, value:실적배부비율(Percent):0.XX
     * @description 실적 배부 비율 조회&매핑
     */
    //실적 배부 비율 조회&매핑
    public Map<String, Decimal> getDistributeRateMap() {
        List<Performance_Distribute_Rate__c> distributeRates = [
                SELECT Id, WBS_CC__c, Calculate_month_F__c, Performance_Distribute_Rate__c
                FROM Performance_Distribute_Rate__c
                WHERE WBS_CC__c IN :this.wbsIdSet
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
     * @param type
     *
     * @return 간접비 배부액 Map :::: key:정산월, value:간접비배부액
     * @description 간접비 배부액 조회&매핑
     */
    public Map<Integer, Ebitda_Tmp__c> getEbitdaTmpMap(String type) {
        //SELECT ALL FIELDS
        Set<String> fields = Ebitda_Tmp__c.SObjectType.getDescribe().fields.getMap().keySet();
        String query = ' SELECT ' + String.join((Iterable<String>)fields, ',')
                     + ' FROM Ebitda_Tmp__c '
                     + ' WHERE Ebitda_Type__c = :type '
                     + ' AND CalculateDate__c = THIS_YEAR ';

        List<Ebitda_Tmp__c> ebitdaTmps = Database.query(query);

        System.debug(ebitdaTmps);

        Map<Integer, Ebitda_Tmp__c> returnMap = new Map<Integer, Ebitda_Tmp__c>();

        for(Ebitda_Tmp__c ebitdaTmp : ebitdaTmps) {
            returnMap.put(ebitdaTmp.CalculateDate__c.month(), ebitdaTmp);
        }

        System.debug('type: ' + type + ' @returnMap: ' + returnMap);
        return returnMap;
    }

    /**
     * @return 손익계산 Map :::: key1:손익계산 구분 필드, key2: WBS-정산월
     * @description 손익계산 조회
     */
    public Map<String, Map<String, ProfitandLoss__c>> getProfitLossMap() {
        System.debug('getProfitLossMap()--------');

        List<ProfitandLoss__c> plList = [
                SELECT id, Profit_Calculate_month__c, WBS__c, AccountSubjectSelect__r.Name, ProfitandLoss_Type__c
                FROM ProfitandLoss__c
                WHERE WBS__c IN :this.wbsIdSet
                AND Calculate_month__c = THIS_YEAR
        ];

        System.debug('wbsIdSet SIZE: ' + this.wbsIdSet.size());
        System.debug('wbsIdSet: ' + this.wbsIdSet);

        Map<String, Map<String, ProfitandLoss__c>> returnMap = new Map<String, Map<String, ProfitandLoss__c>>();

        for(ProfitandLoss__c p : plList) {
            String plKey = p.WBS__c + '-' + p.Profit_Calculate_month__c;

            Map<String, ProfitandLoss__c> innerMap = new Map<String, ProfitandLoss__c>();

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
    public Map<String, Decimal> getAmount1Map() {
        List<AggregateResult> amountAggList = [
                SELECT WBS__c, CALENDAR_MONTH(CalculateDate__c) CAL_MONTH, SUM(PredictAmount__c) SUM_AMOUNT
                FROM Amount__c
                WHERE UpperSorta__c = '매출액'
                AND CalculateDate__c = THIS_YEAR
                AND WBS__c IN :this.wbsIdSet
                GROUP BY WBS__c, CALENDAR_MONTH(CalculateDate__c)
                ORDER BY WBS__c, CALENDAR_MONTH(CalculateDate__c)
        ];
        
        List<AggregateResult> costAggList = [
                SELECT WBS__c, CALENDAR_MONTH(CalculateDate__c) CAL_MONTH, SUM(PurchaseAmount__c) SUM_AMOUNT
                FROM Cost__c
                WHERE UpperSorta__c = '총매출원가'
                AND CalculateDate__c = THIS_YEAR
                AND WBS__c IN :this.wbsIdSet
                GROUP BY WBS__c, CALENDAR_MONTH(CalculateDate__c)
                ORDER BY WBS__c, CALENDAR_MONTH(CalculateDate__c)
        ];

        return subAToB(aggToMap(amountAggList), aggToMap(costAggList));
    }

    /**
     * @return EBITDA 계산 Map
     */
    public Map<String, Decimal> getEbitdaCostMap() {
        List<AggregateResult> ebitdaAggList = [
                SELECT WBS__c, CALENDAR_MONTH(CalculateDate__c) CAL_MONTH, SUM(PurchaseAmount__c) SUM_AMOUNT
                FROM Cost__c
                WHERE LowerSorta__c IN ('(용)감가상각비', '(용)무형자산상각', '(용)산업재산권상각')
                AND CalculateDate__c = THIS_YEAR
                AND WBS__c IN :this.wbsIdSet
                GROUP BY WBS__c, CALENDAR_MONTH(CalculateDate__c)
                ORDER BY WBS__c, CALENDAR_MONTH(CalculateDate__c)
        ];

        return aggToMap(ebitdaAggList);
    }

    private static Map<String, Decimal> aggToMap(List<AggregateResult> aggList) {
        System.debug('---------aggToMap()---------');
        Map<String, Decimal> returnMap = new Map<String, Decimal>();

        for(AggregateResult agg : aggList) {
            //키 매핑 (wbs - 계정과목 - 실적일자)
            String aggKey = agg.get('WBS__c') + '-' + agg.get('CAL_MONTH'); //WBS-월
            if(!returnMap.containsKey(aggKey)) { //가장 최근 시점데이터 기준으로 가져올때 유효....
                Decimal aggSum = agg.get('SUM_AMOUNT') != null ? (Decimal) agg.get('SUM_AMOUNT') : 0;
                returnMap.put(aggKey, aggSum);
            }
        }

        System.debug('@returnMap: ' + returnMap);
        return returnMap;
    }

    private static Map<String, Decimal> subAToB(Map<String, Decimal> aMap, Map<String, Decimal> bMap) {
        System.debug('---------subAToB() START---------');
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

    public void setTeamAPIMap() {
        this.teamAPIMap.put('서울1본부', 'Seoul1__c');
        this.teamAPIMap.put('서울2본부', 'Seoul2__c');
        this.teamAPIMap.put('서울3본부', 'Seoul3__c');
        this.teamAPIMap.put('서울4본부', 'Seoul4__c');
        this.teamAPIMap.put('서울5본부', 'Seoul5__c');
        this.teamAPIMap.put('서울6본부', 'Seoul6__c');
        this.teamAPIMap.put('중부1본부', 'Central1__c');
        this.teamAPIMap.put('중부2본부', 'Central2__c');
        this.teamAPIMap.put('남부1본부', 'Southern1__c');
        this.teamAPIMap.put('남부2본부', 'Southern2__c');

        this.teamAPIMap.put('리노베이션팀', 'Renovation__c');
        this.teamAPIMap.put('보전공사팀', 'Construction__c');
        this.teamAPIMap.put('통신서비스팀', 'Service__c');
        this.teamAPIMap.put('IPM팀', 'IPM__c');
        this.teamAPIMap.put('PFM팀', 'PFM__c');
        this.teamAPIMap.put('기업부동산팀', 'RealEstate__c');
        this.teamAPIMap.put('주차배부(영업총괄)', 'Parking__c');
    }

}