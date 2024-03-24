/**
 * Created by MZC01-DGCHOI on 2023-02-16.
 */

/**
 * 전체 WBS 더미데이터 생성(해당월-해당주차)
 * 2Obj : 주간예상(매출), 주간예상(매입)
 */
public with sharing class WeeklyWBSShell_ba implements Database.Batchable<SObject>, Database.Stateful{

    public String targetAPIKey = '';
    public String nextTargetAPIKey = '';
    public Map<String, Set<Id>> accSubMap = new Map<String, Set<Id>>();
    public Integer batchMonth = 0;
    public Integer batchWeekOfMonth = 0;
    public Integer batchWeekOfYear = 0;

    public String amountFieldLabel = ''; //금액필드

    public Boolean isFailed = false;
    public String ERROR_MSG = '';

    public Date batchDate = Date.today();

    /**
     * @param targetAPIKey : 복제 대상 API
     */
    public WeeklyWBSShell_ba(String targetAPIKey) {
        this.targetAPIKey = targetAPIKey;

        //setBatchDate();

        setAccSubMap();

        setBatchMonth(this.batchDate); // 오늘자 기준 주차 가져오기.....
    }

    public List<WBSandCC__c> start(Database.BatchableContext context) {
        //이번달 최신데이터여부 True인거 있으면 False로 바꾸는 배치부터 ㄱㄱ => LatestDataCheck_Batch에서 False로 이미 Update 함
        Set<String> checkType = new Set<String>();

        checkType.add('WBS');
        if(this.targetAPIKey == 'Weekly_Cost_Expect__c') { //매입일땐 CC도 조회......
            checkType.add('CC');
            this.amountFieldLabel = 'PurchaseAmount__c';
        } else if(this.targetAPIKey == 'Weekly_Amount_Expect__c') {
            this.amountFieldLabel = 'PredictAmount__c';
        }

        List<WBSandCC__c> wbsList = [
                SELECT Id, Check_WBS_CC_ZF__c, AccountSubjectSort__c
                FROM WBSandCC__c
                WHERE Check_WBS_CC_ZF__c IN :checkType
        ];

        return wbsList;
    }

    public void execute(Database.BatchableContext context, List<WBSandCC__c> scope) {
        try {
            List<SObject> insertList = new List<SObject>();

            System.debug('scope SIZE :::: ' + scope.size());

            for(WBSandCC__c wbscc : scope) {

                Set<Id> accSubIdSet = new Set<Id>();
                if(wbscc.Check_WBS_CC_ZF__c == 'WBS') {
                    accSubIdSet = this.accSubMap.get('WBS');
                } else if(wbscc.Check_WBS_CC_ZF__c == 'CC') {
                    if(wbscc.AccountSubjectSort__c == '용') {
                        accSubIdSet = this.accSubMap.get('CCY');
                    } else if(wbscc.AccountSubjectSort__c == '판') {
                        accSubIdSet = this.accSubMap.get('CCP');
                    }
                }

                System.debug('accSubIdSet SIZE :::::' + accSubIdSet.size());

                for(Id accSubId : accSubIdSet) {
                    //해당월-해당주차 레코드 생성
                    SObject sObj = Schema.getGlobalDescribe().get(this.targetAPIKey).newSObject();

                    sObj.put('CalculateDate__c', Date.newInstance(Date.today().year(), this.batchMonth, 1));
                    sObj.put('Name', 'dummy');
                    sObj.put('Monthly_Order__c', String.valueOf(this.batchWeekOfMonth)); //월별 주차
                    sObj.put('WBS__c', wbscc.Id);
                    sObj.put('AccountSubjectselect__c', accSubId);
                    sObj.put('Real_Data_check__c', false); //실제 데이터 여부
                    sObj.put('Latest_Data_Check__c', true); //최신 데이터 여부
                    sObj.put(this.amountFieldLabel, 0);
                    //주차일자 정보 추가
                    sObj.put('Weekly__c', this.batchWeekOfYear);
                    sObj.put('Weekly_date__c', this.batchDate);

                    insertList.add(sObj);
                }
            }

            if(insertList.size() > 0) insert insertList;

        } catch(Exception e) {
            this.isFailed = true;
            this.ERROR_MSG = e.getMessage();

            System.debug('e.getMessage : ' + e.getMessage());
            System.debug('e.getLineNumber : ' + e.getLineNumber());
        }

    }

    public void finish(Database.BatchableContext context) {
        System.debug('------------WeeklyWBSShell_ba finish-------------');
        System.debug('targetAPIKey :::: ' + this.targetAPIKey);

        String title = '';
        String body = '';

        if(!isFailed) { //성공
            ct_ObjectCopy.copyObject('weeklyExpect', this.nextTargetAPIKey);
        } else { //실패
            title = 'S&I: [' + this.targetAPIKey + '] 개체 업로드 실패';
            body = 'WeeklyWBSShell_ba :::::: ' + this.ERROR_MSG;

            EmailController.sendEmail(title, body);
        }
    }

    /**
     * @description 매출, 매입별로 가져올 계정과목 상위구분 값 Set
     */
    public void setAccSubMap() {
        switch on this.targetAPIKey {
            when 'Weekly_Amount_Expect__c' { //주간예상(매출)
                this.accSubMap.put('WBS', getAccSubSet(new Set<String> {'매출액'}));
            }
            when 'Weekly_Cost_Expect__c' { //주간예상(매입)
                this.accSubMap.put('WBS', getAccSubSet(new Set<String> {'총매출원가'}));
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

    public void setBatchMonth(Date stdDate) {
        WeekNumber weekNumber = new WeekNumber(stdDate);

        this.batchWeekOfMonth = weekNumber.batchWeekOfMonth;
        this.batchWeekOfYear = weekNumber.batchWeekOfYear;
        this.batchMonth = weekNumber.batchMonth;

        System.debug('월간주차? ' + weekNumber.batchWeekOfMonth);
        System.debug('연간주차? ' + weekNumber.batchWeekOfYear);
        System.debug('가져와야하는월? ' + weekNumber.batchMonth);
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