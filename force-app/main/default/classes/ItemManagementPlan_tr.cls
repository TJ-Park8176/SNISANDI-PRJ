/**
 * Created by MZC01-USER on 2023-11-15.
 */
public with sharing class ItemManagementPlan_tr extends TriggerHandler{

    private List<ItemManagement_Plan__c> listNew = (List<ItemManagement_Plan__c>) Trigger.new;

    public override void beforeInsert() {
        basicYear();
        setOwner();
    }

    /**
     * Base_Year__c 필드 반영 : 입력 시점 기준 다음 년도
     */
    public void basicYear() {
        Date   thisYear = System.today();
        String baseYear = String.valueOf(thisYear.year() + 1);

        for (ItemManagement_Plan__c itemPlan : listNew) {
            itemPlan.Base_Year__c = baseYear;
        }
    }

    /**
     *  Owner__c, Writer__c 필드 반영 : 로그인 User
     */
    public void setOwner() {
        Id     loginUserId   = UserInfo.getUserId();
        String loginUserName = UserInfo.getName();

        for (ItemManagement_Plan__c itemPlan : listNew) {
            itemPlan.Owner__c  = loginUserId;
            itemPlan.writer__c = loginUserName;
        }
    }
}