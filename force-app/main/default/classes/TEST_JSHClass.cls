/**
 * @description       : 
 * @author            : sungho.jo@mz.co.kr
 * @group             : 
 * @last modified on  : 2024-03-22
 * @last modified by  : sungho.jo@mz.co.kr
**/
public without sharing class TEST_JSHClass {
    

    @AuraEnabled
    public static Case getCase(){
        return [SELECT ID, CreatedBy.Name, Subject, Owner.Name FROM Case LIMIT 1];
    }
}