/**
 * Created by MZC01-DGCHOI on 2023-02-20.
 */

public with sharing class ct_OpptyPerformanceCopy {

    @AuraEnabled
    public static void copyObject(String targetAPIKey) {
        try {
            Database.executeBatch(new OpptyPerformanceCopy_ba(targetAPIKey), 2000);
        } catch(Exception e) { throw new AuraHandledException(e.getMessage()); }
    }

}