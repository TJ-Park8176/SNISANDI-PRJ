/**
 * Created by MZC01-DGCHOI on 2023-03-08.
 */

@IsTest
public with sharing class SniScheduler_Test {

    @isTest
    static void test() {
        Test.startTest();

        SniYearly_sc sc_yearly = new SniYearly_sc();
        sc_yearly.execute(null);

        Test.stopTest();
    }
}