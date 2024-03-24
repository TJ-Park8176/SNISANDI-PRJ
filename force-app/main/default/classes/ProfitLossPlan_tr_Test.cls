/**
 * Created by MZC01-DGCHOI on 2023-01-20.
 */

@isTest
public with sharing class ProfitLossPlan_tr_Test {

    @IsTest
    static void test() {
        Test.startTest();

        Profile p = [SELECT Id FROM Profile LIMIT 1];
        User usr = new User(Alias = 'standt', Email='standarduser@testorg.com',
                EmailEncodingKey='UTF-8', LastName='dgchoi Test', LanguageLocaleKey='en_US',
                LocaleSidKey='en_US', ProfileId = p.Id,
                TimeZoneSidKey='America/Los_Angeles', UserName='dgchoi@testorg.com');
        insert usr ;

        WBSandCC__c wbs = new WBSandCC__c();
        wbs.Name = 'WBS TEST';
        wbs.WBS_Code__c = 'F00001';
        insert wbs;

        AccountSubject__c accSub = new AccountSubject__c();
        accSub.Name = '계정과목 TEST';
        accSub.AccountSubjectCode__c = 'A00001';
        insert accSub;


        ProfitandLoss_Plan__c pp = new ProfitandLoss_Plan__c();
        pp.WBS_Code_Hidden__c = pp.WBS_Code__c;
        pp.AccountSubjectCode_hidden__c = accSub.AccountSubjectCode__c;
        pp.OwnerId = usr.Id;
        pp.ProfitandLoss_Type__c = '매출총이익1';
        pp.Name = '실행계획(손익계산) TEST';
        insert pp;

        Test.stopTest();
    }
}