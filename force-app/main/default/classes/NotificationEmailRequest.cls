/**
 * @description       : NotificationEmailRequest
 * @author            : sungho.jo@mz.co.kr
 * @group             : MegazoneCloud
 * @last modified on  : 2024-03-18
 * @last modified by  : sungho.jo@mz.co.kr
**/
public class NotificationEmailRequest extends NotificationRequest {
    /**
    * @description from Address
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    public String fromAddress;

    /**
    * @description from Name
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    public String fromName;

    /**
    * @description attachments
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    public List<String> attachments;

    public override NotificationRequest convert(Notification notification, Map<Id, sObject> mapSobj){
        this.channel      = notification.type.toLowerCase();
        this.templateCode = notification.templateCode;
        // 입력값 혹은 실행한 유저 기준
        this.fromAddress  = String.isNotBlank(notification.fromAddress) ? notification.fromAddress : UserInfo.getUserEmail();
        this.fromName     = String.isNotBlank(notification.fromName)    ? notification.fromName    : UserInfo.getLastName();
        // Boolean isToValue     = (notification.users.containsKey('to')  || notification.contacts.containsKey('to')  || notification.inputs.containsKey('to'));
        // Boolean isCCValue     = (notification.users.containsKey('cc')  || notification.contacts.containsKey('cc')  || notification.inputs.containsKey('cc'));
        // Boolean isBCCValue    = (notification.users.containsKey('bcc') || notification.contacts.containsKey('bcc') || notification.inputs.containsKey('bcc'));
        Boolean isAttrValue   = NotificationUtil.isNotEmpty(notification.attributes);
        Boolean isButtonValue = NotificationUtil.isNotEmpty(notification.buttons);
        Set<String> toSets = new Set<String>();
        Set<String> ccSets = new Set<String>();
        Set<String> bccSets = new Set<String>();

        // Settings Contact parameter by users
        setContactValues(notification.users, 'to', toSets, 'User', mapSobj, true);
        // setContactValues(notification.users, 'cc', cc, 'User', mapSobj, settings, isEmail);
        // setContactValues(notification.users, 'bcc', bcc, 'User', mapSobj, settings, isEmail);

        // Settings Contact parameter by contacts
        setContactValues(notification.contacts, 'to', toSets, 'Contact', mapSobj, true);
        // setContactValues(notification.contacts, 'cc', cc, 'Contact', mapSobj, settings, isEmail);
        // setContactValues(notification.contacts, 'bcc', bcc, 'Contact', mapSobj, settings, isEmail);

        // Settings Contact parameter by accounts
        setContactValues(notification.accounts, 'to', toSets, 'Account', mapSobj, true);
        // setContactValues(notification.accounts, 'cc', cc, 'Account', mapSobj, settings, isEmail);
        // setContactValues(notification.accounts, 'bcc', bcc, 'Account', mapSobj, settings, isEmail);

        // Settings Contact parameter by inputs
        setContactValuesByInputs(notification.inputs, 'to', toSets);
        // setContactValues(notification.inputs, 'cc', cc);
        // setContactValues(notification.inputs, 'bcc', bcc);

        if(!toSets.isEmpty()){ this.to = new List<String>(toSets); }
        
        /**
         * Settings attribute
         */
        if(isAttrValue){
            this.attributes = new Map<String, String>();
            addAttriubute(notification.attributes);
        }
        /**
         * To-do
         * Settings attachments 
         */
        return this;
    }
}