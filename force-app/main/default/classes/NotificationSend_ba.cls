/**
 * @description       : NotificationSend_ba
 * @author            : sungho.jo@mz.co.kr
 * @group             : MegazoneCloud
 * @last modified on  : 2024-03-18
 * @last modified by  : sungho.jo@mz.co.kr
**/
public class NotificationSend_ba implements Database.Batchable<sObject> 
                                     , Database.AllowsCallouts
                                     , Database.Stateful{
    /**
    * @description notification settings 
    * @author sungho.jo@mz.co.kr | 2024-03-08 
    **/
    private final static  NotificationSettings SETTINGS = NotificationSettings.getInstance();
    private final String SCHEDULE_NAME = SETTINGS.getScheduleName();
    /**
    * @description 
    * @author sungho.jo@mz.co.kr | 2024-03-12 
    * @param bc 
    * @return Database.QueryLocator 
    **/
    public Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator([SELECT ID 
                                            , Notification_Master__c
                                            , Notification_Master__r.Template_Code__c
                                            , Title__c
                                            , To__c
                                            , TraceId__c
                                            , Result__c
                                            , Result_Message__c
                                            , Attachments__c
                                            , Buttons__c
                                            , Attributes__c
                                            , Type__c 
                                            , Request_JSON__c 
                                            FROM Notification_History__c 
                                            WHERE Result__c = 'B' 
                                            ORDER BY CreatedDate ASC]);
        }
        
    /**
    * @description 
    * @author sungho.jo@mz.co.kr | 2024-03-12 
    * @param bc 
    * @param scope 
    **/
    public void execute(Database.BatchableContext bc, List<Notification_History__c> scope){
        Map<String, String> mapTraceIdJson = new Map<String, String>();
        Map<String, List<Notification_History__c>> mapTraceIdHis = new Map<String, List<Notification_History__c>>();
        List<Notification_History__c> listUpdateHis = new List<Notification_History__c>();

        for(Notification_History__c history : scope){
            // 중복 발신을 막기 위해 traceId기준으로 map 할당
            mapTraceIdJson.put(history.TraceId__c, history.Request_JSON__c);
            // history의 결과를 업데이트 하기 위해 map에 할당
            List<Notification_History__c> getHis = mapTraceIdHis.containsKey(history.TraceId__c) ? mapTraceIdHis.get(history.TraceId__c) : new List<Notification_History__c>();
            getHis.add(history);
            mapTraceIdHis.put(history.TraceId__c, getHis);
        }

        for(String key : mapTraceIdJson.keySet()) {
            List<Notification_History__c> getHis = mapTraceIdHis.get(key);
            String reqJson = mapTraceIdJson.get(key);
            NotificationRequest notiRequest;
            switch on getHis[0].Type__c {
                when 'EMAIL'{
                    notiRequest = (NotificationEmailRequest) JSON.deserialize(reqJson, NotificationEmailRequest.class);
                }
                when 'KAKAO'{
                    notiRequest = (NotificationKakaoRequest) JSON.deserialize(reqJson, NotificationKakaoRequest.class);
                }
                when 'SMS'{
                    notiRequest = (NotificationSMSRequest) JSON.deserialize(reqJson, NotificationSMSRequest.class);
                }
            }
            NotificationResponse notiResponse = NotificationSender.callout(notiRequest, getHis[0].Type__c);

            for(Notification_History__c his : getHis) {
                his.Result__c           = 'S'.equals(notiResponse?.resultCode) ? 'SD' : 'F';
                his.Result_Message__c   = notiResponse?.resultMsg;
                his.TraceId__c          = notiResponse?.traceId;    
                listUpdateHis.add(his);
            }
        }
        if( !listUpdateHis.isEmpty() ) { Update listUpdateHis; }
    }

    /**
    * @description finish 5분후 배치 재실행
    * @author sungho.jo@mz.co.kr | 2024-03-12 
    * @param bc 
    **/
    public void finish(Database.BatchableContext bc){
        List<CronTrigger> crons = [SELECT ID FROM CronTrigger WHERE CronJobDetail.Name =:this.SCHEDULE_NAME];
        if(!Test.isRunningTest() && crons.isEmpty()) {
            System.scheduleBatch(new NotificationSend_ba(), SCHEDULE_NAME, 5, 100);
        }        
    }
}