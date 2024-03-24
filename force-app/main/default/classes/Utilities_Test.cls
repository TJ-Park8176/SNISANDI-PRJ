/**
 * Created by MZC01-DGCHOI on 2023-03-03.
 */

@IsTest
public with sharing class Utilities_Test {

    @IsTest
    static void test() {
        Test.startTest();

        Integer input = 5;
        Utilities.formatZero(input);
        Utilities.getRecordTypeBySObject('Contact');
        Utilities.getRecordTypeDevNameBySObject('Contact');
        String dateString = Utilities.formatYYMM(Date.today());

        Test.stopTest();
    }
}