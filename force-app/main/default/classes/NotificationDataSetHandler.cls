/**
 * @description       : NotificationDataSetHandler
 * Override하여 정의할 수 있도록 virtual로 작성
 * @author            : sungho.jo@mz.co.kr
 * @group             : MegazoneCloud
 * @last modified on  : 2024-03-14
 * @last modified by  : sungho.jo@mz.co.kr
**/
public with sharing class NotificationDataSetHandler {
    /**
    * @description notification settings 
    * @author sungho.jo@mz.co.kr | 2024-03-08 
    **/
    private static final NotificationSettings SETTINGS = NotificationSettings.getInstance();
    /**
    * @description 연락처 필드 유형 
    * @author sungho.jo@mz.co.kr | 2024-03-08 
    **/
    private final List<String> CONTACT_FIELDS = new List<String>{'EMAIL', 'PHONE'};
    /**
    * @description Object 별 default 필드
    * @author sungho.jo@mz.co.kr | 2024-03-08 
    **/
    private final Map<String, Set<String>> DEFAULT_FIELDS = new Map<String, Set<String>>{
        'User' => new Set<String>{'ContactId', 'Contact.AccountId'}
        , 'Contact' => new Set<String>{'AccountId'}
    };

    /**
    * @description 
    * @author sungho.jo@mz.co.kr | 2024-03-08 
    * @param templateCodes : Set<String>
    * @return List<Notification_Master__c> 
    **/
    public Map<String, Notification_Master__c> getNotificationMasters(Set<String> templateCodes){
        Map<String, Notification_Master__c> result = new Map<String, Notification_Master__c>();
        List<Notification_Master__c> objs = [SELECT Id
                , Name
                , Template_Code__c
                , Body__c
                , Title__c
                , Type__c
                , Object__c
                , IsActive__c
                , Set_Handler_Class__c
                , (SELECT Id
                    , Notification_Master__c
                    , Attribute__c
                    , Field__c
                    , Data_Type__c
                    , Date_Format__c
                    FROM Notification_Attribute__r)
                , (SELECT ID
                    , Notification_Master__c
                    , Field__c
                    FROM Notification_Button__r) 
                FROM Notification_Master__c  
                WHERE Template_Code__c IN:templateCodes
                AND IsActive__c = true];
        
        if(!objs.isEmpty()) {
            for(Notification_Master__c obj : objs){
                result.put(obj.Template_Code__c , obj);
            }
        }
        return result;
    }

    /**
    * @description 
    * @author sungho.jo@mz.co.kr | 2024-03-08 
    * @param notis : List<Notification>
    * @return Map<Id, sObject> 
    **/
    public Map<Id, sObject> getSobjectDatas(List<Notification> notis){
        Map<Id, sObject> result = new Map<Id, sObject>(); // Id기준으로 오브젝트 데이터를 담아서 리턴함
        
        Map<String, Set<String>> mapIds    = new Map<String, Set<String>>(); // Object 별 Id를 담아둠
        Map<String, Set<String>> mapFields = new Map<String, Set<String>>(); // Object 별 조회 필드를 담아둠
        List<sObject> listObjs             = new List<sObject>();            // 전체 lsit data를 담아둠
        // 노티리스트 Start -
        for(Notification notiObj : notis){
            // 노티 데이터 관련
            // 오브젝트 별 레코드 아이디 설정
            if(String.isNotBlank(notiObj.recordId)) {
                Set<String> getIds = (mapIds.containsKey(notiObj.objectApiName)) ? mapIds.get(notiObj.objectApiName) : new Set<String>();
                getIds.add(notiObj.recordId);
                mapIds.put(notiObj.objectApiName, getIds);
            }
            // 오브젝트 별 조회 필드 설정
            if(!notiObj.isManualAttr && (notiObj.attributes != null && !notiObj.attributes.isEmpty())){    
                Set<String> getFields = (mapFields.containsKey(notiObj.objectApiName)) ? mapFields.get(notiObj.objectApiName) : new Set<String>();
                for(NotificationAttribute attribute : notiObj.attributes){
                    String field = attribute.field;
                    if('picklist'.equals(attribute.dataType)) {
                        field = 'toLabel(' + attribute.field + ')';
                    }
                    getFields.add(field);
                }
                mapFields.put(notiObj.objectApiName, getFields);
            }
            // to, cc 데이터 관련
            // Account 레코드 관련
            putMapIds(mapIds, notiObj.accounts.values(), 'Account');
            // Contact 레코드 관련
            putMapIds(mapIds, notiObj.contacts.values(), 'Contact');
            // User 레코드 관련
            putMapIds(mapIds, notiObj.users.values()   , 'User');
        }
        // Account, Contact, User 연락처 관련 필드 추가
        putMapFields(mapFields, 'Account');
        putMapFields(mapFields, 'Contact');
        putMapFields(mapFields, 'User');
        if(!mapIds.isEmpty()){
            // 여러 템플릿 코드 기반으로 한번에 호출하게는 하였으나
            // 쿼리 제한 및 callout limit이 있을 수 있기 때문에 나눠서 보내는걸로 가이드 필요. -
            // api가 다건 전송이 가능할지 의문.. 타 회사 솔루션의 경우 모두 단건이였음
            for(String objectApiName : mapIds.keySet()) {
                Set<String> ids = mapIds.get(objectApiName); 
                Set<String> fields = (mapFields.containsKey(objectApiName)) ? mapFields.get(objectApiName) : new Set<String>();
                listObjs.addAll(getDatas(objectApiName, fields, ids));
            }
            // 조회한 Object 데이터를 result에 넣어줌
            for( sObject sObj : listObjs){
                result.put((Id)sObj.get('Id'), sObj);
            }
        }
        return result;
    }


    /**
    * @description NotificationAttribute의 value를 레코드 데이터 기반으로 설정함
    * @author sungho.jo@mz.co.kr | 2024-03-08 
    * @param recordId : String Notification.recordId
    * @param attributes : List<NotificationAttribute> Notification.attributes
    * @param sObj : sObject 관련 레코드 정보 
    **/
    public void setNotificationAttributeValue(String recordId, List<NotificationAttribute> attributes, sObject sObj){
        if(sobj != null){
            Map<String, Object> mapJson =  NotificationUtil.convertJsonObjToMap(sObj);
            for(NotificationAttribute attribute : attributes){
                List<String> splitFieldNames = attribute.field.split('\\.');
                attribute.value = NotificationUtil.getValue(splitFieldNames, mapJson);
            }
        }
    }


    /**
    * @description 
    * @author sungho.jo@mz.co.kr | 2024-03-11 
    * @param recordId : String Notification.recordId
    * @param buttons  : List<NotificationButton> Notification.buttons
    * @param sObj : sObject 관련 레코드 정보
    **/
    public void setNotificationButtonValue(String recordId, List<NotificationButton> buttons, sObject sObj){
        if(sobj != null){
            Map<String, Object> mapJson = NotificationUtil.convertJsonObjToMap(sObj);
            for(NotificationButton button : buttons){
                List<String> splitFieldNames = button.field.split('\\.');
                button.value = NotificationUtil.getValue(splitFieldNames, mapJson);
            }
        }
    }

    /**
    * @description Body의 변수의 값을 할당함
    * @author sungho.jo@mz.co.kr | 2024-03-08 
    * @param notification 
    **/
    public void setNotificationBody(Notification notiObj){
        if(notiObj.attributes != null && !notiObj.attributes.isEmpty()){
            for(NotificationAttribute attribute : notiObj.attributes){
                if(String.isNotBlank(attribute.value)){
                    // To-do data type 치환 필요.
                    notiObj.body = notiObj.body.replaceAll('#\\{' + attribute.attribute + '\\}' , attribute.value);
                }
            }
        }
    }

    /**
    * @description getSobjectDatas method의 mapIds 변수에 데이터 추가 할당
    * @author sungho.jo@mz.co.kr | 2024-03-08 
    * @param mapIds : Map<String, Set<String>>
    * @param objIds : List<List<String>>
    * @param objectApiName : String
    **/
    private void putMapIds(Map<String, Set<String>> mapIds, List<List<String>> objIds, String objectApiName){
        if(NotificationUtil.isNotEmpty(objIds)){
            for(List<String> listObjId : objIds){
                Set<String> getObjIds = (mapIds.containsKey(objectApiName)) ? mapIds.get(objectApiName) : new Set<String>();
                getObjIds.addAll(new Set<String>(listObjId));
                mapIds.put(objectApiName , getObjIds);
            }
        }
    }

    /**
    * @description getSobjectDatas method의 mapFields 변수에 데이터 추가 할당
    * @author sungho.jo@mz.co.kr | 2024-03-08 
    * @param mapFields : Map<String, Set<String>>
    * @param objectApiName : String
    **/
    private void putMapFields(Map<String, Set<String>> mapFields, String objectApiName){
        Set<String> fields = mapFields.containsKey(objectApiName) ? mapFields.get(objectApiName) : new Set<String>();
        Set<String> getDefaultFields = DEFAULT_FIELDS.containsKey(objectApiName) ? DEFAULT_FIELDS.get(objectApiName) : new Set<String>();
        fields.addAll(getContactFields(objectApiName));
        if(!getDefaultFields.isEmpty()) {
            fields.addAll(getDefaultFields);
        }
        mapFields.put(objectApiName, fields);
    }

    /**
    * @description 연락처 관련 필드를 가져온다
    * @author sungho.jo@mz.co.kr | 2024-03-08 
    * @param type : String (eg. User, Contact, Account)
    * @return Set<String> 
    **/
    private Set<String> getContactFields(String type){
        Set<String> result = new Set<String>();
        // 연락처 정보 필드 가져오기
        for(String contactField : CONTACT_FIELDS){
            //NotificationSettings의 정의된 NotificationFieldInformation 정보를 type + 필드로 가져옴
            NotificationFieldInformation fieldInfo = SETTINGS.getNotificationFieldInformation(type + '_' + contactField);
            if(fieldInfo != null){
                result.add(fieldInfo.field);
            }
        }
        return result;
    }

    /**
    * @description Data query
    * @author sungho.jo@mz.co.kr | 2024-03-08 
    * @param objectApiName : String
    * @param fields : Set<String>
    * @param ids : Set<String>
    * @return List<sObject> 
    **/
    private List<sObject> getDatas(String objectApiName, Set<String> fields, Set<String> ids){
        // id는 디폴트로 넣어줌
        fields.add('Id');
        return Database.query('SELECT ' + String.join(new List<String>(fields), ',') + ' FROM ' + objectApiName+ ' WHERE ID IN:ids');
    }
}