/**
 * Created by MZC01-DGCHOI on 2023-12-19.
 */

@IsTest
public with sharing class InitialShellPerformance_ba_Test {

    @TestSetup
    static void makeData() {
        WBSandCC__c wbs = new WBSandCC__c();
        wbs.Name = 'WBS';
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
        ccp.Name = 'CCY';
        ccp.Check_WBS_CC_ZF__c = 'CC';
        ccp.AccountSubjectSort__c = '판';
        ccp.WBS_Code__c = 'F00003';
        insert ccp;

        //23.12.19 newWBS추가
        WBSandCC__c newWBS = new WBSandCC__c();
        newWBS.Name = 'ZF매출_매입용 Dummy WBS';
        newWBS.Check_WBS_CC_ZF__c = 'WBS';
        newWBS.WBS_Code__c = '000000000001';
        insert newWBS;

        //계정 과목
        List<String> upperList = new List<String> {'매출액', '총매출원가', '판매비와관리비'};

        List<AccountSubject__c> accList = new List<AccountSubject__c>();
        Integer accIndex = 0;
        for(String upper : upperList) {
            AccountSubject__c accSub = new AccountSubject__c();
            accSub.Name = upper;
            accSub.UpperSort__c = upper;
            accSub.AccountSubjectCode__c = 'a' + accIndex++;

            accList.add(accSub);
        }
        insert accList;


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

    @IsTest
    static void test() {
        Test.startTest();

        InitialShellPerformance_ba batch = new InitialShellPerformance_ba(0);
        Database.executeBatch(batch);

        Test.stopTest();
    }
}