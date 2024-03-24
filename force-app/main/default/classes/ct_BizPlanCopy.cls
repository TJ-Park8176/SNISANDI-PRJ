/**
 * Created by MZC01-DGCHOI on 2023-09-22.
 * TestCode : BizPlanCopy_ba_Test
 */

public with sharing class ct_BizPlanCopy {

    @AuraEnabled
    public static void copyRecord(String baseYear) {
        try {
            //아이템관리 -> 매출/매입
            Database.executeBatch(new BizPlanCopy_ba('아이템관리', baseYear), 5);

            //손익현황
            Database.executeBatch(new BizPlanCopy_ba('손익', baseYear), 1000);

            //수주(통합) -> 수주(!통합) -> 수주매출
            Database.executeBatch(new BizPlanCopyOppty_ba('수주', true, baseYear), 500);
        } catch(Exception e) { throw new AuraHandledException(e.getMessage()); }
    }
}