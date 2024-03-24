/**
 * Created by MZC01-DGCHOI on 2023-01-25.
 */

@IsTest
public with sharing class EmailController_Test {
    @IsTest
    static void test() {
        Test.startTest();

        EmailController.sendEmail('title', 'body');

        Test.stopTest();
    }
}