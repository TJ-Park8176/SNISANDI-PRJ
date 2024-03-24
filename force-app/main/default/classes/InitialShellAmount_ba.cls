/**
 * Created by MZC01-DGCHOI on 2023-02-13.
 */

/**
 * InitialShellAmount_ba
 * 사업계획(매출), 실행계획(매출), 주간예상(매출) Dummy 레코드 생성
 * 주간예상은 올해만 생성(이전 주차까지). 내년(1.1)부터는 월요일마다 자동 생성(WeeklyWBSShell_ba)
 */
public without sharing class InitialShellAmount_ba implements Database.Batchable<SObject>, Database.Stateful{

    //public List<String> TARGET_API_ARR = new List<String> {'Amount_Plan__c', 'Amount_Action_Plan__c', 'Weekly_Amount_Expect__c'};
    //public Integer batchIndex = 0;
    //public String targetAPIKey;

    public Set<Id> accSubIdSet = new Set<Id>();

    public Integer weekAgoMonth; //지난주 월
    public Integer weekAgoWeekOfMonth; //지난주 주차

    public List<Integer> numberOfWeekMonthly = new List<Integer>();

    public Integer stdYear = Date.today().year()+1;

    public Boolean isFailed = false;
    public String ERROR_MSG = '';

    public InitialShellAmount_ba() {
        setAccSubIdSet(); //만들어줘야하는 계정과목 세팅
        setBatchMonth(Date.today().addDays(-7));
        setNumberOfWeekMonthly(); //월별 주 수 세팅
    }

    public Database.QueryLocator start(Database.BatchableContext context) {

        return Database.getQueryLocator(
                ' SELECT Id ' +
                ' FROM WBSandCC__c ' +
                ' WHERE Check_WBS_CC_ZF__c = \'WBS\' '
        );
    }

    public void execute(Database.BatchableContext context, List<WBSandCC__c> scope) {
        List<Amount_plan__c> amtPlanList = new List<Amount_plan__c>();
        List<Amount_Action_Plan__c> amtActionPlanList = new List<Amount_Action_Plan__c>();
        //List<weekly_amount_expect__c> weeklyAmtList = new List<weekly_amount_expect__c>();


        try {
            //더미 사업계획(아이템관리)
            String dummyItemPlanName = 'dummy_2024';
            List<ItemManagement_Plan__c> dummyItemPlan = [
                SELECT Id
                FROM ItemManagement_Plan__c
                WHERE Name =: dummyItemPlanName
                LIMIT 1
            ];

            System.debug('dummyItemPlanName : ' + dummyItemPlanName);
            System.debug('dummyItemPlan : ' + dummyItemPlan);

            Date tmpDate = null;

            for(WBSandCC__c wbs : scope) { //10

                for(Id accSubId : this.accSubIdSet) { //14

                    for(Integer i=1; i<=12; i++) { //12

                        tmpDate = Date.newInstance(stdYear, i, 1);

                        Amount_plan__c planObj = new Amount_plan__c();
                        Amount_Action_Plan__c actionPlanObj = new Amount_Action_Plan__c();

                        //사업계획(아이템관리) 연결
                        planObj.ItemManagement_Plan__c = dummyItemPlan[0].Id;

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
                        planObj.PlanAmount__c = 0;
                        actionPlanObj.ActionPlanAmount__c = 0;

                        //실제 데이터 여부 False
                        planObj.Real_Data_check__c = false;
                        actionPlanObj.Real_Data_check__c = false;

                        //최신데이터 여부
                        actionPlanObj.Latest_Data_Check__c = true; //실행계획은 최신데이터 여부 전부 True

                        //정산일자
                        planObj.calculateDate__c = tmpDate; //사업계획(매출)
                        actionPlanObj.CalculateDate__c = tmpDate; //실행계획(매출)

                        //아이템관리 체크
                        planObj.Itemmanagementcheck__c = true;

                        amtPlanList.add(planObj);
                        amtActionPlanList.add(actionPlanObj);

                        //주간예상 개체
                        /*
                        if(i<=weekAgoMonth) {
                            Integer weekLength = this.numberOfWeekMonthly[i-1]; //N월에 몇주까지 있는지(몇개 껍데기 생성)

                            System.debug('i ::::' + i);
                            System.debug('weekLength :::: ' + weekLength);

                            for(Integer j=1; j<=weekLength; j++) {
                                weekly_amount_expect__c weeklyObj = new weekly_amount_expect__c();
                                weeklyObj.Name = 'dummy';
                                weeklyObj.WBS__c = wbs.Id;
                                weeklyObj.AccountSubjectselect__c = accSubId;
                                weeklyObj.PredictAmount__c = 0;
                                weeklyObj.Real_Data_check__c = false;
                                weeklyObj.CalculateDate__c = Date.newInstance(stdYear, i, 1);
                                weeklyObj.Monthly_Order__c = String.valueOf(j); //월별 차수

                                if(j == weekLength) { //마지막 인덱스면 최신데이터 여부 True
                                    weeklyObj.Latest_Data_Check__c = true;
                                }

                                weeklyAmtList.add(weeklyObj);
                            }
                        }
                        */
                    }
                }
            }
            if(amtPlanList.size() > 0) insert amtPlanList;
            if(amtActionPlanList.size() > 0) insert amtActionPlanList;
            //if(weeklyAmtList.size() > 0) insert weeklyAmtList;
        } catch(Exception e) {
            System.debug(e.getMessage());
            System.debug(e.getLineNumber());

            this.isFailed = true;
            this.ERROR_MSG = e.getMessage();
        }
    }

    public void finish(Database.BatchableContext context) {
        System.debug('--------finish---------');
        if(!isFailed) {
            InitialShellCost_ba batch = new InitialShellCost_ba(false, 0);
            Database.executeBatch(batch, 1);
        } else {
            String title = '[S&I] 연간 dummy 업로드 실패';
            String body = 'InitialShellAmount_ba :::: ' + this.ERROR_MSG;

            EmailController.sendEmail(title, body);
        }

    }

    //WBS-매출액
    public void setAccSubIdSet() {
        List<AccountSubject__c> accSubList = [
                SELECT Id
                FROM AccountSubject__c
                WHERE UpperSort__c = '매출액'
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

            Datetime lastDateOfMonth = nextDate.addDays(-1); //왜??애드먼스 이상해서 이렇게 씀...;;;;;
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

        System.debug('numberOfWeekMonthly :::::::::::::' + weekNumList);
        this.numberOfWeekMonthly = weekNumList;
    }

    public void setBatchMonth(Date stdDate) {
        WeekNumber weekNumber = new WeekNumber(stdDate);
        this.weekAgoMonth = weekNumber.batchMonth; //과거 월 Limit
        this.weekAgoWeekOfMonth = weekNumber.batchWeekOfMonth; //과거 주차 Limit

        System.debug('과거월 : ' + this.weekAgoMonth);
        System.debug('과거주차 : ' + this.weekAgoWeekOfMonth);
    }
}