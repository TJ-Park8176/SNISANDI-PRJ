/**
 * Created by MZC01-DGCHOI on 2023-02-15.
 */

/**
 * 신규 WBS 더미데이터 생성
 * 2Obj : 실행계획(매출), 실행계획(매입)
 */
public with sharing class NewWBSShell_ba implements Database.Batchable<SObject>, Database.Stateful{

    public String targetAPIKey = '';
    public String nextTargetAPIKey = '';
    public List<Integer> numberOfWeekMonthly = new List<Integer>();
    public Integer batchMonth = Date.today().month();

    public Integer weekAgoMonth; //지난주 월
    public Integer weekAgoWeekOfMonth; //지난주 주차

    public Map<String, Set<Id>> accSubMap = new Map<String, Set<Id>>(); //key : WBS, CCP, CCY

    public Boolean isFailed = false;
    public String ERROR_MSG = '';

    public Date batchDate = Date.today();

    /**
     * @param targetAPIKey : Amount_Action_Plan__c(실행계획(매출)), Cost_Action_Plan__c(실행계획(매입))
     */
    public NewWBSShell_ba(String targetAPIKey) {
        System.debug('newWBSShell(targetAPIKey)-------------');
        System.debug('targetAPIKey :::: ' + targetAPIKey);
        this.targetAPIKey = targetAPIKey;

        //setBatchDate();

        setDateWeekAgo();
        setAccSubMap(); //만들어줘야하는 계정과목 세팅
        setNumberOfWeekMonthly(); //월별 주 수 세팅
    }

    /**
     * @param context
     *
     * @return New WBS 1개씩만 리턴
     */
    public List<WBSandCC__c> start(Database.BatchableContext context) {

        System.debug('-----NewWBSShell_ba start-----');
        System.debug('targetAPIKey :::: ' + this.targetAPIKey);
        System.debug('targetAPIKey contains :::: ' + this.targetAPIKey.contains('Amount'));

        Set<String> checkType = new Set<String>();
        checkType.add('WBS');
        if(!this.targetAPIKey.contains('Amount')) { // 실행계획(매입), 주간예상(매입)
            checkType.add('CC');
        }

        List<AggregateResult> existWBSList = Database.query(
                ' SELECT WBS__c ' +
                ' FROM ' + this.targetAPIKey +
                ' WHERE WBS__r.Check_WBS_CC_ZF__c IN :checkType ' +
                ' AND Real_Data_check__c  = FALSE ' +
                ' AND CALENDAR_MONTH(CalculateDate__c) = 12 ' +
                ' AND CalculateDate__c = THIS_YEAR ' +
                ' AND AccountSubjectCodea__c IN (\'4103000\', \'4251440\', \'5104290\') ' + //매출액, 총매출원가, 판매비와관리비
                ' GROUP BY WBS__c '
        );

        List<WBSandCC__c> totalWBSList = Database.query(
                ' SELECT Id, Name ' +
                ' FROM WBSandCC__c ' +
                ' WHERE Check_WBS_CC_ZF__c IN :checkType ' +
                (Test.isRunningTest()==true ? ' LIMIT 1 ' : '')
        );

        Set<Id> existWBSSet = new Set<Id>();
        for(AggregateResult sObj : existWBSList) {
            existWBSSet.add( (Id) sObj.get('WBS__c'));
        }

        Set<Id> totalWBSSet = new Set<Id>();
        for(WBSandCC__c wbscc : totalWBSList) {
            totalWBSSet.add(wbscc.Id);
        }

        totalWBSSet.removeAll(existWBSSet);

        List<WBSandCC__c> wbsList = [
                SELECT Id, Check_WBS_CC_ZF__c, AccountSubjectSort__c
                FROM WBSandCC__c
                WHERE Id IN :totalWBSSet
        ];

        System.debug('targetAPIKey :::: ' + this.targetAPIKey);

        System.debug('return WBS SIZE : ' + wbsList.size());

        return wbsList;
    }

    public void execute(Database.BatchableContext context, List<WBSandCC__c> scope) {

        try {
            List<SObject> insertList = new List<SObject>();

            for(WBSandCC__c wbscc : scope) {//1개만 넘겨받음....

                Set<Id> accSubIdSet = new Set<Id>();
                //계정과목 Set
                if(wbscc.Check_WBS_CC_ZF__c == 'WBS') {
                    accSubIdSet = this.accSubMap.get('WBS');
                } else if(wbscc.Check_WBS_CC_ZF__c == 'CC') {
                    if(wbscc.AccountSubjectSort__c == '용') {
                        accSubIdSet = this.accSubMap.get('CCY');
                    } else if(wbscc.AccountSubjectSort__c == '판') {
                        accSubIdSet = this.accSubMap.get('CCP');
                    }
                }

                //일주일 전 날짜 대상으로....월-주차 구하고 껍데기 생성
                if(this.targetAPIKey == 'Performance__c') { //실적: 전월 껍데기 생성
                    for(Id accSubId : accSubIdSet) {

                        SObject sObj = Schema.getGlobalDescribe().get(this.targetAPIKey).newSObject();
                        sObj.put('Name','dummy');
                        sObj.put('WBS__c', wbscc.Id);
                        sObj.put('AccountSubjectselect__c', accSubId);
                        sObj.put('Real_Data_check__c', false); //실제 데이터 여부 False
                        sObj.put('PerformanceAmount__c', 0);
                        sObj.put('PerformanceMonth__c', Date.newInstance(this.batchDate.year(), this.batchDate.month()-1, 1)); //전월의 실적 생성

                        insertList.add(sObj);
                    }
                } else { //해당월~12월 껍데기 생성
                    //실행계획(매출), 실행계획(매입)
                    for(Id accSubId : accSubIdSet) {

                        for(Integer i=this.batchMonth; i<=12; i++) {
                            SObject sObj = Schema.getGlobalDescribe().get(this.targetAPIKey).newSObject();
                            sObj.put('Name','dummy');
                            sObj.put('WBS__c', wbscc.Id);
                            sObj.put('AccountSubjectselect__c', accSubId);
                            sObj.put('Real_Data_check__c', false); //실제 데이터 여부 False

                            Date tmpDate = Date.newInstance(this.batchDate.year(), i, 1);
                            sObj.put('CalculateDate__c', tmpDate);
                            sObj.put('Latest_Data_Check__c', true); //최신 데이터 여부 True

                            String amountFieldLabel = '';
                            if(this.targetAPIKey == 'Cost_Action_Plan__c') {
                                amountFieldLabel = 'ActionPlanPurchaseAmount__c';
                            } else if(this.targetAPIKey == 'Amount_Action_Plan__c') {
                                amountFieldLabel = 'ActionPlanAmount__c';
                            }

                            sObj.put(amountFieldLabel, 0);

                            insertList.add(sObj);
                        }
                    }
                }
            }

            if(insertList.size() > 0) insert insertList;

        } catch(Exception e) {
            this.isFailed = true;
            this.ERROR_MSG = e.getMessage();

            System.debug(e.getMessage());
            System.debug(e.getLineNumber());
        }
    }

    public void finish(Database.BatchableContext context) {
        System.debug('------------NewWBSShell_ba finish-------------');

        String title = '';
        String body = '';

        if(!isFailed) { //실패
            ct_ObjectCopy.copyObject('actionPlan', this.nextTargetAPIKey);
        } else { //성공
            title = 'S&I: [' + this.targetAPIKey + '] 개체 업로드 실패';
            body = 'NewWBSShell_ba :::::: ' + this.ERROR_MSG;

            EmailController.sendEmail(title, body);
        }
    }

    public void setAccSubMap() {
        switch on this.targetAPIKey {
            when 'Amount_Action_Plan__c' { //매출 Type : 실행계획(매출)
                this.accSubMap.put('WBS', getAccSubSet(new Set<String> {'매출액'}));
            }
            when 'Cost_Action_Plan__c' { //매입 Type : 실행계획(매입)
                this.accSubMap.put('WBS', getAccSubSet(new Set<String> {'총매출원가'}));
                this.accSubMap.put('CCY', getAccSubSet(new Set<String> {'총매출원가'}));
                this.accSubMap.put('CCP', getAccSubSet(new Set<String> {'판매비와관리비'}));
            }
            when 'Performance__c' { //실적
                this.accSubMap.put('WBS', getAccSubSet(new Set<String> {'총매출원가','매출액'}));
                this.accSubMap.put('CCY', getAccSubSet(new Set<String> {'총매출원가'}));
                this.accSubMap.put('CCP', getAccSubSet(new Set<String> {'판매비와관리비'}));
            }
            when else {}
        }
    }

    public Set<Id> getAccSubSet(Set<String> upperSet) {
        List<AccountSubject__c> accSubList = [
                SELECT Id
                FROM AccountSubject__c
                WHERE UpperSort__c IN :upperSet
        ];

        Set<Id> idSet = new Set<Id>();

        for(AccountSubject__c a : accSubList) {
            idSet.add(a.Id);
        }

        return idSet;
    }

    public void setNumberOfWeekMonthly() { //월별 주 수
        List<Integer> weekNumList = new List<Integer> ();

        for(Integer i=1; i<=this.weekAgoMonth; i++) {
            if(i == this.weekAgoMonth) {
                weekNumList.add(this.weekAgoWeekOfMonth);
                break;
            }

            Datetime firstDate = Datetime.newInstance(this.batchDate.year(), i, 1); //해당 월 1일
            Datetime nextDate = Datetime.newInstance(this.batchDate.year(), i+1, 1);
            Integer firstDayOfMonth = Integer.valueOf(firstDate.format('u')) - 1; //해당 월 1일이 무슨 요일인지 0~6:월~일

            Datetime lastDateOfMonth = nextDate.addDays(-1); //?애드먼스 이상해서 이렇게 씀...ㅋㅋㅋ
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

    public void setDateWeekAgo() {
        //Date dateWeekAgo = Date.today().addDays(-7); //일주일 전 날짜
        Date dateWeekAgo = this.batchDate.addDays(-7); //일주일 전 날짜
        WeekNumber weekNumber = new WeekNumber(dateWeekAgo);
        this.weekAgoMonth = weekNumber.batchMonth; //과거 월 Limit
        this.weekAgoWeekOfMonth = weekNumber.batchWeekOfMonth; //과거 주차 Limit
    }

    /*
    public void setBatchDate() {
        Batch_Setting__mdt settingMdt = [
                SELECT Label, stdDate__c
                FROM Batch_Setting__mdt
                WHERE Label = 'test'
                LIMIT 1
        ];

        this.batchDate = settingMdt.stdDate__c;
    }
     */


}