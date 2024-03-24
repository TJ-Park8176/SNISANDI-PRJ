public with sharing class AmountPlan_tr extends TriggerHandler{ //매출 계획

    private List<Amount_plan__c> listNew = (List<Amount_plan__c>) Trigger.new;
    private List<Amount_plan__c> listOld = (List<Amount_plan__c>) Trigger.old;

    public override void beforeInsert() {
        linkLookupField();
        checkItemManagement();
    }

    public override void afterInsert() {
        //copyByAmount();
    }

    public override void beforeUpdate() {
        checkItemManagement();
    }

    private void linkLookupField() {
        //매출 계획 Lookup
        Map<String, Id> wbsMap = getWbsCodeMap();
        Map<String, Id> accSubMap = getAccSubCodeMap();
        Map<String, Id> itemMngMap = getItemMngCodeMap();
        Map<String, Id> accMap = getAccCodeMap();

        for(Amount_plan__c ap : listNew) {
            //WBS
            if(ap.WBS_Code_Hidden__c != null && ap.WBS__c == null)
                ap.WBS__c = wbsMap.get(ap.WBS_Code_Hidden__c);

            //계정과목
            if(ap.AccountSubjectCode_hidden__c != null && ap.AccountSubjectselect__c == null)
                ap.AccountSubjectselect__c = accSubMap.get(ap.AccountSubjectCode_hidden__c);

            //아이템관리
            if(ap.Itemmanagement_code_hidden__c != null && ap.Itemmanagement__c == null)
                ap.Itemmanagement__c = itemMngMap.get(ap.Itemmanagement_code_hidden__c);

            //매출처 //Account_Code__c
            if(ap.Account_code_Hidden__c != null && ap.Account__c == null)
                ap.Account__c = accMap.get(ap.Account_code_Hidden__c);

            //담당자(User)는 ID로 업로드됨 (Lookup 필요X)

        }
        System.debug('beforeInsert END listNew: ' + listNew);
    }

    /*
    private void copyByAmount() {
        // 매출 복제
        List<Amount__c> insertAmtList = new List<Amount__c>();

        for(Amount_plan__c ap : listNew) {
            Amount__c a = new Amount__c();
            //Lookup
            if(ap.WBS__c != null)                  a.WBS__c                   = ap.WBS__c;
            if(ap.AccountSubjectselect__c != null) a.AccountSubjectselect__c  = ap.AccountSubjectselect__c;
            if(ap.Itemmanagement__c != null)       a.Itemmanagement__c        = ap.Itemmanagement__c;
            if(ap.Account__c != null)              a.Account__c               = ap.Account__c;
            if(ap.User__c != null)                 a.User__c                  = ap.User__c;

            //그 외 필드
            if(ap.Name != null)              a.Name               = ap.Name;
            if(ap.Status__c != null)         a.Status__c          = ap.Status__c;
            if(ap.CalculateDate__c != null)  a.CalculateDate__c   = ap.CalculateDate__c;
            if(ap.PlanAmount__c != null)     a.PredictAmount__c   = ap.PlanAmount__c;
            if(ap.AmountType__c != null)     a.AmountType__c      = ap.AmountType__c; //매출 유형
            if(ap.AmountDivision__c != null) a.AmountDivision__c  = ap.AmountDivision__c; //매출 구분
            if(ap.SalesSort__c != null)      a.SalesSort__c       = ap.SalesSort__c; //영업 구분

            //Check
            a.Itemmanagementcheck__c = true;


            //new [삭제 필드]
            //if(ap.Expected_GrossProfit_Rate__c !=null) a.Expected_GrossProfit_Rate__c = ap.Expected_GrossProfit_Rate__c;
            //if(ap.Total_cost_plan__c != null) a.Total_cost_plan__c = ap.Total_cost_plan__c;

            insertAmtList.add(a);
        }

        System.debug(insertAmtList);
        if(insertAmtList.size() > 0) insert insertAmtList;
    }
    */

    private Map<String, Id> getWbsCodeMap() { //WBS Code -> WBS ID
        Set<String> wbsCodeSet = new Set<String>();
        for(Amount_plan__c ap : listNew) {
            wbsCodeSet.add(ap.WBS_Code_hidden__c);
        }
        
        List<WBSandCC__c> wbsList = [
            SELECT id, WBS_Code__c
            FROM WBSandCC__c
            WHERE WBS_Code__c IN: wbsCodeSet
        ];
        
        Map<String, Id> returnMap = new Map<String, Id>();
        for(WBSandCC__c w : wbsList) {
            returnMap.put(w.WBS_Code__c, w.Id);
        }
        
        return returnMap;
    }

    private Map<String, Id> getAccSubCodeMap() {
        Set<String> accSubCodeSet = new Set<String>();
        for(Amount_plan__c ap : listNew) {
            accSubCodeSet.add(ap.AccountSubjectCode_hidden__c);
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
        for(Amount_plan__c ap : listNew) {
            itemCodeSet.add(ap.Itemmanagement_code_hidden__c);
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

    private Map<String, Id> getAccCodeMap() {
        Set<String> accCodeSet = new Set<String>();
        for(Amount_Plan__c ap : listNew) {
            accCodeSet.add(ap.Account_code_Hidden__c);
        }

        List<Account> accList = [
                SELECT Id, Account_Code__c
                FROM Account
                WHERE Account_Code__c IN :accCodeSet
        ];

        Map<String, Id> returnMap = new Map<String, Id>();
        for(Account a : accList) {
            returnMap.put(a.Account_Code__c, a.Id);
        }

        return returnMap;
    }

    private void checkItemManagement() {
        for(Amount_plan__c amNew : (listNew != null ? listNew : listOld)) {
            System.debug('Itemmanagementcheck__c : ' + amNew.Itemmanagementcheck__c);
            if(!amNew.Itemmanagementcheck__c) {
                amNew.addError('사업계획(아이템관리)에서만 매출현황 편집 가능합니다.');
                return;
            } else {
                amNew.Itemmanagementcheck__c = false;
            }
        }
    }
}