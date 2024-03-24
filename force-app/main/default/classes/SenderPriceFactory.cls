/**
 * Created by MZC01-DGCHOI on 2023-10-11.
 */

public without sharing class SenderPriceFactory {

    /**
     * 신규 Sender Price 생성
     */
    public static void makeBaseRecord() {
        List<Group__c> groupList = getGroupList();
        Id latestVersionId       = getLatestVersionId();

        List<Sender_Price__c> baseSenderPrices = new List<Sender_Price__c>();

        //group 1 : sender 1 : calculateMonth 12
        for(Group__c groupData : groupList) {
            for(Integer month=1; month<=12; month++) {
                Sender_Price__c senderPrice              = new Sender_Price__c();
                senderPrice.Group__c                     = groupData.Id;
                senderPrice.Sender__c                    = groupData.Sender__c;
                senderPrice.Calculate_Month__c           = String.valueOf(month);
                senderPrice.Plan_Distribution_Version__c = latestVersionId;
                senderPrice.External_ID__c               = groupData.Id + '-' + groupData.Sender__c + '-' + month;
                //senderPrice.Name = sender.Name + '-' + month + '월';

                baseSenderPrices.add(senderPrice);
            }
        }

        if(baseSenderPrices.size() > 0) upsert baseSenderPrices External_ID__c;
    }

    /**
     * @return 최신 버전 Group
     */

    private static List<Group__c> getGroupList() {
        List<Group__c> groupList = [
                SELECT Id, Name, Sender__c
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