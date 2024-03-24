/**
 * Created by MZC01-DGCHOI on 2023-07-10.
 */

public without sharing class CCGap_tr extends TriggerHandler {

    List<CCGAP__c> listNew = (List<CCGAP__c>) Trigger.new;
    List<CCGAP__c> listOld = (List<CCGAP__c>) Trigger.old;

    //기준 데이터
    public static CCGAPInfo ccgapInfo = new CCGAPInfo();
    Date stdPerformanceDate = null; //기준 실적일
    Date stdWeeklyDate = null; //기준 주간예상일
    Date startDate = null; //반영월(시작)
    Date endDate = null; //반영월(끝) + 1달

    public CCGap_tr() {
        //기준 값 세팅
        setStdPerformanceMonth();
        setStdWeeklyMonth();
    }

    public override void beforeInsert() {
        checkValidation();
        calcAmount();
    }

    public void checkValidation() {
        CCGAP__c ccgap = listNew[0];

        //1. 작성월(Create_Month__c) 는 현재 날짜의 Month 로만 작성
        if(ccgap.Create_Month__c != Date.today()) {
            ccgap.addError('작성월은 현재 날짜를 작성해주세요.');
        } else if(ccgap.End_Date__c <= ccgap.Start_Date__c) {
            //2. End_Date__c는 Start_Date__c보다 커야함(>)
            ccgap.addError('반영월(끝)은 반영월(시작) 보다 이후 날짜여야 합니다.');
        } else {
            //3. Start_Date__c, End_Date__c 각각의 필드에 Input 할 때, Day가 1일이어야함
            ccgap.Start_Date__c = Date.newInstance(
                    ccgap.Start_Date__c.year(),
                    ccgap.Start_Date__c.month(),
                    1
            );
            ccgap.End_Date__c = Date.newInstance(
                    ccgap.End_Date__c.year(),
                    ccgap.End_Date__c.month(),
                    1
            );
        }

        this.startDate = ccgap.Start_Date__c;
        this.endDate   = ccgap.End_Date__c.addMonths(1);
    }

    public void calcAmount() {
        // 1개 기준 사업계획, 연간추정, GAP 계산
        // CC 여서 매입기준 계산 (매출 포함x)

        Map<String, Double> planMap = aggToMap(getCostPlan());           //사업계획
        Map<String, Double> gapMap = new Map<String, Double>();          //GAP
        Map<String, Double> predictMap = new Map<String, Double>();       //연간추정
        Map<String, Double> performanceMap = aggToMap(getPerformance()); //연간추정:실적
        Map<String, Double> weeklyCostMap = aggToMap(getWeeklyCost());   //연간추정:주간예상실적
        Map<String, Double> actionPlanMap = aggToMap(getActionPlan());   //연간추정:실행계획

        //연간추정
        predictMap = sumAToB(actionPlanMap, sumAToB(performanceMap, weeklyCostMap));

        System.debug('실행계획 : ' + actionPlanMap);
        System.debug('주간예상 : ' + weeklyCostMap);
        System.debug('실적 : ' + performanceMap);
        System.debug('실적추정 : ' + predictMap);

        //GAP : 연간추정-사업계획
        gapMap = subAToB(predictMap, planMap);

        //계정과목별 사업계획, 연간추정, GAP 금액값 매핑
        CCGAP__c ccGap = listNew[0];
        Double plan, predict, gap;

        for(CC_GAP_Info__mdt info : ccgapInfo.lowerSortInfos) {
            String key = info.LowerSort__c;

            plan = planMap.containsKey(key) ? planMap.get(key) : 0;
            predict = predictMap.containsKey(key) ? predictMap.get(key) : 0;
            gap = gapMap.containsKey(key) ? gapMap.get(key) : 0;

            ccGap.put(info.PlanField__c, plan);
            ccGap.put(info.PredictField__c, predict);
            ccGap.put(info.GapField__c, gap);
        }

        // 총합 업데이트
        Double sumPlan=0.0, sumPredict=0.0, sumGap=0.0;

        for(Double val : planMap.values()) {
            sumPlan += val;
        }

        for(Double val : predictMap.values()) {
            sumPredict += val;
        }

        for(Double val : gapMap.values()) {
            sumGap += val;
        }

        ccGap.Plan_Total__c = sumPlan;
        ccGap.Predict_Total__c = sumPredict;
        ccGap.GAP_Total__c = sumGap;
    }

    /**
     * @param aggList
     *
     * @return //key: lowerSort - value: 금액
     */
    public Map<String, Double> aggToMap(List<AggregateResult> aggList) {
        Map<String, Double> returnMap = new Map<String, Double>();

        for(AggregateResult agg : aggList) {
            String aggKey = (String) agg.get('LOWER_SORT');
            if(!returnMap.containsKey(aggKey)) {
                Double aggSum = Double.valueOf(agg.get('SUM_AMOUNT'));
                returnMap.put(aggKey, aggSum);
            }
        }

        return returnMap;
    }

    /**
     * @param aMap A
     * @param bMap B
     *
     * @return A+B
     */
    public Map<String, Double> sumAToB(Map<String, Double> aMap, Map<String, Double> bMap) {
        Map<String, Double> returnMap = new Map<String, Double>();

        for(String key : aMap.keySet()) {
            Double value = aMap.get(key);
            if(bMap.containsKey(key)) {
                value += bMap.get(key);
            }

            returnMap.put(key, value);
        }

        for(String key : bMap.keySet()) {
            if(!aMap.containsKey(key)) {
                returnMap.put(key, bMap.get(key));
            }
        }

        System.debug('------sumAToB start------');
        System.debug('aMap : ' + aMap);
        System.debug('bMap : ' + bMap);
        System.debug('sumAToB returnMap : ' + returnMap);
        return returnMap;
    }

    /**
     * @param aMap A
     * @param bMap B
     *
     * @return A-B
     */
    public Map<String, Double> subAToB(Map<String, Double> aMap, Map<String, Double> bMap) {
        Map<String, Double> returnMap = new Map<String, Double>();

        for(String key : aMap.keySet()) {
            Double value = aMap.get(key);
            if(bMap.containsKey(key)) {
                value -= bMap.get(key);
            }

            returnMap.put(key, value);
        }

        for(String key : bMap.keySet()) {
            if(!aMap.containsKey(key)) {
                returnMap.put(key, -bMap.get(key));
            }
        }

        return returnMap;
    }

    /**
     * @return 사업계획(매입) --- 그룹 : 계정과목 Lower
     */
    public List<AggregateResult> getCostPlan() {
        List<AggregateResult> aggList = [
                SELECT AccountSubjectselect__r.LowerSort__c LOWER_SORT,
                        SUM(PlanPurchaseAmount__c) SUM_AMOUNT
                FROM Cost_Plan__c
                WHERE WBS__c = :listNew[0].WBS_CC__c
                AND AccountSubjectselect__r.LowerSort__c IN :ccgapInfo.lowerSortSet
                AND CalculateDate__c >=: this.startDate
                AND CalculateDate__c <: this.endDate
                AND Real_Data_check__c = TRUE
                AND PlanPurchaseAmount__c != 0
                AND PlanPurchaseAmount__c != NULL
                GROUP BY AccountSubjectselect__r.LowerSort__c
        ];

        return aggList;
    }

    /**
     * @description 연간추정 계산
     * @return 실적
     */
    public List<AggregateResult> getPerformance() {
        List<AggregateResult> aggList = [
                SELECT AccountSubjectSelect__r.LowerSort__c LOWER_SORT,
                        SUM(PerformanceAmount__c) SUM_AMOUNT
                FROM Performance__c
                WHERE WBS__c = :listNew[0].WBS_CC__c
                AND AccountSubjectSelect__r.LowerSort__c IN :ccgapInfo.lowerSortSet
                AND PerformanceMonth__c >=: this.startDate
                AND PerformanceMonth__c <: this.endDate
                AND Real_Data_check__c = TRUE
                AND PerformanceAmount__c != 0
                AND PerformanceAmount__c != NULL
                GROUP BY AccountSubjectSelect__r.LowerSort__c
        ];

        return aggList;
    }

    /**
     * @description 연간추정 계산
     * @return 주간예상(매입)
     */
    public List<AggregateResult> getWeeklyCost() {
        List<AggregateResult> aggList = [
                SELECT AccountSubjectselect__r.LowerSort__c LOWER_SORT,
                        SUM(PurchaseAmount__c) SUM_AMOUNT
                FROM Weekly_cost_expect__c
                WHERE WBS__c = :listNew[0].WBS_CC__c
                AND AccountSubjectselect__r.LowerSort__c IN :ccgapInfo.lowerSortSet
                AND CalculateDate__c >: this.stdPerformanceDate
                AND CalculateDate__c <=: this.stdWeeklyDate
                AND CalculateDate__c >=: this.startDate
                AND CalculateDate__c <: this.endDate
                AND Latest_Data_Check__c = TRUE
                AND Real_Data_check__c = TRUE
                AND PurchaseAmount__c != 0
                AND PurchaseAmount__c != NULL
                GROUP BY AccountSubjectselect__r.LowerSort__c
        ];

        return aggList;
    }

    /**
     * @description 연간추정 계산
     * @return 실행계획(매입)
     */
    public List<AggregateResult> getActionPlan() {
        List<AggregateResult> aggList = [
                SELECT AccountSubjectselect__r.LowerSort__c LOWER_SORT,
                        SUM(ActionPlanPurchaseAmount__c) SUM_AMOUNT
                FROM Cost_Action_Plan__c
                WHERE AccountSubjectselect__r.LowerSort__c =: ccgapInfo.lowerSortSet
                AND WBS__c = :listNew[0].WBS_CC__c
                AND Latest_Data_Check__c = TRUE
                AND CalculateDate__c >: this.stdPerformanceDate //check
                AND CalculateDate__c >: this.stdWeeklyDate
                AND CalculateDate__c >=: this.startDate
                AND CalculateDate__c <: this.endDate
                AND Real_Data_check__c = TRUE
                AND ActionPlanPurchaseAmount__c != 0
                AND ActionPlanPurchaseAmount__c != NULL
                GROUP BY AccountSubjectselect__r.LowerSort__c
        ];

        return aggList;
    }

    /**
     * @description 기준 실적 월 Set
     */
    public void setStdPerformanceMonth() {
        List<Performance__c> stdPerformances = [
                SELECT Id, Name, PerformanceMonth__c
                FROM Performance__c
                WHERE CreatedDate >= LAST_N_MONTHS:2
                ORDER BY PerformanceMonth__c DESC
                LIMIT 1
        ];

        if(!stdPerformances.isEmpty()) {
            this.stdPerformanceDate = stdPerformances[0].PerformanceMonth__c;
            System.debug('기준실적월 : ' + stdPerformanceDate);
        }
    }

    /**
     * @description 기준 주간예상 월 Set
     */
    public void setStdWeeklyMonth() {
        List<weekly_amount_expect__c> stdWeeklyAmounts = [
                SELECT Id, CalculateDate__c
                FROM weekly_amount_expect__c
                WHERE Real_Data_check__c = TRUE
                AND Weekly__c != NULL
                AND Latest_Data_Check__c = TRUE
                AND CalculateDate__c = THIS_YEAR
                ORDER BY Weekly__c DESC
                LIMIT 1
        ];

        if(!stdWeeklyAmounts.isEmpty()) {
            this.stdWeeklyDate = stdWeeklyAmounts[0].CalculateDate__c;
            System.debug('기준주간예상일 : ' + stdWeeklyDate);
        }
    }
}