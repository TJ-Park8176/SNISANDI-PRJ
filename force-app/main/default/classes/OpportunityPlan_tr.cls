/**
 * Created by MZC01-DGCHOI on 2023-12-01.
 */

public without sharing class OpportunityPlan_tr extends TriggerHandler {

    private List<Opportunity_plan__c> listOld = (List<Opportunity_plan__c>) Trigger.old;
    private List<Opportunity_plan__c> listNew = (List<Opportunity_plan__c>) Trigger.new;

    public override void beforeInsert() {
        System.debug('OpportunityPlan_tr :::: beforeInsert()');
        checkStage();
    }

    public override void afterInsert() {
        System.debug('OpportunityPlan_tr :::: afterInsert()');
        if(listNew[0].Real_Data_check__c) {
            //1. 하위지점수 update
            updateChildOpptyCount();
            //2. 지점제외 필드 체크
            CheckStoreExclude();
        }
    }

    public override void beforeUpdate() {
        System.debug('OpportunityPlan_tr :::: beforeUpdate()');
        //2. 지점제외 필드 체크
        if(listNew[0].Real_Data_check__c) {
            CheckStoreExclude();
        }
    }

    public override void afterUpdate() {
        System.debug('OpportunityPlan_tr :::: afterUpdate()');
        //1. 하위지점수 update
        if(listNew[0].Real_Data_check__c) updateChildOpptyCount();
    }

    public override void afterDelete() {
        System.debug('Opportunity_tr :::: afterDelete()');
        //1. 하위지점수 update
        updateChildOpptyCount();
    }

    /**
     * 초기 생성 시, StageName 잠재고객이여야 한다.
     */
    private void checkStage() {
        System.debug('OpportunityPlan_tr :::: checkStage()');
        for(Opportunity_plan__c opptyPlan : listNew) {
            if(opptyPlan.StageName__c != '잠재고객') {
                opptyPlan.addError(System.Label.OpptyPlanStageError);
            }
        }
    }

    private void updateChildOpptyCount() { //하위지점수 업데이트
        System.debug('Opportunity_tr :::: updateChildOpptyCount()');

        //사업계획(영업매출) Lookup 필드 count 추가
        List<Opportunity_plan__c> updateOpptyList = new List<Opportunity_plan__c>();
        Set<Id> updateIdSet = new Set<Id>();

        System.debug('listOld :::: ' + listOld);
        System.debug('listNew :::: ' + listNew);

        if(listOld == null) { //insert
            for(Integer i=0; i<listNew.size(); i++) {
                if(listNew[i].Parent_Opportunity__c != null) {
                    updateIdSet.add(listNew[i].Parent_Opportunity__c); // 룩업필드 : 상위 아이디(변경 이후)
                }
            }
        } else if(listNew == null) { //delete
            for(Integer i=0; i<listOld.size(); i++) {
                if(listOld[i].Parent_Opportunity__c != null) {
                    updateIdSet.add(listOld[i].Parent_Opportunity__c); // 룩업필드 : 상위 아이디(변경 이전)
                }
            }
        } else { //update
            for(Integer i=0; i<listNew.size(); i++) {
                if(listNew[i].Parent_Opportunity__c != null) updateIdSet.add(listNew[i].Parent_Opportunity__c); // 룩업필드 : 상위 아이디(변경 이후)
                if(listOld[i].Parent_Opportunity__c != null) updateIdSet.add(listOld[i].Parent_Opportunity__c); // 룩업필드 : 상위 아이디(변경 이전)
            }
        }

        if(updateIdSet.size() > 0) {
            List<AggregateResult> aggList = [
                    SELECT Parent_Opportunity__c, COUNT(Id) CNT, SUM(Totalmonthlyamount__c) SUM_AMOUNT
                    FROM Opportunity_plan__c
                    WHERE Parent_Opportunity__c IN :updateIdSet
                    AND StoreExclude__c = FALSE
                    GROUP BY Parent_Opportunity__c
            ];

            System.debug('aggList :::: ' + aggList);

            Set<Id> aggIdSet = new Set<Id>();

            for(AggregateResult agg : aggList) {
                Opportunity_plan__c opptyPlan        = new Opportunity_plan__c();
                opptyPlan.Id                         = (Id) agg.get('Parent_Opportunity__c');
                opptyPlan.Child_opportunity_count__c = Integer.valueOf(agg.get('CNT')); //하위 지점 수
                opptyPlan.TotalAmount_SumofSore__c   = Double.valueOf(agg.get('SUM_AMOUNT')); //총 매출 발생 금액(지점 합계)
                updateOpptyList.add(opptyPlan);

                aggIdSet.add((Id) agg.get('Parent_Opportunity__c'));
            }

            updateIdSet.removeAll(aggIdSet);

            for(Id opptyId : updateIdSet) {
                Opportunity_plan__c opptyPlan        = new Opportunity_plan__c();
                opptyPlan.Id                         = opptyId;
                opptyPlan.Child_opportunity_count__c = 0; //하위 지점 수
                opptyPlan.TotalAmount_SumofSore__c   = 0; //총 매출 발생 금액(지점 합계)
                updateOpptyList.add(opptyPlan);
            }

            System.debug('Opportunity_tr updateOpptyList ::: ' + updateOpptyList);
        }

        if(updateOpptyList.size() > 0) update updateOpptyList;
    }

    private void CheckStoreExclude() {
        final String STR_EXCEPT = '(제외)';

        for(Opportunity_plan__c opptyPlan : listNew) {
            if(opptyPlan.Parent_Opportunity__c != null) { //하위 수주들만
                if(opptyPlan.StoreExclude__c && !opptyPlan.Name.endsWith(STR_EXCEPT)) { //지점제외 True && (제외) 없
                    opptyPlan.Name += STR_EXCEPT;
                } else if(!opptyPlan.StoreExclude__c && opptyPlan.Name.endsWith(STR_EXCEPT)) { //지점제외 False && (제외) 있
                    opptyPlan.Name = opptyPlan.Name.removeEnd(STR_EXCEPT);
                }
            }
        }
    }

}