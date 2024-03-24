/**
 * Created by MZC01-DGCHOI on 2023-10-11.
 */

public with sharing class SenderPrice_ba implements Database.Batchable<SObject>, Database.Stateful {

    //실패 처리
    public Boolean isFailed = false;
    public String ERROR_MSG = '';

    public Database.QueryLocator start(Database.BatchableContext context) {
        //Sender Price Base Record 생성
        SenderPriceFactory.makeBaseRecord(); //주석풀어야됑

        return Database.getQueryLocator(
            ' SELECT Id, Name, AccountSubject__c, Sender__c ' +
            ' FROM Group__c ' +
            ' WHERE Latest_Version__c = TRUE '
        );
    }

    public void execute(Database.BatchableContext context, List<Group__c> scope) {
        try {

            //1차: group
            Set<Id> groupIdSet = new Set<Id>();

            for (Group__c groupData : scope) {
                groupIdSet.add(groupData.Id);
            }

            List<Sender_Receiver_Team_Member__c> senderTeamMembers = [ //Sender인 TeamMember 조회
                    SELECT Id, CC__c, Group__c, Sender_Receiver__c, Group_Distribution_Ratio__c
                    FROM Sender_Receiver_Team_Member__c
                    WHERE Group__c IN :groupIdSet
                    AND Sender_Receiver__r.Type__c = 'Sender'
            ];

            System.debug('groupIdSet :::: ' + groupIdSet);

            //2차 매핑 : Group Id - CC Id
            Map<Id, Set<Id>> groupCCIdsMap       = new Map<Id, Set<Id>>();
            Map<String, Decimal> groupCCRatioMap  = new Map<String, Decimal>(); //Sender CC - 배부비율 Map
            Set<Id> totalCCIdSet                 = new Set<Id>();

            for (Sender_Receiver_Team_Member__c teamMember : senderTeamMembers) {
                Set<Id> ccIds = new Set<Id>();

                Id ccId     = teamMember.CC__c;
                Id groupId  = teamMember.Group__c;

                if (groupCCIdsMap.containsKey(groupId)) {
                    ccIds = groupCCIdsMap.get(groupId);
                }

                if (ccId != null) {
                    ccIds.add(ccId);
                    totalCCIdSet.add(ccId);
                    groupCCRatioMap.put(groupId + '-' + ccId, teamMember.Group_Distribution_Ratio__c);
                }

                groupCCIdsMap.put(groupId, ccIds);
            }

            System.debug('groupCCIdsMap :::: ' + groupCCIdsMap);

            //3차 매핑 : Group Id 월별 - 금액
            List<AggregateResult> ccBundleCostList = getTotalCostByCC(totalCCIdSet);
            Map<String, Decimal> groupPriceMap      = new Map<String, Decimal>(); //key:groupId-월, value:금액
            Map<String, Decimal> ccPriceMap         = new Map<String, Decimal>(); //key:ccId-월, value:금액

            System.debug('ccBundleCostList :::: ' + ccBundleCostList);

            for (AggregateResult agg : ccBundleCostList) {
                ccPriceMap.put(
                        String.valueOf(agg.get('WBS__c')) + '-' + String.valueOf(agg.get('CAL_MONTH')), //key
                        Decimal.valueOf(String.valueOf(agg.get('SUM_AMOUNT'))) //value
                );
            }

            System.debug('ccPriceMap :::: ' + ccPriceMap);

            for (Id groupId : groupCCIdsMap.keySet()) {
                for (Integer month = 1; month <= 12; month++) {

                    String groupKey = groupId + '-' + month;
                    Decimal groupValue = 0;

                    for (Id ccId : groupCCIdsMap.get(groupId)) { //ccSet
                        String ccKey      = ccId + '-' + month;
                        String groupCCKey = groupId + '-' + ccId; //Ratio - TeamMember의 Ratio, Key: Group-CC
                        Decimal ccRatio   = groupCCRatioMap.get(groupCCKey) != null ? groupCCRatioMap.get(groupCCKey) : 1; //비율 없으면 100% 처리 (확인필요)

                        if (ccPriceMap.containsKey(ccKey)) {
                            groupValue += (ccPriceMap.get(ccKey) * ccRatio).setScale(0);
                        }
                    }

                    groupPriceMap.put(groupKey, groupValue);
                }
            }

            System.debug('groupPriceMap :::: ' + groupPriceMap);

            //4차 매핑 : Sender Price 금액값 업데이트
            List<Sender_Price__c> senderPrices = getSenderPrices(groupIdSet);

            for (Sender_Price__c senderPrice : senderPrices) {
                String key = senderPrice.Group__c + '-' + senderPrice.Calculate_Month__c;
                senderPrice.Price__c = groupPriceMap.get(key);
            }

            System.debug('senderPrices ::: ' + senderPrices);

            if (senderPrices.size() > 0) update senderPrices;

        } catch(Exception e) {
            System.debug(e.getMessage());
            System.debug(e.getLineNumber());
            System.debug(e.getStackTraceString());
            
            this.isFailed = true;
            this.ERROR_MSG = e.getMessage();
        }
    }

    public void finish(Database.BatchableContext context) {
        if(!isFailed) {
            Database.executeBatch(new ReceiverPrice_ba());
        } else {
            String title = 'S&I: [SenderPrice_ba] 배치 실패';
            String body = 'SenderPrice_ba :::::: ' + this.ERROR_MSG;

            EmailController.sendEmail(title, body);
        }
    }

    public List<AggregateResult> getTotalCostByCC(Set<Id> ccIds) {
        System.debug('ccIds :::: ' + ccIds);
        List<AggregateResult> aggList = [
                SELECT WBS__c, CALENDAR_MONTH(CalculateDate__c) CAL_MONTH, SUM(PurchaseAmount__c) SUM_AMOUNT
                FROM Cost__c
                WHERE WBS__c IN: ccIds
                AND CalculateDate__c = THIS_YEAR
                GROUP BY WBS__c, CALENDAR_MONTH(CalculateDate__c)
        ];

        return aggList;
    }

    public List<Sender_Price__c> getSenderPrices(Set<Id> groupIds) {
        System.debug('groupIds :::: ' + groupIds);

        List<Sender_Price__c> senderPrices = [
                SELECT Id, Group__c, Calculate_Month__c
                FROM Sender_Price__c
                WHERE Latest_Version__c = TRUE
                AND Group__c IN :groupIds
        ];

        return senderPrices;
    }

    /*public class GroupClass {
        public Id groupId;
        public Set<Id> ccIds;
        public List<Double> priceList;
    }*/
}