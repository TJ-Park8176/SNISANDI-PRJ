/**
 * @description       : NotificationSender
 * @author            : sungho.jo@dkbmc.com
 * @group             : MegazoneCloud
 * @last modified on  : 2024-03-19
 * @last modified by  : sungho.jo@mz.co.kr
**/
public without sharing class NotificationSender {
    /**
    * @description notification settings 
    * @author sungho.jo@mz.co.kr | 2024-03-08 
    **/
    private final static NotificationSettings SETTINGS  = NotificationSettings.getInstance();

    public class NotificationSenderException extends Exception{}

    /**
    * @description send 
    * @author sungho.jo@mz.co.kr | 2024-03-08 
    * @param notis : List<Notification>
    * @return List<NotificationResponse> 
    **/
    public static List<NotificationResponse> send(List<Notification> notis){
        List<NotificationResponse> result  = new List<NotificationResponse>();
        NotificationDataSetHandler handler = new NotificationDataSetHandler();
        Map<Id, sObject> mapSobj = handler.getSobjectDatas(notis);
        
        for( Notification notiObj : notis){
            // manual로 attribute설정이 아닐 경우 notification의 recordId로 attribute 설정
            if(!notiObj.isManualAttr){
                sObject sObj = mapSobj.containsKey(notiObj.recordId) ? mapSobj.get(notiObj.recordId) : null;
                handler.setNotificationAttributeValue(notiObj.recordId, notiObj.attributes, sObj);
            }

            if(String.isNotBlank(notiObj.master.Set_Handler_Class__c)){
                NotificationSetHandler setHandler = (NotificationSetHandler) Type.forName(notiObj.master.Set_Handler_Class__c.trim()).newInstance();
                setHandler.setNotification(notiObj);
            }
            if(String.isNotBlank(notiObj.body)){ handler.setNotificationBody(notiObj); }
            System.debug('#NotificationSender.send notification.toJSON() : ' + notiObj.toJSON());
            NotificationRequest notiRequest = getNotificationRequestClass(notiObj.type).convert(notiObj, mapSobj);
            System.debug('#NotificationSender.send notificationRequest.toJSON() : ' + notiRequest.toJSON());
            NotificationResponse notiResponse = callout(notiRequest, notiObj.type);
            System.debug('#NotificationSender.send notiResponse : ' + JSON.serialize(notiResponse));
            result.add(notiResponse);
            NotificationHistory.createHistory(notiObj, notiRequest, notiResponse, mapSobj);
        }
        NotificationHistory.insertHistory();
        return result;
    }

    /**
    * @description batch를 통해 전송할 경우 notification history 생성후 배치를 통해 전송함
    * @author sungho.jo@mz.co.kr | 2024-03-12 
    * @param notis : List<Notification>
    **/
    public static void batch(List<Notification> notis){
        NotificationDataSetHandler handler = new NotificationDataSetHandler();
        Map<Id, sObject> mapSobj = handler.getSobjectDatas(notis);
        for( Notification notiObj : notis){
            // manual로 attribute설정이 아닐 경우 notification의 recordId로 attribute 설정
            if(!notiObj.isManualAttr){
                sObject sObj = mapSobj.containsKey(notiObj.recordId) ? mapSobj.get(notiObj.recordId) : null;
                handler.setNotificationAttributeValue(notiObj.recordId, notiObj.attributes, sObj);
            }
            if(String.isNotBlank(notiObj.master.Set_Handler_Class__c)){
                NotificationSetHandler setHandler = (NotificationSetHandler) Type.forName(notiObj.master.Set_Handler_Class__c.trim()).newInstance();
                setHandler.setNotification(notiObj);
            }
            if(String.isNotBlank(notiObj.body)){ handler.setNotificationBody(notiObj); }
            System.debug('#NotificationSender.send notification.toJSON() : ' + notiObj.toJSON());
            NotificationRequest notiRequest = getNotificationRequestClass(notiObj.type).convert(notiObj, mapSobj);
            System.debug('#NotificationSender.send notificationRequest.toJSON() : ' + notiRequest.toJSON());
            NotificationHistory.createHistory(notiObj, notiRequest, null, mapSobj);
        }
        NotificationHistory.insertHistory();
        executeBa();
    }

    public static void executeBa(){
        List<AsyncApexJob> asnycObjs = [SELECT Id, Status
                                        FROM AsyncApexJob 
                                        WHERE ApexClass.Name = 'NotificationSend_ba' 
                                        AND Status IN ('Holding', 'Preparing', 'Processing', 'Queued')];
        // NotificationSend_ba 배치가 실행중이 아닐 경우 enqueueJob
        if(!Test.isRunningTest() && asnycObjs.isEmpty()) { Database.executeBatch(new NotificationSend_ba(), 100); }
    }

    /**
    * @description 클래스 설정
    * @author sungho.jo@mz.co.kr | 2024-03-11 
    * @param notificationType 
    * @return NotificationRequest 
    **/
    private static NotificationRequest getNotificationRequestClass(String notiType){
        return (NotificationRequest) Type.forName(SETTINGS.getNotificationRequestClass(notiType)).newInstance();
    }

    private final static string Boundary = '----7MA4YWxkTrZu0gW';

    /**
    * @description callout
    * @author sungho.jo@mz.co.kr | 2024-03-11 
    * @param notiRequest  : NotificationRequest
    * @return HttpResponse 
    **/
    public static NotificationResponse callout(NotificationRequest notiRequest, String type){
        NotificationResponse result = new NotificationResponse();

        NotificationApiEndpoint apiEndPoint = SETTINGS.getNotificationApiEndpoint(SETTINGS.getApiId(type));
        NotificationApiInformation apiInformation = SETTINGS.getAPiInformation();

        HttpRequest httpRequest   = new HttpRequest();
        HttpResponse httpResponse = new HttpResponse();

        try{
            Http http = new Http();
            httpRequest.setEndpoint(apiInformation.url + apiEndPoint.endpoint);
            httpRequest.setMethod(apiEndPoint.method);
            httpRequest.setTimeout(120000);
            // Settings headers
            if('multipart/form-data'.equals(apiEndPoint.contentType)){
                httpRequest.setHeader('Content-type', apiEndPoint.contentType + '; boundary="' + Boundary + '"');
            } else {
                httpRequest.setHeader('Content-type', apiEndPoint.contentType);
            }

            if(String.isNotBlank(apiEndPoint.headers)){
                Map<String, Object> mapHeader = (Map<String, Object>) JSON.deserializeUntyped(apiEndPoint.headers);
                for(String key : mapHeader.keySet()){
                    httpRequest.setHeader(key, (String) mapHeader.get(key));
                }
            }
            // Settings body
            if('multipart/form-data'.equals(apiEndPoint.contentType)){
                Map<String, Object> mapJson = (Map<String, Object>) JSON.deserializeUntyped(notiRequest.toJson());
                // file 추가후 삭제 처리
                // mapJson.remove('attachments');
                // TMS 제한이 전문 1mb로 인하여 file은 sfdc 기본 기능으로 대체.
                // multipart/form-data로 보내는 형식은 유지
                String convertForm = EncodingUtil.base64Encode(
                    Blob.valueOf('----' + Boundary + '\r\n'
                               + 'Content-Disposition: form-data; name="requestJson"\r\n\r\n'
                               + JSON.serialize(mapJson) + '\r\n'
                               + '----' + Boundary + '--')
                );
                blob formBlob = EncodingUtil.base64Decode(convertForm);
                httpRequest.setHeader('Content-Length', string.valueOf(formBlob.size()));
                httpRequest.setBodyAsBlob(formBlob);
            } else {
                httpRequest.setBody(notiRequest.toJson());
            }
            
            httpResponse = http.send(httpRequest);
            if(SETTINGS.isSuccessCode(httpResponse.getStatusCode()) ) {
                result.setSuccessResult(httpResponse);
            } else {
                result.setErrorResult('Fail', null); 
            }
        }catch(Exception e){
            result.setErrorResult('Fail', e); 
        }
        return result;
    }
}