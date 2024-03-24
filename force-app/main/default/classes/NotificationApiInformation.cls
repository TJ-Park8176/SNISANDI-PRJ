/**
 * @description       : NotificationApiInformation (Notification_API_Information__c)
 * @author            : sungho.jo@mz.co.kr
 * @group             : MegazoneCloud
 * @last modified on  : 2024-03-14
 * @last modified by  : sungho.jo@mz.co.kr
**/
public class NotificationApiInformation {
    /**
    * @description api Key Attribute
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    public String apiKeyAttribute;
    /**
    * @description apiKey
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    public String apiKey;
    /**
    * @description url
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    public String url;

    /**
    * @description constructor 
    * Notification_API_Information__c custom settings를 통해 API Key 관리를 함.
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    public NotificationApiInformation(){
        Notification_API_Information__c info = Notification_API_Information__c.getOrgDefaults();
        this.apiKeyAttribute = info.API_Key_Attribute__c;
        this.apiKey          = info.API_Key__c;
        this.url             = info.url__c;
    }
}