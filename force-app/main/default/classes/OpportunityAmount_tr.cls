/**
 * Created by MZC01-DGCHOI on 2023-01-30.
 */

public with sharing class OpportunityAmount_tr extends TriggerHandler{

    List<Opportunity_amount__c> listNew = Trigger.new;

    public override void beforeInsert() {
        System.debug('OpportunityAmount_tr beforeInsert()');
        System.debug('listNew Size :::: ' + listNew.size());
        //TriggerHandler.bypass('Opportunity_tr');
        checkOpportunity();
    }

    private void checkOpportunity() {
        for(Opportunity_amount__c amNew : listNew) {
            if(!amNew.OpportunityCheck__c) amNew.addError('영업물건관리에서만 영업 매출 등록 가능합니다.');
        }
    }
}