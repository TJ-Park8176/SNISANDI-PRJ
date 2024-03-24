/**
 * Created by MZC01-DGCHOI on 2023-10-31.
 */

public without sharing class OwnerChangeController {
    /**
     * @param recordId 아이템관리의 RecordId
     * @description 해당 아이템의 Id를 가지고 하위 Object 의 소유자를 업데이트
    */
    @AuraEnabled
    public static void updateOwnerWithItem(Id recordId) {
        try {
            System.debug('recordId :::: ' + recordId);

            Id ownerId = [SELECT Id, OwnerId FROM ItemManagement__c WHERE Id = :recordId].OwnerId;
            // 매출현황
            List<Amount__c> amounts = [SELECT Id FROM Amount__c WHERE Itemmanagement__c = :recordId];
            // 매입현황
            List<Cost__c> costs = [SELECT Id FROM Cost__c WHERE Itemmanagement__c = :recordId];
            // 사업계획(매출)
            List<Amount_plan__c> amountPlans = [SELECT Id FROM Amount_plan__c WHERE Itemmanagement__c = :recordId AND Real_Data_check__c = true];
            // 사업계획(매입)
            List<Cost_Plan__c> costPlans = [SELECT Id FROM Cost_Plan__c WHERE Itemmanagement__c = :recordId AND Real_Data_check__c = true];

            System.debug('-------------------- Owner Id : ' + ownerId);

            for (Amount__c am : amounts) {
                am.User__c = ownerId;
            }

            for (Cost__c co : costs) {
                co.Owner__c = ownerId;
            }

            for (Amount_plan__c ap : amountPlans) {
                ap.User__c                = ownerId;
                ap.itemManagementCheck__c = true;
                //ap.OwnerId = ownerId; //운영 필드
            }

            for (Cost_Plan__c cp : costPlans) {
                cp.Owner__c               = ownerId;
                cp.itemManagementCheck__c = true;
                //cp.OwnerId  = ownerId; //운영 필드
            }

            TriggerHandler.bypass('Amount_tr');
            TriggerHandler.bypass('Cost_tr');

            if (amounts.size() > 0) update amounts;
            if (costs.size() > 0) update costs;
            if (amountPlans.size() > 0) update amountPlans;
            if (costPlans.size() > 0) update costPlans;

            //BATCH 실행
            UpdateOwner_ba batch = new UpdateOwner_ba(0, 'Itemmanagement__c', recordId, ownerId);
            Database.executeBatch(batch, 2000);

        } catch (Exception e) {
            String title = 'S&I: 하위 Owner 변경 실패';
            String body  = e.getMessage();
            EmailController.sendEmail(title, body);
        }
    }

    /**
     * @param recordId WBS 의 recordId
     * @description 해당 아이템의 Id를 가지고 하위 Object 의 소유자를 업데이트
    */
    @AuraEnabled
    public static void updateOwnerWithWBS(Id recordId) {
        try {
            System.debug('recordId :::: ' + recordId);
            Id ownerId = [SELECT Id, OwnerId FROM WBSandCC__c WHERE Id = :recordId LIMIT 1].OwnerId;

            //아이템관리
            List<ItemManagement__c> itemManagements = [SELECT Id FROM ItemManagement__c WHERE WBS_CC__c = :recordId];
            // 매출현황
            List<Amount__c> amounts = [SELECT Id FROM Amount__c WHERE WBS__c = :recordId];
            // 매입현황
            List<Cost__c> costs     = [SELECT Id FROM Cost__c WHERE WBS__c = :recordId];
            // 사업계획(매출)
            List<Amount_plan__c> amountPlans = [SELECT Id FROM Amount_plan__c WHERE WBS__c = :recordId AND Real_Data_check__c = true];
            // 사업계획(매입)
            List<Cost_Plan__c> costPlans     = [SELECT Id FROM Cost_Plan__c WHERE WBS__c = :recordId AND Real_Data_check__c = true];


            System.debug('-------------------- Owner Id : ' + ownerId);

            for(ItemManagement__c item : itemManagements) {
                item.OwnerId  = ownerId;
                item.Owner__c = ownerId;
            }

            for (Amount__c am : amounts) {
                am.User__c = ownerId;
            }

            for (Cost__c co : costs) {
                co.Owner__c = ownerId;
            }

            for (Amount_plan__c ap : amountPlans) {
                ap.User__c                = ownerId;
                ap.itemManagementCheck__c = true;
            }

            for (Cost_Plan__c cp : costPlans) {
                cp.Owner__c               = ownerId;
                cp.itemManagementCheck__c = true;
            }

            TriggerHandler.bypass('Amount_tr');
            TriggerHandler.bypass('Cost_tr');

            if (itemManagements.size() > 0) update itemManagements;
            if (amounts.size() > 0) update amounts;
            if (costs.size() > 0) update costs;
            if (amountPlans.size() > 0) update amountPlans;
            if (costPlans.size() > 0) update costPlans;

            //BATCH 실행
            UpdateOwner_ba batch = new UpdateOwner_ba(0, 'WBS__c', recordId, ownerId);
            Database.executeBatch(batch, 2000);

        } catch(Exception e) {
            String title = 'S&I: 하위 Owner 변경 실패';
            String body  = e.getMessage();
            EmailController.sendEmail(title, body);
        }
    }

    @AuraEnabled
    public static Boolean isNoApexJobRunning() {
        List<AsyncApexJob> runningJobs = [
                SELECT CreatedById, CreatedBy.Name, ApexClass.Name, Status
                FROM AsyncApexJob
                WHERE ApexClass.Name = 'UpdateOwner_ba' AND Status IN ('Processing', 'Queued', 'Holding')
        ];
        return runningJobs.isEmpty();
    }
}