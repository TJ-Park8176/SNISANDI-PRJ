/**
 * Created by MZC01-DGCHOI on 2023-04-26.
 */

/**
 * 매출현황/매입현황의 금액을 사업계획의 금액으로 업데이트
 */
public with sharing class BATCH_UpdatePrice implements Database.Batchable<sObject>, Database.Stateful {

    public String targetApiKey;
    public String targetPriceField;
    public String planPriceField;
    public String userField;
    public String externalIdField;
    public SObjectField externalIdsObjectField;

    /**
     * @param targetApiKey Amount__c(매출현황), Cost__c(매입현황)
     */
    public BATCH_UpdatePrice(String targetApiKey) {
        this.targetApiKey = targetApiKey;
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        String query = '';
        String planObj = '';
        switch on this.targetApiKey {
            when 'Amount__c' {
                planObj = 'Amount_Plan__c';

                this.userField = 'User__c';
                this.planPriceField = 'PlanAmount__c';
                this.targetPriceField = 'PredictAmount__c';
                this.externalIdField = 'Amount_External_ID__c';
                this.externalIdsObjectField = Amount__c.Amount_External_ID__c;
            }
            when 'Cost__c' {
                planObj = 'Cost_Plan__c';

                this.userField = 'Owner__c';
                this.planPriceField = 'PlanPurchaseAmount__c';
                this.targetPriceField = 'PurchaseAmount__c';
                this.externalIdField = 'Cost_External_ID__c';
                this.externalIdsObjectField = Cost__c.Cost_External_ID__c;

            }
        }

        SObjectType sObjType = ((SObject) Type.forName(planObj).newInstance()).getSObjectType();
        Set<String> fields = sObjType.getDescribe().fields.getMap().keySet();

        query = ' SELECT ' + String.join((Iterable<String>)fields, ',')
              + ' FROM ' + planObj
              + ' WHERE calculateDate__c = THIS_YEAR '
              + ' AND Itemmanagement__c != null'  ;

        System.debug('start query size :::: ' + Database.query(query).size());

        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext context, List<SObject> scope) {
        try {
            List<SObject> upsertList = new List<SObject>();

            for(SObject planObj : scope) {
                SObject targetObj = Schema.getGlobalDescribe().get(this.targetApiKey).newSObject();

                String externalIdValue = planObj.get('Itemmanagement_code__c') + '-'
                                       + (this.targetApiKey == 'Cost__c' ? planObj.get('AccountSubjectCodea__c') + '-' : '')
                                       + Date.valueOf(planObj.get('calculateDate__c')).year() + '-'
                                       + Date.valueOf(planObj.get('calculateDate__c')).month();

                System.debug('externalID Value :::: ' + externalIdValue);

                targetObj.put('Name', planObj.get('Name'));
                targetObj.put('WBS__c', planObj.get('WBS__c'));
                targetObj.put('calculateDate__c', planObj.get('calculateDate__c')); //정산일자
                targetObj.put('AccountSubjectselect__c', planObj.get('AccountSubjectselect__c')); //계정과목
                targetObj.put('Itemmanagement__c', planObj.get('Itemmanagement__c')); //아이템관리
                targetObj.put('Itemmanagementcheck__c', true);
                targetObj.put(this.userField, planObj.get('OwnerId'));
                targetObj.put(this.targetPriceField, planObj.get(planPriceField)); //금액
                targetObj.put(this.externalIdField, externalIdValue); //External Id

                if(this.targetApiKey == 'Amount__c') { //매출 금액 업데이트 시 매핑 필드 추가
                    targetObj.put('AmountDivision__c', planObj.get('AmountDivision__c'));
                    targetObj.put('AmountType__c', planObj.get('AmountType__c'));
                    targetObj.put('Status__c', planObj.get('Status__c'));
                    targetObj.put('SalesSort__c', planObj.get('SalesSort__c'));
                    targetObj.put('Account__c', planObj.get('Account__c'));
                }

                upsertList.add(targetObj);
            }

            System.debug('upsertList :::: ' + upsertList);
            System.debug('upsertList SIZE :::: ' + upsertList.size());

            Database.UpsertResult[] upsertResults = Database.upsert(upsertList, externalIdsObjectField);

            // upsert 결과 처리
            for (Database.UpsertResult upsertResult : upsertResults) {
                if (!upsertResult.isSuccess()) {
                    // upsert 실패한 경우
                    System.debug(this.targetApiKey + ' upsert failed: ' + upsertResult.getErrors());
                }
            }

        } catch(Exception e) {
            System.debug(e.getMessage());
            System.debug(e.getLineNumber());
        }
    }

    public void finish(Database.BatchableContext context) {
        System.debug('---------------BATCH_UpdatePrice finish()------------');
    }

}