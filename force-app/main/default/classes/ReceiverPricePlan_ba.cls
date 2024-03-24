/**
 * Created by MZC01-DGCHOI on 2023-12-27.
 */

public with sharing class ReceiverPricePlan_ba implements Database.Batchable<SObject>, Database.Stateful {

    public Boolean isFailed = false;
    public String ERROR_MSG = '';

    public String baseYear = '';

    public ReceiverPricePlan_ba(String baseYear) {
        this.baseYear = baseYear;
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        ReceiverPricePlanFactory.makeBaseRecord();

        return Database.getQueryLocator(
                ' SELECT Id, Receiver_Team_Member__r.Group_Distribution_Ratio__c, Sender_Price__r.Price__c ' +
                ' FROM Plan_Receiver_Price__c ' +
                ' WHERE Latest_Version__c = TRUE '
        );
    }

    public void execute(Database.BatchableContext context, List<Plan_Receiver_Price__c> scope) {
        try {
            for(Plan_Receiver_Price__c receiverPrice : scope) {
                Decimal groupRatio  = receiverPrice.Receiver_Team_Member__r.Group_Distribution_Ratio__c;
                Decimal senderPrice = receiverPrice.Sender_Price__r.Price__c;

                System.debug('id : ' + receiverPrice.Id);
                System.debug('groupRatio : ' + groupRatio);
                System.debug('senderPrice : ' + senderPrice);

                if(groupRatio == null) groupRatio = 0;

                receiverPrice.Price__c = (groupRatio * senderPrice).setScale(0);
            }

            System.debug(scope);
            if(scope.size() > 0) update scope;
        } catch(Exception e) {
            System.debug(e.getMessage());
            System.debug(e.getLineNumber());

            this.isFailed = true;
            this.ERROR_MSG = e.getMessage();
        }
    }

    public void finish(Database.BatchableContext context) {
        //updateWBS -> updateCC
        if(!isFailed) {
            Database.executeBatch(new UpdateProfitLossPlanPrice_WBS_ba(this.baseYear), 10);
        } else {
            String title = 'S&I: [사업계획(손익)] 계산 실패';
            String body = 'ReceiverPricePlan_ba :::::: ' + this.ERROR_MSG;

            EmailController.sendEmail(title, body);
        }
    }
}