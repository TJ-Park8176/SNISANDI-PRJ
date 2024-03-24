// * @description       : RecordId를 변수로 사용하여 sObject를 동적으로 RecordTypeId를 가져 오도록 함 Flow호출용.
// * @author            : taejoon.park@origincs.com
// * @group             : OriginCS
// * @last modified on  : 2024-03-22
// * @last modified by  : taejoon.park@origincs.com

//Schema 사용법을 배워야함. ??? 

public with sharing class GetRecordTypeID {

// Flow에서 호출 가능한 Apex 코드를 생성하는데 동적 sObject의 RecordId 변수를 사용하고 RecordTypeId 를 반환 함
    
    // Flow에서 호출 가능한 메서드
    @InvocableMethod
    
    
    public static List<String> getRecordTypeIds(List<String> recordIds) {
        List<String> recordTypeIds = new List<String>();
        
        // 전달된 RecordId 목록을 반복
        for(Id recordId : recordIds) {
            // RecordId를 사용하여 RecordType을 조회
            Schema.SObjectType objectType = recordId.getSObjectType();
            Schema.DescribeSObjectResult objectDescribe = objectType.getDescribe();

            //String recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosById().get(recordId).getRecordTypeId();

            Map<Id,Schema.RecordTypeInfo> recordTypeInfo = objectDescribe.getRecordTypeInfosById();
            //List<Schema.RecordTypeInfo> recordTypeInfo = objectDescribe.getRecordTypeInfos();                        
            //List<Schema.RecordTypeInfo> recordTypeInfo = recordId.getSObjectType().getDescribe().getRecordTypeInfos();
            //RecordType rt = [SELECT Id,Name FROM RecordType WHERE SobjectType='Account' LIMIT 1];
            //Schema.DescribeSObjectResult d = Schema.SObjectType.objectType(); 
            //Map<Id,Schema.RecordTypeInfo> rtMapById = d.getRecordTypeInfosById();
            //Schema.RecordTypeInfo rtById =  rtMapById.get(recordId);
            //Map<String,Schema.RecordTypeInfo> rtMapByName = d.getRecordTypeInfosByName();
            //Schema.RecordTypeInfo rtByName =  rtMapByName.get(rt.name);
            //System.assertEquals(rtById);

            
            // RecordType의 Id를 목록에 추가.
            if(recordTypeInfo != null) {
                recordTypeIds.add(recordTypeInfo.get(recordId).getRecordTypeId());
            } else {
                // If no records found, add null to the list
                recordTypeIds.add('123456789');
            }
    
        }        
        return recordTypeIds;
    }
}