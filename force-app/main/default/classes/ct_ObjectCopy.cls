public with sharing class ct_ObjectCopy {
    
    @AuraEnabled
    public static void copyObject(String type, String targetAPIKey){
        try {
            Database.executeBatch(new LatestDataCheck_Batch(type, targetAPIKey), 2000);
            //최신 데이터 여부 TRUE/FALSE Check Batch -> Object Copy Batch
            /*
            1. type
              weeklyExpect: 주간예상
              actionPlan: 실행계획
            2. targetAPIKey
              Amount__c: 매출현황
              Cost__c : 매입현황
              ProfitandLoss__c: 손익현황
              Opportunity : 영업물건관리(수주)
              Opportunity_amount__c: 영업매출 현황
             */
//            if(Test.isRunningTest()) {
//                throw new AuraHandledException('test Exception');
//            }
        } catch (Exception e) { throw new AuraHandledException(e.getMessage()); }
    }
}