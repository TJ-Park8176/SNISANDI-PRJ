/**
 * @description       : NotificationBuilder
 * @author            : sungho.jo@mz.co.kr
 * @group             : MegazoneCloud
 * @last modified on  : 2024-03-15
 * @last modified by  : sungho.jo@mz.co.kr
**/
public with sharing class NotificationBuilder {
    /**
    * @description Notification_Master__c
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    private Notification_Master__c master;

    /**
    * @description title (eg. email subject OR Kakao, SMS title)
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    private String title;

    /**
    * @description send body
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    private String recordId;

    /**
    * @description manual attribute, default false
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    private Boolean isManualAttr = false;

    /**
    * @description manual attribute, default false
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    private Boolean isManualButton = false;

    /**
    * @description email from address
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    private String fromAddress;
    /**
    * @description email from name
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    private String fromName;

    /**
    * @description to, email, cc by account
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    private Map<String, List<String>> accounts;

    /**
    * @description to, email, cc by contact
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    private Map<String, List<String>> contacts;

    /**
    * @description to, email, cc by user
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    private Map<String, List<String>> users;

    /**
    * @description to, email, cc by input value
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    private Map<String, List<String>> inputs;

    /**
    * @description send attribute
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    private List<NotificationAttribute> attributes;
    
    /**
    * @description send attribute
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    private List<String> attachments;

    /**
    * @description send button
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    private List<NotificationButton> buttons;

    /**
    * @description add-on parameter
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    private Object params;

    public NotificationBuilder(){
        this.accounts   = new Map<String, List<String>>();
        this.contacts   = new Map<String, List<String>>();
        this.users      = new Map<String, List<String>>();
        this.inputs     = new Map<String, List<String>>();
        this.attributes = new List<NotificationAttribute>();
        this.attachments= new List<String>();
        this.buttons    = new List<NotificationButton>();
    }

    /**
    * @description set master
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    * @param master : Notification_Master__c
    * @return NotificationBuilder 
    **/
    public NotificationBuilder master(Notification_Master__c master){
        this.master = master;
        if( master.Notification_Attribute__r != null && !master.Notification_Attribute__r.isEmpty() ) {
            for(Notification_Attribute__c obj : master.Notification_Attribute__r ){
                this.attributes.add(new NotificationAttribute(obj));
            }
        }
        if( master.Notification_Button__r != null && !master.Notification_Button__r.isEmpty() ) {
            for(Notification_Button__c obj : master.Notification_Button__r ){
                this.buttons.add(new NotificationButton(obj));
            }
        }
        return this;
    }

    /**
    * @description set title
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    * @param title : String
    * @return NotificationBuilder 
    **/
    public NotificationBuilder title(String title){
        this.title = title;
        return this;
    }

    /**
    * @description set recordId
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    * @param recordId : String
    * @return NotificationBuilder 
    **/
    public NotificationBuilder recordId(String recordId){
        this.recordId = recordId;
        return this;
    }

    /**
    * @description set isManualAttr
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    * @param isManualAttr : Boolean
    * @return NotificationBuilder 
    **/
    public NotificationBuilder isManualAttr(Boolean isManualAttr){
        this.isManualAttr = isManualAttr;
        return this;
    }

    /**
    * @description set isManualButton
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    * @param isManualAttr : Boolean
    * @return NotificationBuilder 
    **/
    public NotificationBuilder isManualButton(Boolean isManualButton){
        this.isManualButton = isManualButton;
        return this;
    }

    /**
    * @description set fromAddress
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    * @param fromAddress : String
    * @return NotificationBuilder 
    **/
    public NotificationBuilder fromAddress(String fromAddress){
        this.fromAddress = fromAddress;
        return this;
    }
    
    /**
    * @description set fromAddress
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    * @param fromAddress : String
    * @return NotificationBuilder 
    **/
    public NotificationBuilder fromName(String fromName){
        this.fromName = fromName;
        return this;
    }

    /**
    * @description set accounts
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    * @param accounts : Map<String, List<User>>
    * @return NotificationBuilder 
    **/
    public NotificationBuilder accounts(Map<String, List<String>> accounts){
        this.accounts = accounts;
        return this;
    }

    /**
    * @description set contacts
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    * @param contacts : Map<String, List<User>>
    * @return NotificationBuilder 
    **/
    public NotificationBuilder contacts(Map<String, List<String>> contacts){
        this.contacts = contacts;
        return this;
    }

    /**
    * @description set users
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    * @param users : Map<String, List<User>>
    * @return NotificationBuilder 
    **/
    public NotificationBuilder users(Map<String, List<String>> users){
        this.users = users;
        return this;
    }

    /**
    * @description set inputs , 별도 입력받은 연락처 정보
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    * @param users : Map<String, List<User>>
    * @return NotificationBuilder 
    **/
    public NotificationBuilder inputs(Map<String, List<String>> inputs){
        this.inputs = inputs;
        return this;
    }
    
    /**
    * @description set attributes - value를 따로 설정할 경우 해당 method를 통해 설정
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    * @param attributes : List<NotificationAttribute>
    * @return NotificationBuilder 
    **/
    public NotificationBuilder attributes(List<NotificationAttribute> attributes){
        this.attributes = attributes;
        return this;
    }

        /**
    * @description set attachments
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    * @param attachments : List<String>
    * @return NotificationBuilder 
    **/
    public NotificationBuilder attachments(List<String> attachments){
        this.attachments = attachments;
        return this;
    }

    /**
    * @description set buttons
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    * @param attachments : List<String>
    * @return NotificationBuilder 
    **/
    public NotificationBuilder buttons(List<NotificationButton> buttons){
        this.buttons = buttons;
        return this;
    }

    /**
    * @description set params
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    * @param attachments : List<String>
    * @return NotificationBuilder 
    **/
    public NotificationBuilder params(Object params){
        this.params = params;
        return this;
    }

    /**
    * @description Notification Build 
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    * @return Notification 
    **/
    public Notification build(){
        return new Notification(this?.master
                                // 직접 설정한 title이 있을 경우 해당 값, 없으면 master의 title__c 값으로 설정
                                , (String.isNotBlank(this.title)) ? this.title : this?.master?.title__c 
                                , this?.recordId
                                , this?.isManualAttr
                                , this?.isManualButton
                                , this?.fromAddress
                                , this?.fromName
                                , this?.accounts
                                , this?.contacts
                                , this?.users
                                , this?.inputs
                                , this?.attributes
                                , this?.attachments
                                , this?.buttons
                                , this?.params);
    }
}