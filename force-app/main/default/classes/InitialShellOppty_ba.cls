/**
 * Created by MZC01-DGCHOI on 2023-03-23.
 */

public with sharing class InitialShellOppty_ba implements Database.Batchable<SObject>, Database.Stateful{

    //배치사이즈 1개씩 돌려야함

    public Boolean isFailed = false;
    public String ERROR_MSG = '';
    //public List<Opportunity> batchOpptyList = new List<Opportunity>();

    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator(
                ' SELECT Id, Check_WBS_CC_ZF__c, Sales_Management__c, Business_Management__c ' +
                ' FROM WBSandCC__c ' +
                ' WHERE Check_WBS_CC_ZF__c = \'ZF\''
        );
    }

    public void execute(Database.BatchableContext context, List<WBSandCC__c> scope) {
        //ZF 1개당 수주 360개, 수주매출 4320개 생성
        //수주 생성시 -> 수주매출 12개 생성(트리거)
        try {
            Set<Id>    zfIdSet    = getZFIdSet(scope); //안씀
            OpptyDummy opptyDummy = new OpptyDummy();
            opptyDummy.stdYear  = Date.today().year()+1;
            //opptyDummy.stdYear = Date.today().year() + 1;
            List<Opportunity>           opptyList       = opptyDummy.createDummy(scope);
            List<Opportunity_Amount__c> opptyAmountList = opptyDummy.createAmountDummy(opptyList);
        } catch (Exception e) {
            System.debug(e.getMessage());
            System.debug(e.getLineNumber());

            this.isFailed = true;
            this.ERROR_MSG = e.getMessage();
        }
    }

    public void finish(Database.BatchableContext context) {
        System.debug('-------------InitialShellOppty_ba :::: finish------------');
        if(!isFailed) {
            String title = '[S&I] 연간 dummy 업로드 완료';
            String body = '사업계획, 실행계획, 수주, 수주매출 dummy 업로드 완료';

            EmailController.sendEmail(title, body);
            //Database.executeBatch(new OpptyAmountDummy_ba(this.batchOpptyList, true),100); //추가
        } else {
            String title = '[S&I] 연간 dummy 업로드 실패';
            String body = 'InitialShellAmount_ba :::: ' + this.ERROR_MSG;

            EmailController.sendEmail(title, body);
        }
    }
    
    private Set<Id> getZFIdSet(List<WBSandCC__c> scope) {
        Set<Id> returnSet = new Set<Id>();

        for (WBSandCC__c zf : scope) {
            returnSet.add(zf.Id);
        }

        return returnSet;
    }
}