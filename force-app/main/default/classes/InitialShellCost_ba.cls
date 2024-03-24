/**
 * Created by MZC01-DGCHOI on 2023-02-13.
 */

public with sharing class InitialShellCost_ba implements Database.Batchable<SObject>, Database.Stateful {

    /*
        InitialShellCost_ba
        사업계획(매입), 실행계획(매입), 주간예상(매입) 껍데기 레코드 생성

        1. isWeekly False: 사업계획, 실행계획
        2. isWeekly True:  주간예상(이건 올해만 생성) - 내년(1.1)부턴 자동생성
    */

    public Set<Id> accSubIdSet = new Set<Id>();

    public List<String> TYPE_KEY_ARR = new List<String> {'WBS', 'CCP', 'CCY'};
    public Integer batchIndex = 0;
    public String batchTypeName = '';
    public Boolean isWeekly = false;

    public Integer weekAgoMonth; //지난주 월
    public Integer weekAgoWeekOfMonth; //지난주 주차

    public List<Integer> numberOfWeekMonthly = new List<Integer>();

    public Integer stdYear = Date.today().year()+1; //내년 년도

    public Boolean isFailed = false;
    public String ERROR_MSG = '';

    public InitialShellCost_ba(Boolean isWeekly, Integer idx) {
        this.batchIndex = idx;
        this.isWeekly = isWeekly;
        this.batchTypeName = this.TYPE_KEY_ARR[this.batchIndex];

        setAccSubIdSet(); //만들어줘야하는 계정과목 세팅
        setBatchMonth(Date.today().addDays(-7)); //일주일 전 주차 세팅 (올해만...)
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug('------------InitialShellCost_ba START-------------');
        setNumberOfWeekMonthly(); //월별 주 수 세팅

        String query_select = '';
        String query_where  = '';

        query_select = ' SELECT Id '
                     + ' FROM WBSandCC__c ';

        switch on this.batchTypeName {
            when 'WBS' {
                query_where += ' WHERE Check_WBS_CC_ZF__c = \'WBS\'';
            }
            when 'CCP' {
                query_where += ' WHERE Check_WBS_CC_ZF__c = \'CC\''
                             + ' AND AccountSubjectSort__c = \'판\'';
            }
            when 'CCY' {
                query_where += ' WHERE Check_WBS_CC_ZF__c = \'CC\''
                             + ' AND AccountSubjectSort__c = \'용\'';
            }
        }

        return Database.getQueryLocator(query_select + query_where);
    }

    public void execute(Database.BatchableContext bc, List<WBSandCC__c> scope) {

        try {
            /*
            if(isWeekly) { //주간예상

                List<Weekly_cost_expect__c> weeklyList = new List<Weekly_cost_expect__c>();

                for(WBSandCC__c wbs : scope) {//WBS

                    for(Id accSubId : this.accSubIdSet) { //계정과목

                        for(Integer i=1; i<=this.weekAgoMonth; i++) { //12달

                            Integer weekLength = this.numberOfWeekMonthly[i-1]; //N월에 몇주까지 있는지(몇개 껍데기 생성)
                            for(Integer j=1; j<=weekLength; j++) { //달별 주차
                                Weekly_cost_expect__c weeklyObj = new Weekly_cost_expect__c();
                                weeklyObj.Name = 'dummy';
                                weeklyObj.WBS__c = wbs.Id;
                                weeklyObj.AccountSubjectselect__c = accSubId;
                                weeklyObj.PurchaseAmount__c = 0;
                                weeklyObj.Real_Data_check__c = false;
                                weeklyObj.CalculateDate__c =  Date.newInstance(this.stdYear, i, 1); //내년 더미
                                weeklyObj.Monthly_Order__c = String.valueOf(j); //월별 차수

                                if(j == weekLength) { //마지막 인덱스면 최신데이터 여부 True
                                    weeklyObj.Latest_Data_Check__c = true;
                                }

                                weeklyList.add(weeklyObj);
                            }
                        }
                    }
                }

                if(weeklyList.size() > 0) insert weeklyList;

            } else { //사업계획, 실행계획
            */
            Date tmpDate = null;

            String dummyItemPlanName = 'dummy_' + (Date.today().year()+1);
            ItemManagement_Plan__c dummyItemPlan = [
                SELECT Id
                FROM ItemManagement_Plan__c
                WHERE Name =: dummyItemPlanName
                LIMIT 1
            ];

            List<Cost_Plan__c> planList = new List<Cost_Plan__c>();
            List<Cost_Action_Plan__c> actionPlanList = new List<Cost_Action_Plan__c>();

            for(WBSandCC__c wbs : scope) { //WBS

                for (Id accSubId : this.accSubIdSet) { //계정과목

                    for (Integer i = 1; i <= 12; i++) { //12달

                        tmpDate = Date.newInstance(this.stdYear, i, 1); //내년 더미

                        Cost_Plan__c planObj = new Cost_Plan__c();
                        Cost_Action_Plan__c actionPlanObj = new Cost_Action_Plan__c();

                        //사업계획(아이템관리) 연결
                        planObj.ItemManagement_Plan__c = dummyItemPlan.Id;

                        //Name
                        planObj.Name = 'dummy';
                        actionPlanObj.Name = 'dummy';

                        //WBS
                        planObj.WBS__c = wbs.Id;
                        actionPlanObj.WBS__c = wbs.Id;

                        //계정과목
                        planObj.AccountSubjectselect__c = accSubId;
                        actionPlanObj.AccountSubjectselect__c = accSubId;

                        //금액 0
                        planObj.PlanPurchaseAmount__c = 0;
                        actionPlanObj.ActionPlanPurchaseAmount__c = 0;

                        //실제 데이터 여부 False
                        planObj.Real_Data_check__c = false;
                        actionPlanObj.Real_Data_check__c = false;

                        //최신데이터 여부
                        actionPlanObj.Latest_Data_Check__c = true; //실행계획은 최신데이터 여부 전부 True

                        //아이템관리 체크
                        planObj.Itemmanagementcheck__c = true;

                        planObj.CalculateDate__c = tmpDate; //사업계획(매입)
                        actionPlanObj.CalculateDate__c = tmpDate; //실행계획(매입)

                        planList.add(planObj);
                        actionPlanList.add(actionPlanObj);
                    }
                }
            }

            if(planList.size() > 0) insert planList;
            if(actionPlanList.size() > 0) insert actionPlanList;

        } catch (Exception e) {
            System.debug(e.getMessage());
            System.debug(e.getLineNumber());

            this.isFailed  = true;
            this.ERROR_MSG = e.getMessage();
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('------------finish-------------');

        /*
        실행순서
        : 사업계획,실행계획 -> 주간예상
         */

        String title = '';
        String body = '';

        if(!isFailed) {
            /*
            if(isWeekly) { //주간예상
                if(this.batchIndex < 2) {
                    InitialShellCost_ba batch = new InitialShellCost_ba(true, ++this.batchIndex);
                    Database.executeBatch(batch, 1);
                } else {
                    InitialShellOppty_ba batch = new InitialShellOppty_ba();
                    Database.executeBatch(batch, 1);
                }
            } else { //사업계획, 실행계획
            */
            if(this.batchIndex < 2) {
                InitialShellCost_ba batch = new InitialShellCost_ba(false, ++this.batchIndex);
                Database.executeBatch(batch, 1);
            } else {
                InitialShellOppty_ba batch = new InitialShellOppty_ba();
                Database.executeBatch(batch, 1);
            }
        } else {
            //메일 전송
            title = '[S&I] 연간 dummy 업로드 실패';
            body = 'InitialShellCost_ba :::: ' + this.ERROR_MSG;

            EmailController.sendEmail(title, body);
        }
    }

    public void setAccSubIdSet() {
        String upper = '';

        switch on this.batchTypeName {
            when 'WBS', 'CCY' {
                upper = '총매출원가';
            }
            when 'CCP' {
                upper = '판매비와관리비';
            }
            when else {}
        }

        List<AccountSubject__c> accSubList = [
                SELECT Id
                FROM AccountSubject__c
                WHERE UpperSort__c = :upper
        ];

        Set<Id> idSet = new Set<Id>();

        for(AccountSubject__c a : accSubList) {
            idSet.add(a.Id);
        }

        this.accSubIdSet = idSet;
    }

    public void setNumberOfWeekMonthly() { //월별 주 수
        List<Integer> weekNumList = new List<Integer> ();

        for(Integer i=1; i<=this.weekAgoMonth; i++) {
            if(i == this.weekAgoMonth) {
                weekNumList.add(weekAgoWeekOfMonth);
                break;
            }
            System.debug('--------------------------------');
            Datetime firstDate = Datetime.newInstance(stdYear, i, 1); //해당 월 1일
            Datetime nextDate = Datetime.newInstance(stdYear, i+1, 1);
            Integer firstDayOfMonth = Integer.valueOf(firstDate.format('u')) - 1; //해당 월 1일이 무슨 요일인지 0~6:월~일

            Datetime lastDateOfMonth = nextDate.addDays(-1); //?애드먼스 이상해서 이렇게 씀...ㅋㅋㅋㅈㅅ
            Integer lastDayOfMonth = lastDateOfMonth.day();
            System.debug(firstDate);
            System.debug(lastDateOfMonth);

            Integer firstMonday = 1;
            if(firstDayOfMonth > 0) {
                firstMonday = 1 + (7-firstDayOfMonth); //첫번째 월요일
            }
            System.debug(i + '월 첫번째 월요일: ' + firstMonday);
            System.debug(i + '월 마지막 day: ' + lastDayOfMonth);

            Integer mondayNum = Integer.valueOf(Math.floor((lastDayOfMonth - firstMonday) / 7) + 1);

            System.debug('월요일 갯수: ' + mondayNum);

            weekNumList.add(mondayNum);
        }

        this.numberOfWeekMonthly = weekNumList;
    }

    public void setBatchMonth(Date stdDate) {
        WeekNumber weekNumber = new WeekNumber(stdDate);
        this.weekAgoMonth = weekNumber.batchMonth; //과거 월 Limit
        this.weekAgoWeekOfMonth = weekNumber.batchWeekOfMonth; //과거 주차 Limit
    }
}