/**
 * Created by MZC01-DGCHOI on 2022-12-26.
 */

/**
 * 간접비 배부액 계산
 */
public with sharing class CalcDistribOHE { //OHE: 간접비

    public Plan_Distribution_Ratio__c pdr_enterprise;
    public Plan_Distribution_Ratio__c pdr_charge;

    public CalcDistribOHE() {
        setStandardPDR();
    }

    /**
     * @description 전사지원비 계산
     */
    public void calcEnterpriseCost() {
        Map<Integer, Double> costMap_etc  = aggToMap(getEnterpriseCost_etc()); //key: 월 - value: 금액(법인지원비(기타))
        Map<Integer, Double> costMap_safe = aggToMap(getEnterpriseCost_safe()); //key: 월 - value: 금액(법인지원비(안전))

        List<Ebitda_Tmp__c> updateList_etc = getEbitdaTmpList('법인지원비(기타)');
        List<Ebitda_Tmp__c> updateList_safe = getEbitdaTmpList('법인지원비(안전)');

        updateEnterpriseEbitda(updateList_etc, costMap_etc);
        updateEnterpriseEbitda(updateList_safe, costMap_safe);
    }

    /**
     * @description 담당지원비 계산
     */
    public void calcChargeCost() {
        //사업총괄
        Map<Integer, Double> cost_biz_general_map = aggToMap(getChargeCost_general('사업총괄')); //총괄
        Map<String, Double>  cost_biz_hq_map      = aggToMap_HQ(getChargeCost_HQ());   //본부
        //공사총괄
        Map<Integer, Double> cost_const_map = aggToMap(getChargeCost_general('공사총괄')); //construction(공사)
        //영업총괄
        Map<Integer, Double> cost_sales_map = aggToMap(getChargeCost_general('영업총괄')); //sales(영업)

        List<Ebitda_Tmp__c> updateList = getEbitdaTmpList('담당지원비');

        for(Ebitda_Tmp__c target : updateList) {
            Integer tmpMonth = target.CalculateDate__c.month();

            if(cost_biz_general_map.containsKey(tmpMonth)) {
                Double totalCost_biz   = cost_biz_general_map.containsKey(tmpMonth) ? cost_biz_general_map.get(tmpMonth) : 0;
                Double totalCost_sales = cost_sales_map.containsKey(tmpMonth) ? cost_sales_map.get(tmpMonth) : 0;
                Double totalCost_const = cost_const_map.containsKey(tmpMonth) ? cost_const_map.get(tmpMonth) : 0;

                //Seoul
                //서울1본부 = Seoul1__c
                for(Integer i=1; i<=6; i++) {
                    String fieldName = 'Seoul' + i + '__c';
                    Double stdRatio = pdr_charge.get(fieldName) != null ? (Double)pdr_charge.get(fieldName) / 100 : 0;

                    String HQKey = '서울' + i + '본부' + '-' + tmpMonth;
                    Double HQValue = cost_biz_hq_map.containsKey(HQKey) ? cost_biz_hq_map.get(HQKey) : 0;

                    target.put(fieldName, (totalCost_biz * stdRatio) + HQValue);
                }
                //Central
                for(Integer i=1; i<=2; i++) {
                    String fieldName = 'Central' + i + '__c';
                    Double stdRatio = pdr_charge.get(fieldName) != null ? (Double)pdr_charge.get(fieldName) / 100 : 0;

                    String HQKey = '중부' + i +'본부' + '-' + tmpMonth;
                    Double HQValue = cost_biz_hq_map.containsKey(HQKey) ? cost_biz_hq_map.get(HQKey) : 0;

                    target.put(fieldName, (totalCost_biz * stdRatio) + HQValue);
                }
                //Southern
                for(Integer i=1; i<=2; i++) {
                    String fieldName = 'Southern' + i + '__c';
                    Double stdRatio = pdr_charge.get(fieldName) != null ? (Double)pdr_charge.get(fieldName) / 100 : 0;

                    String HQKey = '남부' + i +'본부' + '-' + tmpMonth;
                    Double HQValue = cost_biz_hq_map.containsKey(HQKey) ? cost_biz_hq_map.get(HQKey) : 0;

                    target.put(fieldName, (totalCost_biz * stdRatio) + HQValue);
                }
                //공사총괄
                target.Renovation__c   = totalCost_const * (pdr_charge.get('Renovation__c') != null ? ((Double)pdr_charge.get('Renovation__c') / 100) : 0);
                target.Construction__c = totalCost_const * (pdr_charge.get('Construction__c') != null ? ((Double)pdr_charge.get('Construction__c') / 100) : 0);
                target.Service__c      = totalCost_const * (pdr_charge.get('Service__c') != null ? ((Double)pdr_charge.get('Service__c') / 100) : 0);
                //영업총괄
                target.IPM__c          = totalCost_sales * (pdr_charge.get('IPM__c') != null ? ((Double)pdr_charge.get('IPM__c') / 100) : 0);
                target.PFM__c          = totalCost_sales * (pdr_charge.get('PFM__c') != null ? ((Double)pdr_charge.get('PFM__c') / 100) : 0);
                target.RealEstate__c   = totalCost_sales * (pdr_charge.get('Property__c') != null ? ((Double)pdr_charge.get('Property__c') / 100) : 0);
                target.Parking__c      = totalCost_sales * (pdr_charge.get('Parking_Rate__c') != null ? ((Double)pdr_charge.get('Parking_Rate__c') / 100) : 0);
            }
        }

        if(updateList.size() > 0) update updateList;
        System.debug('@담당지원비 UpdateList: ' + updateList);
    }

    /**
     * @description 팀지원비 계산
     */
    public void calcTeamCost() {
        List<Ebitda_Tmp__c> updateList = getEbitdaTmpList('팀지원비');

        Map<String, Double> cost_sales_map = aggToMap_Team(getTeamCost_sales()); //영업총괄
        Map<String, Double> cost_const_map = aggToMap_Team(getTeamCost_const()); //공사총괄

        for(Ebitda_Tmp__c target : updateList) {
            Integer tmpMonth = target.CalculateDate__c.month();

            //공사총괄
            target.Renovation__c   = cost_const_map.containsKey('리노베이션팀-' + tmpMonth) ? cost_const_map.get('리노베이션팀-' + tmpMonth) : 0;
            target.Construction__c = cost_const_map.containsKey('보전공사팀-' + tmpMonth) ? cost_const_map.get('보전공사팀-' + tmpMonth) : 0;
            target.Service__c      = cost_const_map.containsKey('통신서비스팀-' + tmpMonth) ? cost_const_map.get('통신서비스팀-' + tmpMonth) : 0;
            //영업총괄
            target.IPM__c          = cost_sales_map.containsKey('IPM팀-' + tmpMonth) ? cost_sales_map.get('IPM팀-' + tmpMonth) : 0;
            target.PFM__c          = cost_sales_map.containsKey('PFM팀-' + tmpMonth) ? cost_sales_map.get('PFM팀-' + tmpMonth) : 0;
            target.RealEstate__c   = cost_sales_map.containsKey('기업부동산팀-' + tmpMonth) ? cost_sales_map.get('기업부동산팀-' + tmpMonth) : 0;
            target.Parking__c      = cost_sales_map.containsKey('주차배부(영업총괄)-' + tmpMonth) ? cost_sales_map.get('주차배부(영업총괄)-' + tmpMonth) : 0;
        }

        if(updateList.size() > 0) update updateList;
        System.debug('@팀지원비 UpdateList: ' + updateList);
    }

    /**
     * @param updateList 업데이트할 간접비 배부액 List
     * @param costMap 월별 법인지원비 금액 Map
     */
    public void updateEnterpriseEbitda(List<Ebitda_Tmp__c> updateList, Map<Integer, Double> costMap) {
        for(Ebitda_Tmp__c target : updateList) {
            Integer tmpMonth = target.CalculateDate__c.month();
            if(costMap.containsKey(tmpMonth)) { //해당월 법인지원비 존재
                Double totalCost = costMap.get(tmpMonth);
                
                //Seoul
                for(Integer i=1; i<=6; i++) {
                    String fieldName = 'Seoul' + i + '__c';
                    Double stdRatio = (pdr_enterprise.get(fieldName) != null) ? (Double) pdr_enterprise.get(fieldName) / 100 : 0;
                    target.put(fieldName, totalCost * stdRatio);
                }
                //Central
                for(Integer i=1; i<=2; i++) {
                    String fieldName = 'Central' + i + '__c';
                    Double stdRatio = (pdr_enterprise.get(fieldName) != null) ? (Double) pdr_enterprise.get(fieldName) / 100 : 0;
                    target.put(fieldName, totalCost * stdRatio);
                }
                //Southern
                for(Integer i=1; i<=2; i++) {
                    String fieldName = 'Southern' + i + '__c';
                    Double stdRatio = (pdr_enterprise.get(fieldName) != null) ? (Double) pdr_enterprise.get(fieldName) / 100 : 0;
                    target.put(fieldName, totalCost * stdRatio);
                }
                //공사총괄
                target.Renovation__c   = totalCost * ((pdr_enterprise.get('Renovation__c') != null) ? ((Double)pdr_enterprise.get('Renovation__c') / 100) : 0);
                target.Construction__c = totalCost * ((pdr_enterprise.get('Construction__c') != null) ? ((Double)pdr_enterprise.get('Construction__c') / 100) : 0);
                target.Service__c      = totalCost * ((pdr_enterprise.get('Service__c') != null) ? ((Double)pdr_enterprise.get('Service__c') / 100) : 0);
                //영업총괄
                target.IPM__c          = totalCost * ((pdr_enterprise.get('IPM__c') != null) ? ((Double)pdr_enterprise.get('IPM__c') / 100) : 0);
                target.PFM__c          = totalCost * ((pdr_enterprise.get('PFM__c') != null) ? ((Double)pdr_enterprise.get('PFM__c') / 100) : 0);
                target.RealEstate__c   = totalCost * ((pdr_enterprise.get('Property__c') != null) ? ((Double)pdr_enterprise.get('Property__c') / 100) : 0);
                target.Parking__c      = totalCost * ((pdr_enterprise.get('Parking_Rate__c') != null) ? ((Double)pdr_enterprise.get('Parking_Rate__c') / 100) : 0);
            }
        }

        if(updateList.size() > 0) update updateList;
        System.debug('@법인지원비 UpdateList: ' + updateList);
    }

    /**
     * @return 법인지원비(기타) 금액 List
     */
    public List<AggregateResult> getEnterpriseCost_etc() {
        List<AggregateResult> aggList = [
            SELECT CALENDAR_MONTH(CalculateDate__c) CAL_MONTH, SUM(PurchaseAmount__c) SUM_AMOUNT
            FROM Cost__c
            WHERE wbs__r.Check_WBS_CC_ZF__c = 'CC'
            AND wbs__r.Ebitda_target__c = '법인(기타)'
            //AND AccountSubjectselect__r.UpperSort__c = '판매비와관리비'
            AND CalculateDate__c = THIS_YEAR
            GROUP BY CALENDAR_MONTH(CalculateDate__c)
            ORDER BY CALENDAR_MONTH(CalculateDate__c)
        ];
        return aggList;
    }

    /**
     * @return 법인지원비(안전) 금액 List
     */
    public List<AggregateResult> getEnterpriseCost_safe() { //법인지원비(안전)
        List<AggregateResult> aggList = [
                SELECT CALENDAR_MONTH(CalculateDate__c ) CAL_MONTH, SUM(PurchaseAmount__c) SUM_AMOUNT
                FROM Cost__c
                WHERE wbs__r.Check_WBS_CC_ZF__c = 'CC'
                AND wbs__r.Ebitda_target__c = '법인(안전)'
                //AND AccountSubjectselect__r.UpperSort__c = '판매비와관리비'
                AND CalculateDate__c = THIS_YEAR
                GROUP BY CALENDAR_MONTH(CalculateDate__c)
                ORDER BY CALENDAR_MONTH(CalculateDate__c)
        ];
        return aggList;
    }

    /**
     * @param generalName OO총괄
     *
     * @return 담당지원비 - 총괄 List
     */
    public List<AggregateResult> getChargeCost_general(String generalName) {
        //영업총괄 - 판매비와관리비
        //사업총괄 - 총매출원가
        //String upperSort = (generalName == '영업총괄') ? '판매비와관리비' : '총매출원가';
        List<AggregateResult> aggList = [
                SELECT CALENDAR_MONTH(CalculateDate__c) CAL_MONTH, SUM(PurchaseAmount__c) SUM_AMOUNT
                FROM Cost__c
                WHERE WBS__r.Check_WBS_CC_ZF__c = 'CC'
                AND WBS__r.Ebitda_target__c = '총괄'
                AND WBS__r.General__c =: generalName
                //AND AccountSubjectSelect__r.UpperSort__c =: upperSort // 계정과목 기준 삭제함!
                AND CalculateDate__c = THIS_YEAR
                GROUP BY CALENDAR_MONTH(CalculateDate__c)
                ORDER BY CALENDAR_MONTH(CalculateDate__c)
        ];
        return aggList;
    }

    /**
     * @return  /담당지원비 - 본부 List
     */
    public List<AggregateResult> getChargeCost_HQ() {
        List<AggregateResult> aggList = [
                SELECT WBS__r.OperationsHeadquarters__c HQ, CALENDAR_MONTH(CalculateDate__c) CAL_MONTH, SUM(PurchaseAmount__c) SUM_AMOUNT
                FROM Cost__c
                WHERE WBS__r.Check_WBS_CC_ZF__c = 'CC'
                AND WBS__r.Ebitda_target__c = '본부'
                AND WBS__r.OperationsHeadquarters__c != null
                //AND AccountSubjectSelect__r.UpperSort__c = '총매출원가'
                AND CalculateDate__c = THIS_YEAR
                GROUP BY WBS__r.OperationsHeadquarters__c, CALENDAR_MONTH(CalculateDate__c)
                ORDER BY WBS__r.OperationsHeadquarters__c, CALENDAR_MONTH(CalculateDate__c)
        ];
        return aggList;
    }

    /**
     * @return 팀지원비 - 영업 List
     */
    public List<AggregateResult> getTeamCost_sales() { //팀지원비 - 영업
        List<AggregateResult> aggList = [
                SELECT WBS__r.Team__c TEAM, CALENDAR_MONTH(CalculateDate__c) CAL_MONTH, SUM(PurchaseAmount__c) SUM_AMOUNT
                FROM Cost__c
                WHERE WBS__r.Check_WBS_CC_ZF__c = 'CC'
                AND WBS__r.Ebitda_target__c = '팀'
                AND WBS__r.General__c = '영업총괄'
                AND WBS__r.Team__c IN ('IPM팀','PFM팀','기업부동산팀','주차배부(영업총괄)')
                //AND AccountSubjectSelect__r.UpperSort__c = '총매출원가'
                AND CalculateDate__c = THIS_YEAR
                GROUP BY WBS__r.Team__c, CALENDAR_MONTH(CalculateDate__c)
                ORDER BY WBS__r.Team__c, CALENDAR_MONTH(CalculateDate__c)
        ];
        return aggList;
    }

    /**
     * @return 팀지원비 - 공사 List
     */
    public List<AggregateResult> getTeamCost_const() {
        List<AggregateResult> aggList = [
                SELECT WBS__r.Team__c TEAM, CALENDAR_MONTH(CalculateDate__c) CAL_MONTH, SUM(PurchaseAmount__c) SUM_AMOUNT
                FROM Cost__c
                WHERE WBS__r.Check_WBS_CC_ZF__c = 'CC'
                AND WBS__r.Ebitda_target__c = '팀'
                AND WBS__r.General__c = '공사총괄'
                AND WBS__r.Team__c IN ('리노베이션팀','보전공사팀','통신서비스팀')
                //AND AccountSubjectSelect__r.UpperSort__c = '총매출원가'
                AND CalculateDate__c = THIS_YEAR
                GROUP BY WBS__r.Team__c, CALENDAR_MONTH(CalculateDate__c)
                ORDER BY WBS__r.Team__c, CALENDAR_MONTH(CalculateDate__c)
        ];
        return aggList;
    }


    public Map<Integer, Double> aggToMap(List<AggregateResult> aggList) {
        Map<Integer, Double> tmpMap = new Map<Integer, Double>();
        for(AggregateResult agg : aggList) {
            tmpMap.put((Integer)agg.get('CAL_MONTH'), (Double)agg.get('SUM_AMOUNT'));
        }

         return tmpMap;
    }

    /**
     * @param aggList
     *
     * @return 본부별 Map
     */
    public Map<String, Double> aggToMap_HQ(List<AggregateResult> aggList) {
        Map<String, Double> tmpMap = new Map<String, Double>();
        for(AggregateResult agg : aggList) {
            tmpMap.put((String)agg.get('HQ') + '-' + (Integer)agg.get('CAL_MONTH'), (Double)agg.get('SUM_AMOUNT'));
        }

        return tmpMap;
    }

    /**
     * @param aggList
     *
     * @return 팀별 Map
     */
    public Map<String, Double> aggToMap_Team(List<AggregateResult> aggList) {
        Map<String, Double> tmpMap = new Map<String, Double>();
        for(AggregateResult agg : aggList) {
            tmpMap.put((String)agg.get('TEAM') + '-' + (Integer)agg.get('CAL_MONTH'), (Double)agg.get('SUM_AMOUNT'));
        }

        return tmpMap;
    }

    /**
     * @description 기준 계획배부비율 Set : 법인지원비, 담당지원비
     */
    public void setStandardPDR() {
        this.pdr_enterprise = Database.query(getPDRQuery('법인지원비'));
        this.pdr_charge     = Database.query(getPDRQuery('담당지원비'));
    }

    public String getPDRQuery(String type) { //type : 지원비 구분(법인지원비, 담당지원비)
        //SELECT ALL FIELDS
        Set<String> fields = Plan_Distribution_Ratio__c.SObjectType.getDescribe().fields.getMap().keySet();
        String query = ' SELECT ' + String.join((Iterable<String>)fields, ',')
                     + ' FROM Plan_Distribution_Ratio__c ' +
                     + ' WHERE cost_classification__c = \''+ type + '\' '
                     + ' LIMIT 1 ';
        return query;
    }

    /**
     * @param type : EbitdaType (법인지원비(기타), 법인지원비(안전), 담당지원비, 팀지원비)
     *
     * @return 간접비 배부액 List
     */
    public List<Ebitda_Tmp__c> getEbitdaTmpList(String type) {
        List<Ebitda_Tmp__c> returnList = [
                SELECT Id, CalculateDate__c
                FROM Ebitda_Tmp__c
                WHERE Ebitda_Type__c = :type
                AND CalculateDate__c = THIS_YEAR
                ORDER BY CalculateDate__c
        ];

        return returnList;
    }
}