/**
 * Created by MZC01-DGCHOI on 2023-03-08.
 */

public with sharing class WBSCCZF_tr extends TriggerHandler {

    private List<WBSandCC__c> listNew = (List<WBSandCC__c>) Trigger.new;
    private List<WBSandCC__c> listOld = (List<WBSandCC__c>) Trigger.old;


    public override void afterInsert() {
        //ZF(1) 생성시 수주(180) 생성
        //ZF 하나당 : 레코드 유형(5) x 수주 가능성(3) x 월별(12)
        createOppty();
    }

    public override void beforeDelete() { deleteOppty(); } //해당 [ZF선택]인 수주 삭제

    private void createOppty() {
        List<WBSandCC__c> zfList = getZFList(); //구분값 ZF만

        TriggerHandler.bypass('Opportunity_tr');
        TriggerHandler.bypass('OpportunityAmount_tr');

        OpptyDummy opptyDummy = new OpptyDummy();
        opptyDummy.stdYear = Date.today().year();
        opptyDummy.initValue = Date.today().month();
        List<Opportunity> opptyList = opptyDummy.createDummy(zfList);
        List<Opportunity_Amount__c> opptyAmountList = opptyDummy.createAmountDummy(opptyList);
        //List<Opportunity_Amount__c> opptyAmountList = opptyDummy.createAmountDummy(opptyList);


        /*Boolean isExecuting = (([
                SELECT COUNT()
                FROM AsyncApexJob
                WHERE ApexClassId IN (
                      SELECT Id
                      FROM ApexClass
                      WHERE Name = 'OpptyAmountDummy_ba'
                )
        ]) == 0) ? false : true ;
        if(isExecuting){
            return;
        }*/
        //Database.executeBatch(new OpptyAmountDummy_ba(opptyList),100);

       // List<Opportunity_Amount__c> opptyAmountList = opptyDummy.createAmountDummy(opptyList);
    }

    private void deleteOppty() {
        Set<Id> zfIdSet = getZFIdSet();

        List<Opportunity> deleteList = [
                SELECT Id
                FROM Opportunity
                WHERE WBS_CC__c IN :zfIdSet
        ];

        if(deleteList.size() > 0 && !Test.isRunningTest()) delete deleteList;
    }

    private Set<Id> getZFIdSet() {
        Set<Id> returnSet = new Set<Id>();

        for (WBSandCC__c wbscczf : (listNew != null ? listNew : listOld)) {
            if (wbscczf.Check_WBS_CC_ZF__c == 'ZF') {
                returnSet.add(wbscczf.Id);
            }
        }

        return returnSet;
    }

    private List<WBSandCC__c> getZFList() {
        List<WBSandCC__c> returnList = new List<WBSandCC__c>();

        for (WBSandCC__c wbscczf : (listNew != null ? listNew : listOld)) {
            if (wbscczf.Check_WBS_CC_ZF__c == 'ZF') {
                returnList.add(wbscczf);
            }
        }

        return returnList;
    }

}