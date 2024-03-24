/**
 * Created by MZC01-DGCHOI on 2023-03-07.
 */

public with sharing class SniDaily_sc implements Schedulable {

    /*
        매일 00시에 실행되는 스케줄
        1. 배부비
        2-1. 마감개체 복제
            a. 마감개체 - 수주
            b. 마감개체 - 수주매출
            c. 마감필드 - 아이템관리
        2-2. 주간예상 복제
            a. 매출 -> 매입 -> 손익 -> 수주 -> 수주매출
            (매출/매입은 최근데이터여부Check -> 레코드 복제 -> 주간예상 더미데이터 생성)
            (손익/수주/수주매출은 최근데이터여부 Check -> 레코드 복제)
            b. 수주 상태 변경 (신규 -> 진행중)
        2-3. 실행계획 복제
            a. 매출 -> 매입 -> 손익 -> 수주 -> 수주매출
            (매출/매입은 최근데이터여부 Check -> 레코드 복제 -> 신규 WBS 더미데이터 생성)
            (손익/수주/수주매출은 최근데이터여부 Check -> 레코드 복제)

       Test Code : CalcDistribRate_Batch_Test
     */

    public void execute(SchedulableContext context) {
        /* Daily 간접비 배부 로직 - 주석 해제해야함
        CalcDistribRate_Batch batch = new CalcDistribRate_Batch();
        Database.executeBatch(batch, 10);
        */

        Database.executeBatch(new ClosingObjectCopy_ba('Opportunity'), 2000);
    }
}