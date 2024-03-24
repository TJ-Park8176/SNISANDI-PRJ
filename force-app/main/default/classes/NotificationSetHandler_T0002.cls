/**
 * @description       : NotificationSetHandler extends sample
 * @author            : sungho.jo@mz.co.kr
 * @group             : MegazoneCloud
 * @last modified on  : 2024-03-14
 * @last modified by  : sungho.jo@mz.co.kr
**/
public with sharing class NotificationSetHandler_T0002 extends NotificationSetHandler{
    /**
    * @description 
    * @author sungho.jo@mz.co.kr | 2024-03-13 
    * @param notiObj : Notification
    **/
    public override void setNotification(Notification notiObj){
        Map<String, Object> mapToparams = (Map<String, Object>) notiObj.params;// (Map<String, Map<String, String>>) params;
        List<String> attributes = (List<String> ) mapToparams.get('attributes'); // attribute로 받은 값
        List<String> etcValue   = (List<String>) mapToparams.get('etc');   // etc로 받은 값
        for(Integer i = 0; i < notiObj.attributes.size(); i++){
            notiObj.attributes[i].setAttriubuteValue(attributes[i]);
        }
    }
}