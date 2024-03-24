/**
 * Created by MZC01-DGCHOI on 2023-10-06.
 */

public with sharing class ReceiverPrice_ba implements Database.Batchable<SObject>, Database.Stateful {

    public Boolean isFailed = false;
    public String ERROR_MSG = '';

    public Database.QueryLocator start(Database.BatchableContext context) {
        ReceiverPriceFactory.makeBaseRecord();

        return Database.getQueryLocator(
                ' SELECT Id, Receiver_Team_Member__r.Group_Distribution_Ratio__c, Sender_Price__r.Price__c ' +
                ' FROM Receiver_Price__c ' +
                ' WHERE Latest_Version__c = TRUE '
        );
    }

    public void execute(Database.BatchableContext context, List<Receiver_Price__c> scope) {
        try {
            for(Receiver_Price__c receiverPrice : scope) {
                Decimal groupRatio  = receiverPrice.Receiver_Team_Member__r.Group_Distribution_Ratio__c;
                Decimal senderPrice = receiverPrice.Sender_Price__r.Price__c;

                if(groupRatio == null) {
                    groupRatio = 0;
                }

                System.debug('id : ' + receiverPrice.Id);
                System.debug('groupRatio : ' + groupRatio);
                System.debug('senderPrice : ' + senderPrice);

                receiverPrice.Price__c = (groupRatio * senderPrice).setScale(0);
            }

            System.debug(scope);
            if(scope.size() > 0) update scope;
        } catch (Exception e) {
            System.debug(e.getMessage());
            System.debug(e.getLineNumber());

            this.isFailed = true;
            this.ERROR_MSG = e.getMessage();
        }
    }

    public void finish(Database.BatchableContext context) {
        if(!isFailed) {
            Database.executeBatch(new UpdateProfitLossPrice_WBS_ba(), 10);
        } else {
            String title = 'S&I: [ReceiverPrice_ba] 배치 실패';
            String body = 'ReceiverPrice_ba :::::: ' + this.ERROR_MSG;

            EmailController.sendEmail(title, body);
        }
    }
}