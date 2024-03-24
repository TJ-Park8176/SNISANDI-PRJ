/**
 * Created by MZC01-DGCHOI on 2023-02-15.
 */

public with sharing class InitialShellPerformance_ba implements Database.Batchable<SObject>, Database.Stateful {

    /*
        InitialShellPerformance_ba
        전월 실적 껍데기 레코드 생성
    */

    public List<AccountSubject__c> accSubList = new List<AccountSubject__c>();

    public List<String> TYPE_KEY_ARR = new List<String> {'WBS', 'CCP', 'CCY'};
    public Integer batchIndex = 0;
    public String batchTypeName = '';
    public Date batchDate = Date.newInstance(Date.today().year(), Date.today().month()-1, 1); //전월 실적

    public InitialShellPerformance_ba(Integer idx) {
        this.batchIndex = idx;
        this.batchTypeName = this.TYPE_KEY_ARR[this.batchIndex];

        setAccSubList(); //만들어줘야하는 계정과목 세팅
    }

    public List<WBSandCC__c> start(Database.BatchableContext context) {
        System.debug('------------InitialShellPerformance_ba START-------------');

        insertNewPerformList(); //23.12.19 dgchoi new계정과목(ZF매입,ZF매출) 전월 실적 생성

        String query_select = '';
        String query_where  = '';

        query_select = ' SELECT Id, WBS_Code__c '
                     + ' FROM WBSandCC__c';

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

        return Database.query(query_select + query_where);
    }

    public void execute(Database.BatchableContext context, List<WBSandCC__c> scope) {

        List<Performance__c> performList = new List<Performance__c>();

        try {
            for(WBSandCC__c wbs : scope) {

                System.debug(this.accSubList);

                for (AccountSubject__c accSub : this.accSubList) {
                    Performance__c p = new Performance__c();

                    p.Name = 'dummy';
                    p.WBS__c = wbs.Id;
                    p.AccountSubjectSelect__c = accSub.Id;
                    p.PerformanceAmount__c = 0;
                    p.Real_Data_check__c = false;
                    p.PerformanceMonth__c = batchDate; //전월 실적
                    p.Performance_External_ID__c = wbs.WBS_Code__c + '-'
                                                 + accSub.AccountSubjectCode__c + '-'
                                                 + (p.PerformanceMonth__c).year() + '-'
                                                 + (p.PerformanceMonth__c).month() + '-dummy';

                    performList.add(p);
                }
            }

            if(performList.size() > 0) upsert performList Performance_External_ID__c;

        } catch(Exception e) {
            System.debug(e.getMessage());
            System.debug(e.getLineNumber());
        }

    }

    public void finish(Database.BatchableContext context) {
        System.debug('------------InitialShellPerformance_ba finish-------------');
        if(this.batchIndex < 2) {
            InitialShellPerformance_ba batch = new InitialShellPerformance_ba(++this.batchIndex);
            batch.batchDate = this.batchDate;
            Database.executeBatch(batch, 1);
        }
    }

    /**
     * @description new 계정과목(ZF매입,ZF매출) 전월 실적 생성
     */
    public void insertNewPerformList() {
         try {
             List<Performance__c> newPerformList = new List<Performance__c>();
             Set<String> newAccSubCodeSet        = new Set<String> {'9999998', '9999999'};

             List<WBSandCC__c> newWbs = [
                     SELECT Id, WBS_Code__c
                     FROM WBSandCC__c
                     WHERE WBS_Code__c = '000000000001'
                     LIMIT 1
             ];

             List<AccountSubject__c> newAccList = [
                     SELECT Id, AccountSubjectCode__c
                     FROM AccountSubject__c
                     WHERE AccountSubjectCode__c IN :newAccSubCodeSet
             ];

             if(!newWbs.isEmpty()) {
                 for(AccountSubject__c newAccSub : newAccList) {
                     Performance__c p = new Performance__c();

                     p.Name = 'dummy';
                     p.WBS__c = newWbs[0].Id;
                     p.AccountSubjectSelect__c = newAccSub.Id;
                     p.PerformanceAmount__c = 0;
                     p.Real_Data_check__c = false;
                     p.PerformanceMonth__c = batchDate; //전월 실적
                     p.Performance_External_ID__c = newWbs[0].WBS_Code__c + '-'
                             + newAccSub.AccountSubjectCode__c + '-'
                             + (p.PerformanceMonth__c).year() + '-'
                             + (p.PerformanceMonth__c).month() + '-dummy';

                     newPerformList.add(p);
                 }

                 if(newPerformList.size() > 0) insert newPerformList;
             }
         } catch (Exception e) {
             System.debug('e : '+e);
             System.debug('e.getLine : '+e.getLineNumber());
             System.debug('e.getMessage : '+e.getMessage());
         }
    }

    public void setAccSubList() {

        Set<String> upperSet = new Set<String>();

        switch on this.batchTypeName {
            when 'WBS' {
                upperSet.add('매출액');
                upperSet.add('총매출원가');
                //추가
                upperSet.add('매출총이익1');
                upperSet.add('매출총이익2');
                upperSet.add('영업이익1');
                upperSet.add('영업이익2');
                upperSet.add('공통비배부(용)');
                upperSet.add('공통비배부(판)');
            }
            when 'CCY' {
                upperSet.add('총매출원가');
            }
            when 'CCP' {
                upperSet.add('판매비와관리비');
            }
            when else {}
        }

        this.accSubList = [
                SELECT Id, AccountSubjectCode__c
                FROM AccountSubject__c
                WHERE UpperSort__c IN :upperSet
        ];
    }
}