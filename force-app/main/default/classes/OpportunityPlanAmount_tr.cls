/**
 * Created by MZC01-DGCHOI on 2023-12-04.
 */

public with sharing class OpportunityPlanAmount_tr extends TriggerHandler {

    List<opportunity_amount_plan__c> listNew = Trigger.new;

    public override void beforeInsert() {
        System.debug('OpportunityAmount_tr beforeInsert()');
        System.debug('listNew Size :::: ' + listNew.size());
        checkOpportunity();
    }

    private void checkOpportunity() {
        for(opportunity_amount_plan__c amNew : listNew) {
            if(!amNew.OpportunityCheck__c) amNew.addError('영업물건관리에서만 영업 매출 등록 가능합니다.');
        }
    }
}