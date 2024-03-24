@isTest
public with sharing class ObjectCopy_ba_Test {
    @TestSetup
    static void makeData(){
        WBSandCC__c wbs = new WBSandCC__c();
        wbs.Name = 'testWBS';
        wbs.WBS_Code__c = 'F00001';
        wbs.Check_WBS_CC_ZF__c = 'WBS';
        wbs.AccountSubjectSort__c = '용';
        insert wbs;

        WBSandCC__c zf = new WBSandCC__c();
        zf.Name = 'ZF';
        zf.WBS_Code__c = 'ZF00001';
        zf.Check_WBS_CC_ZF__c = 'ZF';
        zf.WBSType__c = 'FM운영';
        zf.WBSType2__c = 'ZF수주';
        zf.Business_Management__c = true;
        zf.TrackingHeadQuarters__c = '지역미배정';
        insert zf;

        WBSandCC__c newWBS = new WBSandCC__c();
        newWBS.Name = 'newWBS';
        newWBS.WBS_Code__c = 'F00002';
        newWBS.Check_WBS_CC_ZF__c = 'WBS';
        insert newWBS;

        ItemManagement__c itemMng = new ItemManagement__c();
        itemMng.Name = '아이템관리';
        itemMng.WBS_CC__c = wbs.Id;
        insert itemMng;

        //계정과목
        Set<String> upperSet = new Set<String> {'매출액', '총매출원가', '판매비와관리비'};

        List<AccountSubject__c> accSubList = new List<AccountSubject__c>();

        for(String upper : upperSet) {
            AccountSubject__c accSub = new AccountSubject__c();
            accSub.Name = '매출액';
            accSub.UpperSort__c = '매출액';
            accSub.AccountSubjectsort__c = '용';
            accSubList.add(accSub);
        }
        insert accSubList;


        List<Amount__c> amountList = new List<Amount__c>();
        List<Cost__c> costList = new List<Cost__c>();
        //List<ProfitandLoss__c> proList = new List<ProfitandLoss__c>();
        List<Opportunity> opptyList = new List<Opportunity>();
        List<Opportunity_amount__c> opptyAmountList = new List<Opportunity_amount__c>();

        for(Integer i=1; i<=12; i++) {
            Amount__c a = new Amount__c();
            a.Name = '매출 TEST';
            a.WBS__c = wbs.Id;
            a.Itemmanagement__c = itemMng.Id;
            a.AccountSubjectselect__c = accSubList[0].Id;
            a.CalculateDate__c = Date.newInstance(Date.today().year(), i, 1);
            a.Itemmanagementcheck__c = true;
            amountList.add(a);

            Cost__c c = new Cost__c();
            c.Name = '매입 TEST';
            c.WBS__c = wbs.Id;
            c.Itemmanagement__c = itemMng.Id;
            c.AccountSubjectselect__c = accSubList[0].Id;
            c.CalculateDate__c = Date.newInstance(Date.today().year(), i, 1);
            c.Itemmanagementcheck__c = true;
            costList.add(c);

//            ProfitandLoss__c p = new ProfitandLoss__c();
//            p.ProfitandLoss_Type__c = '매출총이익1';
//            p.Name = '손익현황 TEST';
//            p.WBS__c = wbs.Id;
//            p.Calculate_month__c = Date.newInstance(Date.today().year(), i, 1);
//            proList.add(p);

            Opportunity o = new Opportunity();
            o.Name = '수주 TEST';
            o.General_p__c = '사업총괄';
            o.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('FM수주').getRecordTypeId();
            o.WBS_CC__c = zf.Id;
            o.Possibility_of_closed_won__c = '높음';
            o.StageName = '잠재고객';
            o.Type2__c = '단일';
            o.Status__c = '신규';
            o.Expect_date_of_closed__c = Date.newInstance(Date.today().year(), i, 1);
            o.contract_closingdate__c = Date.newInstance(Date.today().year(), i, 1);
            o.CloseDate = Date.newInstance(Date.today().year(), i, 1);
            opptyList.add(o);
        }

        insert amountList;
        insert costList;
        //insert proList;
        insert opptyList;

        for(Opportunity oppty : opptyList) {
            for(Integer i=1; i<=12; i++) {
                Opportunity_amount__c amt = new Opportunity_amount__c();
                amt.OpportunityName__c = oppty.Id;
                amt.Name = i+1 + '월_' + oppty.Name + '_accountName';
                amt.CalculateDate__c = Date.newInstance(Date.today().year(), i, 1);
                amt.Monthly_amount__c = 100;
                amt.OpportunityCheck__c = true;

                opptyAmountList.add(amt);
            }
        }
        insert opptyAmountList;
    }

    @isTest
    static void test(){
        Test.startTest();

        List<WBSandCC__c> wbsList = [SELECT Id FROM WBSandCC__c];
        System.debug('wbsList ::::' + wbsList);

        copyObject();

        Test.stopTest();
    }

    private static void copyObject() {
        ct_ObjectCopy.copyObject('actionPlan', 'Amount__c');
        ct_ObjectCopy.copyObject('actionPlan', 'Opportunity');
//        ct_ObjectCopy.copyObject('actionPlan', 'Opportunity');
//        ct_ObjectCopy.copyObject('actionPlan', 'Cost__c');
//        ct_ObjectCopy.copyObject('actionPlan', 'ProfitandLoss__c');
//        ct_ObjectCopy.copyObject('actionPlan', 'Opportunity');
//        ct_ObjectCopy.copyObject('actionPlan', 'Opportunity_amount__c');

        ct_ObjectCopy.copyObject('weeklyExpect', 'Amount__c');
//        ct_ObjectCopy.copyObject('weeklyExpect', 'Opportunity');
//        ct_ObjectCopy.copyObject('weeklyExpect', 'Cost__c');
//        ct_ObjectCopy.copyObject('weeklyExpect', 'ProfitandLoss__c');
//        ct_ObjectCopy.copyObject('weeklyExpect', 'Opportunity');
//        ct_ObjectCopy.copyObject('weeklyExpect', 'Opportunity_amount__c');
    }
}