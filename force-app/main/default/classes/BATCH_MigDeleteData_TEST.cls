/**
 * @description       : 
 * @author            : soohong@mz.co.kr
 * @group             : 
 * @last modified on  : 2023-02-06
 * @last modified by  : junghwa@mz.co.kr
 * Modifications Log
 * Ver   Date         Author             Modification
 * 1.0   2022-12-19   soohong@mz.co.kr   Initial Version
**/
@isTest
public class BATCH_MigDeleteData_TEST {

    @TestSetup
    static void makeData(){
        Account acc = new Account();
        acc.Name = 'test';
        insert acc;
    }
    
	@isTest
    public static void BATCH_MigDeleteData_TEST1(){
        Database.executeBatch(new BATCH_MigDeleteData('account'));
        new BATCH_MigDeleteData();
    }
    
    @isTest
    public static void BATCH_MigDeleteData_TEST2(){
        Database.executeBatch(new BATCH_MigDeleteData('account','asc'));
    }
}