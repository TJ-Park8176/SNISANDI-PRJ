public with sharing class CostPlan_tr extends TriggerHandler { //매입 계획
    private List<Cost_Plan__c> listNew = (List<Cost_Plan__c>) Trigger.new;
    private List<Cost_Plan__c> listOld = (List<Cost_Plan__c>) Trigger.new;

    public override void beforeInsert() {
        linkLookupField();
        setExternalID();
        checkItemManagement();
    }

    public override void afterInsert() {
        //copyByCost();
    }

    public override void beforeUpdate() {
        setExternalID();
        checkItemManagement();
    }

    private void linkLookupField() {
        //매입 계획 Lookup

        Map<String, Id> wbsMap = getWbsCodeMap();
        Map<String, Id> accSubMap = getAccSubCodeMap();
        Map<String, Id> itemMngMap = getItemMngCodeMap();

        for(Cost_Plan__c cp : listNew) {
            //WBS
            if(cp.WBS_Code_Hidden__c != null && cp.WBS__c == null)
                cp.WBS__c = wbsMap.get(cp.WBS_Code_Hidden__c);

            //계정과목
            if(cp.AccountSubjectCode_hidden__c != null && cp.AccountSubjectselect__c == null)
                cp.AccountSubjectselect__c = accSubMap.get(cp.AccountSubjectCode_hidden__c);

            //아이템관리
            if(cp.Itemmanagement_code_hidden__c != null && cp.Itemmanagement__c == null)
                cp.Itemmanagement__c = itemMngMap.get(cp.Itemmanagement_code_hidden__c);

            //담당자(User)는 ID로 업로드됨 (Lookup 필요X)
        }
        System.debug('beforeInsert END listNew: ' + listNew);
    }

    private void setExternalID() {
        for(Cost_Plan__c cp : listNew) {
            if(cp.Real_Data_check__c) {
                cp.Cost_Plan_External_ID__c = cp.Cost_Plan_External_ID_Hidden__c;
            } else {
                cp.Cost_Plan_External_ID__c = cp.Cost_Plan_External_ID_Hidden__c + '-dummy';
            }
            System.debug(cp.Cost_Plan_External_ID__c);
        }
    }

    /*
    private void copyByCost() {
        //매입 복제
        List<Cost__c> insertCstList = new List<Cost__c>();
        
        for(Cost_Plan__c cp : listNew) {
            Cost__c c = new Cost__c();
            //Lookup
            if(cp.WBS__c != null)                  c.WBS__c = cp.WBS__c;
            if(cp.AccountSubjectselect__c != null) c.AccountSubjectselect__c = cp.AccountSubjectselect__c;
            if(cp.Itemmanagement__c != null)       c.Itemmanagement__c = cp.Itemmanagement__c;
            if(cp.Owner__c != null)                c.Owner__c = cp.Owner__c;

            //그 외 필드
            if(cp.Name != null)                  c.Name               = cp.Name;
            if(cp.PlanPurchaseAmount__c != null) c.PurchaseAmount__c  = cp.PlanPurchaseAmount__c;
            if(cp.CalculateDate__c != null)      c.CalculateDate__c   = cp.CalculateDate__c;
            c.Itemmanagementcheck__c = true;

            insertCstList.add(c);
        }

        System.debug('매입 insert: ' + insertCstList);
        if(insertCstList.size() > 0) insert insertCstList;
    }
    */

    private Map<String, Id> getWbsCodeMap() { //WBS Code -> WBS ID
        Set<String> wbsCodeSet = new Set<String>();
        for(Cost_Plan__c cp : listNew) {
            wbsCodeSet.add(cp.WBS_Code_hidden__c);
        }
        
        List<WBSandCC__c> wbsList = [SELECT id, WBS_Code__c
                                FROM WBSandCC__c
                                WHERE WBS_Code__c IN: wbsCodeSet];
        
        Map<String, Id> returnMap = new Map<String, Id>();
        for(WBSandCC__c w : wbsList) {
            returnMap.put(w.WBS_Code__c, w.Id);
        }
        
        return returnMap;
    }

    private Map<String, Id> getAccSubCodeMap() {
        Set<String> accSubCodeSet = new Set<String>();
        for(Cost_Plan__c cp : listNew) {
            accSubCodeSet.add(cp.AccountSubjectCode_hidden__c);
        }

        List<AccountSubject__c> accSubList = [
                SELECT Id, AccountSubjectCode__c
                FROM AccountSubject__c
                WHERE AccountSubjectCode__c IN: accSubCodeSet
        ];

        Map<String, Id> returnMap = new Map<String, Id>();
        for(AccountSubject__c a : accSubList) {
            returnMap.put(a.AccountSubjectCode__c, a.Id);
        }

        return returnMap;
    }

    private Map<String, Id> getItemMngCodeMap() {
        Set<String> itemCodeSet = new Set<String>();
        for(Cost_Plan__c cp : listNew) {
            itemCodeSet.add(cp.Itemmanagement_code_hidden__c);
        }

        List<ItemManagement__c> itemList = [
                SELECT Id, Itemmanagement_code__c
                FROM ItemManagement__c
                WHERE Itemmanagement_code__c IN: itemCodeSet
        ];

        Map<String, Id> returnMap = new Map<String, Id>();
        for(ItemManagement__c i : itemList) {
            returnMap.put(i.Itemmanagement_code__c, i.Id);
        }

        return returnMap;
    }

    private void checkItemManagement() {
        for(Cost_Plan__c csNew : (listNew!=null ? listNew : listOld)) {
            if(!csNew.Itemmanagementcheck__c) {
                csNew.addError('아이템관리에서만 매입 편집 가능합니다.');
            } else { //true -> false
                csNew.Itemmanagementcheck__c = false;
            }
        }
    }

}