/**
 * Created by MZC01-DGCHOI on 2023-04-27.
 */

@IsTest
public with sharing class Contact_tr_Test {

    @TestSetup
    static void makeData() {
        WBSandCC__c zf = new WBSandCC__c();
        zf.Name = 'ZF';
        zf.WBS_Code__c = 'ZF00001';
        zf.Check_WBS_CC_ZF__c = 'ZF';
        zf.WBSType__c = 'FM운영';
        zf.WBSType2__c = 'ZF수주';
        zf.Business_Management__c = true;
        zf.TrackingHeadQuarters__c = '지역미배정';
        insert zf;

        Opportunity oppty = new Opportunity();
        oppty.Name = '수주 TEST';
        oppty.General_p__c = '사업총괄';
        oppty.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('FM수주').getRecordTypeId();
        oppty.WBS_CC__c = zf.Id;
        oppty.Possibility_of_closed_won__c = '높음';
        oppty.StageName = '잠재고객';
        oppty.Type2__c = '통합';
        oppty.Status__c = '신규';
        oppty.Expect_date_of_closed__c = Date.today();
        oppty.contract_closingdate__c = Date.today();
        oppty.CloseDate = Date.today();
        insert oppty;

        Opportunity_plan__c oppPlan = new Opportunity_plan__c();
        oppPlan.Name = '수주 TEST';
        oppPlan.General_p__c = '사업총괄';
        oppPlan.RecordTypeId = Schema.SObjectType.Opportunity_plan__c.getRecordTypeInfosByName().get('FM수주').getRecordTypeId();
        oppPlan.WBS_CC__c = zf.Id;
        oppPlan.Possibility_of_closed_won__c = '높음';
        oppPlan.StageName__c = '잠재고객';
        oppPlan.Type2__c = '통합';
        oppPlan.Status__c = '신규';
        oppPlan.Expect_date_of_closed__c = Date.today();
        oppPlan.contract_closingdate__c = Date.today();
        oppPlan.CloseDate__c = Date.today();
        insert oppPlan;

        Account account = new Account();
        account.Name = 'Account';
        account.Business_Registration_Number__c = 'A000001';
        insert account;
    }

    @IsTest
    static void test() {
        Test.startTest();

        String oppId = [
                SELECT Id
                FROM Opportunity
                LIMIT 1
        ].Id;

        String oppPlanId = [
                SELECT Id
                FROM Opportunity_plan__c
                LIMIT 1
        ].Id;

        String accId = [
                SELECT Id
                FROM Account
                LIMIT 1
        ].Id;

        Contact con        = new Contact();
        con.LastName       = 'Contact';
        con.Opportunity__c = oppId;
        con.AccountId      = accId;
        insert con; //after insert test
        update con; //after update test
        delete con; //after delete test

        Contact con_plan             = new Contact();
        con_plan.LastName            = 'Contact Plan';
        con_plan.Opportunity_Plan__c = oppPlanId;
        con_plan.AccountId           = accId;
        insert con_plan; //after insert test
        update con_plan; //after update test
        delete con_plan; //after delete test

        Test.stopTest();
    }
}