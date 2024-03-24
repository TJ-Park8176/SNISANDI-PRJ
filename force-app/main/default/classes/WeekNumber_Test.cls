/**
 * Created by MZC01-DGCHOI on 2023-02-20.
 */

@IsTest
public with sharing class WeekNumber_Test {


    @IsTest
    static void test() {
        Test.startTest();

        Date tmpDate = Date.newInstance(2023,1,1);

        for(Integer i=0; i<3; i++) {
            WeekNumber weekNumber = new WeekNumber(tmpDate.addMonths(i));
        }

        Test.stopTest();
    }
}