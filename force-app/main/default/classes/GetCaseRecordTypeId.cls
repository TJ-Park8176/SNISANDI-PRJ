// * @description       : DeveloperName를 변수로 사용하여 Case 기준으로 RecordTypeId를 가져 오도록 함 Flow호출용.
// * @author            : taejoon.park@origincs.com
// * @group             : OriginCS
// * @last modified on  : 2024-03-23
// * @last modified by  : taejoon.park@origincs.com

public class GetCaseRecordTypeId {
    
// 이 메소드는 DeveloperName을 기반으로 Case RecordType Id를 검색합니다.
@InvocableMethod(label='Get Case RecordType ID' description='Retrieve Case RecordType Id based on sObjectType and DeveloperName')
    public static List<String> getCaseRecordTypeId(List<String> developerNames) {
        List<String> caseRecordTypeIds = new List<String>();
        
// developerNames 리스트를 순회하면서 각 DeveloperName에 대한 RecordType Id를 가져옵니다.
for (Integer i = 0; i < developerNames.size(); i++) {
     // developerNames 리스트가 null이 아니고 비어있지 않은 경우에만 처리합니다.
     if (developerNames != null && !developerNames.isEmpty()) {
        if (Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().containsKey(developerNames[0])) {
           Id caseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(developerNames[0]).getRecordTypeId();
              caseRecordTypeIds.add(caseRecordTypeId);
                }
            }
        }

        return caseRecordTypeIds;
    }
}