/**
 * @description       : NotificationFieldInformation (Notification_Email_Phone_Field_Info__mdt)
 * @author            : sungho.jo@mz.co.kr
 * @group             : MegazoneCloud
 * @last modified on  : 2024-03-14
 * @last modified by  : sungho.jo@mz.co.kr
**/
public class NotificationFieldInformation {
    /**
    * @description type (eg. EMAIL, PHONE)
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    public String type;
    /**
    * @description object api name
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    public String objectApiName;
    /**
    * @description field api name
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    public String field;

    /**
    * @description constructor 
    * Notification_Email_Phone_Field_Info__mdt custom metadata를 통해 이메일, 전화번호가 오브젝트의 어떤 필드인지 관리함.
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    public NotificationFieldInformation(Notification_Email_Phone_Field_Info__mdt mdt) {
        this.type          = mdt.Type__c;
        this.objectApiName = mdt.Object__c;
        this.field         = mdt.Field__c;
    }
}