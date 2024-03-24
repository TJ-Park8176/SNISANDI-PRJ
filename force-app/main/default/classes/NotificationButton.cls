/**
 * @description       : 
 * @author            : sungho.jo@mz.co.kr
 * @group             : 
 * @last modified on  : 2024-03-14
 * @last modified by  : sungho.jo@mz.co.kr
**/
public with sharing class NotificationButton {
    /**
    * @description Notification_Master__c id
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    public String notificationMaster;
    /**
    * @description Field api name
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    public String field;
    /**
    * @description attribute value
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    public String value;

    public NotificationButton(Notification_Button__c obj) {
        this.notificationMaster = obj?.Notification_Master__c;
        this.field              = obj?.Field__c;
    }
    public NotificationButton(Notification_Button__c obj, String val) {
        this.notificationMaster = obj?.Notification_Master__c;
        this.field              = obj?.Field__c;
        this.value              = val;
    }

    public NotificationButton(String target, String val) {
        this.field              = target;
        this.value              = val;
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