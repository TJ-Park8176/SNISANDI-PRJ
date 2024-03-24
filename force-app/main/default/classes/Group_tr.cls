/**
 * @description       : 
 * @author            : jisoolee@mz.co.kr
 * @group             : 
 * @last modified on  : 2023-10-30
 * @last modified by  : jisoolee@mz.co.kr
**/

public class Group_tr extends TriggerHandler{
    public override void afterInsert(){
        matchGroupAfterInsert();
    }
    public override void afterUpdate(){
        matchGroupAfterUpdate();
    }
    
    public void matchGroupAfterInsert(){
        try{
            Map<String, String> senderReceiverMap = new Map<String, String>();

            for(Group__c g : (List<Group__c>) Trigger.new){
                senderReceiverMap.put(g.Sender__c, g.Id);
                senderReceiverMap.put(g.Recevier__c, g.Id);
            }
    
            List<Sender_Receiver__c> senderReceiverList = [ SELECT Id, Group__c
                                                            FROM Sender_Receiver__c
                                                            WHERE Id IN: senderReceiverMap.keySet() ];
    
            for(Sender_Receiver__c senderReceiver : senderReceiverList){
                if(senderReceiverMap.containsKey(senderReceiver.Id)) senderReceiver.Group__c = senderReceiverMap.get(senderReceiver.Id);
            }
        	update senderReceiverList;
        } catch (Exception e) {
            System.debug('e : '+e);
            System.debug('e.getLine : '+e.getLineNumber());
            System.debug('e.message : '+e.getMessage());
        }
    }

    public void matchGroupAfterUpdate(){
        try{
            Map<String, String> senderReceiverNewMap    = new Map<String, String>();
            Map<String, String> senderReceiverOldMap    = new Map<String, String>();
            List<String> senderList                     = new List<String>();
            List<String> receiverList                   = new List<String>();

            for(Group__c g : (List<Group__c>) Trigger.new){
                if(g.Sender__c != null){
                    senderReceiverNewMap.put(g.Sender__c, g.Id);
                }else{
                    senderList.add(g.Id);
                }
                
                if(g.Recevier__c != null){
                    senderReceiverNewMap.put(g.Recevier__c, g.Id);
                }else{
                    receiverList.add(g.Id);
                }
            }
            
            for(Group__c g : (List<Group__c>) Trigger.old){
                for(String senderGroupId : senderList){
                    if(g.Id == senderGroupId){
                        senderReceiverOldMap.put(g.Sender__c, g.Id);
                    }
                }
                for(String receiverGroupId : receiverList){
                    if(g.Id == receiverGroupId){
                        senderReceiverOldMap.put(g.Recevier__c, g.Id);
                    }
                }
            }
    
            List<Sender_Receiver__c> senderReceiverList = [ SELECT Id, Group__c
                                                            FROM Sender_Receiver__c
                                                            WHERE Id IN: senderReceiverNewMap.keySet()
                                                            OR Id IN: senderReceiverOldMap.keySet() ];
    
            for(Sender_Receiver__c senderReceiver : senderReceiverList){
                if(senderReceiverNewMap.containsKey(senderReceiver.Id)) senderReceiver.Group__c = senderReceiverNewMap.get(senderReceiver.Id);
                if(senderReceiverOldMap.containsKey(senderReceiver.Id)){
                    senderReceiver.Group__c = null;
                } 
            }
        	update senderReceiverList;
        } catch (Exception e) {
            System.debug('e : '+e);
            System.debug('e.getLine : '+e.getLineNumber());
            System.debug('e.message : '+e.getMessage());
        }
    }
}