/**
 * Created by MZC01-DGCHOI on 2023-03-07.
 */

public with sharing class SniYearly_sc implements Schedulable {
    /*
        매년 마지막날 XX시에 실행되는 스케줄
        1. 매출(사업계획/실행계획) dummy 생성
        2. 매입(사업계획/실행계획) dummy 생성

        Test Code : InitialShell_ba_Test
     */

    public void execute(SchedulableContext context) {
        //매출-매입-수주-수주매출 더미 생성
        InitialShellAmount_ba batch = new InitialShellAmount_ba();
        Database.executeBatch(batch, 9);

        //실적 배부비율 더미 생성
        Database.executeBatch(new InitialShellDistributeRate_ba(), 100);
    }
}