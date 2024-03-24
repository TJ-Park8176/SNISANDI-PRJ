/**
 * @description       : NotificationAttribute
 * @author            : sungho.jo@mz.co.kr
 * @group             : MegazoneCloud
 * @last modified on  : 2024-03-14
 * @last modified by  : sungho.jo@mz.co.kr
**/
public with sharing class NotificationAttribute {
    /**
    * @description Notification_Master__c id
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    public String notificationMaster;
    /**
    * @description Attrbute key
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    public String attribute;
    /**
    * @description Field api name
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    public String field;
    /**
    * @description field datatype (eg. string, date, datetime, number)
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    public String dataType;
    /**
    * @description date , datetiem format
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    public String dateFormat;
    /**
    * @description attribute value
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    public String value;

    public NotificationAttribute(Notification_Attribute__c obj) {
        this.notificationMaster = obj?.Notification_Master__c;
        this.attribute          = obj?.Attribute__c;
        this.field              = obj?.Field__c;
        this.dataType           = obj?.Data_Type__c;
        this.dateFormat         = obj?.Date_Format__c;
    }

    public NotificationAttribute(Notification_Attribute__c obj, String val) {
        this.notificationMaster = obj?.Notification_Master__c;
        this.attribute          = obj?.Attribute__c;
        this.field              = obj?.Field__c;
        this.dataType           = obj?.Data_Type__c;
        this.dateFormat         = obj?.Date_Format__c;
        this.value              = val;
    }

    public NotificationAttribute(String attribute, String val){
        this.attribute = attribute;
        this.value     = val;
    }

    /**
    * @description set value
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    * @param value 
    **/
    public void setAttriubuteValue(String val){
        this.value =  val;
    }
}