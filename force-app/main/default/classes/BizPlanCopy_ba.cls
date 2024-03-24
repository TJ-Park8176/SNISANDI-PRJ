/**
 * Created by MZC01-DGCHOI on 2023-09-22.
 * TestCode : BizPlanCopy_ba_Test
 */

public without sharing class BizPlanCopy_ba implements Database.Batchable<SObject>, Database.Stateful{

    public String type = '';
    public String baseYear = '';
    public Map<String, String> targetObjKeyMap = new Map<String, String>();
    public Map<String, String> copyObjKeyMap   = new Map<String, String>();

    //실패 처리
    public Boolean isFailed = false;
    public String ERROR_MSG = '';

    public BizPlanCopy_ba(String type, String baseYear) {
        this.type     = type;
        this.baseYear = baseYear;

        System.debug(':::type::: ' + type);
        System.debug(':::baseYear::: ' + baseYear);
        

        setTargetObjKeyMap();
        setCopyObjKeyMap();
    }

    /**
     * @return type별 복제 대상 오브젝트 전체 레코드
     */
    public Database.QueryLocator start(Database.BatchableContext context) {
        String query = getQuerySelect();

        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext context, List<SObject> scope) {
        try {
            switch on this.type {
                when '아이템관리' {
                    copyItemManagement(scope);
                }
                when '매출' {
                    copyAmount(scope);
                }
                when '매입' {
                    copyCost(scope);
                }
                when '손익' {
                    copyProfitLoss(scope);
                }
            }
        } catch(Exception e) {
            this.isFailed = true;
            this.ERROR_MSG = e.getMessage();

            System.debug(e.getMessage());
            System.debug(e.getLineNumber());
        }
    }

    public void finish(Database.BatchableContext context) {
        System.debug('------------------- BizPlanCopy_ba finish() -------------------');

        String title = '';
        String body = '';

        if(!isFailed) {
            title = 'S&I: [사업계획(' + this.type + ')] 복제 완료';
            body  = '사업계획(' + this.type + ')] 복제 완료되었습니다.';

            EmailController.sendEmail(title, body);

            switch on this.type {
                when '아이템관리' {
                    Database.executeBatch(new BizPlanCopy_ba('매출', this.baseYear), 2000);
                    Database.executeBatch(new BizPlanCopy_ba('매입', this.baseYear), 2000);
                }
            }
        } else {
            title = 'S&I: [사업계획(' + this.type + ')] 복제 실패';
            body = 'BizPlanCopy_ba :::::: ' + this.ERROR_MSG;

            EmailController.sendEmail(title, body);
        }
    }

    /**
     * @description 복제 : 사업계획(아이템관리) -> 아이템관리
     */
    public void copyItemManagement(List<SObject> scope) {
        try {
            System.debug('::: copyItemManagement() :::');

            List<ItemManagement__c> insertList = new List<ItemManagement__c>();
            Set<String> itemPlanCodeSet        = new Set<String>();
            Map<Id, Id> recordTypeMap          = getItemRecordTypeId();

            for(ItemManagement_Plan__c copyItem : (List<ItemManagement_Plan__c>) scope) {
                ItemManagement__c tmpObj                = new ItemManagement__c();
                tmpObj.Name                             = copyItem.Name;
                tmpObj.RecordTypeId                     = recordTypeMap.get(copyItem.RecordTypeId);
                tmpObj.amount_code__c                   = copyItem.amount_code__c;
                tmpObj.Upload_Item_code__c              = copyItem.Upload_Item_code__c;
                tmpObj.Base_Year__c                     = copyItem.Base_Year__c;
                tmpObj.AmountType__c                    = copyItem.AmountType__c;
                tmpObj.Tax__c                           = copyItem.Tax__c;
                tmpObj.SalesSort__c                     = copyItem.SalesSort__c;
                tmpObj.AmountDivision__c                = copyItem.AmountDivision__c;
                tmpObj.AccountDivision__c               = copyItem.AccountDivision__c;
                tmpObj.AccountSubjectselect__c          = copyItem.AccountSubjectselect__c;
                tmpObj.WBS_CC__c                        = copyItem.WBS_CC__c;
                tmpObj.Account__c                       = copyItem.Account__c;
                tmpObj.CalculateDate__c                 = copyItem.CalculateDate__c;
                tmpObj.Yearly_total_purchase_closing__c = copyItem.Yearly_total_purchase_closing__c;
                tmpObj.Yearly_total_amount_closing__c   = copyItem.Yearly_total_amount_closing__c;
                tmpObj.Total_cost__c                    = copyItem.Total_cost__c;
                tmpObj.PredictAmount__c                 = copyItem.PredictAmount__c;
                tmpObj.ItemManagement_report__c         = copyItem.ItemManagement_report__c;
                tmpObj.Itemmanagement_plan_code__c      = copyItem.Itemmanagement_code__c; //사업계획(아이템관리) 코드 매핑!
                tmpObj.IsDeleted__c                     = copyItem.IsDeleted__c;
                tmpObj.Owner__c                         = copyItem.Owner__c;
                tmpObj.OwnerId                          = copyItem.OwnerId;
                tmpObj.test1__c                         = copyItem.test1__c;
                tmpObj.writer__c                        = copyItem.writer__c;
                tmpObj.AccountSubjectCode_hidden__c     = copyItem.AccountSubjectCode_hidden__c;
                tmpObj.WBS_Code_Hidden__c               = copyItem.WBS_Code_Hidden__c;
                tmpObj.AmountType2__c                   = copyItem.AmountType2__c;
                tmpObj.Possibility__c                   = copyItem.Possibility__c;

                insertList.add(tmpObj);
                itemPlanCodeSet.add(copyItem.Itemmanagement_code__c);
            }

            if(insertList.size() > 0) {
                System.debug('insertList : '      + insertList);
                System.debug('insertList size : ' + insertList.size());

                insert insertList;
                lookupItemManagementByItemCode(itemPlanCodeSet);
            }
        } catch (Exception e) {
            this.isFailed = true;
            this.ERROR_MSG = e.getMessage();

            System.debug(e.getLineNumber());
            System.debug(e.getMessage());
        }

        //1. 아이템관리 복제 후 사업계획(매출/매입)에 매핑.
        //     사업계획(아이템관리), 아이템관리 1:1 매핑
        //     아이템관리 코드(복제용) : wbsCode-사업계획아이템관리코드
        //2. 사업계획(매입/매출)에 아이템관리 Lookup
    }


    /**
     * @description 복제 : 사업계획(매출) -> 매출현황
     */
    public void copyAmount(List<SObject> scope) {
        try {
            List<Amount__c> insertList = new List<Amount__c>();

            for(Amount_plan__c copyAmt : (List<Amount_plan__c>) scope) {
                Amount__c tmpObj               = new Amount__c();
                tmpObj.Name                    = copyAmt.Name;
                tmpObj.WBS__c                  = copyAmt.WBS__c;
                tmpObj.PredictAmount__c        = copyAmt.PlanAmount__c;
                tmpObj.CalculateDate__c        = copyAmt.calculateDate__c;
                tmpObj.Amount_report__c        = copyAmt.Amount_Plan_report__c;
                tmpObj.AmountType__c           = copyAmt.AmountType__c;
                tmpObj.Tax__c                  = copyAmt.Tax__c;
                tmpObj.SalesSort__c            = copyAmt.SalesSort__c;
                tmpObj.Status__c               = copyAmt.Status__c;
                tmpObj.Account__c              = copyAmt.Account__c;
                tmpObj.AccountSubjectselect__c = copyAmt.AccountSubjectselect__c;
                tmpObj.amount_code__c          = copyAmt.Amount_code__c;
                tmpObj.AccountDivision__c      = copyAmt.AccountDivision__c;
                tmpObj.AmountDivision__c       = copyAmt.AmountDivision__c;
                tmpObj.Itemmanagement__c       = copyAmt.Itemmanagement__c; //아이템관리 Lookup
                tmpObj.User__c                 = copyAmt.User__c;
                tmpObj.Amount_sort_report__c   = '운영(예상실적)';
                tmpObj.Itemmanagementcheck__c  = true;
                //Amount_External_ID_Hidden__c, Amount_External_ID__c <- 두개 필드 복제시 인입 잘 되는지 확인

                insertList.add(tmpObj);
            }

            if(insertList.size() > 0) insert insertList;
        } catch (Exception e) {
            this.isFailed = true;
            this.ERROR_MSG = e.getMessage();

            System.debug(e.getLineNumber());
            System.debug(e.getMessage());
        }
    }

    /**
     * @description 복제 : 사업계획(매입) -> 매입현황
     */
    public void copyCost(List<SObject> scope) {
        try {
            List<Cost__c> insertList = new List<Cost__c>();

            for(Cost_Plan__c copyCost : (List<Cost_Plan__c>) scope) {
                Cost__c tmpObj                 = new Cost__c();
                tmpObj.Name                    = copyCost.Name;
                tmpObj.CalculateDate__c        = copyCost.CalculateDate__c;
                tmpObj.WBS__c                  = copyCost.WBS__c;
                tmpObj.AccountSubjectselect__c = copyCost.AccountSubjectselect__c;
                tmpObj.Itemmanagement__c       = copyCost.Itemmanagement__c; //아이템관리 Lookup
                tmpObj.Cost_report__c          = copyCost.Cost_Plan_report__c;
                tmpObj.PurchaseAmount__c       = copyCost.PlanPurchaseAmount__c;
                tmpObj.Owner__c                = copyCost.Owner__c;
                tmpObj.AccountSubjectsort__c   = copyCost.AccountSubjectsort__c;
                tmpObj.Amount_sort_report__c   = '운영(예상실적)';
                tmpObj.Itemmanagementcheck__c  = true;
                //tmpObj.amount_plan__c        = copyCost.amount_plan__c; //필요없을거같음
                //tmpObj.ownerid               = copyCost.ownerid;
                // Cost External ID Hidden, Cost External ID <- 두개 필드 복제시 인입 잘 되는지 확인

                insertList.add(tmpObj);
            }

            if(insertList.size() > 0) insert insertList;
        } catch (Exception e) {
            this.isFailed = true;
            this.ERROR_MSG = e.getMessage();

            System.debug(e.getLineNumber());
            System.debug(e.getMessage());
        }
    }

    /**
     * @description 복제 : 사업계획(손익) -> 손익현황
     */
    public void copyProfitLoss(List<SObject> scope) {
        try {
            List<ProfitandLoss__c> insertList = new List<ProfitandLoss__c>();

            for(ProfitandLoss_Plan__c copyPro : (List<ProfitandLoss_Plan__c>) scope) {
                ProfitandLoss__c tmpObj             = new ProfitandLoss__c();
                tmpObj.Name                         = copyPro.Name;
                tmpObj.WBS__c                       = copyPro.WBS__c;
                tmpObj.Calculate_month__c           = copyPro.Calculate_month__c;
                tmpObj.Amount__c                    = copyPro.Amount__c;
                tmpObj.AccountSubjectSelect__c      = copyPro.AccountSubjectselect__c;
                tmpObj.ProfitandLoss_Type__c        = copyPro.ProfitandLoss_Type__c;
                tmpObj.ProfitandLoss_report__c      = copyPro.ProfitandLoss_Plan_report__c;
                tmpObj.OwnerId                      = copyPro.OwnerId;
                tmpObj.ProfitandLoss_External_ID__c = copyPro.WBS_Code__c + '-'
                                                    + copyPro.AccountSubjectCodea__c + '-'
                                                    + copyPro.Calculate_month__c.year() + '-'
                                                    + copyPro.Calculate_month__c.month();
                tmpObj.Amount_sort_report__c        = '운영(예상실적)';

                insertList.add(tmpObj);
            }

            if(insertList.size() > 0) insert insertList;
        } catch (Exception e) {
            this.isFailed = true;
            this.ERROR_MSG = e.getMessage();

            System.debug(e.getLineNumber());
            System.debug(e.getMessage());
        }
    }


    /**
     * @description 사업계획(매입/매출)에 아이템관리 Lookup
     */
    public void lookupItemManagementByItemCode(Set<String> itemPlanCodeSet) {
        try {
            System.debug('::: lookupItemManagementByItemCode() :::');
            System.debug('itemPlanCodeSet Size : ' + itemPlanCodeSet.size());

            List<ItemManagement__c> itemList = [
                    SELECT Id, Itemmanagement_plan_code__c
                    FROM ItemManagement__c
                    WHERE Itemmanagement_plan_code__c IN: itemPlanCodeSet
            ];

            List<Amount_plan__c> amountPlans = [
                    SELECT Id, ItemManagement_Plan__c, ItemManagement_Plan__r.Itemmanagement_code__c
                    FROM Amount_plan__c
                    WHERE ItemManagement_Plan__r.Itemmanagement_code__c IN: itemPlanCodeSet
                    AND Real_Data_check__c = TRUE
            ];

            List<Cost_Plan__c> costPlans = [
                    SELECT Id, ItemManagement_Plan__c, ItemManagement_Plan__r.Itemmanagement_code__c
                    FROM Cost_Plan__c
                    WHERE ItemManagement_Plan__r.Itemmanagement_code__c IN: itemPlanCodeSet
                    AND Real_Data_check__c = TRUE
            ];

            Map<String, Id> planCodeItemMap = new Map<String, Id>();
            for(ItemManagement__c item : itemList) {
                planCodeItemMap.put(item.Itemmanagement_plan_code__c, item.Id);
            }

            for(Amount_plan__c amountPlan : amountPlans) {
                String planCode = amountPlan.ItemManagement_Plan__r.Itemmanagement_code__c;

                if(planCodeItemMap.containsKey(planCode) && planCode != null) {
                    amountPlan.Itemmanagement__c = planCodeItemMap.get(planCode);
                }
                amountPlan.Itemmanagementcheck__c = true;
            }

            for(Cost_Plan__c costPlan : costPlans) {
                String planCode = costPlan.ItemManagement_Plan__r.Itemmanagement_code__c;

                if(planCodeItemMap.containsKey(planCode) && planCode != null) {
                    costPlan.Itemmanagement__c = planCodeItemMap.get(costPlan.ItemManagement_Plan__r.Itemmanagement_code__c);
                }
                costPlan.Itemmanagementcheck__c = true;
            }

            System.debug('amountPlans size: ' + amountPlans.size());
            System.debug('costPlans size: ' + costPlans.size());

            update amountPlans;
            update costPlans;
        } catch (Exception e) {
            this.isFailed = true;
            this.ERROR_MSG = e.getMessage();

            System.debug(e.getMessage());
            System.debug(e.getLineNumber());
        }
    }

    public String getQuerySelect() {
        String objectKey = targetObjKeyMap.get(this.type);
        Schema.SObjectType sObjType = Schema.getGlobalDescribe().get(objectKey);
        Set<String> fields = sObjType.getDescribe().fields.getMap().keySet();

        String query_select = '',
               query_where  = '';

        query_select = ' SELECT ' + String.join((Iterable<String>)fields, ',')
                     + ' FROM ' + objectKey;

        Set<String> realDataCheckObjSet = new Set<String> {'매출', '매입'};

        //매출, 매입
        if(realDataCheckObjSet.contains(this.type)) {
            query_where = ' WHERE Real_Data_check__c = TRUE ';
        }

        //baseYear 기준 복제
        switch on this.type {
            when '매출', '매입'{
                query_where = ' WHERE Real_Data_check__c = TRUE '
                            + ' AND BaseYear__c = \''   + this.baseYear + '\'';
            }
            when '아이템관리' {
                query_where = ' WHERE BaseYear__c = \'' + this.baseYear + '\'';
            }
            when '손익' {
                query_where = ' WHERE BaseYear__c = \'' + this.baseYear + '\'';
            }
        }

        System.debug('query_where :::: ' + query_where);
        return query_select + query_where;
    }

    /**
     * @description 복제 대상 ObjectKey 매핑
     */
    public void setTargetObjKeyMap() {
        targetObjKeyMap.put('아이템관리', 'ItemManagement_Plan__c');
        targetObjKeyMap.put('매출',      'Amount_plan__c');
        targetObjKeyMap.put('매입',      'Cost_Plan__c');
        targetObjKeyMap.put('손익',      'ProfitandLoss_Plan__c');
    }


    /**
     * @description 복제될 ObjectKey 매핑
     */
    public void setCopyObjKeyMap() {
        copyObjKeyMap.put('아이템관리', 'ItemManagement__c');
        copyObjKeyMap.put('매출',      'Amount__c');
        copyObjKeyMap.put('매입',      'Cost__c');
        copyObjKeyMap.put('손익',      'ProfitandLoss__c');
    }

    /**
     * @return key:사업계획(아이템관리) RecordType Id , value: 아이템관리 RecordType Id
     */
    public Map<Id, Id> getItemRecordTypeId() {
        Map<String, RecordTypeInfo> itemMap     = Schema.SObjectType.ItemManagement__c.getRecordTypeInfosByDeveloperName();
        Map<String, RecordTypeInfo> planItemMap = Schema.SObjectType.ItemManagement_Plan__c.getRecordTypeInfosByDeveloperName();

        Id amountItem = itemMap.get('Amount_item').getRecordTypeId();
        Id costItem = itemMap.get('Cost_Item').getRecordTypeId();
        Id amountItem_plan = planItemMap.get('Amount_item').getRecordTypeId();
        Id costItem_plan = planItemMap.get('Cost_Item').getRecordTypeId();

        Map<Id, Id> returnMap = new Map<Id, Id>();
        returnMap.put(amountItem_plan, amountItem);
        returnMap.put(costItem_plan, costItem);

        return returnMap;
    }

}