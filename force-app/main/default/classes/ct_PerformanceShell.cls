/**
 * Created by MZC01-DGCHOI on 2023-02-24.
 */

public with sharing class ct_PerformanceShell {

    @AuraEnabled
    public static void createObject() {
        try {
            Database.executeBatch(new InitialShellPerformance_ba(0), 1);
        } catch(Exception e) { throw new AuraHandledException(e.getMessage()); }
    }

}