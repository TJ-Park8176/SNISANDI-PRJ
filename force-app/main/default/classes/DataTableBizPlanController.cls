/**
 * Created by MZC01-DGCHOI on 2023-09-21.
 */

public without sharing class DataTableBizPlanController {

    public static String WBS_ID = '';
    public static Boolean isCCP = false; //CC&판 유무 -> TRUE: 판매비와관리비 보여줌
    public static Boolean includeAmount = false; //매출포함유무
    public static Integer stdPerformanceMonth = null;
    public static Integer stdWeeklyMonth = null;
    public static List<String> stringFormats = new String[]{'0','number','###,###,###,##0'};
    public static final Integer NUMBER_OF_MONTHS = 12;
    public static final String BASE_YEAR = String.valueOf(Date.today().year());

    //WBS 클릭시 호출
    //현장/운영 구분 클릭시 호출
    @AuraEnabled(Cacheable = true)
    public static String getAmountInfo(String wbsId) {

        System.debug('@@@wbsId: ' + wbsId);

        //----------공통작업---------->
        WBSandCC__c targetWBS = getWBS(wbsId);
        WBS_ID  = targetWBS.Id;

//        stdPerformanceMonth = getStdPerformanceMonth();
//        stdWeeklyMonth = getStdWeeklyMonth();

        List<AccountSubject__c> accSubList = getAccountSubjectList(targetWBS);

        System.debug('isCCP: ' + isCCP);

        Map<String, Double> planAmtMap = new Map<String, Double>(); //사업계획

        if(includeAmount) {
            //매출 포함
            planAmtMap.putAll(aggToMap(getAmountPlan()));
        }
        //매입 포함(ALL)
        planAmtMap.putAll(aggToMap(getCostPlan()));


        //-----------returnList 생성------------
        List<returnClass> returnList = new List<returnClass>();

        for(AccountSubject__c accSub : accSubList) {
            returnClass returnClass = new returnClass();

            //계정과목
            AccountSubjectClass accSubClass = new AccountSubjectClass();
            accSubClass.Id                 = accSub.Id;
            accSubClass.Upper              = accSub.UpperSort__c;
            accSubClass.Middle             = accSub.MiddleSort__c;
            accSubClass.Lower              = accSub.LowerSort__c;
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
                   planAmt = 0.0;

            for(Integer i=1; i<=NUMBER_OF_MONTHS; i++) { //1~12월 달별 실적
                PerformanceClass pClass = new PerformanceClass();

                Date stdDate = Date.newInstance(Date.today().year(), i, 1);
                String amtKey = accSub.Id + '-' + i;

                planAmt = (planAmtMap.containsKey(amtKey) == true && planAmtMap.get(amtKey) != null) ? planAmtMap.get(amtKey) : 0;

                pClass.CalDate  = stdDate;
                pClass.CalMonth = i;
                pClass.PlanAmt = formatNumber(planAmt);

                sumPlanAmt += planAmt;

                pClassList.add(pClass);
            }

            //연간 합계(total) - stdDate는 null 들어갈꺼.....
            PerformanceClass totalPClass = new PerformanceClass();
            totalPClass.PlanAmt = formatNumber(sumPlanAmt);
            pClassList.add(0, totalPClass); //total이 맨 처음값

            returnClass.Performance = pClassList;

            returnList.add(returnClass);
        }

        System.debug('--------사업 계획--------');
        System.debug(planAmtMap);
        System.debug('returnList: ' + returnList);

        return JSON.serialize(returnList);
    }

    //구분별 금액 합
    @AuraEnabled(Cacheable = true)
    public static Map<String, Map<String, List<String>>> getSumAmount(String wbsId) { //accSubType: upper, middle, lower
        //----------공통작업---------->
        WBSandCC__c targetWBS = getWBS(wbsId);
        WBS_ID  = targetWBS.Id;

//        stdPerformanceMonth = getStdPerformanceMonth();
//        stdWeeklyMonth = getStdWeeklyMonth();

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
        Map<String, Double> middle_planAmtMap = new Map<String, Double>(); //사업계획
        Map<String, Double> lower_planAmtMap = new Map<String, Double>(); //사업계획

        if(includeAmount) {
            //매출 포함
            upper_planAmtMap.putAll(aggToMap(getAmountPlan('UpperSort__c')));
            middle_planAmtMap.putAll(aggToMap(getAmountPlan('MiddleSort__c')));
            lower_planAmtMap.putAll(aggToMap(getAmountPlan('LowerSort__c')));
        }
        //매입 포함(ALL)
        upper_planAmtMap.putAll(aggToMap(getCostPlan('UpperSort__c')));
        middle_planAmtMap.putAll(aggToMap(getCostPlan('MiddleSort__c')));
        lower_planAmtMap.putAll(aggToMap(getCostPlan('LowerSort__c')));


        //계정과목 key 별 합 리스트
        Double sumPlanAmt = 0.0,
               sumExpectPerformanceAmt = 0.0;

        //1. Upper(상위구분)
        for(String upperKey : upperSet) {
            sumPlanAmt = 0;

            List<String> amountList = new List<String>();

            for(Integer i=1; i<=NUMBER_OF_MONTHS; i++) {
                String amtKey = upperKey + '-' + i;
                amountList.add(upper_planAmtMap.containsKey(amtKey) ? formatNumber(upper_planAmtMap.get(amtKey)) : '0');  //사업계획
            }

            //연간 총 합계
            sumPlanAmt = sumMapValuesContainsKey(upper_planAmtMap, upperKey);
            amountList.add(0, formatNumber(sumPlanAmt));
            upperMap.put(upperKey, amountList);
        }

        //2. Middle(중위구분)
        for(String middleKey : middleSet) {
            sumPlanAmt = 0;

            List<String> amountList = new List<String>();

            for(Integer i=1; i<=NUMBER_OF_MONTHS; i++) {
                String amtKey = middleKey + '-' + i;
                amountList.add(middle_planAmtMap.containsKey(amtKey) ? formatNumber(middle_planAmtMap.get(amtKey)) : '0');  //사업계획
            }

            //연간 총 합계
            sumPlanAmt = sumMapValuesContainsKey(middle_planAmtMap, middleKey);
            amountList.add(0, formatNumber(sumPlanAmt));
            middleMap.put(middleKey, amountList);
        }

        //3. lower(하위구분)
        for(String lowerKey : lowerSet) {
            sumPlanAmt = 0;

            List<String> amountList = new List<String>();

            for(Integer i=1; i<=NUMBER_OF_MONTHS; i++) {
                String amtKey = lowerKey + '-' + i;
                amountList.add(lower_planAmtMap.containsKey(amtKey) ? formatNumber(lower_planAmtMap.get(amtKey)) : '0');  //사업계획
            }

            //연간 총 합계
            sumPlanAmt = sumMapValuesContainsKey(lower_planAmtMap, lowerKey);
            amountList.add(0, formatNumber(sumPlanAmt));
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
                AND BaseYear__c = :BASE_YEAR
                // AND calculateDate__c = NEXT_YEAR
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
                ' AND BaseYear__c = \'' + BASE_YEAR + '\'' +
                //' AND calculateDate__c = NEXT_YEAR ' +
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
                SELECT wbs__c, AccountSubjectselect__c ACC_SUB,
                        CALENDAR_MONTH(CalculateDate__c) KEYMONTH,
                        SUM(PlanPurchaseAmount__c) SUM_AMOUNT
                FROM Cost_Plan__c
                WHERE wbs__c = :WBS_ID
                AND AccountSubjectselect__r.UpperSort__c =: upper
                AND BaseYear__c = :BASE_YEAR
                //AND calculateDate__c = NEXT_YEAR
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
                ' AND BaseYear__c = \'' + BASE_YEAR + '\'' +
                //' AND calculateDate__c = NEXT_YEAR ' +
                ' AND Real_Data_check__c = TRUE ' +
                ' AND PlanPurchaseAmount__c != 0 ' +
                ' AND PlanPurchaseAmount__c != NULL ' +
                ' GROUP BY WBS__c, ' + 'AccountSubjectselect__r.' + type +', CALENDAR_MONTH(calculateDate__c) ' +
                ' ORDER BY WBS__c, ' + 'AccountSubjectselect__r.' + type +', CALENDAR_MONTH(calculateDate__c) ';
        return Database.query(query);
    }

    //static resource - css
    @AuraEnabled(Cacheable=true)
    public static String getCSS() {
        StaticResource srObject = [
                SELECT id, body
                FROM StaticResource
                WHERE Name = 'DataTableCSS' LIMIT 1];

        String contents = srObject.body.toString();
        System.debug(contents);

        return contents;
    }


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
    }

}