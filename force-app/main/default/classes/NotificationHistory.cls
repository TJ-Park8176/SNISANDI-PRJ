/**
 * @description       : NotificationHistory
 * @author            : sungho.jo@mz.co.kr
 * @group             : MegazoneCloud
 * @last modified on  : 2024-03-18
 * @last modified by  : sungho.jo@mz.co.kr
**/
public with sharing class NotificationHistory {
    /**
    * @description notification settings 
    * @author sungho.jo@mz.co.kr | 2024-03-08 
    **/
    private static final NotificationSettings SETTINGS  = NotificationSettings.getInstance();

    /**
    * @description history를 해당 LIST에 담아둔 후 추후 insert 처리 
    * @author sungho.jo@mz.co.kr | 2024-03-08 
    **/
    private static List<Notification_History__c> historys = new List<Notification_History__c>();

    /**
    * @description 
    * @author sungho.jo@mz.co.kr | 2024-03-11 
    * @param settings 
    * @param notification 
    * @param notificationRequest 
    * @param notificationResponse 
    * @param mapSobj 
    * @return List<Notification_History__c> 
    **/
    public static void createHistory(Notification notiObj
                            , NotificationRequest notiRequest
                            , NotificationResponse notiResponse
                            , Map<Id, sObject> mapSobj){

        Boolean isEmail          = ('EMAIL'.equals(notiObj.type)); 
        String contactValueField = isEmail ? 'Email__c' : 'Phone__c';
        String fieldInfoType     = contactValueField.replaceAll('__c', '').toUpperCase();

        // 공통 history 정보
        Notification_History__c commonHis = new Notification_History__c();
        commonHis.Type__c = notiObj?.type;
        // request value
        commonHis.Body__c = notiObj?.body;
        commonHis.Request_JSON__c = notiRequest.toJSON();
        // attribute 정보
        if(NotificationUtil.isNotEmpty(notiRequest.attributes)){
            commonHis.Attributes__c = JSON.serialize(notiRequest.attributes);
        }
        // attachment 정보
        // if(NotificationUtil.isNotEmpty(notiRequest.attachments)){
        //     commonHis.Attachments__c = JSON.serialize(notiRequest.attachments);
        // }
        // button 정보
        // if(NotificationUtil.isNotEmpty(notiRequest.buttons)){
        //     commonHis.Buttons__c = JSON.serialize(notiRequest.buttons);
        // }
        commonHis.Notification_Master__c = notiObj?.master?.Id;
        commonHis.RecordId__c            = notiObj?.recordId;
        commonHis.Title__c               = notiObj?.title;
        commonHis.To__c                  = JSON.serialize(notiRequest?.to);
        // response value
        if(notiResponse == null){
            commonHis.Result__c              = 'B';
        } else {
            commonHis.Result__c              = 'S'.equals(notiResponse?.resultCode) ? 'SD' : 'F';
            // commonHis.Result_Message__c      = notiResponse?.resultMsg;
            commonHis.TraceId__c             = notiResponse?.traceId;
        }
        
        //if('F'.equals(commonHis.Result__c)){ commonHis.Failed_Json__c = notiRequest.toJSON(); }
        /**
         * accounts로 넣은 경우   Account__c
         * contacts로 넣을 경우 Account__c, Contact__c
         * users로 넣을 경우      User__c, Contact__c, Account__c
         */
        // users
        if(!notiObj.users.isEmpty()){
            String objContactField = SETTINGS.getNotificationFieldInformation('User' + '_' + fieldInfoType).field;
            for(List<String> userIds : notiObj.users.values()){
                addHistory(objContactField
                , userIds
                , commonHis
                , mapSobj
                , new List<String>{'ContactId', 'Contact.AccountId'}
                , new List<String>{'Contact__c', 'Account__c'}
                , 'User__c'
                , contactValueField);
            }
        }
        // accounts
        if(!notiObj.accounts.isEmpty()){
            String objContactField = SETTINGS.getNotificationFieldInformation('Account' + '_' + fieldInfoType).field;
            for(List<String> accountIds : notiObj.accounts.values()){
                addHistory(objContactField
                , accountIds
                , commonHis
                , mapSobj
                , new List<String>()
                , new List<String>()
                , 'Account__c'
                , contactValueField);
            }
        }
        // contacts
        if(!notiObj.contacts.isEmpty()){
            String objContactField = SETTINGS.getNotificationFieldInformation('Contact' + '_' + fieldInfoType).field;
            for(List<String> contactIds : notiObj.contacts.values()){
                addHistory(objContactField
                                    , contactIds
                                    , commonHis
                                    , mapSobj
                                    , new List<String>{'AccountId'}
                                    , new List<String>{'Account__c'}
                                    , 'Contact__c'
                                    , contactValueField);
            }
        }
        // inputs
        if(!notiObj.inputs.isEmpty()){
            for(List<String> inputs : notiObj.inputs.values()) {
                for(String input : inputs){
                    Notification_History__c history = copyHistory(commonHis);
                    history.put(contactValueField, input);
                    NotificationHistory.historys.add(history);
                }                
            }
        }
    }

    /**
    * @description 공통으로 생성한 history객체를 copy
    * @author sungho.jo@mz.co.kr | 2024-03-12 
    * @param commonHis : Notification_History__c
    * @return Notification_History__c 
    **/
    private static Notification_History__c copyHistory(Notification_History__c commonHis){
        return (Notification_History__c) JSON.deserialize(JSON.serialize(commonHis), Notification_History__c.class);
    }

    /**
    * @description 
    * @author sungho.jo@mz.co.kr | 2024-03-12 
    * @param objContactField : String 연락처 필드명
    * @param objs : List<String> 대상 object list
    * @param commonHis Notification_History__c 공통으로 만든 history
    * @param mapSobj  Map<Id, sObject>
    * @param fields List<String> 가져올 값들
    * @param objInputFields List<String> objInputFields 가져온 값을 넣을 필드
    * @param defaultField : default로 넣을 필드
    **/
    private static void addHistory(String objContactField
                                    , List<String> objs
                                    , Notification_History__c commonHis
                                    , Map<Id, sObject> mapSobj
                                    , List<String> fields
                                    , List<String> objInputFields
                                    , String defaultField
                                    , String contactValueField){
            for(String objStr : objs){
                Notification_History__c history = copyHistory(commonHis);
                history.put(defaultField, objStr);
                if(mapSobj.containsKey(objStr)){
                    Map<String, Object> mapJson = NotificationUtil.convertJsonObjToMap(mapSobj.get(objStr));
                    for(Integer i=0; i < fields.size(); i++){
                        String objValue = NotificationUtil.getValue(fields[i].split('\\.'), mapJson);
                        if(String.isNotBlank(objValue)){
                            history.put(objInputFields[i], objValue);
                        }
                    }
    
                    String contactValue = NotificationUtil.getValue(objContactField.split('\\.'), mapJson);
                    history.put(contactValueField, contactValue);
                }
                NotificationHistory.historys.add(history);
        }
    }
    /**
    * @description insert history
    * @author sungho.jo@mz.co.kr | 2024-03-11 
    **/
    public static void insertHistory(){
        if(!NotificationHistory.historys.isEmpty()){ insertFailHistory(Database.insert(NotificationHistory.historys, false)); }
        NotificationHistory.historys = new List<Notification_History__c>();
    }

    /**
    * @description history 생성 실패시 실패한 내용을 생성함
    * @author sungho.jo@mz.co.kr | 2024-03-14 
    * @param srList 
    **/
    private static void insertFailHistory(Database.SaveResult[] srList){
        try{
            List<Notification_History__c> insertFailedHistorys = new List<Notification_History__c>();
            for(integer i = 0; i < srList.size(); i++){
                Database.SaveResult sr = srList[i];
                if(!sr.isSuccess()){
                    Notification_History__c failedHis = NotificationHistory.historys[i];
                    List<FailDesc> filDescs = setFailDescs(sr.getErrors());
                    insertFailedHistorys.add(new Notification_History__c(
                        Notification_Master__c = failedHis.Notification_Master__c
                        , Failed_Json__c = JSON.serialize(failedHis)
                        , Result__c = 'IFAIL'
                        , Result_Message__c = JSON.serialize(filDescs)
                    ));
                }
            }
            if(!insertFailedHistorys.isEmpty()){ INSERT insertFailedHistorys; }
        }catch(Exception e){
            // history 생성 실패 내역 자체가 혹시라도 실패할 경우 그냥 패스함.
            System.debug('#NotificationHistory.insertFailHistory Exception (none tracking) :' + e.getMessage());
        }
    }

    /**
    * @description FailDesc 생성
    * @author sungho.jo@mz.co.kr | 2024-03-14 
    * @param errs : Database.Error[]
    * @return List<FailDesc> 
    **/
    private static List<FailDesc> setFailDescs(Database.Error[] errs){
        List<FailDesc> result = new List<FailDesc>();
        for(Database.Error err : errs) { result.add(new FailDesc(err)); }
        return result;
    }

    /**
    * @description FailDesc history 생성 실패 class
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    private class FailDesc{
        /**
        * @description status Code
        * @author sungho.jo@mz.co.kr | 2024-03-07 
        **/
        private String statusCode;
        /**
        * @description message : error
        * @author sungho.jo@mz.co.kr | 2024-03-07 
        **/
        private String message;
        /**
        * @description fields : error field
        * @author sungho.jo@mz.co.kr | 2024-03-07 
        **/
        private String fields;

        public FailDesc(Database.Error err){
            this.statusCode = String.valueOf(err.getStatusCode());
            this.message    = err.getMessage();
            this.fields     = JSON.serialize(err.getFields());
        }
    }
}