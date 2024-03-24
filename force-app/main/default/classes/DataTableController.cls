public without sharing class DataTableController {

    public static String WBS_ID = '';
    public static Integer YEAR_INPUT_INT = 0;
    public static String  YEAR_INPUT_STR = '';
    public static String  THIS_YEAR_STR = String.valueOf(Date.today().year());
    public static Boolean isCCP = false; //CC&판 유무 -> TRUE: 판매비와관리비 보여줌
    public static Boolean includeAmount = false; //매출포함유무
    public static final Integer NUMBER_OF_MONTHS = 12;
    public static List<String> stringFormats = new String[]{'0','number','###,###,###,##0'};
    public static Integer stdPerformanceMonth = null;
    public static Integer stdWeeklyMonth = null;

    //WBS 클릭시 호출
    //현장/운영 구분 클릭시 호출
    @AuraEnabled(Cacheable = true)
    public static String getAmountInfo(String wbsId, String locType, String yearInput) {
        String sampleKey = 'a015g00000nvy3rAAA-1';
        String sampleKey2 = 'a015g00000nvy3rAAA-2';

        System.debug(
                '   @@@wbsId: ' + wbsId +
                '   @@@locType: ' + locType +
                '   @@@yearInput: ' + yearInput
        );

        //----------공통작업---------->

        WBSandCC__c targetWBS = getWBS(wbsId);
        WBS_ID  = targetWBS.Id;

        if(yearInput != null) {
            YEAR_INPUT_INT = Integer.valueOf(yearInput);
            YEAR_INPUT_STR = yearInput;
        }

        stdPerformanceMonth = getStdPerformanceMonth();
        stdWeeklyMonth      = getStdWeeklyMonth();

        System.debug('THIS_YEAR_STR : ' + THIS_YEAR_STR);
        System.debug('YEAR_INPUT_STR : ' + YEAR_INPUT_STR);
        System.debug('Equal? : ' + THIS_YEAR_STR.equals(YEAR_INPUT_STR));


//        if(targetWBS.Check_WBS_CC_ZF__c == 'CC') { //CC일때는 무조건 현장
//            locType = '현장';
//        }

        //--------------------------//

        List<AccountSubject__c> accSubList = getAccountSubjectList(targetWBS);

        System.debug('isCCP: ' + isCCP);
        //사업 계획 (키: wbs-계정과목-정산일자)
        //Map<String, Double> planAmtMap = sumAToB(aggToMap(getAmountPlan(wbsId)), aggToMap(getCostPlan(wbsId)));
        Map<String, Double> planAmtMap = new Map<String, Double>(); //사업계획
        Map<String, Double> actionPlanAmtMap = new Map<String, Double>(); //실행계획
        Map<String, Double> expectPerformanceAmtMap = new Map<String, Double>(); //예상실적
        Map<String, Double> performanceAmtMap = aggToMap(getPerformance()); //실적
        Map<String, Double> expectGAPAmtMap = new Map<String, Double>(); //예상 GAP
        Map<String, Double> performanceGAPAmtMap = new Map<String, Double>(); //실적 GAP
        Map<String, Double> performanceEstimateAmtMap = new Map<String, Double>(); //실적 추정 (운영추가 23.03.21)
        Map<String, Double> performanceEstimateGAPAmtMap = new Map<String, Double>(); //실적 추정 GAP (운영추가 23.03.21)

        if(includeAmount) {
            //매출 포함
            planAmtMap.putAll(aggToMap(getAmountPlan()));
            actionPlanAmtMap.putAll(aggToMap(getAmountActionPlan()));
            expectPerformanceAmtMap.putAll(aggToMap((locType=='현장') ? getAmount() : getWeeklyAmount()));
        }
        //매입 포함(ALL)
        planAmtMap.putAll(aggToMap(getCostPlan()));
        actionPlanAmtMap.putAll(aggToMap(getCostActionPlan()));
        expectPerformanceAmtMap.putAll(aggToMap((locType=='현장') ? getCost() : getWeeklyCost()));

        if(locType == '현장') {
            //GAP 계산
            expectGAPAmtMap      = subAToB(expectPerformanceAmtMap, actionPlanAmtMap); //예상 GAP
            performanceGAPAmtMap = subAToB(performanceAmtMap, actionPlanAmtMap); //실적 GAP //230404 수정 (수식변경 : 사업계획 -> 실행계획)

            //23.05.30 dgchoi :: 실적 추정
            Double estimateValue = 0;
            String mapKey = '';
            for(AccountSubject__c accSub : accSubList) {
                for(Integer i=1; i<=NUMBER_OF_MONTHS; i++) {
                    mapKey = accSub.Id + '-' + i; //아이템관리Id-정산월

                    System.debug('mapkey :::: ' + mapkey);
                    if (THIS_YEAR_STR.equals(YEAR_INPUT_STR)) { //24.01.29 dgchoi 과거년도 조건 추가
                        if (stdPerformanceMonth != null && i <= stdPerformanceMonth) { //실적이 있고, 실적 이하 월일 때
                            estimateValue = performanceAmtMap.containsKey(mapKey) ? performanceAmtMap.get(mapKey) : 0; //실적
                        } else if (stdPerformanceMonth == null || i > stdPerformanceMonth) { //실적이 없거나, 실적 초과 월일 때
                            estimateValue = expectPerformanceAmtMap.containsKey(mapKey) ? expectPerformanceAmtMap.get(mapKey) : 0; //예상실적
                        } else {
                            estimateValue = 0;
                        }
                    } else { //24.01.29 dgchoi 과거년도 조건 추가
                        estimateValue = performanceAmtMap.containsKey(mapKey) ? performanceAmtMap.get(mapKey) : 0; //실적
                    }

                    performanceEstimateAmtMap.put(mapKey, estimateValue);

                    /*
                    mapKey = accSub.Id + '-' + i; //아이템관리Id-정산월
                    if(performanceAmtMap.containsKey(mapKey)) { //실적
                        estimateValue = performanceAmtMap.get(mapKey);
                    } else if(expectPerformanceAmtMap.containsKey(mapKey)){ //주간예상
                        estimateValue = expectPerformanceAmtMap.get(mapKey);
                    } else {
                        estimateValue = 0;
                    }
                    performanceEstimateAmtMap.put(mapKey, estimateValue);
                     */
                }
            }

        } else if(locType == '운영') {
            //실적 추정 계산
            Double estimateValue = 0;
            String mapKey = '';
            for(AccountSubject__c accSub : accSubList) {
                for(Integer i=1; i<=NUMBER_OF_MONTHS; i++) {
                    mapKey = accSub.Id + '-' + i; //아이템관리Id-정산월

                    if(THIS_YEAR_STR.equals(YEAR_INPUT_STR)) { //24.01.29 dgchoi 과거년도 체크 조건 추가
                        if(stdPerformanceMonth!=null && i<=stdPerformanceMonth) { //기준실적이 있고, 실적 이하 월 일때
                            estimateValue = performanceAmtMap.containsKey(mapKey) ? performanceAmtMap.get(mapKey) : 0; //실적
                        } else if(stdPerformanceMonth==null || i>stdPerformanceMonth) { //실적이 없거나, 실적 초과 월일 때
                            if(stdWeeklyMonth!=null && i==stdWeeklyMonth) { //기준주간예상이 있고, 주간예상 월 일때
                                estimateValue = expectPerformanceAmtMap.containsKey(mapKey) ? expectPerformanceAmtMap.get(mapKey) : 0; //주간예상실적
                            } else {
                                estimateValue = actionPlanAmtMap.containsKey(mapKey) ? actionPlanAmtMap.get(mapKey) : 0; //실행계획
                            }
                        } else {
                            estimateValue = 0;
                        }
                    } else { //24.01.29 dgchoi 과거년도 체크 조건 추가
                        estimateValue = performanceAmtMap.containsKey(mapKey) ? performanceAmtMap.get(mapKey) : 0; //실적
                    }

                    performanceEstimateAmtMap.put(mapKey, estimateValue);

                    /*
                    mapKey = accSub.Id + '-' + i; //아이템관리Id-정산월
                    if(performanceAmtMap.containsKey(mapKey)) { //실적
                        estimateValue = performanceAmtMap.get(mapKey);
                    } else if(expectPerformanceAmtMap.containsKey(mapKey)){ //주간예상
                        estimateValue = expectPerformanceAmtMap.get(mapKey);
                    } else if(actionPlanAmtMap.containsKey(mapKey)) { //실행계획
                        estimateValue = actionPlanAmtMap.get(mapKey);
                    } else {
                        estimateValue = 0;
                    }
                    performanceEstimateAmtMap.put(mapKey, estimateValue);
                     */
                }
            }

            //GAP 계산
            performanceEstimateGAPAmtMap = subAToB(performanceEstimateAmtMap, planAmtMap);
        }

        //실적 추정 (키: wbs-계정과목-정산일자)
        //함수 내에서 현장/운영  구분
        //Map<String, Double> expPerformMap = calculPerformance(locType);

//       System.debug('실적추정Map: ' + expPerformMap);
//       //계획대비차이 (키: wbs-계정과목-정산일자)
//       Map<String, Double> gapMap = subAToB(planAmtMap, expPerformMap);

        //-----------returnList 생성------------
        List<returnClass> returnList = new List<returnClass>();

        for(AccountSubject__c accSub : accSubList) {
            returnClass returnClass = new returnClass();

            //계정과목
            AccountSubjectClass accSubClass = new AccountSubjectClass();
            accSubClass.Id = accSub.Id;
            accSubClass.Upper = accSub.UpperSort__c;
            accSubClass.Middle = accSub.MiddleSort__c;
            accSubClass.Lower = accSub.LowerSort__c;
            accSubClass.AccountSubjectCode = accSub.AccountSubjectCode__c;
            accSubClass.AccountSubjectName = accSub.Name;
            returnClass.AccountSubject = accSubClass;

            //WBS   //for(WBSandCC__c wbs : wbsList) {
            WBSClass wbsClass = new WBSClass();
            wbsClass.Name    = targetWBS.Name;
            wbsClass.WBSCode = targetWBS.WBS_Code__c;
            wbsClass.WBSorCC = targetWBS.Check_WBS_CC_ZF__c;
            wbsClass.YorP    = targetWBS.AccountSubjectSort__c;
            returnClass.WBS = wbsClass;

            //실적
            List<PerformanceClass> pClassList = new List<PerformanceClass>();

            Double sumPlanAmt = 0.0,
                   sumActionPlanAmt = 0.0,
                   sumExpectPerformance = 0.0,
                   sumPerformance = 0.0,
                   sumExpectGAP = 0.0,
                   sumPerformanceGAP = 0.0,
                   sumPerformanceEstimate = 0.0,
                   sumPerformanceEstimateGAP = 0.0;

            Double planAmt = 0.0,
                   actionPlanAmt = 0.0,
                   expectPerformance = 0.0,
                   performance = 0.0,
                   expectGap = 0.0,
                   performanceGap = 0.0,
                   performanceEstimate = 0.0,
                   performanceEstimateGap = 0.0;

            for(Integer i=1; i<=NUMBER_OF_MONTHS; i++) { //1~12월 달별 실적
                PerformanceClass pClass = new PerformanceClass();

                Date stdDate = Date.newInstance(Date.today().year(), i, 1);
                String amtKey = accSub.Id + '-' + i;

                planAmt = (planAmtMap.containsKey(amtKey) == true && planAmtMap.get(amtKey) != null) ? planAmtMap.get(amtKey) : 0;
                actionPlanAmt = (actionPlanAmtMap.containsKey(amtKey) == true && actionPlanAmtMap.get(amtKey) != null) ? actionPlanAmtMap.get(amtKey) : 0;
                expectPerformance = (expectPerformanceAmtMap.containsKey(amtKey) == true && expectPerformanceAmtMap.get(amtKey) != null) ? expectPerformanceAmtMap.get(amtKey) : 0;
                performance = (performanceAmtMap.containsKey(amtKey) == true && performanceAmtMap.get(amtKey) != null) ? performanceAmtMap.get(amtKey) : 0;
                expectGap = (expectGAPAmtMap.containsKey(amtKey) == true && expectGAPAmtMap.get(amtKey) != null) ? expectGAPAmtMap.get(amtKey) : 0;
                performanceGap = (performanceGAPAmtMap.containsKey(amtKey) == true && performanceGAPAmtMap.get(amtKey) != null) ? performanceGAPAmtMap.get(amtKey) : 0;
                //운영
                performanceEstimate = (performanceEstimateAmtMap.containsKey(amtKey) == true && performanceEstimateAmtMap.get(amtKey) != null) ? performanceEstimateAmtMap.get(amtKey) : 0;
                performanceEstimateGap = (performanceEstimateGAPAmtMap.containsKey(amtKey) == true && performanceEstimateGAPAmtMap.get(amtKey) != null) ? performanceEstimateGAPAmtMap.get(amtKey) : 0;

                pClass.CalDate  = stdDate;
                pClass.CalMonth = i;
                pClass.PlanAmt                = formatNumber(planAmt);
                pClass.ActionPlanAmt          = formatNumber(actionPlanAmt);
                pClass.ExpectPerformance      = formatNumber(expectPerformance);
                pClass.Performance            = formatNumber(performance);
                pClass.ExpectGAP              = formatNumber(expectGap);
                pClass.PerformanceGAP         = formatNumber(performanceGap);
                pClass.PerformanceEstimate    = formatNumber(performanceEstimate); //운영
                pClass.PerformanceEstimateGAP = formatNumber(performanceEstimateGap); //운영

                //pClass.ExpectedPerformanceAmt = (expPerformMap.containsKey(amtKey) == true) ? expPerformMap.get(amtKey) : 0; //실적추정
                //pClass.GapAmt = (gapMap.containsKey(amtKey) == true) ? gapMap.get(amtKey) : 0; //계획대비차이
                sumPlanAmt                += planAmt;
                sumActionPlanAmt          += actionPlanAmt;
                sumExpectPerformance      += expectPerformance;
                sumPerformance            += performance;
                sumExpectGAP              += expectGap;
                sumPerformanceGAP         += performanceGap;
                sumPerformanceEstimate    += performanceEstimate; //현장,운영 실적추정 : 23.05.30 dgchoi
                sumPerformanceEstimateGAP += performanceEstimateGap; //운영

                pClassList.add(pClass);
            }

            //연간 합계(total) - stdDate는 null 들어갈꺼.....
            PerformanceClass totalPClass = new PerformanceClass();
            totalPClass.PlanAmt                = formatNumber(sumPlanAmt);
            totalPClass.ActionPlanAmt          = formatNumber(sumActionPlanAmt);
            totalPClass.ExpectPerformance      = formatNumber(sumExpectPerformance);
            totalPClass.Performance            = formatNumber(sumPerformance);
            totalPClass.ExpectGAP              = formatNumber(sumExpectGAP);
            totalPClass.PerformanceGAP         = formatNumber(sumPerformanceGAP);
            totalPClass.PerformanceEstimate    = formatNumber(sumPerformanceEstimate); //운영
            totalPClass.PerformanceEstimateGAP = formatNumber(sumPerformanceEstimate - sumPlanAmt); //운영
            pClassList.add(0, totalPClass); //total이 맨 처음값

            returnClass.Performance = pClassList;

            returnList.add(returnClass);
        }


        System.debug('--------사업 계획--------');
        System.debug(planAmtMap);
        System.debug('--------실적 추정--------');
        System.debug('실적추정 Map : ' + performanceEstimateAmtMap);

        //System.debug('실적추정 1월 ::::' + (performanceEstimateAmtMap.containsKey(sampleKey) ? performanceEstimateAmtMap.get(sampleKey) : 9999));
        //System.debug('실적추정 2월 ::::' + (performanceEstimateAmtMap.containsKey(sampleKey2) ? performanceEstimateAmtMap.get(sampleKey2) : 9999));
        System.debug('---------실적----------');
        System.debug(performanceAmtMap);
        //System.debug('실적 1월 ::::' + (performanceAmtMap.containsKey(sampleKey) ? performanceAmtMap.get(sampleKey) : 9999));
        //System.debug('실적 2월 ::::' + (performanceAmtMap.containsKey(sampleKey2) ? performanceAmtMap.get(sampleKey2) : 9999));
        System.debug('---------예상실적---------');
        System.debug(expectPerformanceAmtMap);
        //System.debug('예상실적 1월 ::::' + (expectPerformanceAmtMap.containsKey(sampleKey) ? expectPerformanceAmtMap.get(sampleKey) : 9999));
        //System.debug('예상실적 2월 ::::' + (expectPerformanceAmtMap.containsKey(sampleKey2) ? expectPerformanceAmtMap.get(sampleKey2) : 9999));
        System.debug('---------실행계획---------');
        System.debug(actionPlanAmtMap);
        //System.debug('실행계획 1월 ::::' + (actionPlanAmtMap.containsKey(sampleKey) ? actionPlanAmtMap.get(sampleKey) : 9999));
        //System.debug('실행계획 2월 ::::' + (actionPlanAmtMap.containsKey(sampleKey2) ? actionPlanAmtMap.get(sampleKey2) : 9999));
        System.debug('--------sampleKey1--------');



        //    System.debug(gapMap);
        //---------------------------------------
        System.debug('returnList: ' + returnList);

        return JSON.serialize(returnList);
    }

    //구분별 금액 합
    @AuraEnabled(Cacheable = true)
    public static Map<String, Map<String, List<String>>> getSumAmount(String wbsId, String locType, String yearInput) { //accSubType: upper, middle, lower
        //----------공통작업---------->
        WBSandCC__c targetWBS = getWBS(wbsId);
        WBS_ID  = targetWBS.Id;

        if(yearInput != null) {
            YEAR_INPUT_INT = Integer.valueOf(yearInput);
            YEAR_INPUT_STR = yearInput;
        }

        stdPerformanceMonth = getStdPerformanceMonth();
        stdWeeklyMonth = getStdWeeklyMonth();

//        if(targetWBS.Check_WBS_CC_ZF__c == 'CC') { //CC일때는 무조건 현장
//            locType = '현장';
//        }
        //--------------------------//

        //23.05.30 dgchoi : 현장 연간합계 열 변경 : 사업계획, 실적 합계(연간추정), GAP

        List<AccountSubject__c> accSubList = getAccountSubjectList(targetWBS);

        Set<String> upperSet = new Set<String>();
        Set<String> middleSet = new Set<String>();
        Set<String> lowerSet = new Set<String>();

        for(AccountSubject__c a : accSubList) {
            upperSet.add(a.UpperSort__c);
            middleSet.add(a.MiddleSort__c);
            lowerSet.add(a.LowerSort__c);
        }

        Map<String, Map<String, List<String>>> returnMap = new Map<String, Map<String, List<String>>> ();

        Map<String, List<String>> upperMap = new Map<String, List<String>>();
        Map<String, List<String>> middleMap = new Map<String, List<String>>();
        Map<String, List<String>> lowerMap = new Map<String, List<String>>();

        Map<String, Double> upper_planAmtMap = new Map<String, Double>(); //사업계획
        Map<String, Double> upper_actionPlanAmtMap = new Map<String, Double>(); //실행계획
        Map<String, Double> upper_expectPerformanceAmtMap = new Map<String, Double>(); //예상실적
        Map<String, Double> upper_performanceAmtMap = aggToMap(getPerformance('UpperSort__c')); //실적
        Map<String, Double> upper_expectGapAmtMap = new Map<String, Double>(); //현장
        Map<String, Double> upper_performanceGapAmtMap = new Map<String, Double>(); //현장
        Map<String, Double> upper_performanceEstimateAmtMap = new Map<String, Double>(); //23.05.30 dgchoi 현장,운영 - 실적추정
        Map<String, Double> upper_performanceEstimateGapAmtMap = new Map<String, Double>(); //23.05.30 dgchoi 23.05.30 dgchoi 현장,운영 - GAP(실적추정-사업계획)

        Map<String, Double> middle_planAmtMap = new Map<String, Double>();
        Map<String, Double> middle_actionPlanAmtMap = new Map<String, Double>();
        Map<String, Double> middle_expectPerformanceAmtMap = new Map<String, Double>();
        Map<String, Double> middle_performanceAmtMap = aggToMap(getPerformance('MiddleSort__c'));
        Map<String, Double> middle_expectGapAmtMap = new Map<String, Double>();
        Map<String, Double> middle_performanceGapAmtMap = new Map<String, Double>();
        Map<String, Double> middle_performanceEstimateAmtMap = new Map<String, Double>(); //23.05.30 dgchoi 현장,운영 - 실적추정
        Map<String, Double> middle_performanceEstimateGapAmtMap = new Map<String, Double>(); //23.05.30 dgchoi 현장,운영 - GAP(실적추정-사업계획)

        Map<String, Double> lower_planAmtMap = new Map<String, Double>();
        Map<String, Double> lower_actionPlanAmtMap = new Map<String, Double>();
        Map<String, Double> lower_expectPerformanceAmtMap = new Map<String, Double>();
        Map<String, Double> lower_performanceAmtMap = aggToMap(getPerformance('LowerSort__c'));
        Map<String, Double> lower_expectGapAmtMap = new Map<String, Double>();
        Map<String, Double> lower_performanceGapAmtMap = new Map<String, Double>();
        Map<String, Double> lower_performanceEstimateAmtMap = new Map<String, Double>();  //23.05.30 dgchoi 현장,운영 - 실적추정
        Map<String, Double> lower_performanceEstimateGapAmtMap = new Map<String, Double>(); //23.05.30 dgchoi 현장,운영 - GAP(실적추정-사업계획)

        if(includeAmount) {
            //매출 포함
            upper_planAmtMap.putAll(aggToMap(getAmountPlan('UpperSort__c')));
            upper_actionPlanAmtMap.putAll(aggToMap(getAmountActionPlan('UpperSort__c')));
            upper_expectPerformanceAmtMap.putAll(aggToMap((locType=='현장') ? getAmount('UpperSort__c') : getWeeklyAmount('UpperSort__c')));

            middle_planAmtMap.putAll(aggToMap(getAmountPlan('MiddleSort__c')));
            middle_actionPlanAmtMap.putAll(aggToMap(getAmountActionPlan('MiddleSort__c')));
            middle_expectPerformanceAmtMap.putAll(aggToMap((locType=='현장') ? getAmount('MiddleSort__c') : getWeeklyAmount('MiddleSort__c')));

            lower_planAmtMap.putAll(aggToMap(getAmountPlan('LowerSort__c')));
            lower_actionPlanAmtMap.putAll(aggToMap(getAmountActionPlan('LowerSort__c')));
            lower_expectPerformanceAmtMap.putAll(aggToMap((locType=='현장') ? getAmount('LowerSort__c') : getWeeklyAmount('LowerSort__c')));
        }
        //매입 포함(ALL)
        upper_planAmtMap.putAll(aggToMap(getCostPlan('UpperSort__c')));
        upper_actionPlanAmtMap.putAll(aggToMap(getCostActionPlan('UpperSort__c')));
        upper_expectPerformanceAmtMap.putAll(aggToMap((locType=='현장') ? getCost('UpperSort__c') : getWeeklyCost('UpperSort__c')));

        middle_planAmtMap.putAll(aggToMap(getCostPlan('MiddleSort__c')));
        middle_actionPlanAmtMap.putAll(aggToMap(getCostActionPlan('MiddleSort__c')));
        middle_expectPerformanceAmtMap.putAll(aggToMap((locType=='현장') ? getCost('MiddleSort__c') : getWeeklyCost('MiddleSort__c')));

        lower_planAmtMap.putAll(aggToMap(getCostPlan('LowerSort__c')));
        lower_actionPlanAmtMap.putAll(aggToMap(getCostActionPlan('LowerSort__c')));
        lower_expectPerformanceAmtMap.putAll(aggToMap((locType=='현장') ? getCost('LowerSort__c') : getWeeklyCost('LowerSort__c')));

        if(locType == '현장') {
            //GAP 계산
            upper_expectGapAmtMap = subAToB(upper_expectPerformanceAmtMap, upper_actionPlanAmtMap); //예상 GAP
            upper_performanceGapAmtMap = subAToB(upper_performanceAmtMap, upper_actionPlanAmtMap); //실적 GAP

            middle_expectGapAmtMap = subAToB(middle_expectPerformanceAmtMap, middle_actionPlanAmtMap); //예상 GAP
            middle_performanceGapAmtMap = subAToB(middle_performanceAmtMap, middle_actionPlanAmtMap); //실적 GAP

            lower_expectGapAmtMap = subAToB(lower_expectPerformanceAmtMap, lower_actionPlanAmtMap); //예상 GAP
            lower_performanceGapAmtMap = subAToB(lower_performanceAmtMap, lower_actionPlanAmtMap); //실적 GAP

            //23.05.30 현장 실적추정 계산값 추가 (상위/중위/하위)
            String mapKey = '';
            Double estimateValue = 0;

            for(String upperKey : upperSet) {
                for(Integer i=1; i<=NUMBER_OF_MONTHS; i++) {
                    mapKey = upperKey + '-' + i;
                    //상위구분 SUM Map
                    if(THIS_YEAR_STR.equals(YEAR_INPUT_STR)) { //올해일때 //24.01.29 dgchoi 과거년도 체크 조건 추가
                        if(stdPerformanceMonth!=null && i<=stdPerformanceMonth) {
                            estimateValue = upper_performanceAmtMap.containsKey(mapKey) ? upper_performanceAmtMap.get(mapKey) : 0; //실적
                        } else if(stdPerformanceMonth==null || i>stdPerformanceMonth) {
                            estimateValue = upper_expectPerformanceAmtMap.containsKey(mapKey) ? upper_expectPerformanceAmtMap.get(mapKey) : 0; //예상실적
                        } else {
                            estimateValue = 0;
                        }
                    } else { //과거년도 일때 //24.01.29 dgchoi 과거년도 체크 조건 추가
                        estimateValue = upper_performanceAmtMap.containsKey(mapKey) ? upper_performanceAmtMap.get(mapKey) : 0; //실적
                    }

                    upper_performanceEstimateAmtMap.put(mapKey, estimateValue);

                    /*
                    mapKey = upperKey + '-' + i;
                    //상위구분 SUM Map
                    if(upper_performanceAmtMap.containsKey(mapKey)) { //실적
                        estimateValue = upper_performanceAmtMap.get(mapKey);
                    } else if(upper_expectPerformanceAmtMap.containsKey(mapKey)) { //주간예상
                        estimateValue = upper_expectPerformanceAmtMap.get(mapKey);
                    } else {
                        estimateValue = 0;
                    }
                    upper_performanceEstimateAmtMap.put(mapKey, estimateValue);
                     */
                }
            }

            for(String middleKey : middleSet) {
                for (Integer i=1; i<=NUMBER_OF_MONTHS; i++) {
                    mapKey = middleKey + '-' + i;
                    //중위구분 SUM Map
                    if(THIS_YEAR_STR.equals(YEAR_INPUT_STR)) { //올해일때 //24.01.29 dgchoi 과거년도 체크 조건 추가
                        if(stdPerformanceMonth!=null && i<=stdPerformanceMonth) {
                            estimateValue = middle_performanceAmtMap.get(mapKey); //실적
                        } else if (stdPerformanceMonth==null || i>stdPerformanceMonth) {
                            estimateValue = middle_expectPerformanceAmtMap.get(mapKey); //예상실적
                        } else {
                            estimateValue = 0;
                        }
                    } else { //과거년도 일때 //24.01.29 dgchoi 과거년도 체크 조건 추가
                        estimateValue = middle_performanceAmtMap.get(mapKey); //실적
                    }

                    middle_performanceEstimateAmtMap.put(mapKey, estimateValue);

                    /*mapKey = middleKey + '-' + i;
                    //중위구분 SUM Map
                    if (middle_performanceAmtMap.containsKey(mapKey)) { //실적
                        estimateValue = middle_performanceAmtMap.get(mapKey);
                    } else if (middle_expectPerformanceAmtMap.containsKey(mapKey)) { //주간예상
                        estimateValue = middle_expectPerformanceAmtMap.get(mapKey);
                    } else {
                        estimateValue = 0;
                    }
                    middle_performanceEstimateAmtMap.put(mapKey, estimateValue);*/
                }
            }

            for(String lowerKey : lowerSet) {
                for(Integer i=1; i<=NUMBER_OF_MONTHS; i++) {
                    mapKey = lowerKey + '-' + i;
                    //하위구분 SUM Map
                    if(THIS_YEAR_STR.equals(YEAR_INPUT_STR)) { //올해일때 //24.01.29 dgchoi 과거년도 체크 조건 추가
                        if(stdPerformanceMonth!=null && i<=stdPerformanceMonth) {
                            estimateValue = lower_performanceAmtMap.get(mapKey); //실적
                        } else if (stdPerformanceMonth==null || i>stdPerformanceMonth) {
                            estimateValue = lower_expectPerformanceAmtMap.get(mapKey); //예상실적
                        } else {
                            estimateValue = 0;
                        }
                    } else { //과거년도 일때 //24.01.29 dgchoi 과거년도 체크 조건 추가
                        estimateValue = lower_performanceAmtMap.get(mapKey); //실적
                    }

                    lower_performanceEstimateAmtMap.put(mapKey, estimateValue);

                    /*mapKey = lowerKey + '-' + i;
                    //하위구분 SUM Map
                    if(lower_performanceAmtMap.containsKey(mapKey)) { //실적
                        estimateValue = lower_performanceAmtMap.get(mapKey);
                    } else if(lower_expectPerformanceAmtMap.containsKey(mapKey)) { //주간예상
                        estimateValue = lower_expectPerformanceAmtMap.get(mapKey);
                    } else {
                        estimateValue = 0;
                    }
                    lower_performanceEstimateAmtMap.put(mapKey, estimateValue);*/
                }
            }

        } else if(locType == '운영') {
            String mapKey = '';
            Double estimateValue = 0;

            for(String upperKey : upperSet) {
                for(Integer i=1; i<=NUMBER_OF_MONTHS; i++) {
                    mapKey = upperKey + '-' + i;
                    if(THIS_YEAR_STR.equals(YEAR_INPUT_STR)) { //올해일때 //24.01.29 dgchoi 과거년도 체크 조건 추가
                        if(stdPerformanceMonth!=null && i<=stdPerformanceMonth) {
                            estimateValue = upper_performanceAmtMap.containsKey(mapKey) ? upper_performanceAmtMap.get(mapKey) : 0; //실적
                        } else if (stdPerformanceMonth==null || i>stdPerformanceMonth) {
                            if(stdWeeklyMonth!=null && i==stdWeeklyMonth) {
                                estimateValue = upper_expectPerformanceAmtMap.containsKey(mapKey) ? upper_expectPerformanceAmtMap.get(mapKey) : 0; //주간예상실적
                            } else {
                                estimateValue = upper_actionPlanAmtMap.containsKey(mapKey) ? upper_actionPlanAmtMap.get(mapKey) : 0; //실행계획
                            }
                        } else {
                            estimateValue = 0;
                        }
                    } else { //과거년도일때 //24.01.29 dgchoi 과거년도 체크 조건 추가
                        estimateValue = upper_performanceAmtMap.containsKey(mapKey) ? upper_performanceAmtMap.get(mapKey) : 0; //실적
                    }

                    upper_performanceEstimateAmtMap.put(mapKey, estimateValue);

                    /*mapKey = upperKey + '-' + i;
                    //상위구분 SUM Map
                    if(upper_performanceAmtMap.containsKey(mapKey)) { //실적
                        estimateValue = upper_performanceAmtMap.get(mapKey);
                    } else if(upper_expectPerformanceAmtMap.containsKey(mapKey)) { //주간예상
                        estimateValue = upper_expectPerformanceAmtMap.get(mapKey);
                    } else if(upper_actionPlanAmtMap.containsKey(mapKey)) { //실행계획
                        estimateValue = upper_actionPlanAmtMap.get(mapKey);
                    } else {
                        estimateValue = 0;
                    }
                    upper_performanceEstimateAmtMap.put(mapKey, estimateValue);*/
                }
            }

            for(String middleKey : middleSet) {
                for (Integer i=1; i<=NUMBER_OF_MONTHS; i++) {
                    mapKey = middleKey + '-' + i;
                    //중위구분 SUM Map
                    if(THIS_YEAR_STR.equals(YEAR_INPUT_STR)) { //올해일때 //24.01.29 dgchoi 과거년도 체크 조건 추가
                        if(stdPerformanceMonth!=null && i<=stdPerformanceMonth) {
                            estimateValue = middle_performanceAmtMap.containsKey(mapKey) ? middle_performanceAmtMap.get(mapKey) : 0; //실적
                        } else if (stdPerformanceMonth==null || i>stdPerformanceMonth) {
                            if(stdWeeklyMonth!=null && i==stdWeeklyMonth) {
                                estimateValue = middle_expectPerformanceAmtMap.containsKey(mapKey) ? middle_expectPerformanceAmtMap.get(mapKey) : 0; //주간예상실적
                            } else {
                                estimateValue = middle_actionPlanAmtMap.containsKey(mapKey) ? middle_actionPlanAmtMap.get(mapKey) : 0; //실행계획
                            }
                        } else {
                            estimateValue = 0;
                        }
                    } else { //과거년도일때 //24.01.29 dgchoi 과거년도 체크 조건 추가
                        estimateValue = middle_performanceAmtMap.containsKey(mapKey) ? middle_performanceAmtMap.get(mapKey) : 0; //실적
                    }

                    middle_performanceEstimateAmtMap.put(mapKey, estimateValue);

                    /*mapKey = middleKey + '-' + i;
                    //중위구분 SUM Map
                    if (middle_performanceAmtMap.containsKey(mapKey)) { //실적
                        estimateValue = middle_performanceAmtMap.get(mapKey);
                    } else if (middle_expectPerformanceAmtMap.containsKey(mapKey)) { //주간예상
                        estimateValue = middle_expectPerformanceAmtMap.get(mapKey);
                    } else if (middle_actionPlanAmtMap.containsKey(mapKey)) { //실행계획
                        estimateValue = middle_actionPlanAmtMap.get(mapKey);
                    } else {
                        estimateValue = 0;
                    }
                    middle_performanceEstimateAmtMap.put(mapKey, estimateValue);*/
                }
            }

            for(String lowerKey : lowerSet) {
                for(Integer i=1; i<=NUMBER_OF_MONTHS; i++) {
                    mapKey = lowerKey + '-' + i;
                    //하위구분 SUM Map
                    if(THIS_YEAR_STR.equals(YEAR_INPUT_STR)) { //올해일때 //24.01.29 dgchoi 과거년도 체크 조건 추가
                        if(stdPerformanceMonth!=null && i<=stdPerformanceMonth) {
                            estimateValue = lower_performanceAmtMap.containsKey(mapKey) ? lower_performanceAmtMap.get(mapKey) : 0; //실적
                        } else if (stdPerformanceMonth==null || i>stdPerformanceMonth) {
                            if(stdWeeklyMonth!=null && i==stdWeeklyMonth) {
                                estimateValue = lower_expectPerformanceAmtMap.containsKey(mapKey) ? lower_expectPerformanceAmtMap.get(mapKey) : 0; //주간예상실적
                            } else {
                                estimateValue = lower_actionPlanAmtMap.containsKey(mapKey) ? lower_actionPlanAmtMap.get(mapKey) : 0; //실행계획
                            }
                        } else {
                            estimateValue = 0;
                        }
                    } else { //과거년도일때 //24.01.29 dgchoi 과거년도 체크 조건 추가
                        estimateValue = lower_performanceAmtMap.containsKey(mapKey) ? lower_performanceAmtMap.get(mapKey) : 0; //실적
                    }

                    lower_performanceEstimateAmtMap.put(mapKey, estimateValue);

                    /*mapKey = lowerKey + '-' + i;
                    //하위구분 SUM Map
                    if(lower_performanceAmtMap.containsKey(mapKey)) { //실적
                        estimateValue = lower_performanceAmtMap.get(mapKey);
                    } else if(lower_expectPerformanceAmtMap.containsKey(mapKey)) { //주간예상
                        estimateValue = lower_expectPerformanceAmtMap.get(mapKey);
                    } else if(lower_actionPlanAmtMap.containsKey(mapKey)) { //실행계획
                        estimateValue = lower_actionPlanAmtMap.get(mapKey);
                    } else {
                        estimateValue = 0;
                    }
                    lower_performanceEstimateAmtMap.put(mapKey, estimateValue);*/
                }
            }

            //GAP 계산 - 실적추정GAP
            upper_performanceEstimateGapAmtMap  = subAToB(upper_performanceEstimateAmtMap, upper_planAmtMap);
            middle_performanceEstimateGapAmtMap = subAToB(middle_performanceEstimateAmtMap, middle_planAmtMap);
            lower_performanceEstimateGapAmtMap  = subAToB(lower_performanceEstimateAmtMap, lower_planAmtMap);
        }


        //계정과목 key 별 합 리스트
        Double sumPlanAmt = 0.0,
               sumExpectPerformanceAmt = 0.0;

        //1. Upper(상위구분)
        for(String upperKey : upperSet) {
            sumPlanAmt = 0;
            sumExpectPerformanceAmt = 0;

            List<String> amountList = new List<String>();

            for(Integer i=1; i<=NUMBER_OF_MONTHS; i++) {
                String amtKey = upperKey + '-' + i;

                amountList.add(upper_planAmtMap.containsKey(amtKey) ? formatNumber(upper_planAmtMap.get(amtKey)) : '0');  //사업계획
                if(locType == '현장') {
                    amountList.add(upper_actionPlanAmtMap.containsKey(amtKey) ? formatNumber(upper_actionPlanAmtMap.get(amtKey)) : '0');  //실행계획
                    amountList.add(upper_expectPerformanceAmtMap.containsKey(amtKey) ? formatNumber(upper_expectPerformanceAmtMap.get(amtKey)) : '0');  //예상실적
                    amountList.add(upper_performanceAmtMap.containsKey(amtKey) ? formatNumber(upper_performanceAmtMap.get(amtKey)) : '0');  //실적
                    amountList.add(upper_expectGapAmtMap.containsKey(amtKey) ? formatNumber(upper_expectGapAmtMap.get(amtKey)) : '0');  //예상 GAP
                    amountList.add(upper_performanceGapAmtMap.containsKey(amtKey) ? formatNumber(upper_performanceGapAmtMap.get(amtKey)) : '0');  //실적 GAP
                } else if(locType == '운영') {
                    amountList.add(upper_performanceEstimateAmtMap.containsKey(amtKey) ? formatNumber(upper_performanceEstimateAmtMap.get(amtKey)) : '0');  //실적추정
                    amountList.add(upper_performanceEstimateGapAmtMap.containsKey(amtKey) ? formatNumber(upper_performanceEstimateGapAmtMap.get(amtKey)) : '0');  //실적추정 GAP
                }
            }

            //연간 총 합계
            /* 23.05.30 dgchoi 연간 합계 열 수정
            amountList.add(0, formatNumber(sumMapValuesContainsKey(upper_planAmtMap, upperKey)));
            if(locType == '현장') {
                amountList.add(1, formatNumber(sumMapValuesContainsKey(upper_actionPlanAmtMap, upperKey)));
                amountList.add(2, formatNumber(sumMapValuesContainsKey(upper_expectPerformanceAmtMap, upperKey)));
                amountList.add(3, formatNumber(sumMapValuesContainsKey(upper_performanceAmtMap, upperKey)));
                amountList.add(4, formatNumber(sumMapValuesContainsKey(upper_expectGapAmtMap, upperKey)));
                amountList.add(5, formatNumber(sumMapValuesContainsKey(upper_performanceGapAmtMap, upperKey)));
            } else if(locType == '운영') {
                amountList.add(1, formatNumber(sumMapValuesContainsKey(upper_performanceEstimateAmtMap, upperKey)));
                amountList.add(2, formatNumber(sumMapValuesContainsKey(upper_performanceEstimateGapAmtMap, upperKey)));
            }
            upperMap.put(upperKey, amountList);
             */

            //연간 총 합계
            sumPlanAmt = sumMapValuesContainsKey(upper_planAmtMap, upperKey);
            sumExpectPerformanceAmt = sumMapValuesContainsKey(upper_performanceEstimateAmtMap, upperKey);

            amountList.add(0, formatNumber(sumPlanAmt));
            amountList.add(1, formatNumber(sumExpectPerformanceAmt));
            amountList.add(2, formatNumber(sumExpectPerformanceAmt - sumPlanAmt));

            upperMap.put(upperKey, amountList);

        }

        //2. Middle(중위구분)
        for(String middleKey : middleSet) {
            sumPlanAmt = 0;
            sumExpectPerformanceAmt = 0;

            List<String> amountList = new List<String>();

            for(Integer i=1; i<=NUMBER_OF_MONTHS; i++) {
                String amtKey = middleKey + '-' + i;

                amountList.add(middle_planAmtMap.containsKey(amtKey) ? formatNumber(middle_planAmtMap.get(amtKey)) : '0');  //사업계획
                if(locType == '현장') {
                    amountList.add(middle_actionPlanAmtMap.containsKey(amtKey) ? formatNumber(middle_actionPlanAmtMap.get(amtKey)) : '0');  //실행계획 //23.05.30 dgchoi
                    amountList.add(middle_expectPerformanceAmtMap.containsKey(amtKey) ? formatNumber(middle_expectPerformanceAmtMap.get(amtKey)) : '0');  //예상실적
                    amountList.add(middle_performanceAmtMap.containsKey(amtKey) ? formatNumber(middle_performanceAmtMap.get(amtKey)) : '0');  //실적
                    amountList.add(middle_expectGapAmtMap.containsKey(amtKey) ? formatNumber(middle_expectGapAmtMap.get(amtKey)) : '0');  //예상 GAP
                    amountList.add(middle_performanceGapAmtMap.containsKey(amtKey) ? formatNumber(middle_performanceGapAmtMap.get(amtKey)) : '0');  //실적 GAP //23.05.30 dgchoi
                } else if(locType == '운영') {
                    amountList.add(middle_performanceEstimateAmtMap.containsKey(amtKey) ? formatNumber(middle_performanceEstimateAmtMap.get(amtKey)) : '0');  //실적추정
                    amountList.add(middle_performanceEstimateGapAmtMap.containsKey(amtKey) ? formatNumber(middle_performanceEstimateGapAmtMap.get(amtKey)) : '0');  //실적추정 GAP
                }
            }

            //연간 총 합계
            /* 23.05.30 dgchoi 연간 합계 열 수정
            amountList.add(0, formatNumber(sumMapValuesContainsKey(middle_planAmtMap, middleKey)));
            if(locType == '현장') {
                amountList.add(1, formatNumber(sumMapValuesContainsKey(middle_actionPlanAmtMap, middleKey)));
                amountList.add(2, formatNumber(sumMapValuesContainsKey(middle_expectPerformanceAmtMap, middleKey)));
                amountList.add(3, formatNumber(sumMapValuesContainsKey(middle_performanceAmtMap, middleKey)));
                amountList.add(4, formatNumber(sumMapValuesContainsKey(middle_expectGapAmtMap, middleKey)));
                amountList.add(5, formatNumber(sumMapValuesContainsKey(middle_performanceGapAmtMap, middleKey)));
            } else if(locType == '운영') {
                amountList.add(1, formatNumber(sumMapValuesContainsKey(middle_performanceEstimateAmtMap, middleKey)));
                amountList.add(2, formatNumber(sumMapValuesContainsKey(middle_performanceEstimateGapAmtMap, middleKey)));
            }

            middleMap.put(middleKey, amountList);
             */

            //연간 총 합계
            sumPlanAmt = sumMapValuesContainsKey(middle_planAmtMap, middleKey);
            sumExpectPerformanceAmt = sumMapValuesContainsKey(middle_performanceEstimateAmtMap, middleKey);

            amountList.add(0, formatNumber(sumPlanAmt));
            amountList.add(1, formatNumber(sumExpectPerformanceAmt));
            amountList.add(2, formatNumber(sumExpectPerformanceAmt - sumPlanAmt));

            middleMap.put(middleKey, amountList);
        }

        //3. lower(하위구분)
        for(String lowerKey : lowerSet) {
            sumPlanAmt = 0;
            sumExpectPerformanceAmt = 0;

            List<String> amountList = new List<String>();

            for(Integer i=1; i<=NUMBER_OF_MONTHS; i++) {
                String amtKey = lowerKey + '-' + i;

                amountList.add(lower_planAmtMap.containsKey(amtKey) ? formatNumber(lower_planAmtMap.get(amtKey)) : '0');  //사업계획
                if(locType == '현장') {
                    amountList.add(lower_actionPlanAmtMap.containsKey(amtKey) ? formatNumber(lower_actionPlanAmtMap.get(amtKey)) : '0');  //실행계획 //23.05.30 dgchoi
                    amountList.add(lower_expectPerformanceAmtMap.containsKey(amtKey) ? formatNumber(lower_expectPerformanceAmtMap.get(amtKey)) : '0');  //예상실적
                    amountList.add(lower_performanceAmtMap.containsKey(amtKey) ? formatNumber(lower_performanceAmtMap.get(amtKey)) : '0');  //실적
                    amountList.add(lower_expectGapAmtMap.containsKey(amtKey) ? formatNumber(lower_expectGapAmtMap.get(amtKey)) : '0');  //예상 GAP //23.05.30 dgchoi
                    amountList.add(lower_performanceGapAmtMap.containsKey(amtKey) ? formatNumber(lower_performanceGapAmtMap.get(amtKey)) : '0');  //실적 GAP //23.05.30 dgchoi
                } else if(locType == '운영') {
                    amountList.add(lower_performanceEstimateAmtMap.containsKey(amtKey) ? formatNumber(lower_performanceEstimateAmtMap.get(amtKey)) : '0');  //실적추정
                    amountList.add(lower_performanceEstimateGapAmtMap.containsKey(amtKey) ? formatNumber(lower_performanceEstimateGapAmtMap.get(amtKey)) : '0');  //실적추정 GAP
                }
            }

            //연간 총 합계
            /* 23.05.30 dgchoi 연간 합계 열 수정
            amountList.add(0, formatNumber(sumMapValuesContainsKey(lower_planAmtMap, lowerKey)));
            if(locType == '현장') {
                amountList.add(1, formatNumber(sumMapValuesContainsKey(lower_actionPlanAmtMap, lowerKey)));
                amountList.add(2, formatNumber(sumMapValuesContainsKey(lower_expectPerformanceAmtMap, lowerKey)));
                amountList.add(3, formatNumber(sumMapValuesContainsKey(lower_performanceAmtMap, lowerKey)));
                amountList.add(4, formatNumber(sumMapValuesContainsKey(lower_expectGapAmtMap, lowerKey)));
                amountList.add(5, formatNumber(sumMapValuesContainsKey(lower_performanceGapAmtMap, lowerKey)));
            } else if(locType == '운영') {
                amountList.add(1, formatNumber(sumMapValuesContainsKey(lower_performanceEstimateAmtMap, lowerKey)));
                amountList.add(2, formatNumber(sumMapValuesContainsKey(lower_performanceEstimateGapAmtMap, lowerKey)));
            }

            lowerMap.put(lowerKey, amountList);
             */

            //연간 총 합계
            sumPlanAmt = sumMapValuesContainsKey(lower_planAmtMap, lowerKey);
            sumExpectPerformanceAmt = sumMapValuesContainsKey(lower_performanceEstimateAmtMap, lowerKey);

            amountList.add(0, formatNumber(sumPlanAmt));
            amountList.add(1, formatNumber(sumExpectPerformanceAmt));
            amountList.add(2, formatNumber(sumExpectPerformanceAmt - sumPlanAmt));

            lowerMap.put(lowerKey, amountList);

        }

        returnMap.put('Upper', upperMap);
        returnMap.put('Middle', middleMap);
        returnMap.put('Lower', lowerMap);

        return returnMap;
    }

    @AuraEnabled(Cacheable=true)
    public static List<Map<String, String>> getWBSList() {
        List<Map<String, String>> returnList = new List<Map<String, String>>();

        Id userId = UserInfo.getUserId();
        Id userRoleId = UserRoleController.getUserRoleId(userId);
        Boolean isHeadOfCenter = UserRoleController.isUserRoleHeadOfCenter(userRoleId);
        Set<Id> subRoleSet = UserRoleController.getSubordinateRoles(userRoleId);

        if(!isHeadOfCenter) { //센터장아니면
            subRoleSet.add(userRoleId); //본인과 같은 Role인 Owner들도 보이게
        }

        List<WBSandCC__c> wbsList = [
                SELECT Id, Name, WBS_Code__c
                FROM WBSandCC__c
                WHERE (OwnerId =: userId OR Owner.UserRoleId IN :subRoleSet)
                AND Check_WBS_CC_ZF__c != 'ZF'
                AND Closing_check__c = FALSE // 24.03.15 Sanghee 마감된 WBS 미노출
                ORDER BY Name
        ];

        for(WBSandCC__c w : wbsList) {
            Map<String, String> tmpMap = new Map<String, String>();
            tmpMap.put('label', w.Name);
            tmpMap.put('value', w.Id);
            returnList.add(tmpMap);
        }

        System.debug('getWBSList: ' + returnList);
        System.debug('getWBSList size: ' + returnList.size());

        return returnList;
    }


    //Query...
    //WBSandCC 전체
    public static WBSandCC__c getWBS(String wbsId) {
        WBSandCC__c wbs = new WBSandCC__c();

        String query = ' SELECT id, Name, WBS_Code__c, Check_WBS_CC_ZF__c, AccountSubjectSort__c ' +
                       ' FROM WBSandCC__c ' +
                       ' WHERE Check_WBS_CC_ZF__c != \'ZF\'';
        String ownerId = UserInfo.getUserId();

        if(wbsId != null) {
            query += ' AND id = :wbsId ';
        } else {
            query += ' AND OwnerId =: ownerId ';
        }
        query += ' LIMIT 1 ';

        wbs = Database.query(query);

        return wbs;
    }

    public static List<AccountSubject__c> getAccountSubjectList(WBSandCC__c targetWBS) {
        Set<String> upperSortSet = new Set<String>();

        if(targetWBS.Check_WBS_CC_ZF__c == 'CC' && targetWBS.AccountSubjectSort__c == '판') {
            upperSortSet.add('판매비와관리비'); //매입
            isCCP = true;
        } else if(targetWBS.Check_WBS_CC_ZF__c == 'CC' && targetWBS.AccountSubjectSort__c == '용'){
            upperSortSet.add('총매출원가'); //매입
        } else {
            upperSortSet.add('총매출원가'); //매입
            upperSortSet.add('매출액'); //매출
            includeAmount = true;
        }

        List<AccountSubject__c> returnList = [
                SELECT Id, UpperSort__c, MiddleSort__c, LowerSort__c, AccountSubjectCode__c, Name, SortOrder__c
                FROM AccountSubject__c
                WHERE UpperSort__c IN :upperSortSet
                ORDER BY SortOrder__c
        ];

        return returnList;
    }

    //매출 계획 (wbs - 계정과목 - 정산일자)
    public static List<AggregateResult> getAmountPlan() { //Group : none, upper, middle, lower
        List<AggregateResult> aggList = [
                SELECT WBS__c, AccountSubjectselect__c ACC_SUB, CALENDAR_MONTH(calculateDate__c) KEYMONTH,
                        SUM(PlanAmount__c) SUM_AMOUNT
                FROM Amount_plan__c
                WHERE WBS__c = :WBS_ID
                AND AccountSubjectselect__r.UpperSort__c = '매출액'
                AND BaseYear__c = :YEAR_INPUT_STR
                //AND calculateDate__c = THIS_YEAR
                AND Real_Data_check__c = TRUE
                AND PlanAmount__c != 0
                AND PlanAmount__c != NULL
                GROUP BY WBS__c, AccountSubjectselect__c, calculateDate__c
                ORDER BY WBS__c, AccountSubjectselect__c, calculateDate__c
        ];

        return aggList;
    }

    //계정과목 SUM - 매출계획
    public static List<AggregateResult> getAmountPlan(String type) {
        String query = ' SELECT WBS__c, AccountSubjectselect__r.' + type + ' ACC_SUB, CALENDAR_MONTH(calculateDate__c) KEYMONTH, ' +
                       ' SUM(PlanAmount__c) SUM_AMOUNT ' +
                       ' FROM Amount_plan__c ' +
                       ' WHERE WBS__c = :WBS_ID' +
                       ' AND AccountSubjectselect__r.UpperSort__c = \'매출액\' ' +
                       ' AND BaseYear__c = :YEAR_INPUT_STR ' +
                       //' AND calculateDate__c = THIS_YEAR ' +
                       ' AND Real_Data_check__c = TRUE ' +
                       ' AND PlanAmount__c != 0 ' +
                       ' AND PlanAmount__c != NULL ' +
                       ' GROUP BY WBS__c, ' + 'AccountSubjectselect__r.' + type +', CALENDAR_MONTH(calculateDate__c) ' +
                       ' ORDER BY WBS__c, ' + 'AccountSubjectselect__r.' + type +', CALENDAR_MONTH(calculateDate__c) ';
        return Database.query(query);
    }

    //매입 계획 (wbs - 계정과목 - 정산일자)
    public static List<AggregateResult> getCostPlan() {
        String upper = (isCCP == true) ? '판매비와관리비' : '총매출원가';
        List<AggregateResult> aggList = [
                SELECT WBS__c, AccountSubjectselect__c ACC_SUB,
                       CALENDAR_MONTH(CalculateDate__c) KEYMONTH,
                       SUM(PlanPurchaseAmount__c) SUM_AMOUNT
                FROM Cost_Plan__c
                WHERE WBS__c = :WBS_ID
                AND AccountSubjectselect__r.UpperSort__c =: upper
                AND BaseYear__c = :YEAR_INPUT_STR
                //AND CalculateDate__c = THIS_YEAR
                AND Real_Data_check__c = TRUE
                AND PlanPurchaseAmount__c != 0
                AND PlanPurchaseAmount__c != NULL
                GROUP BY WBS__c, AccountSubjectselect__c, CALENDAR_MONTH(CalculateDate__c)
                ORDER BY WBS__c, AccountSubjectselect__c, CALENDAR_MONTH(CalculateDate__c)
        ];
        return aggList;
    }

    //계정과목 SUM - 매입 계획
    public static List<AggregateResult> getCostPlan(String type) {
        String upper = (isCCP == true) ? '판매비와관리비' : '총매출원가';
        String query = ' SELECT wbs__c, AccountSubjectselect__r.' + type + ' ACC_SUB, ' +
                       ' CALENDAR_MONTH(calculateDate__c) KEYMONTH, ' +
                       ' SUM(PlanPurchaseAmount__c) SUM_AMOUNT ' +
                       ' FROM Cost_Plan__c ' +
                       ' WHERE wbs__c = :WBS_ID ' +
                       ' AND AccountSubjectselect__r.UpperSort__c =: upper ' +
                       ' AND BaseYear__c = :YEAR_INPUT_STR ' +
                       //' AND calculateDate__c = THIS_YEAR ' +
                       ' AND Real_Data_check__c = TRUE ' +
                       ' AND PlanPurchaseAmount__c != 0 ' +
                       ' AND PlanPurchaseAmount__c != NULL ' +
                       ' GROUP BY WBS__c, ' + 'AccountSubjectselect__r.' + type +', CALENDAR_MONTH(calculateDate__c) ' +
                       ' ORDER BY WBS__c, ' + 'AccountSubjectselect__r.' + type +', CALENDAR_MONTH(calculateDate__c) ';
        return Database.query(query);
    }

    //실적(Performance__c)
    public static List<AggregateResult> getPerformance() {
        List<AggregateResult> aggList = [
                SELECT WBS__c, AccountSubjectSelect__c ACC_SUB,
                        CALENDAR_MONTH(PerformanceMonth__c) KEYMONTH,
                        SUM(PerformanceAmount__c) SUM_AMOUNT
                FROM Performance__c
                WHERE WBS__c = :WBS_ID
                AND CALENDAR_YEAR(PerformanceMonth__c) = :YEAR_INPUT_INT
                //AND PerformanceMonth__c = THIS_YEAR
                AND Real_Data_check__c = TRUE
                AND PerformanceAmount__c != 0
                AND PerformanceAmount__c != NULL
                GROUP BY WBS__c, AccountSubjectSelect__c, CALENDAR_MONTH(PerformanceMonth__c)
        ];
        return aggList;
    }

    //계정과목 SUM - 실적
    public static List<AggregateResult> getPerformance(String type) {
        String query = ' SELECT WBS__c, AccountSubjectSelect__r.' + type + ' ACC_SUB, ' +
                       ' CALENDAR_MONTH(PerformanceMonth__c) KEYMONTH, ' +
                       ' SUM(PerformanceAmount__c) SUM_AMOUNT ' +
                ' FROM Performance__c ' +
                ' WHERE WBS__c = :WBS_ID ' +
                ' AND CALENDAR_YEAR(PerformanceMonth__c) = :YEAR_INPUT_INT ' +
                //' AND PerformanceMonth__c = THIS_YEAR ' +
                ' AND Real_Data_check__c = TRUE ' +
                ' AND PerformanceAmount__c != 0 ' +
                ' AND PerformanceAmount__c != NULL ' +
                ' GROUP BY WBS__c, ' + 'AccountSubjectselect__r.' + type +', CALENDAR_MONTH(PerformanceMonth__c) ' +
                ' ORDER BY WBS__c, ' + 'AccountSubjectselect__r.' + type +', CALENDAR_MONTH(PerformanceMonth__c) ';
        return Database.query(query);
    }

    //매출(Amount__c)
    public static List<AggregateResult> getAmount() {
        List<AggregateResult> aggList = [
                SELECT WBS__c, AccountSubjectselect__c ACC_SUB,
                        CALENDAR_MONTH(CalculateDate__c) KEYMONTH,
                        SUM(PredictAmount__c) SUM_AMOUNT
                FROM Amount__c
                WHERE WBS__c = :WBS_ID
                AND AccountSubjectselect__r.UpperSort__c = '매출액'
                AND CALENDAR_YEAR(CalculateDate__c) = :YEAR_INPUT_INT
                //AND CalculateDate__c = THIS_YEAR
                AND PredictAmount__c != 0
                AND PredictAmount__c != NULL
                GROUP BY WBS__c, AccountSubjectselect__c, CALENDAR_MONTH(CalculateDate__c)
                ORDER BY WBS__c, AccountSubjectselect__c, CALENDAR_MONTH(CalculateDate__c)
        ];
        return aggList;
    }

    //계정과목 SUM - 매출
    public static List<AggregateResult> getAmount(String type) {
        String query = ' SELECT WBS__c, AccountSubjectselect__r.' + type + ' ACC_SUB, ' +
                ' CALENDAR_MONTH(CalculateDate__c) KEYMONTH, ' +
                ' SUM(PredictAmount__c) SUM_AMOUNT ' +
                ' FROM Amount__c ' +
                ' WHERE WBS__c = :WBS_ID ' +
                ' AND AccountSubjectselect__r.UpperSort__c = \'매출액\' ' +
                ' AND CALENDAR_YEAR(CalculateDate__c) = :YEAR_INPUT_INT ' +
                //' AND calculateDate__c = THIS_YEAR ' +
                ' AND PredictAmount__c != 0 ' +
                ' AND PredictAmount__c != NULL ' +
                ' GROUP BY WBS__c, ' + 'AccountSubjectselect__r.' + type +', CALENDAR_MONTH(CalculateDate__c) ' +
                ' ORDER BY WBS__c, ' + 'AccountSubjectselect__r.' + type +', CALENDAR_MONTH(CalculateDate__c) ';
        return Database.query(query);
    }

    //매입(Cost__c)
    public static List<AggregateResult> getCost() {
        String upper = (isCCP == true) ? '판매비와관리비' : '총매출원가';
        List<AggregateResult> aggList = [
                SELECT WBS__c, AccountSubjectselect__c ACC_SUB,
                        CALENDAR_MONTH(CalculateDate__c) KEYMONTH,
                        SUM(PurchaseAmount__c) SUM_AMOUNT
                FROM Cost__c
                WHERE WBS__c = :WBS_ID
                AND AccountSubjectselect__r.UpperSort__c =: upper
                AND CALENDAR_YEAR(CalculateDate__c) = :YEAR_INPUT_INT
                //AND CalculateDate__c = THIS_YEAR
                AND PurchaseAmount__c != 0
                AND PurchaseAmount__c != NULL
                GROUP BY WBS__c, AccountSubjectselect__c, CALENDAR_MONTH(CalculateDate__c)
                ORDER BY WBS__c, AccountSubjectselect__c, CALENDAR_MONTH(CalculateDate__c)
        ];
        return aggList;
    }

    //계정과목 SUM - 매입
    public static List<AggregateResult> getCost(String type) {
        String upper = (isCCP == true) ? '판매비와관리비' : '총매출원가';
        String query = ' SELECT WBS__c, AccountSubjectselect__r.' + type + ' ACC_SUB, ' +
                       ' CALENDAR_MONTH(CalculateDate__c) KEYMONTH, ' +
                       ' SUM(PurchaseAmount__c) SUM_AMOUNT ' +
                       ' FROM Cost__c ' +
                       ' WHERE WBS__c = :WBS_ID ' +
                       ' AND AccountSubjectselect__r.UpperSort__c =: upper ' +
                       ' AND CALENDAR_YEAR(CalculateDate__c) = :YEAR_INPUT_INT ' +
                       //' AND calculateDate__c = THIS_YEAR ' +
                       ' AND PurchaseAmount__c != 0 ' +
                       ' AND PurchaseAmount__c != NULL ' +
                       ' GROUP BY WBS__c, ' + 'AccountSubjectselect__r.' + type +', CALENDAR_MONTH(CalculateDate__c) ' +
                       ' ORDER BY WBS__c, ' + 'AccountSubjectselect__r.' + type +', CALENDAR_MONTH(CalculateDate__c) ';
        return Database.query(query);
    }

    //매출 실행 계획(Amount_Action_Plan__c)
    public static List<AggregateResult> getAmountActionPlan() {
        List<AggregateResult> aggList = [
                SELECT WBS__c, AccountSubjectselect__c ACC_SUB,
                        CALENDAR_MONTH(CalculateDate__c) KEYMONTH,
                        SUM(ActionPlanAmount__c) SUM_AMOUNT
                FROM Amount_Action_Plan__c
                WHERE AccountSubjectselect__r.UpperSort__c = '매출액'
                AND WBS__c = :WBS_ID
                AND Latest_Data_Check__c = TRUE
                AND CALENDAR_YEAR(CalculateDate__c) = :YEAR_INPUT_INT
                //AND CalculateDate__c = THIS_YEAR
                AND Real_Data_check__c = TRUE
                AND ActionPlanAmount__c != 0
                AND ActionPlanAmount__c != NULL
                GROUP BY WBS__c, AccountSubjectselect__c, CALENDAR_MONTH(CalculateDate__c)
                ORDER BY WBS__c, AccountSubjectselect__c, CALENDAR_MONTH(CalculateDate__c) DESC
        ];
        return aggList;
    }

    //계정과목 SUM - 매출실행계획
    public static List<AggregateResult> getAmountActionPlan(String type) {
        String query = ' SELECT WBS__c, AccountSubjectselect__r.' + type + ' ACC_SUB, ' +
                ' CALENDAR_MONTH(CalculateDate__c) KEYMONTH, ' +
                ' SUM(ActionPlanAmount__c) SUM_AMOUNT ' +
                ' FROM Amount_Action_Plan__c ' +
                ' WHERE AccountSubjectselect__r.UpperSort__c = \'매출액\' ' +
                ' AND WBS__c = :WBS_ID ' +
                ' AND Latest_Data_Check__c = true ' +
                ' AND CALENDAR_YEAR(CalculateDate__c) = :YEAR_INPUT_INT ' +
                //' AND calculateDate__c = THIS_YEAR ' +
                ' AND Real_Data_check__c = true ' +
                ' AND ActionPlanAmount__c != 0 ' +
                ' AND ActionPlanAmount__c != NULL ' +
                ' GROUP BY WBS__c, ' + 'AccountSubjectselect__r.' + type +', CALENDAR_MONTH(CalculateDate__c) ' +
                ' ORDER BY WBS__c, ' + 'AccountSubjectselect__r.' + type +', CALENDAR_MONTH(CalculateDate__c) DESC';
        return Database.query(query);
    }

    //매입 실행 계획(cost_Action_plan__c)
    public static List<AggregateResult> getCostActionPlan() {
        String upper = (isCCP == true) ? '판매비와관리비' : '총매출원가';
        List<AggregateResult> aggList = [
                SELECT WBS__c, AccountSubjectselect__c ACC_SUB, CALENDAR_MONTH(CalculateDate__c) KEYMONTH,
                        SUM(ActionPlanPurchaseAmount__c) SUM_AMOUNT
                FROM Cost_Action_Plan__c
                WHERE AccountSubjectselect__r.UpperSort__c =: upper
                AND WBS__c = :WBS_ID
                AND Latest_Data_Check__c = TRUE
                AND CALENDAR_YEAR(CalculateDate__c) = :YEAR_INPUT_INT
                //AND CalculateDate__c = THIS_YEAR
                AND Real_Data_check__c = TRUE
                AND ActionPlanPurchaseAmount__c != 0
                AND ActionPlanPurchaseAmount__c != NULL
                GROUP BY WBS__c, AccountSubjectselect__c, CALENDAR_MONTH(CalculateDate__c)
                ORDER BY WBS__c, AccountSubjectselect__c, CALENDAR_MONTH(CalculateDate__c) DESC
        ];
        return aggList;
    }

    //계정과목 SUM - 매입 실행 계획
    public static List<AggregateResult> getCostActionPlan(String type) {
        String upper = (isCCP == true) ? '판매비와관리비' : '총매출원가';
        String query = ' SELECT WBS__c, AccountSubjectselect__r.' + type + ' ACC_SUB, CALENDAR_MONTH(CalculateDate__c) KEYMONTH, ' +
                ' SUM(ActionPlanPurchaseAmount__c) SUM_AMOUNT ' +
                ' FROM cost_Action_plan__c ' +
                ' WHERE AccountSubjectselect__r.UpperSort__c =: upper ' +
                ' AND WBS__c = :WBS_ID ' +
                ' AND Latest_Data_Check__c = true ' +
                ' AND CALENDAR_YEAR(CalculateDate__c) = :YEAR_INPUT_INT ' +
                //' AND calculateDate__c = THIS_YEAR ' +
                ' AND Real_Data_check__c = true ' +
                ' AND ActionPlanPurchaseAmount__c != 0 ' +
                ' AND ActionPlanPurchaseAmount__c != NULL ' +
                ' GROUP BY WBS__c, ' + 'AccountSubjectselect__r.' + type +', CALENDAR_MONTH(CalculateDate__c) ' +
                ' ORDER BY WBS__c, ' + 'AccountSubjectselect__r.' + type +', CALENDAR_MONTH(CalculateDate__c) DESC';
        return Database.query(query);
    }

    //주차별 매출 예상
    public static List<AggregateResult> getWeeklyAmount() {
        List<AggregateResult> aggList = [
                SELECT WBS__c, AccountSubjectselect__c ACC_SUB,
                        CALENDAR_MONTH(CalculateDate__c) KEYMONTH,
                        SUM(PredictAmount__c) SUM_AMOUNT
                FROM weekly_amount_expect__c
                WHERE AccountSubjectselect__r.UpperSort__c = '매출액'
                AND WBS__c = :WBS_ID
                AND Latest_Data_Check__c = true
                AND CALENDAR_YEAR(CalculateDate__c) = :YEAR_INPUT_INT
                //AND CalculateDate__c = THIS_YEAR
                AND Real_Data_check__c = TRUE
                AND PredictAmount__c != 0
                AND PredictAmount__c != NULL
                GROUP BY WBS__c, AccountSubjectselect__c, CALENDAR_MONTH(CalculateDate__c)
                ORDER BY WBS__c, AccountSubjectselect__c, CALENDAR_MONTH(CalculateDate__c) DESC
        ];
        return aggList;
    }

    //계정과목 SUM - 주차별 매출 예상
    public static List<AggregateResult> getWeeklyAmount(String type) {
        String query = ' SELECT WBS__c, AccountSubjectselect__r.' + type + ' ACC_SUB, ' +
                       ' CALENDAR_MONTH(CalculateDate__c) KEYMONTH, ' +
                       ' SUM(PredictAmount__c) SUM_AMOUNT ' +
                       ' FROM weekly_amount_expect__c ' +
                       ' WHERE AccountSubjectselect__r.UpperSort__c = \'매출액\' ' +
                       ' AND WBS__c = :WBS_ID ' +
                       ' AND Latest_Data_Check__c = true ' +
                       ' AND CALENDAR_YEAR(CalculateDate__c) = :YEAR_INPUT_INT ' +
                       //' AND CalculateDate__c = THIS_YEAR ' +
                       ' AND Real_Data_check__c = TRUE ' +
                       ' AND PredictAmount__c != 0 ' +
                       ' AND PredictAmount__c != NULL ' +
                       ' GROUP BY WBS__c, ' + 'AccountSubjectselect__r.' + type +', CALENDAR_MONTH(CalculateDate__c)' +
                       ' ORDER BY WBS__c, ' + 'AccountSubjectselect__r.' + type +', CALENDAR_MONTH(CalculateDate__c) DESC';
        return Database.query(query);
    }

    //주차별 매입 예상
    public static List<AggregateResult> getWeeklyCost() {
        String upper = (isCCP == true) ? '판매비와관리비' : '총매출원가';
        List<AggregateResult> aggList = [
                SELECT WBS__c, AccountSubjectselect__c ACC_SUB,
                        CALENDAR_MONTH(CalculateDate__c) KEYMONTH,
                        SUM(PurchaseAmount__c) SUM_AMOUNT
                FROM Weekly_cost_expect__c
                WHERE AccountSubjectselect__r.UpperSort__c = :upper
                AND WBS__c = :WBS_ID
                AND Latest_Data_Check__c = true
                AND CALENDAR_YEAR(CalculateDate__c) = :YEAR_INPUT_INT
                //AND CalculateDate__c = THIS_YEAR
                AND Real_Data_check__c = TRUE
                AND PurchaseAmount__c != 0
                AND PurchaseAmount__c != NULL
                GROUP BY WBS__c, AccountSubjectselect__c, CALENDAR_MONTH(CalculateDate__c)
                ORDER BY WBS__c, AccountSubjectselect__c, CALENDAR_MONTH(CalculateDate__c) DESC
        ];
        return aggList;
    }

    //계정과목 SUM - 주차별 매입 예상
    public static List<AggregateResult> getWeeklyCost(String type) {
        String upper = (isCCP == true) ? '판매비와관리비' : '총매출원가';
        String query = ' SELECT WBS__c, AccountSubjectselect__r.' + type + ' ACC_SUB, ' +
                       ' CALENDAR_MONTH(CalculateDate__c) KEYMONTH, ' +
                       ' SUM(PurchaseAmount__c) SUM_AMOUNT ' +
                       ' FROM Weekly_cost_expect__c ' +
                       ' WHERE AccountSubjectselect__r.UpperSort__c = :upper ' +
                       ' AND WBS__c = :WBS_ID ' +
                       ' AND Latest_Data_Check__c = true ' +
                       ' AND CALENDAR_YEAR(CalculateDate__c) = :YEAR_INPUT_INT ' +
                       //' AND CalculateDate__c = THIS_YEAR ' +
                       ' AND Real_Data_check__c = TRUE ' +
                       ' AND PurchaseAmount__c != 0 ' +
                       ' AND PurchaseAmount__c != NULL ' +
                       ' GROUP BY WBS__c, ' + 'AccountSubjectselect__r.' + type +', CALENDAR_MONTH(CalculateDate__c)' +
                       ' ORDER BY WBS__c, ' + 'AccountSubjectselect__r.' + type +', CALENDAR_MONTH(CalculateDate__c) DESC';
        return Database.query(query);
    }

    //기준 실적 월 GET
    public static Integer getStdPerformanceMonth() {
        List<Performance__c> stdPerformances = [
                SELECT Id, Name, PerformanceMonth__c
                FROM Performance__c
                WHERE CALENDAR_YEAR(PerformanceMonth__c) = :YEAR_INPUT_INT
                ORDER BY PerformanceMonth__c DESC
                LIMIT 1
        ];

        if(stdPerformances.isEmpty()) {
            return null;
        }

        return stdPerformances[0].PerformanceMonth__c.month();
    }

    //기준 주간예상 월 GET
    public static Integer getStdWeeklyMonth() {
        List<weekly_amount_expect__c> stdWeeklyAmounts = [
                SELECT Id, CalculateDate__c
                FROM weekly_amount_expect__c
                WHERE Real_Data_check__c = TRUE
                AND Weekly__c != NULL
                AND Latest_Data_Check__c = TRUE
                AND CALENDAR_YEAR(CalculateDate__c) = :YEAR_INPUT_INT
                //AND CalculateDate__c = THIS_YEAR
                ORDER BY Weekly__c DESC
                LIMIT 1
        ];

        if(stdWeeklyAmounts.isEmpty()) {
            return null;
        }

        return stdWeeklyAmounts[0].CalculateDate__c.month();
    }

    //static resource - css
    @AuraEnabled(Cacheable=true)
    public static String getCSS() {
        StaticResource srObject = [
                SELECT Id, Body
                FROM StaticResource
        WHERE Name = 'DataTableCSS' LIMIT 1];

        String contents = srObject.Body.toString();
        System.debug(contents);

        return contents;
    }


    /*
    //실적 추정 : 현장
    private static Map<String, Double> calculPerformance(String locType) {
        //과거 - 실적 - 현장/운영
        List<AggregateResult> prev_perform = getPerformance('PREV');
        //과거 - 매출
        List<AggregateResult> prev_amount = new List<AggregateResult>();
        //과거 - 매입
        List<AggregateResult> prev_cost = new List<AggregateResult>();

        //당월 - 매출
        List<AggregateResult> now_amount = new List<AggregateResult>();
        //당월 - 매입
        List<AggregateResult> now_cost = new List<AggregateResult>();

        //미래 - 매출
        List<AggregateResult> next_amount = new List<AggregateResult>();
        //미래 - 매입
        List<AggregateResult> next_cost = new List<AggregateResult>();


        if(locType == '현장') {
            if(includeAmount) { //매출액/총매출원가 보여줄땐 -> 매출도 세팅
                prev_amount = getAmount('PREV');
                now_amount  = getAmount('NOW');
                next_amount = getAmount('NEXT');
            }
            //판매비와 관리비일땐 -> 매입만 세팅
            prev_cost   = getCost('PREV');
            now_cost    = getCost('NOW');
            next_cost   = getCost('NEXT');

        } else if(locType == '운영') {
            prev_amount = getWeeklyAmount('PREV');      //주차별 매출 예상(정산일자 젤최근)
            prev_cost   = getWeeklyCost('PREV');        //주차별 매입 예상(정산일자 젤최근)

            now_amount  = getWeeklyAmount('NOW');       //주차별 매출 예상
            now_cost    = getWeeklyCost('NOW');         //주차별 매입 예상

            next_amount = getAmountActionPlan('NEXT');  //매출 실행 계획(시점일자 젤최근)
            next_cost   = getCostActionPlan('NEXT');    //매입 실행 계획(시점일자 젤최근)
        }

        Map<String, Double> prevPerMap = aggToMap(prev_perform);
        Map<String, Double> prevAmtMap = aggToMap(prev_amount);
        Map<String, Double> prevCstMap = aggToMap(prev_cost);

        Map<String, Double> prevResultMap = new Map<String, Double>();
        for(String key : prevPerMap.keySet()) {
            Double value = 0.0;
            if(prevPerMap.get(key) != 0 && prevPerMap.get(key) != null) { //실적에 금액이 있으면
                prevResultMap.put(key, prevPerMap.get(key));
            } else if(prevAmtMap.containsKey(key)){ //실적에 금액 없고 && 매출에 있으면
                prevResultMap.put(key, prevAmtMap.get(key));
            } else if(prevCstMap.containsKey(key)) { //실적에 금액 없고 && 매입에 있으면
                prevResultMap.put(key, prevCstMap.get(key));
            }
        }


        //실적 추정 Map
        Map<String, Double> performMap = new Map<String, Double>();

        performMap.putAll(aggToMap(prev_amount));
        performMap.putAll(aggToMap(prev_cost));

        for(AggregateResult agg : prev_perform) {
            String aggKey = agg.get('AccountSubjectselect__c') + '-' + agg.get('KEYDATE'); //계정과목-정산일자
            Double sumAmt = Double.valueOf(agg.get('SUM_AMOUNT'));

            if(sumAmt!=0 && sumAmt!=null) { //실적이 0이 아닐때 과거월 업데이트
                performMap.put(aggKey, sumAmt);
            }
        }

        performMap.putAll(aggToMap(now_amount));
        performMap.putAll(aggToMap(now_cost));
        performMap.putAll(aggToMap(next_amount));
        performMap.putAll(aggToMap(next_cost));

        return performMap;
    }

    */

    //공통
    //매출계획,매입계획 용 aggToMap
    private static Map<String, Double> aggToMap(List<AggregateResult> aggList) {
        Map<String, Double> returnMap = new Map<String, Double>();

        for(AggregateResult agg : aggList) {
            String aggKey = agg.get('ACC_SUB') + '-' + agg.get('KEYMONTH'); //계정과목-정산일자
            if(!returnMap.containsKey(aggKey)) { //가장 최근 시점데이터 기준으로 가져올때 유효....
                Double aggSum = Double.valueOf(agg.get('SUM_AMOUNT'));
                returnMap.put(aggKey, aggSum);
            }
        }

        return returnMap;
    }

    //금액 합
    private static Map<String, Double> sumAToB(Map<String, Double> aMap, Map<String, Double> bMap) {
        Map<String, Double> returnMap = new Map<String, Double>();

        for(String key : aMap.keySet()) {

            Double value = aMap.get(key);
            if(bMap.containsKey(key)) {
                value += bMap.get(key);
            }

            returnMap.put(key, value);
        }

        return returnMap;
    }

    //금액 차
    private static Map<String, Double> subAToB(Map<String, Double> aMap, Map<String, Double> bMap) {
        Map<String, Double> returnMap = new Map<String, Double>();

        for(String key : aMap.keySet()) {

            Double value = aMap.get(key) == null ? 0 : aMap.get(key);

            if(bMap.containsKey(key)) {
                value -= (bMap.get(key) == null ? 0 : bMap.get(key));
            }

            returnMap.put(key, value);
        }

        for(String key : bMap.keySet()) {
            if(!aMap.containsKey(key)) { //aMap에 없을 때
                returnMap.put(key, (
                    (bMap.get(key) != 0 && bMap.get(key) != null)
                        ? -bMap.get(key)
                        : 0
                ));
            }
        }

        return returnMap;
    }

    //list SUM
    private static Double sumMapValuesContainsKey(Map<String, Double> tmpMap, String type) {
        Double returnValue = 0;
        for(String tmpKey : tmpMap.keySet()) {
            if(tmpKey.contains(type + '-')) { //23.05.30 dgchoi 수정
                returnValue += (tmpMap.get(tmpKey) == null ? 0 : tmpMap.get(tmpKey));
            }
        }

        return returnValue;
    }

    private static String formatNumber(Double target) {
        if(target != null) {
            return String.format(target.format(), stringFormats);
        }
        return '0';
    }

    //시점별 연산자 리턴
    private static String getTimeOperator(String timePoint) {
        switch on timePoint {
            when 'PREV' { return '<'; } //과거
            when 'NOW' {  return '='; } //현재
            when 'NEXT' { return '>'; } //미래
            when else {}
        }
        return null;
    }

    //Class
    public class returnClass {
        public WBSClass WBS;
        public AccountSubjectClass AccountSubject;
        public List<PerformanceClass> Performance;

    }
    public class WBSClass {
        public String Name;
        public String WBSCode;
        public String WBSorCC;
        public String YorP; //용or판
    }

    public class AccountSubjectClass {
        public String Id;
        public String Upper;
        public String Middle;
        public String Lower;
        public String AccountSubjectCode;
        public String AccountSubjectName;
    }

    public class PerformanceClass {
        public Integer CalMonth; //정산월
        public Date CalDate;
        public String PlanAmt; //사업계획
        public String ActionPlanAmt; //실행계획
        public String ExpectPerformance; //현장:매출/매입, 운영:주간예상(매출/매입)
        public String Performance; //실적
        public String ExpectGAP; //현장only : 예상 GAP (예상실적-실행계획)
        public String PerformanceGAP; //현장only : 실적 GAP (실적-실행계획)
        public String PerformanceEstimate; //운영only : 실적 추정
        public String PerformanceEstimateGAP; //운영only : 실적 추정 GAP
    }

    public class SumAmountClass { //계정과목 별 금액합산 클래스 (상위,중위,하위)
        public String type; //타입
        public List<Double> amounts; //갯수: TOTAL_TD_MONTH
    }
}