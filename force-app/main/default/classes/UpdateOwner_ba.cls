/**
 * Created by MZC01-DGCHOI on 2023-11-06.
 */

/**
 * test code : OwnerChangeController_Test
 */
public without sharing class UpdateOwner_ba implements Database.Batchable<SObject>, Database.Stateful {

    public String objectKey;
    public String fieldKey;
    public Id     recordId;
    public Id     ownerId;
    public Integer batchIndex = 0;

    public static final List<String> OBJECT_KEY_SET = new List<String> {
            'Weekly_amount_expect__c', //주간예상(매출)
            'Weekly_cost_expect__c', //주간예상(매입)
            'Amount_Action_Plan__c', //실행계획(매출)
            'Cost_Action_Plan__c' //실행계획(매입)
    };

    //배치 결과
    public Boolean isFailed = false;
    public String  errorMsg = '';

    /**
     * @param batchIndex 실행할
     * @param fieldKey 'WBS__c', 'Itemmanagement__c'
     * @param recordId fieldKey 의 recordId
     * @param ownerId update 할 OwnerId
     */
    public UpdateOwner_ba(Integer batchIndex, String fieldKey, Id recordId, Id ownerId) {
        this.batchIndex = batchIndex;
        this.objectKey = OBJECT_KEY_SET[batchIndex];
        this.fieldKey  = fieldKey;
        this.recordId  = recordId;
        this.ownerId   = ownerId;
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator(
                ' SELECT Id ' +
                ' FROM ' + objectKey +
                ' WHERE ' + fieldKey + ' = \'' + recordId + '\'' +
                ' AND Real_Data_check__c = TRUE '
        );
    }

    public void execute(Database.BatchableContext context, List<SObject> scope) {
        try {
            Set<String> ownerFieldSet = new Set<String>();

            switch on objectKey {
                when 'Weekly_amount_expect__c' { //주간예상(매출)
                    ownerFieldSet.add('OwnerId');
                    ownerFieldSet.add('User__c');
                }
                when 'Weekly_cost_expect__c' { //주간예상(매입)
                    ownerFieldSet.add('OwnerId');
                    ownerFieldSet.add('Owner__c');
                }
                when 'Amount_Action_Plan__c' { //실행계획(매출)
                    ownerFieldSet.add('OwnerId');
                    ownerFieldSet.add('User__c');
                }
                when 'Cost_Action_Plan__c' { //실행계획(매입)
                    ownerFieldSet.add('OwnerId');
                    ownerFieldSet.add('Owner__c');
                }
            }

            for(SObject sObj : scope) {
                for(String ownerField : ownerFieldSet) {
                    sObj.put(ownerField, this.ownerId);
                }
            }

            if(scope.size() > 0) update scope;

        } catch(Exception e) {
            this.isFailed = true;
            this.errorMsg = e.getMessage();
        }
    }

    public void finish(Database.BatchableContext context) {
        System.debug('::::::::::::::::::::::::::::::::::finish::::::::::::::::::::::::::::::::::');
        System.debug('this.batchIndex : ' + this.batchIndex);
        System.debug('this.ObjectKey  : ' + this.objectKey);
        System.debug('this.fieldKey   : ' + this.fieldKey);
        System.debug('this.recordId   : ' + this.recordId);
        System.debug('this.ownerId    : ' + this.ownerId);

        if(this.isFailed) {
            String title = 'S&I: 하위 Owner 변경 실패';
            String body  = this.errorMsg;
            EmailController.sendEmail(title, body);
        } else if(this.batchIndex == 3) { //마지막 배치
            String title = 'S&I: 하위 Owner 변경 완료';
            String body  = '해당 Data Owner 로 하위 Owner 변경 완료 되었습니다.';
            EmailController.sendEmail(title, body);
        } else {
            UpdateOwner_ba batch = new UpdateOwner_ba(this.batchIndex + 1, this.fieldKey, this.recordId, this.ownerId);
            Database.executeBatch(batch, 2000);
        }
    }

}