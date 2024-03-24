/**
 * Created by MZC01-DGCHOI on 2022-12-12.
 */

public with sharing class Amount_tr extends TriggerHandler {

    private List<Amount__c> listNew = (List<Amount__c>) Trigger.new;
    private List<Amount__c> listOld = (List<Amount__c>) Trigger.old;

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
        for(Amount__c a : listNew) {
            a.Amount_External_ID__c = a.Amount_External_ID_Hidden__c;
        }
    }

    private void checkItemManagement() {
        for(Amount__c amNew : (listNew != null ? listNew : listOld)) {
            if(!amNew.Itemmanagementcheck__c) {
                amNew.addError('아이템관리에서만 매출현황 편집 가능합니다.');
                return;
            } else {
                amNew.Itemmanagementcheck__c = false;
            }
        }
    }

//    private void checkItemManagement_delete() {
//        for(Amount__c amNew : (listNew != null ? listNew : listOld)) {
//            if(!amNew.Itemmanagementcheck__c) {
//                amNew.addError('아이템관리에서만 매출현황 편집 가능합니다.');
//                return;
//            }
//        }
//    }
}