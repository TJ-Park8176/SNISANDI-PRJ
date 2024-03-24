/**
 * Created by MZC01-DGCHOI on 2023-09-13.
 */

public with sharing class Account_tr extends TriggerHandler {

    List<Account> listNew = (List<Account>) Trigger.new;
    List<Account> listOld = (List<Account>) Trigger.old;

    public override void beforeInsert() {
        checkDuplicateAccounts();
    }

    public override void beforeUpdate() {
        checkDuplicateAccounts();
    }

    public void checkDuplicateAccounts() {
        Set<String> registrationNumbers = new Set<String>();
        Account newAcc = listNew[0];
        Account oldAcc = listOld != null ? listOld[0] : null;
        
        for(Account acc : listNew) {
           
            //////// 개인회원은 사업자번호 중복허용//////////
            if(acc.CustomerSort__c == '기업') {
                if(acc.Business_Registration_Number__c != null) {
                    System.debug('acc.Business_Registration_Number__c ================= >>>' +acc.Business_Registration_Number__c);
                    System.debug('acc.SANDI_F_BizNumer__c ================= >>>' +acc.SANDI_F_BizNumer__c);

                    registrationNumbers.add(acc.SANDI_F_BizNumer__c);
                } else {
                    if(oldAcc.CustomerSort__c == newAcc.CustomerSort__c){
                        acc.addError('사업자등록번호를 입력해주세요.');
                    } else {
                        System.debug('개인 -> 기업으로 업데이트');
                    }
                   
                }
            }
        }

        List<Account> duplicateAccounts = new List<Account>();
        // 활성화된
        duplicateAccounts = [SELECT Id 
                             FROM   Account 
                             WHERE  IsActive__c = true 
                             AND    CustomerSort__c = '기업' 
                             AND    SANDI_F_BizNumer__c IN: registrationNumbers];

        if(!duplicateAccounts.isEmpty()) {
            //for(Integer i=0; i<listNew.size(); i++) {
            if(oldAcc != null) { //update
                if(newAcc.SANDI_F_BizNumer__c != oldAcc.SANDI_F_BizNumer__c) {
                    if(registrationNumbers.contains(newAcc.SANDI_F_BizNumer__c)) {
                        newAcc.addError('동일한 사업자등록번호가 존재합니다.');
                    }
                }
            } else {
                System.debug(newAcc.SANDI_F_BizNumer__c);
                if(registrationNumbers.contains(newAcc.SANDI_F_BizNumer__c)) {
                    newAcc.addError('동일한 사업자등록번호가 존재합니다.');
                }
            }

            //}
        }
    }

}