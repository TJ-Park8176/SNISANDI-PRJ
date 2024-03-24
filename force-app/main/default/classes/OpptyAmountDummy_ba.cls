/**
 * Created by user on 2023-04-03.
 */

/*
TestCode : OpptyDummy_Test
 */

public with sharing class OpptyAmountDummy_ba implements Database.Batchable<sObject>, Database.Stateful {

    public Boolean isYearlyBatch = false;
    public List<Opportunity> opptyDummyList = new List<Opportunity>();
    
    public Boolean isFailed = false;
    public String ERROR_MSG = '';

    public OpptyAmountDummy_ba(List<Opportunity> opptyDummyList) {
        this.opptyDummyList = opptyDummyList;
    }

    public OpptyAmountDummy_ba(List<Opportunity> opptyDummyList, Boolean isYearlyBatch) {
        this.opptyDummyList = opptyDummyList;
        this.isYearlyBatch  = isYearlyBatch;
    }

    public List<Opportunity> start(Database.BatchableContext context) {
        return opptyDummyList;
    }

    public void execute(Database.BatchableContext context, List<Opportunity> scope) {
        try {
            TriggerHandler.bypass('Opportunity_tr');
            TriggerHandler.bypass('OpportunityAmount_tr');

            OpptyDummy opptyDummy = new OpptyDummy();
            opptyDummy.stdYear = Date.today().year()+1;
            opptyDummy.createAmountDummy(scope);
        } catch(Exception e) {
            System.debug(e.getMessage());
            System.debug(e.getLineNumber());

            this.isFailed = true;
            this.ERROR_MSG = e.getMessage();
        }
    }

    public void finish(Database.BatchableContext context) {
        System.debug('-------------OpptyAmountDummy_ba :::: finish------------');
        if(!isFailed && isYearlyBatch) {
            //성공 & Yearly배치에서만 메일 전송
            String title = '[S&I] 연간 dummy 업로드 완료';
            String body = '사업계획, 실행계획, 수주, 수주매출 dummy 업로드 완료';

            EmailController.sendEmail(title, body);

            System.debug('OpptyAmountDummy_ba : 메일 전송 완료');
        }
    }

}