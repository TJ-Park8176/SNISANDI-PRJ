/**
 * @description       : NotificationSettings
 * Custom settings, Custom metadata 정보를 설정
 * @author            : sungho.jo@mz.co.kr
 * @group             : MegazoneCloud
 * @last modified on  : 2024-03-15
 * @last modified by  : sungho.jo@mz.co.kr
**/
public class NotificationSettings {
    /**
    * @description Notification_Master__c
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    private static NotificationSettings instance;

    /**
    * @description NotificationApiInformation
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    private NotificationApiInformation apiInfo;

    /**
    * @description NotificationApiEndpoint key [id]
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    private Map<String, NotificationApiEndpoint> apiEnpoint = new Map<String, NotificationApiEndpoint>();
    
    /**
    * @description NotificationFieldInformation key [object + type]
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    private Map<String, NotificationFieldInformation> fieldInformations = new Map<String, NotificationFieldInformation>();

    /**
    * @description Class Mapping
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    private Map<String, String> mapRequestClass = new Map<String, String> {
        'EMAIL'   => 'NotificationEmailRequest'
        , 'KAKAO' => 'NotificationKakaoRequest'
        , 'SMS'   => 'NotificationSMSRequest'
    };

    /**
    * @description api id Mapping
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    private Map<String, String> apiTypeIds = new Map<string, String>{
        'EMAIL'   => 'sendEmail'
        , 'KAKAO' => 'sendKakao'
        , 'SMS'   => 'sendSMS'
    };
    
    private final String scheduleName = '[TMS] Notification send';

    /**
    * @description Http success code
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    private List<Integer> successCodes = new List<Integer> {
        200 // OK
        , 201 // Created
        , 202 // Accepted
    };

    /**
    * @description Noti전송 대상 체크가 켜져있으면 notificationTestContacts에 있는 연락처 정보만 발송되게 체크함
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    private Boolean isTestContactsCheck = false;
    /**
    * @description 테스트 대상 연락처 정보
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    private Set<String> notificationTestContacts = new Set<String>();

    /**
    * @description get Instance
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    * @return NotificationSettings 
    **/
    public static NotificationSettings getInstance(){
        if( instance == null ) {
            instance = new NotificationSettings();
        }
        return instance;
    }    
    
    /**
    * @description constructor
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    private NotificationSettings(){
        setApiInformation();
        setNotificationApiEndpoints();
        setNotificationFieldInformations();
        setTestContacts();
    }

    /**
    * @description 
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    private void setApiInformation(){
        this.apiInfo = new NotificationApiInformation();
    }

    /**
    * @description set NotificationApiEndpoints
    * Notification_API_Endpoint__mdt 정보를 통해 id 키로 map 설정
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    private void setNotificationApiEndpoints(){
        List<NotificationApiEndpoint> objs = new List<NotificationApiEndpoint>();
        for(Notification_API_Endpoint__mdt mdt : [SELECT ID, Id__c, Endpoint__c, Type__c, Method__c,Header__c,Content_Type__c FROM Notification_API_Endpoint__mdt]){
            objs.add(new NotificationApiEndpoint(mdt));
        }

        if(!objs.isEmpty()){
            for(NotificationApiEndpoint obj : objs){
                this.apiEnpoint.put(obj.id, obj);
            }
        }
    }

    /**
    * @description set NotificationFieldInformations
    * Notification_Email_Phone_Field_Info__mdt 정보를 통해 object + type 키로 map 설정
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    private void setNotificationFieldInformations(){
        List<NotificationFieldInformation> objs = new List<NotificationFieldInformation>();
        for(Notification_Email_Phone_Field_Info__mdt mdt : [SELECT ID, Type__c, Object__c, Field__c FROM Notification_Email_Phone_Field_Info__mdt]){
            objs.add(new NotificationFieldInformation(mdt));
        }
        if(!objs.isEmpty()){
            /**
             * type eg. EMAIL, Phone
             */
            for(NotificationFieldInformation obj : objs){
                this.fieldInformations.put(obj.objectApiName + '_' + obj.type , obj);
            }
        }
    }

    /**
    * @description Test Contacts 관련 설정
    * @author sungho.jo@mz.co.kr | 2024-03-14 
    **/
    private void setTestContacts(){
        Notification_Test_Contacts_Check__c orgDefault = Notification_Test_Contacts_Check__c.getOrgDefaults();
        if(orgDefault != null){
            this.isTestContactsCheck = orgDefault?.Is_Check__c;
        }
        for(Notification_Test_Contacts__mdt mdt : [SELECT 
                                                    value__c 
                                                   FROM Notification_Test_Contacts__mdt]){
            if(String.isNotEmpty(mdt.value__c)){ this.notificationTestContacts.add(mdt.value__c); }
        }
    }

    /**
    * @description get APiInformation
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    * @return NotificationApiInformation 
    **/
    public NotificationApiInformation getAPiInformation(){
        return this.apiInfo = new NotificationApiInformation();
    }
    
    /**
    * @description get NotificationApiEndpoint
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    * @param id : String if id
    * @return NotificationApiEndpoint 
    **/
    public NotificationApiEndpoint getNotificationApiEndpoint(String id){
        return this.apiEnpoint.containsKey(id) ? this.apiEnpoint.get(id) : null;
    }
    
    /**
    * @description get NotificationFieldInformation
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    * @param key : String objectAPiName + Type (EMAIL, PHONE)
    * @return NotificationFieldInformation 
    **/
    public NotificationFieldInformation getNotificationFieldInformation(String key){
        return this.fieldInformations.containsKey(key) ? this.fieldInformations.get(key) : null;
    }


    /**
    * @description getNotificationRequestClass
    * @author sungho.jo@mz.co.kr | 2024-03-10 
    * @param key : String eg.EMAIL, KAKAO, SMS
    * @return String 
    **/
    public String getNotificationRequestClass(String key){
        return this.mapRequestClass.containsKey(key) ? this.mapRequestClass.get(key) : 'NotificationRequest';
    }


    /**
    * @description api 정보를 가져옴
    * @author sungho.jo@mz.co.kr | 2024-03-13 
    * @param key : String
    * @return String 
    **/
    public String getApiId(String key){
        return this.apiTypeIds.containsKey(key) ? this.apiTypeIds.get(key) : '';
    }

    /**
    * @description 성공 코드가 맞는지 체크함
    * @author sungho.jo@mz.co.kr | 2024-03-13 
    * @param code : Integer
    * @return Boolean 
    **/
    public Boolean isSuccessCode(Integer code){
        return this.successCodes.contains(code);
    }

    /**
    * @description 스케쥴명을 가져옴
    * @author sungho.jo@mz.co.kr | 2024-03-13 
    * @return String 
    **/
    public String getScheduleName(){
        return this.scheduleName;
    }

    /**
    * @description Test Contacts Check 여부
    * @author sungho.jo@mz.co.kr | 2024-03-14 
    * @return Boolean 
    **/
    public Boolean isTestContactsCheck(){
        return this.isTestContactsCheck;
    }

    /**
    * @description Test Contacts에 포함되어있는지 여부
    * @author sungho.jo@mz.co.kr | 2024-03-14 
    * @param value 
    * @return Boolean 
    **/
    public Boolean isTestContacts(String value){
        return this.notificationTestContacts.contains(value);
    }
}