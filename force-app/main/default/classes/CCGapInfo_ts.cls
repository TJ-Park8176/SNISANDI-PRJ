/**
 * Created by MZC01-DGCHOI on 2023-08-03.
 */

@IsTest
public with sharing class CCGapInfo_ts {

    @TestSetup
    static void makeData() {

    }

    @IsTest
    static void test() {
        Test.startTest();

        CCGAPInfo info = new CCGAPInfo();

        Test.stopTest();
    }

}