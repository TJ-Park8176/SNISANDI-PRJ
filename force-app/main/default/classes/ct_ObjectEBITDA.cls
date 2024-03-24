/**
 * Created by MZC01-DGCHOI on 2023-02-24.
 */

public with sharing class ct_ObjectEBITDA {
    @AuraEnabled
    public static void createObject(String targetAPIKey) {
        try {
            if(targetAPIKey == 'Performance__c') {
                //실적 : EBITDA 업로드 & 금액 계산
                Database.executeBatch(new EbitdaPerformance_ba());
            } else if(targetAPIKey == 'ProfitandLoss_Plan__c') {
                //사업계획(손익) : EBITDA 계산
                Database.executeBatch(new EbitdaProfitPlan_ba());
            }

        } catch(Exception e) { throw new AuraHandledException(e.getMessage()); }
    }
}