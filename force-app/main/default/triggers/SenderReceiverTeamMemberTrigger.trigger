/**
 * Created by MZC01-DGCHOI on 2023-10-06.
 */

trigger SenderReceiverTeamMemberTrigger on Sender_Receiver_Team_Member__c (after insert) {
    new SenderReceiverTeamMember_tr().run();
}