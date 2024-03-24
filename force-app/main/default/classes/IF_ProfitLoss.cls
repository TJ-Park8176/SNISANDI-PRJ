public with sharing class IF_ProfitLoss {

    public static final Integer NUM_OF_MONTHS = 12;
    public static final List<String> subTypes    = new List<String> {'법인지원비-기타_배부(판)', '법인지원비-안전보건관리비_배부(판)', '담당지원비_배부(용)', '팀지원비_배부(용)', '매출총이익1', '매출총이익2', '영업이익1', '영업이익2', 'EBITDA', '사업간지원비_배부(용)', '(판)사업전담지원비', '(판)사업간지원비'};
    public static final List<String> profitTypes = new List<String> {'법인지원비(기타)', '법인지원비(안전)', '담당지원비', '팀지원비', '매출총이익1', '매출총이익2', '영업이익1', '영업이익2', 'EBITDA', '사업간지원비_배부(용)', '(판)사업전담지원비', '(판)사업간지원비'};
    public static final Integer BATCH_MONTH = Date.today().month();
    
    public static Integer initValue = 1; //1월부터

    public static Map<String, AccountSubject__c> accSubMap = new Map<String, AccountSubject__c>();

    public IF_ProfitLoss() {
        setAccountSubjectMap();
    }

    public static void makeBaseRecord_WBS(List<WBSandCC__c> wbsList) {
        setAccountSubjectMap();

        List<ProfitandLoss__c> upsertPLList = new List<ProfitandLoss__c>();

        for(WBSandCC__c wbs : wbsList) {
            for(Integer i=initValue; i<=NUM_OF_MONTHS; i++) { 
                for(Integer j=0; j<subTypes.size(); j++) {
                    ProfitandLoss__c pl = new ProfitandLoss__c();
                    pl.ProfitandLoss_Type__c        = profitTypes[j];
                    pl.Name                         = i + '월_' + wbs.Name + '_' + subTypes[j];
                    pl.WBS__c                       = wbs.Id;
                    pl.Calculate_month__c           = Date.newInstance(Date.today().year(), i, 1);
                    //external Key
                    pl.ProfitandLoss_External_ID__c = wbs.WBS_Code__c + '-'
                                                    + (accSubMap.containsKey(subTypes[j]) ? accSubMap.get(subTypes[j]).AccountSubjectCode__c : String.valueOf(j)) + '-'
                                                    + pl.Calculate_month__c.year() + '-'
                                                    + pl.Calculate_month__c.month();

                    System.debug('key ::: ' + subTypes[j]);
                    System.debug('값있니? ' + accSubMap.containsKey(subTypes[j]));

                    System.debug(accSubMap);
                    if(accSubMap.containsKey(subTypes[j])) {
                        System.debug('accSubMap get :::: ' + accSubMap.get(subTypes[j]));
                        pl.AccountSubjectSelect__c = accSubMap.get(subTypes[j]).Id;
                    }

                    upsertPLList.add(pl);
                }
            }
        }

        System.debug('@@newWBS: ' + upsertPLList);
        if(upsertPLList.size() > 0) upsert upsertPLList ProfitandLoss_External_ID__c;
    }

    public static void makeBaseRecord_CC(List<WBSandCC__c> wbsList) {
        setAccountSubjectMap();

        List<ProfitandLoss__c> upsertPLList = new List<ProfitandLoss__c>();

        for(WBSandCC__c wbs : wbsList) {
            for(Integer i=initValue; i<=NUM_OF_MONTHS; i++) {
                    ProfitandLoss__c pl = new ProfitandLoss__c();
                    pl.ProfitandLoss_Type__c        = 'EBITDA';
                    pl.Name                         = i + '월_' + wbs.Name + '_' + 'EBITDA';
                    pl.WBS__c                       = wbs.Id;
                    pl.Calculate_month__c           = Date.newInstance(Date.today().year(), i, 1);
                    //external Key
                    pl.ProfitandLoss_External_ID__c = wbs.WBS_Code__c + '-'
                                                    + (accSubMap.containsKey('EBITDA') ? accSubMap.get('EBITDA').AccountSubjectCode__c : String.valueOf(i)) + '-'
                                                    + pl.Calculate_month__c.year() + '-'
                                                    + pl.Calculate_month__c.month();

                    if(accSubMap.containsKey('EBITDA')) pl.AccountSubjectSelect__c  = accSubMap.get('EBITDA').Id;

                upsertPLList.add(pl);
            }
        }
        if(upsertPLList.size() > 0) upsert upsertPLList ProfitandLoss_External_ID__c;
    }

    public static void makeNewRecord(String checkType, List<WBSandCC__c> wbsList) {
        initValue = BATCH_MONTH;

        if(checkType == 'WBS') {
            //wbsList = getNewWBS();
            if(wbsList.size() > 0) makeBaseRecord_WBS(wbsList);
        } else if(checkType == 'CC') {
            //wbsList = getNewCC();
            if(wbsList.size() > 0) makeBaseRecord_CC(wbsList);
        }
    }

    public static List<WBSandCC__c> getNewWBS() { //어제 생성된 WBS
        List<WBSandCC__c> wbsList = [
                SELECT id, Name, WBS_Code__c
                FROM WBSandCC__c
                WHERE Check_WBS_CC_ZF__c = 'WBS'
        ];

        System.debug('newWBS Size :::: ' + wbsList.size());

        if(wbsList.size()==0) wbsList = new List<WBSandCC__c>();
        return wbsList;         
    }

    public static List<WBSandCC__c> getNewCC() {
        List<WBSandCC__c> ccList = [
                SELECT id, Name, WBS_Code__c
                FROM WBSandCC__c
                //WHERE CreatedDate = YESTERDAY //YESTERDAY
                WHERE Check_WBS_CC_ZF__c = 'CC'
        ];

        System.debug('newCC Size :::: ' + ccList.size());

        if(ccList.size()==0) ccList = new List<WBSandCC__c>();
        return ccList;
    }

    public static void setAccountSubjectMap() {
        List<AccountSubject__c> accSubList = [
                SELECT Id, Name, AccountSubjectCode__c
                FROM AccountSubject__c
                WHERE AccountSubjectCode__c IN (
                        '9100002', //법인지원비-기타_배부(판)
                        '9100011', //법인지원비-안전보건관리비_배부(판)
                        '9100008', //담당지원비_배부(용)
                        '9100007', //팀지원비_배부(용)
                        'A1', //매출총이익1
                        'A2', //매출총이익2
                        'A3', //영업이익1
                        'A4', //영업이익2
                        'A5',  //EBITDA
                        '9100013', //사업간지원비_배부(용)
                        '9100009', //(판)사업전담지원비
                        '9100005'  //(판)사업간지원비
                )
        ];

        for(AccountSubject__c a : accSubList) {
            accSubMap.put(a.Name, a);
        }

        System.debug('accSubMap :::: ' + accSubMap);
    }

}