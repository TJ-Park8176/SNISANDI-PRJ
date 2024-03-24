/**
 * @description       : NotificationApiEndpoint (Notification_API_Endpoint__mdt)
 * @author            : sungho.jo@mz.co.kr
 * @group             : MegazoneCloud
 * @last modified on  : 2024-03-15
 * @last modified by  : sungho.jo@mz.co.kr
**/
public class NotificationApiEndpoint {
    /**
    * @description api id
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    public String id;
    /**
    * @description endpoint
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    public String endpoint;
    /**
    * @description type
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    public String type;
    /**
    * @description method
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    public String method;
    /**
    * @description headers
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    public String headers;
    /**
    * @description Content_Type__c
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    public String contentType;
    /**
    * @description constructor 
    * Notification_API_Endpoint__mdt metadata 정보로 설정
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    public NotificationApiEndpoint(Notification_API_Endpoint__mdt mdt) {
        this.id       = mdt?.Id__c;
        this.endpoint = mdt?.Endpoint__c;
        this.type     = mdt?.Type__c;
        this.method   = mdt?.Method__c;
        this.headers  = mdt?.Header__c;
        this.contentType = mdt?.Content_Type__c;
    }
}