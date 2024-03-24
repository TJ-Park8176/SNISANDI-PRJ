/**
 * Created by MZC01-DGCHOI on 2022-12-12.
 */

public with sharing class Cost_tr extends TriggerHandler {
    private List<Cost__c> listNew = (List<Cost__c>) Trigger.new;
    private List<Cost__c> listOld = (List<Cost__c>) Trigger.old;

    public override void beforeInsert() {
        setExternalID();
        checkItemManagement();
    }

    public override void beforeUpdate() {
        setExternalID();
        checkItemManagement();
    }

//    public override void beforeDelete() {
//        checkItemManagement_delete();
//    }

    private void setExternalID() {
        for(Cost__c c : listNew) {
            c.Cost_External_ID__c = c.Cost_External_ID_Hidden__c;
        }
    }

    private void checkItemManagement() {
        for(Cost__c csNew : (listNew!=null ? listNew : listOld)) {
            if(!csNew.Itemmanagementcheck__c) {
                csNew.addError('아이템관리에서만 매입 편집 가능합니다.');
            } else { //true -> false
                csNew.Itemmanagementcheck__c = false;
            }
        }
    }

//    private void checkItemManagement_delete() {
//        for(Cost__c csNew : (listNew!=null ? listNew : listOld)) {
//            if(!csNew.Itemmanagementcheck__c) {
//                csNew.addError('아이템관리에서만 매입 편집 가능합니다.');
//            }
//        }
//    }

}