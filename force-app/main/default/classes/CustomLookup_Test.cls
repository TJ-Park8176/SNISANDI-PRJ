/**
 * Created by MZC01-DGCHOI on 2023-03-29.
 */

@IsTest
public with sharing class CustomLookup_Test {

    @TestSetup
    static void makeData() {
        AccountSubject__c accSub = new AccountSubject__c();
        accSub.Name = 'test';
        accSub.UpperSort__c = '매출액';
        accSub.AccountSubjectCode__c = 'A1';
        accSub.AccountSubjectsort__c = '용';
        insert accSub;
    }

    @IsTest
    static void test() {
        Test.startTest();

        CustomLookup.search('test', 'AccountSubject__c', '용');
        CustomLookup.search('test', 'AccountSubject__c', '');
        CustomLookup.search('', 'AccountSubject__c', '');

        Test.stopTest();
    }
}