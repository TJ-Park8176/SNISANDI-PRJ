/**
 * @description       : Notification 
 * @author            : sungho.jo@mz.co.kr
 * @group             : MegazoneCloud
 * @last modified on  : 2024-03-15
 * @last modified by  : sungho.jo@mz.co.kr
**/
public with sharing class Notification {
    /**
    * @description Notification_Master__c
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    public Notification_Master__c master;

    /**
    * @description template code
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    public String templateCode;

    /**
    * @description master에 등록된 object__c 값
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    public String objectApiName;

    /**
    * @description type (eg. EMAIL OR KAKAO OR SMS)
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    public String type;

    /**
    * @description title (eg. email subject OR Kakao, SMS title)
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    public String title;

    /**
    * @description send body
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    public String body;

    /**
    * @description using record
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    public String recordId;

    /**
    * @description manual attribute, default false
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    public Boolean isManualAttr;

    /**
    * @description manual button, default false
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    public Boolean isManualButton;
    
    /**
    * @description email from address
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    public String fromAddress;
    /**
    * @description email from name
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    public String fromName;

    /**
    * @description to, email, cc by account
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    public Map<String, List<String>> accounts;

    /**
    * @description to, email, cc by contact
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    public Map<String, List<String>> contacts;

    /**
    * @description to, email, cc by user
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    public Map<String, List<String>> users;

    /**
    * @description to, email, cc by input value
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    public Map<String, List<String>> inputs;

    /**
    * @description send attribute
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    public List<NotificationAttribute> attributes;

    /**
    * @description send attribute
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    public List<String> attachments;

    /**
    * @description send button
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    public List<NotificationButton> buttons;

    /**
    * @description add-on parameter
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    public Object params;

    /**
    * @description constructor
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    public Notification(Notification_Master__c master
                        , String title
                        , String recordId
                        , Boolean isManualAttr
                        , Boolean isManualButton
                        , String fromAddress
                        , String fromName
                        , Map<String, List<String>> accounts
                        , Map<String, List<String>> contacts
                        , Map<String, List<String>> users
                        , Map<String, List<String>> inputs
                        , List<NotificationAttribute> attributes
                        , List<String> attachments
                        , List<NotificationButton> buttons
                        , Object params) {
        this.master        = master;                            
        this.templateCode  = master?.Template_Code__c;
        this.objectApiName = master?.Object__c;
        this.type          = master?.Type__c;
        this.title         = title;
        this.body          = master?.Body__c;
        this.recordId      = recordId       != null ? recordId      : null;
        this.isManualAttr  = isManualAttr   != null ? isManualAttr  : false;
        this.isManualButton= isManualButton != null ? isManualButton: false; 
        this.fromAddress   = fromAddress;
        this.fromName      = fromName;
        this.accounts      = accounts       != null ? accounts      : new Map<String, List<String>>();
        this.contacts      = contacts       != null ? contacts      : new Map<String, List<String>>();
        this.users         = users          != null ? users         : new Map<String, List<String>>();
        this.inputs        = inputs         != null ? inputs        : new Map<String, List<String>>();
        this.attributes    = attributes     != null ? attributes    : new List<NotificationAttribute>();
        this.attachments   = attachments    != null ? attachments   : new List<String>();
        this.buttons       = buttons        != null ? buttons       : new List<NotificationButton>();
        this.params        = params;
    }

    /**
    * @description Set recordId
    * @author sungho.jo@mz.co.kr | 2024-03-13 
    * @param recordId 
    **/
    public void setRecordId(String recordId){
        this.recordId = recordId;
    }

    /**
    * @description Set isManualAttr
    * @author sungho.jo@mz.co.kr | 2024-03-13 
    * @param isManualAttr 
    **/
    public void setIsManualAttr(Boolean isManualAttr){
        this.isManualAttr = isManualAttr;
    }

    /**
    * @description Set isManualButton
    * @author sungho.jo@mz.co.kr | 2024-03-13 
    * @param isManualButton 
    **/
    public void setIsManualButton(Boolean isManualButton){
        this.isManualButton = isManualButton;
    }

    /**
    * @description Set attributes
    * @author sungho.jo@mz.co.kr | 2024-03-13 
    * @param attributes 
    **/
    public void setAttributes(List<NotificationAttribute> attributes){
        this.attributes = attributes;
    }

    /**
    * @description Set Buttons
    * @author sungho.jo@mz.co.kr | 2024-03-13 
    * @param buttons 
    **/
    public void setButtons(List<NotificationButton> buttons){
        this.buttons = buttons;
    }

    /**
    * @description Set Params
    * @author sungho.jo@mz.co.kr | 2024-03-13 
    * @param params 
    **/
    public void setParams(Object params){
        this.params = params;
    }

    /** JSON Serialize
    * @description 
    * @author sungho.jo@mz.co.kr | 2024-03-13 
    * @return String 
    **/
    public String toJSON(){
        return JSON.serialize(this, true);
    }
}