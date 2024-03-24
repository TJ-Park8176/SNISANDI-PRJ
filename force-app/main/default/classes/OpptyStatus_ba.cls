/**
 * Created by MZC01-DGCHOI on 2023-03-03.
 */

/**
 *  OpptyStatus_ba
 *  주간예상(영업수주), 주간예상(영업매출) 복제 작업 후 '상태' 필드 업데이트
 *  영업물건관리 : 신규 -> 진행중
 */
public with sharing class OpptyStatus_ba implements Database.Batchable<SObject>, Database.Stateful {

    public Boolean isFailed = false;
    public String ERROR_MSG;

    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator(
                ' SELECT Id ' +
                ' FROM Opportunity ' +
                ' WHERE Status__c = \'신규\''
        );
    }

    public void execute(Database.BatchableContext context, List<Opportunity> scope) {
        try {
            for(Opportunity oppty : scope) {
                oppty.Status__c ='진행중';
            }
            update scope;

            System.debug('scope SIZE :::: ' + scope.size());
        } catch (Exception e) {
            System.debug(e.getMessage());
            System.debug(e.getLineNumber());

            this.isFailed = true;
            this.ERROR_MSG = e.getMessage();
        }

    }

    public void finish(Database.BatchableContext context) {
        System.debug('---------OpptyStatus_ba finish-------');

        String title = '';
        String body = '';

        if(!isFailed) {
            title = 'S&I: [주간예상 개체] 업로드 완료';
            body = '[주간예상 개체] 업로드 되었습니다.';
        } else {
            title = 'S&I: [주간예상 개체] 업로드 실패';
            body = 'OpptyStatus_ba :::::: ' + this.ERROR_MSG;
        }

        EmailController.sendEmail(title, body);
    }


}