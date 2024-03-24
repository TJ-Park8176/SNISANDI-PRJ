/**
 * Created by MZC01-DGCHOI on 2023-03-02.
 */

public with sharing class Utilities {

    public static String formatZero(Integer input) {
        String formatString = String.valueOf(input);
        if(input<10) {
            formatString = formatString.leftPad(2, '0');
        }

        return formatString;
    }

    /**
     * @param objName
     *
     * @return Map<String, Id> RecordType Id 별 RecordType DeveloperName
     */
    public static Map<String, Id> getRecordTypeBySObject(String objName) {
        List<RecordType> rtList = [
                SELECT Id, DeveloperName
                FROM RecordType
                WHERE SobjectType = :objName
                AND IsActive = TRUE
        ];

        Map<String, Id> rtnMap = new Map<String, Id>();

        for(RecordType rt : rtList){
            rtnMap.put(rt.DeveloperName, rt.Id);
        }

        return rtnMap;
    }

    public static Map<Id, String> getRecordTypeDevNameBySObject(String objName) {
        List<RecordType> rtList = [
                SELECT Id, DeveloperName
                FROM RecordType
                WHERE SobjectType = :objName
                AND IsActive = TRUE
        ];

        Map<Id, String> rtnMap = new Map<Id, String>();

        for(RecordType rt : rtList){
            rtnMap.put(rt.Id, rt.DeveloperName);
        }

        return rtnMap;
    }

    /**
     * @param tmpDate
     *
     * @return YYMM
     */
    public static String formatYYMM(Date tmpDate) {
        return String.valueOf(tmpDate.year()).substring(2,4)
                + Utilities.formatZero(tmpDate.month());
    }

}