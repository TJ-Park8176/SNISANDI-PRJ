/**
 * Created by MZC01-DGCHOI on 2023-10-06.
 */

public with sharing class SenderReceiverTeamMember_tr extends TriggerHandler {

    public static Boolean isAlreadyExecuted = false;    // 재귀호출 방지 flag
    private List<Sender_Receiver_Team_Member__c> listNew = (List<Sender_Receiver_Team_Member__c>) Trigger.new;

    public override void afterInsert() {
        updateReceiverTargetCC();
        updateGroup();
    }

    /**
     * 생성된 CC의 Receiver_Target_CC__c 필드 전체 true
     */
    public void updateReceiverTargetCC() {
        Map<Id, WBSandCC__c> updateCCMap = new Map<Id, WBSandCC__c>();

        for(Sender_Receiver_Team_Member__c teamMember : listNew) {
            WBSandCC__c cc = new WBSandCC__c();
            cc.Id          = teamMember.CC__c;
            if(teamMember.Sender_Receiver_Type__c == 'Receiver') {
                cc.Receiver_Target_CC__c          = true;
                cc.Team_OperationsHeadquarters__c = true;
            }

            updateCCMap.put(cc.Id, cc);
        }

        if(updateCCMap.values().size() > 0) update updateCCMap.values();
    }

    /**
     * Sender Receiver Team Member 생성시에, Group을 자동으로 input
     */

    public void updateGroup() {
        List<String> senderReceivers_Id = new List<String>();

        for (Sender_Receiver_Team_Member__c teamMember : listNew) {
            senderReceivers_Id.add(teamMember.Sender_Receiver__c);
        }

        List<Sender_Receiver__c> get_SenderReceivers = [SELECT Id, Group__c FROM Sender_Receiver__c WHERE Id IN :senderReceivers_Id];

        Map<String, String> GroupId = new Map<String, String>();
        for (Sender_Receiver__c sr : get_SenderReceivers) {
            GroupId.put(sr.Id, sr.Group__c);
        }

        List<Sender_Receiver_Team_Member__c> Sender_Receiver_TeamMembers = new List<Sender_Receiver_Team_Member__c>();

        for (Sender_Receiver_Team_Member__c teamMember : listNew) {
            Sender_Receiver_Team_Member__c sr_TeamMember = new Sender_Receiver_Team_Member__c();
            sr_TeamMember.Id = teamMember.Id;
            sr_TeamMember.Group__c = GroupId.get(teamMember.Sender_Receiver__c);
            Sender_Receiver_TeamMembers.add(sr_TeamMember);
        }

        if(Sender_Receiver_TeamMembers.size() > 0) update Sender_Receiver_TeamMembers;
    }
}