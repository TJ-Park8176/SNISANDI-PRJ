/**
 * Created by MZC01-DGCHOI on 2023-03-08.
 */

@IsTest
public with sharing class WBSCCZF_tr_Test {
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
    }

    @IsTest
    static void test() {
        Test.startTest();

        WBSandCC__c zf = new WBSandCC__c();
        zf.Name = 'ZF';
        zf.WBS_Code__c = 'ZF00002';
        zf.Check_WBS_CC_ZF__c = 'ZF';
        zf.WBSType__c = 'FM운영';
        zf.WBSType2__c = 'ZF수주';
        zf.Business_Management__c = true;
        zf.TrackingHeadQuarters__c = '지역미배정';
        insert zf;

        WBSandCC__c deleteZF = [
                SELECT Id
                FROM WBSandCC__c
                WHERE WBS_Code__c = 'ZF00002'
                LIMIT 1
        ];

        delete deleteZF;

        Test.stopTest();
    }
}