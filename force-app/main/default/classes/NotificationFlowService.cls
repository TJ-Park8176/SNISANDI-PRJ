/**
 * @description       : 
 * @author            : sungho.jo@mz.co.kr
 * @group             : 
 * @last modified on  : 2024-03-18
 * @last modified by  : sungho.jo@mz.co.kr
**/
public class NotificationFlowService {
    
    public static Map<String, List<Notification>> notis;
    
    static {
        NotificationFlowService.notis = new Map<String, List<Notification>>();
    }

    @InvocableMethod(label='Notification Flow service' description='')
    public static List<NotificationFlowResult> actionNotification(List<NotificationFlowRequest> requests){
        System.debug('#requests.size() : ' + requests.size());
        List<NotificationFlowResult> result = new List<NotificationFlowResult>{new NotificationFlowResult()};
        try{
            switch on requests[0].actionName {
                when 'add'{
                    addNotification(requests);
                }
                when 'startBatch'{
                    startBatch(requests);
                }
            }
        }catch(Exception e){

        }
        return result;
    }


    /**
    * @description NotificationFlowService.notis에 flowInterviewGuid 기준으로 put
    * @author sungho.jo@mz.co.kr | 2024-03-13 
    * @param notificationFlowAddRequests 
    **/
    private static void addNotification(List<NotificationFlowRequest> requests){
        List<Notification> notis   = new List<Notification>();
        Map<String, Notification_Master__c> notiMasters = new Map<String, Notification_Master__c>();

        Set<String> templateCodes = new Set<String>();
        for(NotificationFlowRequest request : requests){ templateCodes.add(request.templateCode); }
        // get Notification_Master__c
        notiMasters = new NotificationDataSetHandler().getNotificationMasters(templateCodes);        
        for(NotificationFlowRequest request : requests){
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
        //notisender.batch(notis);
        String flowInterviewGuid = requests[0].flowInterviewGuid;
        // static 변수인 NotificationFlowService.notis에 해당 guid에 대한 값이 추가되어있는지 확인
        List<Notification> getNotis = NotificationFlowService.notis.containsKey(flowInterviewGuid) 
                                      ? NotificationFlowService.notis.get(flowInterviewGuid)
                                      : new List<Notification>();
        getNotis.addAll(notis);
        NotificationFlowService.notis.put(requests[0].flowInterviewGuid, getNotis);
    }

    /**
    * @description batch 실행
    * @author sungho.jo@mz.co.kr | 2024-03-13 
    * @param requests : List<NotificationFlowRequest>
    **/
    private static void startBatch(List<NotificationFlowRequest> requests){
        String flowInterviewGuid = requests[0].flowInterviewGuid;
        // flowInterviewGuid로 목록이 있는지 체크 후 배치 실행 > key 제거
        if(NotificationFlowService.notis.containsKey(flowInterviewGuid)){
            NotificationSender.batch(NotificationFlowService.notis.get(flowInterviewGuid));
            NotificationFlowService.notis.remove(flowInterviewGuid);
        }
    }

    public class NotificationFlowRequest{    
        /**
        * @description Action name (eg.add, startBatch)
        * @author sungho.jo@mz.co.kr | 2024-03-07 
        **/
        @InvocableVariable(label='Action name' description='input send, add, startBatch'  required=true)
        public String actionName;

        /**
        * @description Flow Interview Guid
        * @author sungho.jo@mz.co.kr | 2024-03-07 
        **/
        @InvocableVariable(label='Flow interview guid' required=true)
        public String flowInterviewGuid;

        /**
        * @description Template Code
        * @author sungho.jo@mz.co.kr | 2024-03-07 
        **/
        @InvocableVariable(label='Template code' required=true)
        public String templateCode;

        /**
        * @description title
        * @author sungho.jo@mz.co.kr | 2024-03-07 
        **/
        @InvocableVariable(label='Title or Subject')
        public String title;

        /**
        * @description Record Id
        * @author sungho.jo@mz.co.kr | 2024-03-07 
        **/
        @InvocableVariable(label='Record id')
        public String recordId;

        /**
        * @description to Users
        * @author sungho.jo@mz.co.kr | 2024-03-07 
        **/
        @InvocableVariable(label='To Users')
        public List<String> toUsers = new List<String>();

        /**
        * @description to Accounts
        * @author sungho.jo@mz.co.kr | 2024-03-07 
        **/
        @InvocableVariable(label='To Accounts')
        public List<String> toAccounts = new List<String>();

        /**
        * @description to Contacts
        * @author sungho.jo@mz.co.kr | 2024-03-07 
        **/
        @InvocableVariable(label='To Contacts')
        public List<String> toContacts = new List<String>();

        /**
        * @description to Inputs
        * @author sungho.jo@mz.co.kr | 2024-03-07 
        **/
        @InvocableVariable(label='To Inputs')
        public List<String> toInputs = new List<String>();

        /**
        * @description cc Users
        * @author sungho.jo@mz.co.kr | 2024-03-07 
        **/
        @InvocableVariable(label='CC Users')
        public List<String> ccUsers = new List<String>();

        /**
        * @description cc Accounts
        * @author sungho.jo@mz.co.kr | 2024-03-07 
        **/
        @InvocableVariable(label='CC Accounts')
        public List<String> ccAccounts = new List<String>();

        /**
        * @description cc Contacts
        * @author sungho.jo@mz.co.kr | 2024-03-07 
        **/
        @InvocableVariable(label='CC Contacts')
        public List<String> ccContacts = new List<String>();

        /**
        * @description cc Inputs
        * @author sungho.jo@mz.co.kr | 2024-03-07 
        **/
        @InvocableVariable(label='CC Inputs')
        public List<String> ccInputs = new List<String>();

        /**
        * @description bcc Users
        * @author sungho.jo@mz.co.kr | 2024-03-07 
        **/
        @InvocableVariable(label='BCC Users')
        public List<String> bccUsers = new List<String>();

        /**
        * @description bcc Accounts
        * @author sungho.jo@mz.co.kr | 2024-03-07 
        **/
        @InvocableVariable(label='BCC Accounts')
        public List<String> bccAccounts = new List<String>();

        /**
        * @description bcc Contacts
        * @author sungho.jo@mz.co.kr | 2024-03-07 
        **/
        @InvocableVariable(label='BCC Contacts')
        public List<String> bccContacts = new List<String>();

        /**
        * @description bcc Inputs
        * @author sungho.jo@mz.co.kr | 2024-03-07 
        **/
        @InvocableVariable(label='BCC Inputs')
        public List<String> bccInputs = new List<String>();

        /**
        * @description is manual attr
        * @author sungho.jo@mz.co.kr | 2024-03-07 
        **/
        @InvocableVariable(label='Is manual attribute')
        public Boolean isManualAttr = false;

        /**
        * @description attributes
        * @author sungho.jo@mz.co.kr | 2024-03-07 
        **/
        @InvocableVariable(label='Attributes')
        public List<String> attributes = new List<String>();

        /**
        * @description Is Manual button
        * @author sungho.jo@mz.co.kr | 2024-03-07 
        **/
        @InvocableVariable(label='Is manual button')
        public Boolean isManualButton = false;

        /**
        * @description Buttons
        * @author sungho.jo@mz.co.kr | 2024-03-07 
        **/
        @InvocableVariable(label='Buttons')
        public List<String> buttons = new List<String>();

        /**
        * @description Attachements
        * @author sungho.jo@mz.co.kr | 2024-03-07 
        **/
        @InvocableVariable(label='Attachments')
        public List<String> attachments = new List<String>();
        /**
        * @description add-on param
        * @author sungho.jo@mz.co.kr | 2024-03-07 
        **/
        @InvocableVariable(label='Params')
        public List<String> params;
    }

    public class NotificationFlowResult{
        /**
        * @description Result (eg. true, false)
        * @author sungho.jo@mz.co.kr | 2024-03-07 
        **/
        @InvocableVariable(label='Result' description='Boolean True, False')
        public Boolean result;
        /**
        * @description Result message 
        * @author sungho.jo@mz.co.kr | 2024-03-07 
        **/
        @InvocableVariable(label='Result message')
        public String resultMessage;

        public NotificationFlowResult(){
            this.result = true;
        }

        public void setErrorResult(String message){
            this.result        = false;
            this.resultMessage = message;
        }
    }
}