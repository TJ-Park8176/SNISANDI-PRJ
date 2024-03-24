/**
 * Created by MZC01-DGCHOI on 2023-02-14.
 */

@IsTest
public with sharing class InitialShell_ba_Test {

    @TestSetup
    static void makeData(){
        WBSandCC__c wbs = new WBSandCC__c();
        wbs.Name = 'testWBS';
        wbs.Check_WBS_CC_ZF__c = 'WBS';
        wbs.WBS_Code__c = 'F00001';
        insert wbs;

        WBSandCC__c ccy = new WBSandCC__c();
        ccy.Name = 'CCY';
        ccy.Check_WBS_CC_ZF__c = 'CC';
        ccy.AccountSubjectSort__c = '용';
        ccy.WBS_Code__c = 'F00002';
        insert ccy;

        WBSandCC__c ccp = new WBSandCC__c();
        ccp.Name = 'CCP';
        ccp.Check_WBS_CC_ZF__c = 'CC';
        ccp.AccountSubjectSort__c = '판';
        ccp.WBS_Code__c = 'F00003';
        insert ccp;
        
        WBSandCC__c zf = new WBSandCC__c();
        zf.Name = 'ZF';
        zf.WBS_Code__c = 'ZF00001';
        zf.Check_WBS_CC_ZF__c = 'ZF';
        zf.WBSType__c = 'FM운영';
        zf.WBSType2__c = 'ZF수주';
        zf.Business_Management__c = true;
        zf.TrackingHeadQuarters__c = '지역미배정';
        insert zf;

        //계정 과목
        AccountSubject__c accSub = new AccountSubject__c();
        accSub.Name = '매출액';
        accSub.UpperSort__c = '매출액';
        accSub.MiddleSort__c = '매출액';
        accSub.LowerSort__c = '매출액';
        insert accSub;

        //아이템관리
        String dummyItemPlanName = 'dummy_' + (Date.today().year()+1);
        ItemManagement_Plan__c itemMng = new ItemManagement_Plan__c();
        itemMng.Name = dummyItemPlanName;
        itemMng.WBS_CC__c = wbs.id;
        itemMng.AccountSubjectselect__c = accSub.Id;
        insert itemMng;

        //계정 과목
        List<String> upperList = new List<String> {'매출액', '총매출원가', '판매비와관리비'};

        List<AccountSubject__c> accList = new List<AccountSubject__c>();
        Integer accIndex = 0;
        for(String upper : upperList) {
            AccountSubject__c newAccSub = new AccountSubject__c();
            newAccSub.Name = upper;
            newAccSub.UpperSort__c = upper;
            newAccSub.AccountSubjectCode__c = 'a' + accIndex++;

            accList.add(newAccSub);
        }
        insert accList;

        //계정과목 - ebitda
        AccountSubject__c ebitda = new AccountSubject__c();
        ebitda.Name = 'EBITDA';
        ebitda.UpperSort__c = 'EBITDA';
        ebitda.AccountSubjectCode__c = 'A5';
        insert ebitda;

        //23.12.19 new계정과목 추가
        AccountSubject__c newAccSub_zfCost = new AccountSubject__c();
        newAccSub_zfCost.Name = 'ZF매입';
        newAccSub_zfCost.UpperSort__c = '총매출원가';
        newAccSub_zfCost.MiddleSort__c = '매출원가';
        newAccSub_zfCost.LowerSort__c = 'ZF매입';
        newAccSub_zfCost.AccountSubjectCode__c = '9999998';
        insert newAccSub_zfCost;

        //23.12.19 new계정과목 추가
        AccountSubject__c newAccSub_zfAmount = new AccountSubject__c();
        newAccSub_zfAmount.Name = 'ZF매출';
        newAccSub_zfAmount.UpperSort__c = '매출액';
        newAccSub_zfAmount.MiddleSort__c = '매출';
        newAccSub_zfAmount.LowerSort__c = 'ZF매출';
        newAccSub_zfAmount.AccountSubjectCode__c = '9999999';
        insert newAccSub_zfAmount;
    }

    @isTest
    static void test(){
        Test.startTest();

        SniYearly_sc sc_yearly = new SniYearly_sc();
        sc_yearly.execute(null);

        Test.stopTest();
    }
}