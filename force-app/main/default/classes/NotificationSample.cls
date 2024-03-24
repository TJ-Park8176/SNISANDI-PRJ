/**
 * @description       : Notification Sample - 현재 클래스는 코드 테스트용
 * @author            : sungho.jo@mz.co.kr
 * @group             : MegazoneCloud
 * @last modified on  : 2024-03-18
 * @last modified by  : sungho.jo@mz.co.kr
**/
public with sharing class NotificationSample {

    public static void run(){
        NotificationDataSetHandler handler = new NotificationDataSetHandler();

        List<Account> testAcc =  [SELECT Id FROM Account WHERE PersonEmail = 'sungho.jo@mz.co.kr'];
        Map<String, Notification_Master__c> notiMasters = handler.getNotificationMasters(new Set<String>{'T_0001','T_0002'});

        List<Notification> notifications = new List<Notification>();
        for (Notification_Master__c notificationMaster : notiMasters.values()){
            /**
             * NotificationBuilder set method desc 
             * 
             * ** [user, account, contact, inputs 중 하나는 필수] **
             * .master(Notification_Master__c notificationMaster) : Notification_Master__c sObject 필수
             * .title(String title)                               : kakao title or email subject 값을 따로 설정하지 않을 경우 master의 title__c 값으로 설정
             * .recordId(String recordId)                         : 레코드 기반으로 데이터 설정시 필수
             * .users(New Map<String, List<String>())             : user 수신자 설정     [eg.  .users(new Map<String, List<String>>{'to' => new List<String>{'0051y00000OzJKAAA3'}}) ]
             * .accounts(new Map<String, List<String>())          : account 수신자 설정  [eg.  .accounts(new Map<String, List<String>>{'to' => new List<String>{'0051y00000OzJKAAA3'}}) ]
             * .contacts(new Map<String, List<String>())          : contact 수신자 설정  [eg.  .contacts(new Map<String, List<String>>{'to' => new List<String>{'0051y00000OzJKAAA3'}}) ]
             * .inputs(new Map<String, List<String>())            : 별도 입력받은 수신자로 설정   [eg.  .inputs(new Map<String, List<String>>{'to' => new List<String>{'01065597859'}}) ]
             * .isManualAttr(Boolean isManualAttr)                : *Attribute 설정을 코드로 따로 작업할 경우 [필수]
             * .attributes(new List<NotificationAttribute>())     : *Attribute 설정을 코드로 따로 작업할 경우 [필수] [eg. .attributes(new List<NotificationAttribute>{new NotificationAttribute('name', 'Sungho')})]
             * .isManualButton(Boolean)                           : *Button 설정을 코드로 따로 작업할 경우 [필수] 
             * .buttons(new List<NotificationButton>())           : *Button 설정을 코드로 따로 작업할 경우 [필수] [eg. .buttons(new List<NotificationButton>())]
             * .attachments(new List<String>())                   : ContentVersion Id 또는 ContentDocument Id를 List로 설정
             * .params(Object obj)                                : 각 노티별로 추가 파라미터를 통해 작업할 내용이 있으면 해당 method를 통해 params에 할당
             * .build()                                           : return Notification()
             */
            List<String> attachments = new List<String>();
            
            // 레코드 하나로 설정이 가능할 경우 아래 정보로만 생성해도 OK
            Notification notification = new NotificationBuilder()
                                            .master(notificationMaster)
                                            .title(notificationMaster.Title__c)
                                            .recordId(testAcc[0].Id)
                                            .users(new Map<String, List<String>>{'to'=>new List<String>{'0051y00000OzJKAAA3'}})
                                            .accounts(new Map<String, List<String>>{'to'=>new List<String>{testAcc[0].Id}})
                                            .contacts(new Map<String, List<String>>{'to'=>new List<String>{'0031y00000ccHiYAAU'}})
                                            .inputs(new Map<String, List<String>>{'to'=>new List<String>{'+821065597859'}})
                                            .attachments(attachments)
                                            .build();

            if('T_0002'.equals(notificationMaster.Template_Code__c)){
                // attributes, buttons, 별도 NotificationSetHandler가 필요할 경우 아래 정보로 설정
                // NotificationSetHandler로 설정할 경우 params만 설정해서 handler에서 처리해도 무관하나,
                // handler에서 추가 쿼리하는 방향이 아닌 쿼리한 데이터를 맞춰서 보내주는 식으로 개발해야함
                List<NotificationAttribute> attributes = new List<NotificationAttribute>();
                List<NotificationButton> buttons       = new List<NotificationButton>();

                Map<String, Object> params = new Map<String, Object>{
                    'attributes' => new List<String>{'Sungho', 'King'}
                    ,'etc' => new List<String>{'Hello world'}
                };
                // attributes, buttons, params를 선택해서 보냄
                // params는 각 노티별 NotificationSetHandler 확장 클래스에서 추가 작업하기 위한 파라미터를 넘김
                
                // attribute eg.
                attributes.add(new NotificationAttribute('name', 'Sungho'));
                attributes.add(new NotificationAttribute('rank', 'King'));
                // button은 확정은 아님
                buttons.add(new NotificationButton('1', 'https://google.com'));
                buttons.add(new NotificationButton('2', 'https://naver.com'));

                // 값 할당
                notification.setIsManualAttr(true);
                notification.setIsManualButton(true);
                notification.setAttributes(attributes);
                notification.setButtons(buttons);
                notification.setParams(params);
            }
            
            notifications.add(notification);
        }
        /**
         * NotificationSender.send(List<Notification>) : Notification 목록을 전송
         * governor limit을 고려해서 위에서 설정해야함.
         * send class에서 object 별로 쿼리함
         * NotificationResponse는 전송한 Notification 건 별로 return
         */
        List<NotificationResponse> notificationResponse = NotificationSender.send(notifications);
        System.debug('#NotificationSample.run notificationResponse : ' + JSON.serialize(notificationResponse));
    }


    /**
    * @description 
    * @author sungho.jo@mz.co.kr | 2024-03-15 
    * @param templateCode :String MHSMS_T01, MHEMAIL_T01
    * @param recordId :Id Notification_Master__c Id
    **/
    public static void realRun(String templateCode, Id recordId){
        NotificationDataSetHandler handler = new NotificationDataSetHandler();
        String sObjectName = recordId.getSObjectType().getDescribe().getName();

        List<sObject> getObjs = Database.query('SELECT ID FROM ' + sObjectName + ' WHERE Id=:recordId');
        Map<String, Notification_Master__c> notiMasters = handler.getNotificationMasters(new Set<String>{templateCode});
        Notification_Master__c notiMaster = notiMasters.get(templateCode);
        Notification notification = new NotificationBuilder()
        .master(notiMaster)
        //.title(notificationMaster.Title__c)
        .recordId((String)getObjs[0].get('Id'))
        //.users(new Map<String, List<String>>{'to'=>new List<String>{'0051y00000OzJKAAA3'}})
        //.accounts(new Map<String, List<String>>{'to'=>new List<String>{testAcc[0].Id}})
        //.contacts(new Map<String, List<String>>{'to'=>new List<String>{'0031y00000ccHiYAAU'}})
        .inputs(new Map<String, List<String>>{'to'=>new List<String>{ 'EMAIL'.equals(notiMaster.Type__c)  ? 'sungho.jo@mz.co.kr' : '+821065597859'}})
        //.attachments(attachments)
        .build();
        List<NotificationResponse> notificationResponse = NotificationSender.send(new List<Notification>{notification});
        System.debug('#NotificationSample.run notificationResponse : ' + JSON.serialize(notificationResponse));

    }
}