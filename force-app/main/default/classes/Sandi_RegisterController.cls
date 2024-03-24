/**
 * @description       : 
 * @author            : hyeona.chai@mz.co.kr
 * @group             : MegazoneCloud
 * @last modified on  : 2024-03-19
 * @last modified by  : hyeona.chai@mz.co.kr
**/
public without sharing class Sandi_RegisterController {
    
    @AuraEnabled // (Cacheable=true)
    public static Boolean checkDuplicateEmail(String email) {
        try {
            Boolean result = false;

            String likeValue = '%' + email + '%'; 

            // List<User> users = [SELECT Id FROM User WHERE Username LIKE :likeValue]; // or Email?
            // List<SANDI_Registration__c> users = [SELECT Id FROM SANDI_Registration__c WHERE Email__c LIKE :likeValue];
            
            List<User> users = [SELECT Id FROM User WHERE Username = :email]; // or Email?
            if(!users.isEmpty()) {
                result = true; // 중복
            }
            System.debug('DuplicateResult2--->'+result);
            return result;

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}