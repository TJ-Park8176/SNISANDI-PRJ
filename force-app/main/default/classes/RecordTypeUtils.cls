// * @description       : RecordId를 변수로 사용하여 sObject를 동적으로 RecordTypeId를 가져 오도록 함 Flow호출용.
// * @author            : taejoon.park@origincs.com
// * @group             : OriginCS
// * @last modified on  : 2024-03-23
// * @last modified by  : taejoon.park@origincs.com

public class RecordTypeUtils {

    /**
     * 사용자 정의 예외 오류 처리.
     */
    private class RecordTypeUtilsException extends Exception {}

    /**
     * 레코드 ID에서 레코드 유형 ID를 가져오는 Method
     */
    @InvocableMethod(label='Get Record Type Id' description='RecordId 기준으로 RecordTypeId를 가져옴')
    public static List<Id> getRecordTypeIdFromRecordId(List<String> recordIds) {
        List<Id> recordTypeIds = new List<Id>();
        try {
            Map<Id, Id> recordIdToRecordTypeIdMap = createRecordIdToRecordTypeIdMap(recordIds);
            // 제공된 RecordId를 반복하고 해당 RecordTypeId를 목록에 추가.
            for (String recordId : recordIds) {
                recordTypeIds.add(recordIdToRecordTypeIdMap.get(recordId));
            }
        } catch (RecordTypeUtilsException e) {
            // Handle custom exception
            throw new FlowException('Error occurred: ' + e.getMessage());
        }
        return recordTypeIds;
    }

    /**
     * 레코드 유형 ID에 대한 레코드 ID 매핑을 생성하는 Method
     */
    private static Map<Id, Id> createRecordIdToRecordTypeIdMap(List<String> recordIds) {
        Set<String> sObjectTypeCheck = new Set<String>();
        Map<Id, Id> recordIdToRecordTypeIdMap = new Map<Id, Id>();
        String singleSObjectTypeFromList;

        for (String recordId : recordIds) {
            Id recId = (Id)recordId;
            String sObjectTypeFromId = String.valueOf(recId.getSObjectType());

            // 동적 SOQL을 위해 한 번에 하나의 sObject만 처리함.
            sObjectTypeCheck.add(sObjectTypeFromId);
            if (sObjectTypeCheck.size() > 1) {
                throw new RecordTypeUtilsException('이 동적 SOQL에 대해 둘 이상의 sObjectType을 가질 수 없습니다.');
            }
            singleSObjectTypeFromList = sObjectTypeFromId;
        }

        // Dynamic Soql to handle our dataset
        String queryString = 'SELECT RecordTypeId FROM ' + singleSObjectTypeFromList + ' WHERE Id IN :recordIds';
        try {
            List<SObject> records = Database.query(queryString);
            for (SObject dynamicSObj : records) {
                recordIdToRecordTypeIdMap.put((Id)dynamicSObj.get('Id'), (Id)dynamicSObj.get('RecordTypeId'));
            }
        } catch (Exception e) {            
            throw new RecordTypeUtilsException(e.getMessage());
        }

        return recordIdToRecordTypeIdMap;
    }

}