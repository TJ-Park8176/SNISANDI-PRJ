/**
 * @description       : SANDI_NicepayController
 * @author            : sungho.jo@mz.co.kr
 * @group             : MegazoneCloud
 * @last modified on  : 2024-03-22
 * @last modified by  : sungho.jo@mz.co.kr
**/
public with sharing class SANDI_NicepayController {

    private static SANDI_Nicepay pay = new SANDI_Nicepay();

    @AuraEnabled
    public static SANDI_Nicepay.NicepayApprResponse requestApprPayments(){
        try{
            return null;
        }catch(AuraHandledException e){
            throw new AuraHandledException(e.getMessage());
        }
    }

}