/**
 * Created by MZC01-DGCHOI on 2023-04-17.
 */

/**
 * Owner Update Batch : WBS/CC/ZF의 owner로 update
 */
public with sharing class BATCH_UpdateOwner implements Database.Batchable<sObject>, Database.Stateful {

    public String targetApiKey;
    public Boolean checkDummy = false;
    public String wbsField = '';

    public Boolean userField = false; //User__c
    public Boolean ownerField = false; //Owner__c
    public Boolean ownerIdField = false; //OwnerId

    public BATCH_UpdateOwner(String targetApiKey) {
        this.targetApiKey = targetApiKey;
    }

    public BATCH_UpdateOwner(String targetApiKey, Boolean checkDummy) {
        this.targetApiKey = targetApiKey;
        this.checkDummy = checkDummy;
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        //WBSandCC__c Label명 찾기
        setWbsFieldKey(this.targetApiKey);

        return Database.getQueryLocator(
                ' SELECT Id, ' + this.wbsField +
                ' FROM ' + this.targetApiKey +
                (this.checkDummy == true ? ' WHERE Real_Data_check__c = true ' : '')
        );
    }

    public void execute(Database.BatchableContext context, List<SObject> scope) {
        System.debug('scope :::: ' + scope);

        try {
            Set<Id> wbsIdSet = new Set<Id>();
            for(SObject sObj : scope) {
                wbsIdSet.add((Id) sObj.get(this.wbsField));
            }

            Map<Id, Id> ownerMap = getOwnerMap(wbsIdSet);

            for(SObject sObj : scope) {
                Id ownerValue = ownerMap.get((Id) sObj.get(wbsField));

                System.debug('ownerValue :::: ' + ownerValue);

                if(ownerValue != null) {
                    if(userField) sObj.put('User__c', ownerValue);
                    if(ownerField) sObj.put('Owner__c', ownerValue);
                    if(ownerIdField) sObj.put('OwnerId', ownerValue);
                }

                if(this.targetApiKey == 'Amount__c' || this.targetApiKey == 'Cost__c') {
                    sObj.put('Itemmanagementcheck__c', true);
                }
            }
        } catch (Exception e) {
            System.debug(e.getLineNumber());
            System.debug(e.getMessage());
        }

        update scope;
    }

    public void finish(Database.BatchableContext context) {
        System.debug('--------BATCH_UpdateOwner finish----------');
    }

    public void setWbsFieldKey(String objName) {
        System.debug('objName :::: ' + objName);

        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType objSchema = schemaMap.get(objName);
        Map<String, Schema.SObjectField> fieldMap = objSchema.getDescribe().fields.getMap();

        for (String fieldName: fieldMap.keySet()) {
            Schema.DisplayType fieldDataType = fieldMap.get(fieldName).getDescribe().getType();
            if(String.valueOf(fieldDataType) == 'REFERENCE' && fieldName.containsIgnoreCase('WBS')) { //대소문자 구분x
                this.wbsField = fieldName;
            }
        }

        if(fieldMap.containsKey('User__c')) this.userField = true;
        if(fieldMap.containsKey('Owner__c')) this.ownerField = true;
        if(fieldMap.containsKey('OwnerId')) this.ownerIdField = true;

        System.debug('wbsField :::: ' + this.wbsField);
        System.debug('User__c :::: ' + this.userField);
        System.debug('Owner__c :::: ' + this.ownerField);
        System.debug('OwnerId :::: ' + this.ownerIdField);
    }

    /**
     * @param wbsIdSet 배치 scope WBSIdSet
     *
     * @return wbsId-ownerId Map
     */
    public Map<Id, Id> getOwnerMap(Set<Id> wbsIdSet) { //key :wbsId, value:ownerId
        List<WBSandCC__c> wbsList = [
                SELECT Id, OwnerId
                FROM WBSandCC__c
                WHERE Id IN :wbsIdSet
        ];

        Map<Id, Id> returnMap = new Map<Id, Id>();

        for(WBSandCC__c wbs : wbsList) {
            returnMap.put(wbs.Id, wbs.OwnerId);
        }

        return returnMap;
    }
}