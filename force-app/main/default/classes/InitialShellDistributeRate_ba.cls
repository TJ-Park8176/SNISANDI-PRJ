public with sharing class InitialShellDistributeRate_ba implements Database.Batchable<sObject>, Database.Stateful {
    
    //실패 처리 
    public Boolean isFailed = false;
    public String ERROR_MSG = '';
    
    /**
     * @param context
     *
     * @return WBS 100개씩 리턴
     */
    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator(
            ' SELECT Id, Name ' + 
            ' FROM WBSandCC__c ' +
            ' WHERE Check_WBS_CC_ZF__c = \'WBS\' '
        );
    }

    public void execute(Database.BatchableContext context, List<WBSandCC__c> scope) {
        try {
            List<Performance_Distribute_Rate__c> insertList = new List<Performance_Distribute_Rate__c>();

            Integer nextYear = Date.today().year() + 1;
            for (WBSandCC__c wbs : scope) {
                for (Integer i=1; i<=12; i++) {
                    Performance_Distribute_Rate__c pdr = new Performance_Distribute_Rate__c();
                    pdr.Name               = i + '월_' + wbs.Name;
                    pdr.Calculate_month__c = Date.newInstance(nextYear, i, 1);
                    pdr.WBS_CC__c          = wbs.Id;
                    insertList.add(pdr);
                }
            }
    
            System.debug('@insertList: ' + insertList);
            if (insertList.size() > 0) insert insertList;
        } catch(Exception e) {
            System.debug(e.getMessage());
            System.debug(e.getLineNumber());

            this.isFailed = true;
            this.ERROR_MSG = e.getMessage();
        }
        
    }

    public void finish(Database.BatchableContext context) {
        if(!isFailed) {
            String title = 'S&I: [실적배부비율] 연간 더미 생성 완료';
            String body = '실적 배부 비율 연간 더미 생성 완료';

            EmailController.sendEmail(title, body);
        } else {
            String title = 'S&I: [실적배부비율] 연간 더미 생성 실패';
            String body = 'InitialShellDistributeRate_ba :::::: ' + this.ERROR_MSG;

            EmailController.sendEmail(title, body);
        }
    }
}