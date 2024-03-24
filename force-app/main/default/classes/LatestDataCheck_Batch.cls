/**
 * Created by MZC01-DGCHOI on 2023-01-10.
 */

/**
 * 최신데이터 여부 Check
 */
public with sharing class LatestDataCheck_Batch implements Database.Batchable<sObject>, Database.Stateful{

    public String type;
    public String targetAPIKey;

    public Boolean isFailed = false;
    public String ERROR_MSG = '';

    public Date batchDate;

    //타겟 데이터 전월 or 당월
    public Boolean isThisMonth = true;
    public Integer batchMonth;

    //실행계획 인지
    public Boolean isActionPlan = false;

    //3주차인지
    public Boolean isThirdWeek = false;

    //주간예상에서 조회할 계정과목 갯수
    //public static final Integer ACC_SUB_NUM = 10;

    /**
     * @param type : weeklyExpect(주간예상), actionPlan(실행계획)
     * @param targetAPIKey : 대상 개체 API명 :::: Amount__c(매출),  Cost__c(매입),  ProfitandLoss__c(손익), Opportunity(수주),  Opportunity_amount__c(수주매출)
     */
    public LatestDataCheck_Batch(String type, String targetAPIKey) {
        this.type = type;
        this.targetAPIKey = targetAPIKey;
        this.batchDate    = Date.today();
        //this.batchDate = Date.newInstance(2023,10,30);
        this.isActionPlan = checkActionPlan(type);
        this.isThirdWeek  = checkThirdWeek(this.batchDate);

        checkTargetMonth();

        System.debug('@type: ' + type);
        System.debug('@targetAPIKey: ' + targetAPIKey);
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        Map<String, String> updateObjAPIMap = getUpdateObjAPIMap();
        String mapKey = this.type + this.targetAPIKey;

        String query_select = ' SELECT Id FROM ' + updateObjAPIMap.get(mapKey);
        String query_where  = '';

        String calDateLabel = '';
        switch on this.targetAPIKey {
            when 'ProfitandLoss__c' {
                calDateLabel = 'Calculate_month__c';
            }
            when 'Opportunity' {
                calDateLabel = 'stdDate__c'; //Expect_date_of_closed__c
            }
            when else {
                calDateLabel = 'CalculateDate__c';
            }
        }

        if(this.type == 'weeklyExpect') { //주간예상
            query_where = ' WHERE CALENDAR_MONTH(' + calDateLabel + ') = ' + this.batchMonth;
                        // + (isThisMonth == true ? batchDate.month() : batchDate.month()-1); //당월/전월 체크
        } else if(this.type == 'actionPlan') { //실행계획
            query_where = ' WHERE CALENDAR_MONTH(' + calDateLabel + ') > ' + batchDate.month(); //THIS_MONTH

            if(this.targetAPIKey == 'Amount__c' || this.targetAPIKey == 'Cost__c') {
                query_where += ' AND Real_Data_check__c = true '; //실제 데이터만
            }
        }

        if(!this.isActionPlan) { //실행계획(수주/수주매출) 제외만
            query_where += ' AND Latest_Data_Check__c = true ';
        }
        query_where += ' AND ' + calDateLabel + ' = THIS_YEAR ';

        System.debug('query: ' + query_select + query_where);
        return Database.getQueryLocator(query_select + query_where);
    }

    /**
     * @description 최신 데이터 여부 false 로 변경
     */
    public void execute(Database.BatchableContext context, List<SObject> scope) {
        try {
            for(SObject obj : scope) {
                obj.put('Latest_Data_Check__c', false);
                // ****Third_Week_Index__c 
                // if(this.isActionPlanOppty && this.isThirdWeek) { //실행계획(수주/수주매출) && 3주차인지 체크
                //     obj.put('Third_Week_Index__c',  false);
                // }
            }

            if(scope.size() > 0) update scope;
        } catch(Exception e) {
            this.isFailed = true;
            this.ERROR_MSG = e.getMessage();
        }
    }

    /**
     * @description
     * Chain
     * 1. 주간예상 : 최신데이터 여부 체크 -> 개체복사 -> 주간예상 dummy -> 수주 상태 변경
     * 2. 실행계획 : 최신데이터 여부 체크 -> 개체복사 -> new WBS dummy
     */
    public void finish(Database.BatchableContext context) {
        System.debug('-----------------------------------------finish------------------------------------------');
        if(!isFailed) {
            ObjectCopy_ba copyBatch = new ObjectCopy_ba(this.type, this.targetAPIKey);
            Database.executeBatch(copyBatch, 500);
        } else {
            String title = 'S&I: ['+ this.type + '-' + this.targetAPIKey + '] 개체 업로드 실패';
            String body = this.ERROR_MSG;
            EmailController.sendEmail(title, body);
        }
    }

    /**
     * @return type, targetApiKey 별 대상개체 API Map
     */
    public Map<String, String> getUpdateObjAPIMap() {
        Map<String, String> returnMap = new Map<String, String>();
        returnMap.put('weeklyExpect'+'Amount__c',             'weekly_amount_expect__c');
        returnMap.put('weeklyExpect'+'Cost__c',               'weekly_cost_expect__c');
        returnMap.put('weeklyExpect'+'ProfitandLoss__c',      'Weekly_profitandloss_expect__c');
        returnMap.put('weeklyExpect'+'Opportunity',           'weekly_opportunity_expect__c');
        returnMap.put('weeklyExpect'+'Opportunity_amount__c', 'weekly_opportunity_amount_expect__c');

        returnMap.put('actionPlan'+'Amount__c',               'Amount_Action_Plan__c');
        returnMap.put('actionPlan'+'Cost__c',                 'Cost_Action_Plan__c');
        returnMap.put('actionPlan'+'ProfitandLoss__c',        'ProfitandLoss_ActionPlan__c');
        returnMap.put('actionPlan'+'Opportunity',             'Opportunity_actionplan__c');
        returnMap.put('actionPlan'+'Opportunity_amount__c',   'Opportunity_amount_actionplan__c');

        return returnMap;
    }

    /**
     * @description 데이터 체크 대상 월 체크 : 당월 or 전월
     */
    public void checkTargetMonth() {
        WeekNumber weekNumber = new WeekNumber(Date.today());
        this.isThisMonth      = weekNumber.isThisMonth;
        this.batchMonth       = weekNumber.batchMonth;
    }

    /**
     * @param type 실행계획인지 주간예상인지 (actionPlan, weeklyExpect)
     * @param targetApiKey 대상 오브젝트
     *
     * @return
     */
    public Boolean checkActionPlan(String type) {
        return (type == 'actionPlan') ? true : false;
    }

    /**
     * @param stdDate 기준 날짜
     *
     * @return 기준 날짜가 3주차일때 True
     */
    public Boolean checkThirdWeek(Date stdDate) {
        WeekNumber weekNumber = new WeekNumber(stdDate);
        return (weekNumber.batchWeekOfMonth == 3 ? true : false);
    }

}