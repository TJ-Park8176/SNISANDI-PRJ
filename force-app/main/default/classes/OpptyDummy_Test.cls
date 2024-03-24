/**
 * Created by MZC01-DGCHOI on 2023-04-03.
 */

@IsTest
public with sharing class OpptyDummy_Test {

    @TestSetup
    static void makeData() {

    }

    @IsTest
    static void test() {
        Test.startTest();

        WBSandCC__c zf = new WBSandCC__c();
        zf.Name = 'ZF';
        zf.WBS_Code__c = 'ZF00001';
        zf.Check_WBS_CC_ZF__c = 'ZF';
        zf.WBSType__c = 'FM운영';
        zf.WBSType2__c = 'ZF수주';
        zf.Business_Management__c = true;
        zf.TrackingHeadQuarters__c = '지역미배정';
        insert zf;

        InitialShellOppty_ba batch = new InitialShellOppty_ba();
        Database.executeBatch(batch, 1);


        Test.stopTest();
    }
}