public with sharing class Opportunity_tr extends TriggerHandler{

    private List<Opportunity> listOld = (List<Opportunity>) Trigger.old;
    private List<Opportunity> listNew = (List<Opportunity>) Trigger.new;

    private static Map<String, Id> rtMap_Opportunity = Utilities.getRecordTypeBySObject('Opportunity');

    //23.07.08 Sanghee
    public override void beforeInsert() {
        System.debug('Opportunity_tr :::: beforeInsert()');
        checkStage(); //23.07.08 Sanghee - 영업물건관리 초기 생성 Stage 관리
    }

    public override void afterInsert() {
        System.debug('Opportunity_tr :::: afterInsert()');
        if(listNew[0].Real_Data_check__c) {
            //1. 하위지점수 update
            updateChildOpptyCount();
            //2. 지점제외 필드 체크
            CheckStoreExclude();            
        }
        /*else {
            //3. 수주매출 dummy insert
            insertDummyOpptyAmount();
        }*/
    }


    public override void beforeUpdate() {
        System.debug('Opportunity_tr :::: beforeUpdate()');
        System.debug('beforeUpdate listNew Size :::: ' + listNew.size());

        //지점제외 필드 체크
        if(listNew[0].Real_Data_check__c) {
            CheckStoreExclude();
        }

    }

    public override void afterUpdate() {
        System.debug('Opportunity_tr :::: afterUpdate()');
        if(listNew[0].Real_Data_check__c) updateChildOpptyCount(); //하위지점수 update
    }
    
    public override void afterDelete() {
        System.debug('Opportunity_tr :::: afterDelete()');
        updateChildOpptyCount(); //하위 지점수 update
    }

    // 23.07.08 Sanghee - 초기 생성 시, Stage는 무조건 잠재고객
    private void checkStage() {
        System.debug('Opportunity_tr :::: checkStage()');
        for (opportunity opty : listNew) {
            if (opty.StageName != '잠재고객' && opty.recordtypeId <> '0121y000003WkLcAAK') {
                opty.addError(System.Label.OpptyStageError);
            }
        }
    }

    private void updateChildOpptyCount() { //하위지점수 업데이트
        System.debug('Opportunity_tr :::: updateChildOpptyCount()');

        //영업물건관리 Lookup필드 count 추가 - 2023.03.10 loki & dgchoi

        List<Opportunity> updateOpList = new List<Opportunity>();
        Set<Id> updateIdSet = new Set<Id>();

        System.debug('listOld :::: ' + listOld);
        System.debug('listNew :::: ' + listNew);

        if(listOld == null) { //insert
            for(Integer i=0; i<listNew.size(); i++) {
                if(listNew[i].parent_Opportunity__c != null) {
                    updateIdSet.add(listNew[i].parent_Opportunity__c); // 룩업필드 : 상위 아이디(변경 이후)
                }
            }
        } else if(listNew == null) { //delete
            for(Integer i=0; i<listOld.size(); i++) {
                if(listOld[i].parent_Opportunity__c != null) {
                    updateIdSet.add(listOld[i].parent_Opportunity__c); // 룩업필드 : 상위 아이디(변경 이전)
                }
            }
        } else { //update
            for(Integer i=0; i<listNew.size(); i++) {
                if(listNew[i].parent_Opportunity__c != null) updateIdSet.add(listNew[i].parent_Opportunity__c); // 룩업필드 : 상위 아이디(변경 이후)
                if(listOld[i].parent_Opportunity__c != null) updateIdSet.add(listOld[i].parent_Opportunity__c); // 룩업필드 : 상위 아이디(변경 이전)
            }
        }

        if(updateIdSet.size() > 0) {
            List<AggregateResult> aggList = [
                    SELECT parent_Opportunity__c, COUNT(Id) CNT, SUM(Totalmonthlyamount__c) SUM_AMOUNT
                    FROM Opportunity
                    WHERE parent_Opportunity__c IN :updateIdSet
                    AND StoreExclude__c = FALSE
                    GROUP BY parent_Opportunity__c
            ];

            System.debug('aggList :::: ' + aggList);

            Set<Id> aggIdSet = new Set<Id>();

            for(AggregateResult agg : aggList) {
                Opportunity oppty = new Opportunity();
                oppty.Id = (Id) agg.get('parent_Opportunity__c');
                oppty.Child_opportunity_count__c = Integer.valueOf(agg.get('CNT')); //하위 지점 수
                oppty.TotalAmount_SumofSore__c = Double.valueOf(agg.get('SUM_AMOUNT')); //총 매출 발생 금액(지점 합계)
                updateOpList.add(oppty);

                aggIdSet.add((Id)agg.get('parent_Opportunity__c'));
            }

            updateIdSet.removeAll(aggIdSet);

            for(Id opptyId : updateIdSet) {
                Opportunity oppty = new Opportunity();
                oppty.Id = opptyId;
                oppty.Child_opportunity_count__c = 0; //하위 지점 수
                oppty.TotalAmount_SumofSore__c = 0; //총 매출 발생 금액(지점 합계)
                updateOpList.add(oppty);
            }

            System.debug('Opportunity_tr UpdateOpList ::: ' + updateOpList);
        }

        if(updateOpList.size() > 0) update updateOpList;
    }

    private void CheckStoreExclude() {
        for(Opportunity opp : listNew) {
            if(opp.parent_Opportunity__c != null) { //하위 수주들만

                if(opp.StoreExclude__c && !opp.Name.endsWith('(제외)')) { //지점제외 True && (제외) 없
                    opp.Name += '(제외)';
                } else if(!opp.StoreExclude__c && opp.Name.endsWith('(제외)')) { //지점제외 False && (제외) 있
                    opp.Name = opp.Name.removeEnd('(제외)');
                }
            }
        }
    }

    
}