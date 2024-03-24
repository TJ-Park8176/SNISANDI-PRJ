/**
 * @description       : NotificationRequest
 * @author            : sungho.jo@mz.co.kr
 * @group             : MegazoneCloud
 * @last modified on  : 2024-03-18
 * @last modified by  : sungho.jo@mz.co.kr
 * 
 * To-do
 * 2024-03-07 api 정의서에 맞게 수정, 아직 정의서 받지 못함.
**/
public virtual with sharing class NotificationRequest {
    private final static NotificationSettings SETTINGS = NotificationSettings.getInstance();

    /**
     * 공통 변수
     */
    /**
    * @description template code
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    public String channel; // eg. sms, email

    /**
    * @description template code
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    public String templateCode;

    /**
    * @description to
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    public List<String> to;

    /**
    * @description attributes
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    public Map<String, String> attributes;

    public notificationRequest(){}

    /**
    * @description 현재 클래스명 가져오기
    * @author sungho.jo@mz.co.kr | 2024-03-10 
    * @return String 
    **/
    public String getClassName() {
        return String.valueOf(this).substring(0,String.valueOf(this).indexOf(':'));
    }

    /**
    * @description JSON으로 변환 , null값 제외
    * @author sungho.jo@mz.co.kr | 2024-03-10 
    * @return String 
    **/
    public String toJSON(){
        return JSON.serialize(this,true);
    }

    /**
    * @description Type별로 extend한 클래스에서 convert 재정의
    * @author sungho.jo@mz.co.kr | 2024-03-10 
    * @return NotificationRequest 
    **/
    public virtual NotificationRequest convert(Notification notification, Map<Id, sObject> mapSobj){
        return null;
    }


    /**
    * @description Notification의 users, accounts, contacts로 데이터 설정
    * @author sungho.jo@mz.co.kr | 2024-03-11 
    * @param values : Map<String, List<String>> Notification users, accounts, contacts values
    * @param target : String to, cc ..
    * @param targets : List<String> Request value to, cc, ..
    * @param objectApiName : String Account, Contact, User
    * @param mapSobj : Map<Id, sObject> map sObj 
    * @param settings : NotificationSettings
    * @param isEmail : Boolean 
    **/
    protected void setContactValues(Map<String, List<String>> values
                                  , String target
                                  , Set<String> targets
                                  , String objectApiName
                                  , Map<Id, sObject> mapSobj
                                  , Boolean isEmail){
        if(!values.isEmpty()){
            String fieldSuffix = isEmail ? '_EMAIL' : '_PHONE';
            List<String> targetValues = values.containsKey(target) ? values.get(target) : null;
            if(NotificationUtil.isNotEmpty(targetValues)) {
                for(String targetValue : targetValues){
                    String contactValue = '';
                    sObject sObj = mapSobj.containsKey(targetValue) ? mapSobj.get(targetValue) : null;
                    if(sObj != null){
                        contactValue = NotificationUtil.getValue(sObj, SETTINGS.getNotificationFieldInformation(objectApiName + fieldSuffix).field);
                    }
                    String validValue = validContact(contactValue);
                    if(String.isNotBlank(validValue)) { targets.add(validValue); }
                }
            }
        }
    }

    /**
    * @description Notification의 iuput로 데이터 설정
    * @author sungho.jo@mz.co.kr | 2024-03-11 
    * @param values : Map<String, List<String>> Notification inputs
    * @param target : String to, cc ..
    * @param targets : List<String> Request value to, cc, ..
    **/
    protected void setContactValuesByInputs(Map<String, List<String>> values
                                          , String target
                                          , Set<String> targets){
        if(!values.isEmpty()){
            List<String> targetValues = values.containsKey(target) ? values.get(target) : null;
            if(NotificationUtil.isNotEmpty(targetValues)) {
                for(String targetValue : targetValues){
                    String validValue = validContact(targetValue);
                    if(String.isNotBlank(validValue)) { targets.add(validValue); }
                }
            }
        }
    }

    /**
    * @description add attribute
    * @author sungho.jo@mz.co.kr | 2024-03-11 
    * @param attributes : List<NotificationAttribute>
    **/
    protected void addAttriubute(List<NotificationAttribute> attributes){
        for(NotificationAttribute attribute : attributes){
            this.attributes.put(attribute.attribute, attribute.value);
        }
    }

    /**
    * @description add button
    * @author sungho.jo@mz.co.kr | 2024-03-11 
    * @param buttons : List<NotificationButton>
    **/
    protected void addButton(List<NotificationButton> buttons){
        for(NotificationButton button : buttons){
            // this.buttons.add(new Map<String, String>{
            //     NotificationButton.attribute => NotificationButton.value
            // });
        }
    }

    /**
    * @description test check
    * @author sungho.jo@mz.co.kr | 2024-03-14 
    * @param val : String
    **/
    protected String validContact(String val){
        if(SETTINGS.isTestContactsCheck() && !SETTINGS.isTestContacts(val)) { return ''; }
        else { return val;}
    }
}