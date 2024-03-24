/**
 * @description       : Notificaion Send Flow Service
 * @author            : sungho.jo@mz.co.kr
 * @group             : MegazoneCloud
 * @last modified on  : 2024-03-15
 * @last modified by  : sungho.jo@mz.co.kr
**/
public with sharing class NotificaionSendFlowService {

    @InvocableMethod(label='Notification send flow service' description='')
    public static List<NotificationFlowService.NotificationFlowResult> sendNotification(List<NotificationFlowService.NotificationFlowRequest> requests){
        List<Notification> notis   = new List<Notification>();
        Map<String, Notification_Master__c> notiMasters = new Map<String, Notification_Master__c>();

        Set<String> templateCodes = new Set<String>();
        for(NotificationFlowService.NotificationFlowRequest request : requests){ templateCodes.add(request.templateCode); }
        // get Notification_Master__c
        notiMasters = new NotificationDataSetHandler().getNotificationMasters(templateCodes);        
        for(NotificationFlowService.NotificationFlowRequest request : requests){
            // build notification
            Map<String, Object> params = new Map<String, Object>{
                'attributes' => request?.attributes
                , 'buttons' => request?.buttons
                , 'etc' => request?.params
            };
            Notification notification = new NotificationBuilder()
                                        .master(notiMasters.get(request.templateCode))
                                        .recordId(request?.recordId)
                                        .users(new Map<String, List<String>>{   'to'=> request?.toUsers,    'cc' => request?.ccUsers,    'bcc' => request?.bccUsers})
                                        .accounts(new Map<String, List<String>>{'to'=> request?.toAccounts, 'cc' => request?.ccAccounts, 'bcc' => request?.bccAccounts})
                                        .contacts(new Map<String, List<String>>{'to'=> request?.toContacts, 'cc' => request?.ccContacts, 'bcc' => request?.bccContacts})
                                        .inputs(new Map<String, List<String>>{  'to'=> request?.toInputs,   'cc' => request?.ccInputs,   'bcc' => request?.bccInputs})
                                        .isManualAttr(request?.isManualAttr)
                                        .isManualButton(request?.isManualButton)
                                        .attachments(request?.attachments)
                                        .params(params)
                                        .build();
            notis.add(notification);
        }
        List<NotificationResponse> notificationResponse = NotificationSender.send(notis);
        return new List<NotificationFlowService.NotificationFlowResult>{new NotificationFlowService.NotificationFlowResult()};
    }
}