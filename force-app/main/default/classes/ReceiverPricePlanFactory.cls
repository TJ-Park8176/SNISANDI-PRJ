/**
 * Created by MZC01-DGCHOI on 2023-12-27.
 */

public with sharing class ReceiverPricePlanFactory {

    public static void makeBaseRecord() {
        List<Group__c> groupList = getGroupList();
        Id latestVersionId       = getLatestVersionId();
        Set<Id> groupIdSet       = new Set<Id>();

        for(Group__c groupData : groupList) {
            groupIdSet.add(groupData.Id);
        }

        System.debug('groupIdSet ::: ' + groupIdSet);

        //Group-월 - Sender Price Map
        Map<String, Id> groupSenderPriceMap = new Map<String, Id>();
        List<Plan_Sender_Price__c> senderPriceList = [
                SELECT Id, Group__c, Calculate_Month__c
                FROM Plan_Sender_Price__c
                WHERE Group__c IN :groupIdSet
        ];

        for(Plan_Sender_Price__c senderPrice : senderPriceList) {
            groupSenderPriceMap.put(
                    senderPrice.Group__c + '-' + senderPrice.Calculate_Month__c,
                    senderPrice.Id
            );
        }

        System.debug('groupSenderPriceMap ::: ' + groupSenderPriceMap);

        //TeamMember 별로 Receiver Price 월별(12개) 생성
        List<Sender_Receiver_Team_Member__c> receiverTeamMemberList = [
                SELECT Id, Sender_Receiver__c, Group__c
                FROM Sender_Receiver_Team_Member__c
                WHERE Group__c IN :groupIdSet
                AND Sender_Receiver__r.Type__c = 'Receiver'
        ];

        System.debug('receiverTeamMemberList :::: ' + receiverTeamMemberList);

        List<Plan_Receiver_Price__c> baseReceiverPrices = new List<Plan_Receiver_Price__c>();

        for(Sender_Receiver_Team_Member__c teamMember : receiverTeamMemberList) {
            Id groupDataId  = teamMember.Group__c;
            Id receiverId   = teamMember.Sender_Receiver__c;
            Id teamMemberId = teamMember.Id;

            for (Integer month = 1; month <= 12; month++) {
                Id senderPriceId = groupSenderPriceMap.get(groupDataId + '-' + month);

                Plan_Receiver_Price__c receiverPrice       = new Plan_Receiver_Price__c();
                receiverPrice.Calculate_Month__c           = String.valueOf(month);
                receiverPrice.Recevier__c                  = receiverId;
                receiverPrice.Group__c                     = groupDataId;
                receiverPrice.Sender_Price__c              = senderPriceId; // group-월
                receiverPrice.Receiver_Team_Member__c      = teamMemberId;
                receiverPrice.Plan_Distribution_Version__c = latestVersionId;
                receiverPrice.External_ID__c               = groupDataId + '-' + receiverId + '-' + teamMemberId + '-' + month; //Group - Receiver - teamMember - 월
                //receiverPrice.Price__c                     = 0;

                baseReceiverPrices.add(receiverPrice);
            }
        }

        System.debug('baseReceiverPrices :::: ' + baseReceiverPrices);
        if(baseReceiverPrices.size() > 0) upsert baseReceiverPrices External_ID__c;
    }

    /**
     * @return 최신 버전 Group
     */
    private static List<Group__c> getGroupList() {
        List<Group__c> groupList = [
                SELECT Id, Name, Recevier__c
                FROM Group__c
                WHERE Latest_Version__c = TRUE
                //AND CreatedDate = YESTERDAY //YESTERDAY로 바꾸기 //주석풀어야됑
        ];

        return groupList;
    }

    /**
     * @return 최신 버전 Id
     */
    private static Id getLatestVersionId() {
        Plan_Distribution_Version__c version = [
                SELECT Id
                FROM Plan_Distribution_Version__c
                WHERE Latest_Version__c = TRUE
                LIMIT 1
        ];

        if(version != null) {
            return version.Id;
        }
        return null;
    }
}