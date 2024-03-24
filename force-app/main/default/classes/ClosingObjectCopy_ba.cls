/**
 * Created by MZC01-DGCHOI on 2023-02-28.
 */

/**
 * 마감 개체 업데이트 Batch : 수주, 수주 매출의 실제 데이터(전체) 복사
 */
public with sharing class ClosingObjectCopy_ba implements Database.Batchable<SObject>, Database.Stateful {

    public String targetApiKey; //복제대상 : Opportunity, Opportunity_amount__c

    public String weeklyFormat; //23년 00월 00주차
    public Integer weeklyNumber; //주차
    public Date batchDate = Date.today();

    public ClosingObjectCopy_ba(String targetApiKey) {
        this.targetApiKey = targetApiKey;

        //setBatchDate();
        setWeekNumber(this.batchDate);
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator(
            getQuerySelect()
        );
    }

    public void execute(Database.BatchableContext context, List<SObject> scope) {
        try {
            switch on this.targetApiKey {
                when 'Opportunity' {
                    copyOpportunity(scope);
                }
                when 'Opportunity_amount__c' {
                    copyOpportunityAmount(scope);
                }
            }
        } catch(Exception e) {
            System.debug(e.getMessage());
            System.debug(e.getLineNumber());
        }
    }

    /**
     * @description 마감 Chain : 마감(수주) -> 마감(수주매출) -> 아이템관리
     */
    public void finish(Database.BatchableContext context) {
        System.debug('------------ClosingObjectCopy_ba finish()---------------');
        if(this.targetApiKey == 'Opportunity') {
            Database.executeBatch(new ClosingObjectCopy_ba('Opportunity_amount__c'), 2000);
        } else if(this.targetApiKey == 'Opportunity_amount__c') {
            Database.executeBatch(new ClosingItemManagement_ba(), 2000);
        }
    }

    public String getQuerySelect() {
        SObjectType sObjType = ((SObject) Type.forName(this.targetAPIKey).newInstance()).getSObjectType();

        Set<String> fields = sObjType.getDescribe().fields.getMap().keySet();

        //2023.06.07 dgchoi 필드 조회 추가 : Owner.isActive
        String query_select = ' SELECT ' + String.join((Iterable<String>)fields, ',')
                            + (targetApiKey == 'Opportunity' ? ', Owner.IsActive ' : '')
                            + (targetApiKey == 'Opportunity_amount__c' ? ', OwnerId__r.IsActive ' : '')
                            + ' FROM ' + this.targetApiKey
                            + ' WHERE Real_Data_check__c = TRUE ' //실제 데이터만 복사
                            + ' AND StoreExclude__c = FALSE '; //지점제외 안된것만(FALSE)

        return query_select;
    }

    /**
     * @description 마감(수주)로 복사
     */
    public void copyOpportunity(List<SObject> scope) {
        List<Closing_opportunity__c> insertList = new List<Closing_opportunity__c>();

        for(Opportunity copyOppty : (List<Opportunity>) scope) {
            Closing_opportunity__c tmpObj = new Closing_opportunity__c();

            tmpObj.Closing_Weekly_date__c = this.weeklyFormat; //마감 주차
            tmpObj.Weekly__c = this.weeklyNumber; //주차
            tmpObj.Weekly_date__c = this.batchDate; //주차 일자

            //매핑
            if(copyOppty.OwnerId != null && copyOppty.Owner.isActive) { //2023.06.07 dgchoi 조건 추가 : Active된 유저만 복제
                tmpObj.OwnerId = copyOppty.OwnerId;
                tmpObj.Salesreps__c = copyOppty.OwnerId;
            }
            if(copyOppty.Name != null)                                tmpObj.Name                                = copyOppty.Name;
            if(copyOppty.AccountId != null)                           tmpObj.AccountId__c                        = copyOppty.AccountId;
            if(copyOppty.AI_CCTV_month__c != null)                    tmpObj.AI_CCTV_month__c                    = copyOppty.AI_CCTV_month__c;
            if(copyOppty.Budget_Confirmed__c != null)                 tmpObj.Budget_Confirmed__c                 = copyOppty.Budget_Confirmed__c;
            if(copyOppty.CloseDate != null)                           tmpObj.CloseDate__c                        = copyOppty.CloseDate;
            if(copyOppty.CampaignId != null)                          tmpObj.CampaignId__c                       = copyOppty.CampaignId;
            if(copyOppty.ContractId != null)                          tmpObj.ContractId__c                       = copyOppty.ContractId;
            if(copyOppty.Description != null)                         tmpObj.Description__c                      = copyOppty.Description;
            if(copyOppty.Discovery_Completed__c != null)              tmpObj.Discovery_Completed__c              = copyOppty.Discovery_Completed__c;
            if(copyOppty.ExpectedRevenue != null)                     tmpObj.ExpectedRevenue__c                  = copyOppty.ExpectedRevenue;
            if(copyOppty.ForecastCategoryName != null)                tmpObj.ForecastCategoryName__c             = copyOppty.ForecastCategoryName;
            if(copyOppty.ForecastCategoryName != null)                tmpObj.ForecastCategory__c                 = copyOppty.ForecastCategoryName;
            if(copyOppty.ForecastCategoryName != null)                tmpObj.ForecastCategory__c                 = copyOppty.ForecastCategoryName;
            if(copyOppty.LeadSource != null)                          tmpObj.LeadSource__c                       = copyOppty.LeadSource;
            if(copyOppty.Loss_Reason__c != null)                      tmpObj.Loss_Reason__c                      = copyOppty.Loss_Reason__c;
            if(copyOppty.NextStep != null)                            tmpObj.NextStep__c                         = copyOppty.NextStep;
            if(copyOppty.IsPrivate != null)                           tmpObj.IsPrivate__c                        = copyOppty.IsPrivate;
            if(copyOppty.Probability != null)                         tmpObj.Probability__c                      = copyOppty.Probability;
            if(copyOppty.ProductDivision__c != null)                  tmpObj.ProductDivision__c                  = copyOppty.ProductDivision__c;
            if(copyOppty.TotalOpportunityQuantity != null)            tmpObj.TotalOpportunityQuantity__c         = copyOppty.TotalOpportunityQuantity;
            if(copyOppty.RFPdate__c != null)                          tmpObj.RFPdate__c                          = copyOppty.RFPdate__c;
            if(copyOppty.RMS_month__c != null)                        tmpObj.RMS_month__c                        = copyOppty.RMS_month__c;
            if(copyOppty.ROI_Analysis_Completed__c != null)           tmpObj.ROI_Analysis_Completed__c           = copyOppty.ROI_Analysis_Completed__c;
            if(copyOppty.StageName != null)                           tmpObj.StageName__c                        = copyOppty.StageName;
            if(copyOppty.WIN_LOSS_reason__c != null)                  tmpObj.WIN_LOSS_reason__c                  = copyOppty.WIN_LOSS_reason__c;
            if(copyOppty.feet__c != null)                             tmpObj.feet__c                             = copyOppty.feet__c;
            if(copyOppty.construct_type__c != null)                   tmpObj.construct_type__c                   = copyOppty.construct_type__c;
            if(copyOppty.Architecturaltype__c != null)                tmpObj.Architecturaltype__c                = copyOppty.Architecturaltype__c;
            if(copyOppty.Competitors__c != null)                      tmpObj.Competitors__c                      = copyOppty.Competitors__c;
            if(copyOppty.Competitors_etc__c != null)                  tmpObj.Competitors_etc__c                  = copyOppty.Competitors_etc__c;
            if(copyOppty.ContractMethod__c != null)                   tmpObj.ContractMethod__c                   = copyOppty.ContractMethod__c;
            if(copyOppty.Amount != null)                              tmpObj.Amount__c                           = copyOppty.Amount;
            if(copyOppty.contract_closingdate__c != null)             tmpObj.contract_closingdate__c             = copyOppty.contract_closingdate__c;
            if(copyOppty.air_quality_month__c != null)                tmpObj.air_quality_month__c                = copyOppty.air_quality_month__c;
            if(copyOppty.Construction__c != null)                     tmpObj.Construction__c                     = copyOppty.Construction__c;
            if(copyOppty.ManagementOrNon__c != null)                  tmpObj.ManagementOrNon__c                  = copyOppty.ManagementOrNon__c;
            if(copyOppty.Supplier__c != null)                         tmpObj.Supplier__c                         = copyOppty.Supplier__c;
            if(copyOppty.Regional_Headquarters__c != null)            tmpObj.Regional_Headquarters__c            = copyOppty.Regional_Headquarters__c;
            if(copyOppty.opportunity_report__c != null)               tmpObj.weekly_opportunity_expect_report__c = copyOppty.opportunity_report__c;
            if(copyOppty.Numberofstore__c != null)                    tmpObj.Numberofstore__c                    = copyOppty.Numberofstore__c;
            if(copyOppty.Gross_Profit_rate__c != null)                tmpObj.weekly_profitgross_percent__c       = copyOppty.Gross_Profit_rate__c;
            if(copyOppty.amount_occur_date__c != null)                tmpObj.amount_occur_date__c                = copyOppty.amount_occur_date__c;
            if(copyOppty.security_robot_date__c != null)              tmpObj.security_robot_date__c              = copyOppty.security_robot_date__c;
            if(copyOppty.ServiceForm__c != null)                      tmpObj.ServiceForm__c                      = copyOppty.ServiceForm__c;
            if(copyOppty.Location__c != null)                         tmpObj.Location__c                         = copyOppty.Location__c;
            if(copyOppty.Possibility_of_closed_won__c != null)        tmpObj.Possibility_of_closed_won__c        = copyOppty.Possibility_of_closed_won__c;
            if(copyOppty.Annual_sales_accrual_amount__c != null   )   tmpObj.Annual_sales_accrual_amount__c      = copyOppty.Annual_sales_accrual_amount__c;
            if(copyOppty.Type != null)                                tmpObj.Type__c                             = copyOppty.Type;
            if(copyOppty.Check_sales_target__c != null)               tmpObj.Check_sales_target__c               = copyOppty.Check_sales_target__c;
            if(copyOppty.Id != null)                                  tmpObj.Opportunity_actual__c               = copyOppty.Id;
            if(copyOppty.Reason_of_nontarget__c != null)              tmpObj.Reason_of_nontarget__c              = copyOppty.Reason_of_nontarget__c;
            if(copyOppty.Estimated_contract_date__c != null)          tmpObj.Estimated_contract_date__c          = copyOppty.Estimated_contract_date__c;
            if(copyOppty.estimatedorederamount__c != null)            tmpObj.estimatedorederamount__c            = copyOppty.estimatedorederamount__c;
            if(copyOppty.Expect_date_of_closed__c != null)            tmpObj.Expect_date_of_closed__c            = copyOppty.Expect_date_of_closed__c;
            if(copyOppty.Preferred_date_of_negotiation__c != null)    tmpObj.Preferred_date_of_negotiation__c    = copyOppty.Preferred_date_of_negotiation__c;
            if(copyOppty.Number__c != null)                           tmpObj.Number__c                           = copyOppty.Number__c;
            if(copyOppty.information_route__c != null)                tmpObj.information_route__c                = copyOppty.information_route__c;
            if(copyOppty.FM__c != null)                               tmpObj.FM__c                               = copyOppty.FM__c;
            if(copyOppty.PM__c != null)                               tmpObj.PM__c                               = copyOppty.PM__c;
            if(copyOppty.ProposalPTdate__c != null)                   tmpObj.ProposalPTdate__c                   = copyOppty.ProposalPTdate__c;
            if(copyOppty.Proposalsubmissiondate__c != null)           tmpObj.Proposalsubmissiondate__c           = copyOppty.Proposalsubmissiondate__c;
            if(copyOppty.Parking_month__c != null)                    tmpObj.Parking_month__c                    = copyOppty.Parking_month__c;
            if(copyOppty.Cleaning_robot_month__c != null)             tmpObj.Cleaning_robot_month__c             = copyOppty.Cleaning_robot_month__c;
            if(copyOppty.pineapple_month__c != null)                  tmpObj.pineapple_month__c                  = copyOppty.pineapple_month__c;
            if(copyOppty.SceneName__c != null)                        tmpObj.SceneName__c                        = copyOppty.SceneName__c;
            if(copyOppty.Fieldsessiondate__c != null)                 tmpObj.Fieldsessiondate__c                 = copyOppty.Fieldsessiondate__c;
            if(copyOppty.FMcompany__c != null)                        tmpObj.FMcompany__c                        = copyOppty.FMcompany__c;
            if(copyOppty.PMcompany__c != null)                        tmpObj.PMcompany__c                        = copyOppty.PMcompany__c;
            if(copyOppty.VRB_1__c != null)                            tmpObj.VRB_1__c                            = copyOppty.VRB_1__c;
            if(copyOppty.VRB_2__c != null)                            tmpObj.VRB_2__c                            = copyOppty.VRB_2__c;
            if(copyOppty.FM_etc__c != null)                           tmpObj.FM_etc__c                           = copyOppty.FM_etc__c;
            if(copyOppty.DROP_REASON__c != null)                      tmpObj.DROP_REASON__c                      = copyOppty.DROP_REASON__c;
            if(copyOppty.NewConstructionDuedate__c != null)           tmpObj.NewConstructionDuedate__c           = copyOppty.NewConstructionDuedate__c;
            if(copyOppty.purpose_etc__c != null)                      tmpObj.purpose_etc__c                      = copyOppty.purpose_etc__c;
            if(copyOppty.Department__c != null)                       tmpObj.Department__c                       = copyOppty.Department__c;
            if(copyOppty.AccountPersonInChargeName__c != null)        tmpObj.AccountPersonInChargeName__c        = copyOppty.AccountPersonInChargeName__c;
            if(copyOppty.AccountPersonInChargeEmail__c != null)       tmpObj.AccountPersonInChargeEmail__c       = copyOppty.AccountPersonInChargeEmail__c;
            if(copyOppty.AccountPersonInChargePhoneNumber__c != null) tmpObj.AccountPersonInChargePhoneNumber__c = copyOppty.AccountPersonInChargePhoneNumber__c;
            if(copyOppty.Contract_startdate__c != null)               tmpObj.Contract_startdate__c               = copyOppty.Contract_startdate__c;
            if(copyOppty.Contract_enddate__c != null)                 tmpObj.Contract_enddate__c                 = copyOppty.Contract_enddate__c;
            if(copyOppty.ContractYear__c != null)                     tmpObj.ContractYear__c                     = copyOppty.ContractYear__c;
            if(copyOppty.ContractMonth__c != null)                    tmpObj.ContractMonth__c                    = copyOppty.ContractMonth__c;
            if(copyOppty.Closing_company__c != null)                  tmpObj.Closing_company__c                  = copyOppty.Closing_company__c;
            if(copyOppty.Closing_company_etc__c != null)              tmpObj.Closing_company_etc__c              = copyOppty.Closing_company_etc__c;
            if(copyOppty.Lessons_Learned__c != null)                  tmpObj.Lessons_Learned__c                  = copyOppty.Lessons_Learned__c;
            if(copyOppty.Estimated_contract_period__c != null)        tmpObj.Estimated_contract_period__c        = copyOppty.Estimated_contract_period__c;

            //추가
            if(copyOppty.recordtype__c != null)                       tmpObj.recordtype__c                       = copyOppty.recordtype__c;
            if(copyOppty.parent_Opportunity__c != null)               tmpObj.parent_Opportunity__c               = copyOppty.parent_Opportunity__c;
            if(copyOppty.Type2__c != null)                            tmpObj.Type2__c                            = copyOppty.Type2__c;
            if(copyOppty.purpose__c != null)                          tmpObj.purpose__c                          = copyOppty.purpose__c;
            if(copyOppty.WBS_CC__c != null)                           tmpObj.WBS_CC__c                           = copyOppty.WBS_CC__c;

            //마감필드 추가
            if(copyOppty.Drop_stage__c != null)                       tmpObj.Drop_stage__c                       = copyOppty.Drop_stage__c;
            if(copyOppty.Status__c != null)                           tmpObj.Status__c                           = copyOppty.Status__c;
            if(copyOppty.Totalmonthlyamount__c != null)               tmpObj.Totalmonthlyamount__c               = copyOppty.Totalmonthlyamount__c;

            //추가....
            if(copyOppty.StoreExclude__c != null)                     tmpObj.StoreExclude__c                     = copyOppty.StoreExclude__c; //지점 제외
            if(copyOppty.Child_opportunity_count__c != null)          tmpObj.Child_opportunity_count__c          = copyOppty.Child_opportunity_count__c; //하위 지점 수
            if(copyOppty.TotalAmount_SumofSore__c != null)            tmpObj.TotalAmount_SumofSore__c            = copyOppty.TotalAmount_SumofSore__c; //총 매출 발생 금액(지점 합계)
            if(copyOppty.Totalmonthlyamount_Formula__c != null)       tmpObj.Totalmonthlyamount_Formula__c       = copyOppty.Totalmonthlyamount_Formula__c;
            if(copyOppty.sort__c != null)                             tmpObj.sort__c                             = copyOppty.sort__c;
            //24.03.08 Sanghee 추가필드
            if(copyOppty.Product_NPD__c != null)                      tmpObj.Product_NPD__c                      = copyOppty.Product_NPD__c;

            //매핑데이
            if(copyOppty.WBS_CC__c != null)                           tmpObj.WBS_CC__c                           = copyOppty.WBS_CC__c;
            //if(copyOppty.Responsibily_Area__c != null)                tmpObj.Responsibily_Area__c                = copyOppty.Responsibily_Area__c;
            //if(copyOppty.ZF_Code__c != null)                          tmpObj.ZF_Code__c                          = copyOppty.ZF_Code__c;
            //if(copyOppty.Opportunity_code__c != null)                 tmpObj.Opportunity_code__c                 = copyOppty.Opportunity_code__c;
            //if(copyOppty.Expect_Month_of_closed__c != null)           tmpObj.Expect_Month_of_closed__c           = copyOppty.Expect_Month_of_closed__c;
            if(copyOppty.ThisYear_total_Amount_Formula__c != null)    tmpObj.ThisYear_total_Amount_Formula__c    = copyOppty.ThisYear_total_Amount_Formula__c;
            if(copyOppty.Conversion_amount__c != null)                tmpObj.Conversion_amount__c                = copyOppty.Conversion_amount__c;
            if(copyOppty.Totalmonthlyamount_Formula__c != null)       tmpObj.Totalmonthlyamount_Formula__c       = copyOppty.Totalmonthlyamount_Formula__c;
            if(copyOppty.sort__c != null)                             tmpObj.sort__c                             = copyOppty.sort__c;
            if(copyOppty.Real_Data_check__c != null)                  tmpObj.Real_Data_check__c                  = copyOppty.Real_Data_check__c;
            if(copyOppty.Oppty_Amount_sort__c != null)                tmpObj.Oppty_Amount_sort__c                = copyOppty.Oppty_Amount_sort__c;
            if(copyOppty.UpperSort__c != null)                        tmpObj.UpperSort__c                        = copyOppty.UpperSort__c;
            if(copyOppty.Service_construction__c != null)             tmpObj.Service_construction__c             = copyOppty.Service_construction__c;
            if(copyOppty.Service_Product__c != null)                  tmpObj.Service_Product__c                  = copyOppty.Service_Product__c;
            if(copyOppty.Validation__c != null)                       tmpObj.Validation__c                       = copyOppty.Validation__c;
            if(copyOppty.Yearly_total_opportunity_amount__c != null)  tmpObj.Yearly_total_opportunity_amount__c  = copyOppty.Yearly_total_opportunity_amount__c;
            if(copyOppty.Building_Owner__c != null)                   tmpObj.Building_Owner__c                   = copyOppty.Building_Owner__c;
            if(copyOppty.information_route_etc__c != null)            tmpObj.information_route_etc__c            = copyOppty.information_route_etc__c;

            insertList.add(tmpObj);
        }

        if(insertList.size()>0) insert insertList;
    }

    /**
     * @description 마감(수주매출)로 복사
     */
    public void copyOpportunityAmount(List<SObject> scope) {
        List<Closing_opportunity_amount__c> insertList = new List<Closing_opportunity_amount__c>();

        for(Opportunity_amount__c copyOpptyAmt : (List<Opportunity_amount__c>) scope) {
            Closing_opportunity_amount__c tmpObj = new Closing_opportunity_amount__c();

            tmpObj.Closing_Weekly_date__c = this.weeklyFormat; //마감 주차
            tmpObj.Weekly__c = this.weeklyNumber; //주차
            tmpObj.Weekly_date__c = this.batchDate; //주차 일자

            //매핑
            if(copyOpptyAmt.Name != null)                           tmpObj.Name                                       = copyOpptyAmt.Name;
            if(copyOpptyAmt.AI_CCTV_month__c != null)               tmpObj.AI_CCTV_month__c                           = copyOpptyAmt.AI_CCTV_month__c;
            if(copyOpptyAmt.Budget_Confirmed__c != null)            tmpObj.Budget_Confirmed__c                        = copyOpptyAmt.Budget_Confirmed__c;
            if(copyOpptyAmt.CampaignId__c != null)                  tmpObj.CampaignId__c                              = copyOpptyAmt.CampaignId__c;
            if(copyOpptyAmt.CloseDate__c != null)                   tmpObj.CloseDate__c                               = copyOpptyAmt.CloseDate__c;
            if(copyOpptyAmt.IsClosed__c != null)                    tmpObj.IsClosed__c                                = copyOpptyAmt.IsClosed__c;
            if(copyOpptyAmt.IsDeleted__c != null)                   tmpObj.IsDeleted__c                               = copyOpptyAmt.IsDeleted__c;
            if(copyOpptyAmt.Discovery_Completed__c != null)         tmpObj.Discovery_Completed__c                     = copyOpptyAmt.Discovery_Completed__c;
            if(copyOpptyAmt.ExpectedRevenue__c != null)             tmpObj.ExpectedRevenue__c                         = copyOpptyAmt.ExpectedRevenue__c;
            if(copyOpptyAmt.Fiscal__c != null)                      tmpObj.Fiscal__c                                  = copyOpptyAmt.Fiscal__c;
            if(copyOpptyAmt.FiscalQuarter__c != null)               tmpObj.FiscalQuarter__c                           = copyOpptyAmt.FiscalQuarter__c;
            if(copyOpptyAmt.FiscalYear__c != null)                  tmpObj.FiscalYear__c                              = copyOpptyAmt.FiscalYear__c;
            if(copyOpptyAmt.ForecastCategory__c != null)            tmpObj.ForecastCategory__c                        = copyOpptyAmt.ForecastCategory__c;
            if(copyOpptyAmt.ForecastCategoryName__c != null)        tmpObj.ForecastCategoryName__c                    = copyOpptyAmt.ForecastCategoryName__c;
            if(copyOpptyAmt.HasOpportunityLineItem__c != null)      tmpObj.HasOpportunityLineItem__c                  = copyOpptyAmt.HasOpportunityLineItem__c;
            if(copyOpptyAmt.HasOpenActivity__c != null)             tmpObj.HasOpenActivity__c                         = copyOpptyAmt.HasOpenActivity__c;
            if(copyOpptyAmt.HasOverdueTask__c != null)              tmpObj.HasOverdueTask__c                          = copyOpptyAmt.HasOverdueTask__c;
            if(copyOpptyAmt.LeadSource__c != null)                  tmpObj.LeadSource__c                              = copyOpptyAmt.LeadSource__c;
            if(copyOpptyAmt.Loss_Reason__c != null)                 tmpObj.Loss_Reason__c                             = copyOpptyAmt.Loss_Reason__c;
            if(copyOpptyAmt.NextStep__c != null)                    tmpObj.NextStep__c                                = copyOpptyAmt.NextStep__c;
            if(copyOpptyAmt.Parent_Opportunity__c != null)          tmpObj.Parent_Opportunity__c                      = copyOpptyAmt.Parent_Opportunity__c;
            if(copyOpptyAmt.Pricebook2Id__c != null)                tmpObj.Pricebook2Id__c                            = copyOpptyAmt.Pricebook2Id__c;
            if(copyOpptyAmt.IsPrivate__c != null)                   tmpObj.IsPrivate__c                               = copyOpptyAmt.IsPrivate__c;
            if(copyOpptyAmt.Probability__c != null)                 tmpObj.Probability__c                             = copyOpptyAmt.Probability__c;
            if(copyOpptyAmt.ProductDivision__c != null)             tmpObj.ProductDivision__c                         = copyOpptyAmt.ProductDivision__c;
            if(copyOpptyAmt.TotalOpportunityQuantity__c != null)    tmpObj.TotalOpportunityQuantity__c                = copyOpptyAmt.TotalOpportunityQuantity__c;
            if(copyOpptyAmt.SyncedQuoteId__c != null)               tmpObj.SyncedQuoteId__c                           = copyOpptyAmt.SyncedQuoteId__c;
            if(copyOpptyAmt.RFPdate__c != null)                     tmpObj.RFPdate__c                                 = copyOpptyAmt.RFPdate__c;
            if(copyOpptyAmt.RMS_month__c != null)                   tmpObj.RMS_month__c                               = copyOpptyAmt.RMS_month__c;
            if(copyOpptyAmt.ROI_Analysis_Completed__c != null)      tmpObj.ROI_Analysis_Completed__c                  = copyOpptyAmt.ROI_Analysis_Completed__c;
            if(copyOpptyAmt.WIN_LOSS_reason__c != null)             tmpObj.WIN_LOSS_reason__c                         = copyOpptyAmt.WIN_LOSS_reason__c;
            if(copyOpptyAmt.IsWon__c != null)                       tmpObj.IsWon__c                                   = copyOpptyAmt.IsWon__c;
            if(copyOpptyAmt.WBS_CC__c != null)                      tmpObj.WBS_CC__c                                  = copyOpptyAmt.WBS_CC__c;
            if(copyOpptyAmt.feet__c != null)                        tmpObj.feet__c                                    = copyOpptyAmt.feet__c;
            if(copyOpptyAmt.purpose__c != null)                     tmpObj.purpose__c                                 = copyOpptyAmt.purpose__c;
            if(copyOpptyAmt.construct_type__c != null)              tmpObj.construct_type__c                          = copyOpptyAmt.construct_type__c;
            if(copyOpptyAmt.Architecturaltype__c != null)           tmpObj.Architecturaltype__c                       = copyOpptyAmt.Architecturaltype__c;
            if(copyOpptyAmt.Competitors__c != null)                 tmpObj.Competitors__c                             = copyOpptyAmt.Competitors__c;
            if(copyOpptyAmt.Competitors_etc__c != null)             tmpObj.Competitors_etc__c                         = copyOpptyAmt.Competitors_etc__c;
            if(copyOpptyAmt.ContractMethod__c != null)              tmpObj.ContractMethod__c                          = copyOpptyAmt.ContractMethod__c;
            if(copyOpptyAmt.Amount__c != null)                      tmpObj.Amount__c                                  = copyOpptyAmt.Amount__c;
            if(copyOpptyAmt.contract_closingdate__c != null)        tmpObj.contract_closingdate__c                    = copyOpptyAmt.contract_closingdate__c;
            if(copyOpptyAmt.AccountId__c != null)                   tmpObj.AccountId__c                               = copyOpptyAmt.AccountId__c;
            if(copyOpptyAmt.air_quality_month__c != null)           tmpObj.air_quality_month__c                       = copyOpptyAmt.air_quality_month__c;
            if(copyOpptyAmt.Construction__c != null)                tmpObj.Construction__c                            = copyOpptyAmt.Construction__c;
            if(copyOpptyAmt.ManagementOrNon__c != null)             tmpObj.ManagementOrNon__c                         = copyOpptyAmt.ManagementOrNon__c;
            if(copyOpptyAmt.Supplier__c != null)                    tmpObj.Supplier__c                                = copyOpptyAmt.Supplier__c;
            if(copyOpptyAmt.Regional_Headquarters__c != null)       tmpObj.Regional_Headquarters__c                   = copyOpptyAmt.Regional_Headquarters__c;
            if(copyOpptyAmt.Opportunity_amount_report__c != null)   tmpObj.weekly_opportunity_amount_expect_report__c = copyOpptyAmt.Opportunity_amount_report__c;
            if(copyOpptyAmt.Numberofstore__c != null)               tmpObj.Numberofstore__c                           = copyOpptyAmt.Numberofstore__c;
            if(copyOpptyAmt.security_robot_date__c != null)         tmpObj.security_robot_date__c                     = copyOpptyAmt.security_robot_date__c;
            if(copyOpptyAmt.ServiceForm__c != null)                 tmpObj.ServiceForm__c                             = copyOpptyAmt.ServiceForm__c;
            if(copyOpptyAmt.Description__c != null)                 tmpObj.Description__c                             = copyOpptyAmt.Description__c;
            if(copyOpptyAmt.Location__c != null)                    tmpObj.Location__c                                = copyOpptyAmt.Location__c;
            if(copyOpptyAmt.Opportunityname__c != null)             tmpObj.Opportunityname__c                         = copyOpptyAmt.Opportunityname__c;
            if(copyOpptyAmt.Annual_sales_accrual_amount__c != null) tmpObj.Annual_sales_accrual_amount__c             = copyOpptyAmt.Annual_sales_accrual_amount__c;
            if(copyOpptyAmt.CalculateDate__c != null)               tmpObj.CalculateDate__c                           = copyOpptyAmt.CalculateDate__c;
            if(copyOpptyAmt.Recordtype__c != null)                  tmpObj.Recordtype__c                              = copyOpptyAmt.Recordtype__c;
            if(copyOpptyAmt.Monthly_amount__c != null)              tmpObj.Monthly_amount__c                          = copyOpptyAmt.Monthly_amount__c;

            //formula                                                text                                               formula
            if(copyOpptyAmt.Type2f__c != null)                       tmpObj.Type2__c                                   = copyOpptyAmt.Type2f__c;
            if(copyOpptyAmt.Possibility_of_closed_wonf__c != null)   tmpObj.Possibility_of_closed_won__c               = copyOpptyAmt.Possibility_of_closed_wonf__c;
            if(copyOpptyAmt.StageNamef__c != null)                   tmpObj.StageName__c                               = copyOpptyAmt.StageNamef__c;
            if(copyOpptyAmt.Gross_Profit_rate__c != null)            tmpObj.weekly_profitgross_percent__c              = copyOpptyAmt.Gross_Profit_rate__c;
            if(copyOpptyAmt.Gross_Profit__c != null)                 tmpObj.weekly_profitgross1_oppty__c               = copyOpptyAmt.Gross_Profit__c;
            if(copyOpptyAmt.Expect_date_of_closedf__c != null)       tmpObj.Expect_date_of_closed__c                   = copyOpptyAmt.Expect_date_of_closedf__c;
            if(copyOpptyAmt.estimatedorederamountf__c != null)       tmpObj.estimatedorederamount__c                   = copyOpptyAmt.estimatedorederamountf__c;
            if(copyOpptyAmt.amount_occur_datef__c != null)           tmpObj.amount_occur_date__c                       = copyOpptyAmt.amount_occur_datef__c;
            if(copyOpptyAmt.Annual_sales_accrual_amountf__c != null) tmpObj.Annual_sales_accrual_amount__c             = copyOpptyAmt.Annual_sales_accrual_amountf__c;

            //추가....
            if(copyOpptyAmt.StoreExclude__c != null)                 tmpObj.StoreExclude__c                            = copyOpptyAmt.StoreExclude__c; //지점 제외
            if(copyOpptyAmt.Month_Amount_report__c != null)          tmpObj.Month_Amount_report__c                     = copyOpptyAmt.Month_Amount_report__c; //월 매출 금액(레포트용)

            //매핑데이
            if(copyOpptyAmt.Oppty_Amount_sort__c != null)            tmpObj.Oppty_Amount_sort__c                       = copyOpptyAmt.Oppty_Amount_sort__c; //수주/매출 구분
            if(copyOpptyAmt.Real_Data_check__c != null)              tmpObj.Real_Data_check__c                         = copyOpptyAmt.Real_Data_check__c; //실제 데이터 여부
            if(copyOpptyAmt.Status__c != null)                       tmpObj.Status__c                                  = copyOpptyAmt.Status__c; //상태
            if(copyOpptyAmt.OwnerId__c != null && copyOpptyAmt.OwnerId__r.IsActive) { //2023.06.07 dgchoi 조건 추가 : Active된 유저만 복제
                tmpObj.OwnerId = copyOpptyAmt.OwnerId__c;
                tmpObj.Salesreps__c = copyOpptyAmt.OwnerId__c;
            }
            if(copyOpptyAmt.information_route_etc__c != null)        tmpObj.information_route_etc__c                   = copyOpptyAmt.information_route_etc__c;

            insertList.add(tmpObj);
        }

        if(insertList.size()>0) insert insertList;
    }

    public void setWeekNumber(Date stdDate) {
        WeekNumber weekNumber = new WeekNumber(stdDate);

        String year = String.valueOf(stdDate.year()).substring(2,4);
        String month = Utilities.formatZero(weekNumber.batchMonth); //월
        String weekOfMonth = Utilities.formatZero(weekNumber.batchWeekOfMonth); //월별주차

        this.weeklyNumber = weekNumber.batchWeekOfMonth;

        this.weeklyFormat = year + '년 '
                          + month + '월 '
                          + weekOfMonth + '주차';
    }

    /*
    public void setBatchDate() {
        Batch_Setting__mdt settingMdt = [
                SELECT Label, stdDate__c
                FROM Batch_Setting__mdt
                WHERE Label = 'test'
                LIMIT 1
        ];

        this.batchDate = settingMdt.stdDate__c;
    }
     */

}