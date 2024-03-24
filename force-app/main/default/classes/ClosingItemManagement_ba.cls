/**
 * Created by MZC01-DGCHOI on 2023-03-06.
 */

/**
 * 아이템관리 마감 필드 업데이트 Batch
 */
public with sharing class ClosingItemManagement_ba implements Database.Batchable<SObject>, Database.Stateful {

    public String baseYear;

    public ClosingItemManagement_ba() {
        this.baseYear = String.valueOf(Date.today().year());
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator(
            ' SELECT Id, Yearly_total_amount__c, Yearly_total_purchase__c ' + //연간 총 매출(실시간), 연간 총 매입(실시간)
            ' FROM ItemManagement__c ' +
            ' WHERE Base_Year__c = \'' + this.baseYear + '\''
        );
    }

    public void execute(Database.BatchableContext context, List<ItemManagement__c> scope) {
        try {
            for(ItemManagement__c itemMng : scope) {
                itemMng.Yearly_total_amount_closing__c = itemMng.Yearly_total_amount__c; //연간 총 매출(주 마감)
                itemMng.Yearly_total_purchase_closing__c = itemMng.Yearly_total_purchase__c; //연간 총 매입(주 마감)
            }
            update scope;

            System.debug('scope SIZE :::: ' + scope.size());
        } catch(Exception e) {
            System.debug(e.getMessage());
            System.debug(e.getLineNumber());
        }
    }

    public void finish(Database.BatchableContext context) {
        System.debug('--------ClosingItemManagement_ba finish---------');
    }


}