/**
 * Created by MZC01-DGCHOI on 2023-09-13.
 */

@IsTest
public with sharing class Account_tr_ts {

    @TestSetup
    public static void makeData() {
        Account acc = new Account();
        acc.Name = 'existing account';
        acc.Business_Registration_Number__c = 'test01';
        insert acc;
    }

    @IsTest
    public static void testDuplicateNumber() {
        Test.startTest();

        //insert & duplicate check
        try {
            Account acc = new Account();
            acc.Name = 'new account';
            acc.Business_Registration_Number__c = 'test01';
            insert acc;
        } catch (Exception e) {
            Boolean expectedExceptionThrown =  e.getMessage().contains('동일한 사업자등록번호가 존재합니다.') ? true : false;
            System.assertEquals(expectedExceptionThrown, true);
        }

        Test.stopTest();
    }

    @isTest
    public static void testBusinessRegistrationNumberNull() {
        Test.startTest();

        try {
            //update & null check
            Account acc = [
                    SELECT Id
                    FROM Account
                    WHERE Business_Registration_Number__c = 'test01'
                    LIMIT 1
            ];
            acc.Business_Registration_Number__c = null;
            update acc;
        } catch (Exception e) {
            Boolean expectedExceptionThrown =  e.getMessage().contains('사업자등록번호를 입력해주세요.') ? true : false;
            System.assertEquals(expectedExceptionThrown, true);
        }
    }
}