/**
 * Created by MZC01-DGCHOI on 2023-02-20.
 */

public with sharing class OpptyPerformanceCopy_ba implements Database.Batchable<SObject>, Database.Stateful {

    /*
        '실적산출' 버튼 눌러서 실적(영업수주), 실적(영업매출) 복사
     */

    public String targetAPIKey = '';
    public String copyObjLabel = '';

    public Boolean isFailed = false;
    public String ERROR_MSG = '';

    public OpptyPerformanceCopy_ba(String targetAPIKey) {
        this.targetAPIKey = targetAPIKey;
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        String query_select = getQuerySelect();

        String calDateField = '';
        String stageField = '';

        switch on this.targetAPIKey {
            when 'Opportunity' {
                //Stage : Closed Won && 계약체결시기 전월인 레코드 복제
                calDateField = 'contract_closingdate__c'; //계약체결시기
                stageField = 'StageName'; //Stage
                copyObjLabel = '실적(영업수주)'; //실적(영업수주)
            }
            when 'Opportunity_Amount__c' {
                //Stage : Closed won && 정산일자 전월인 레코드 복제
                calDateField = 'CalculateDate__c'; //정산일자
                stageField = 'StageNamef__c'; //Stage
                copyObjLabel = '실적(영업매출)'; //실적(영업매출)
            }
            when else {}
        }

        String query_where = ' WHERE ' + calDateField + ' = LAST_MONTH '
                           + ' AND ' + stageField + ' = \'Closed Won\' '
                           + ' AND StoreExclude__c = FALSE '; //지점제외 안된것만(FALSE)
        if(this.targetAPIKey == 'Opportunity') {
            query_where += ' AND Type2__c IN (\'통합\', \'단일\') '; //04.12 수주만 조건 추가
        }


        return Database.getQueryLocator(query_select + query_where);
    }

    public void execute(Database.BatchableContext context, List<SObject> scope) {

        System.debug('scope: ' + scope);
        System.debug('scope SIZE:::: ' + scope.size());

        try {
            switch on this.targetAPIKey {
                when 'Opportunity' {
                    copyOpportunity(scope);
                }
                when 'Opportunity_Amount__c' {
                    copyOpportunityAmount(scope);
                }
            }
        } catch(Exception e) {
            System.debug(e.getLineNumber());
            System.debug(e.getMessage());

            this.isFailed = true;
            this.ERROR_MSG = e.getMessage();
        }
    }

    public void finish(Database.BatchableContext context) {
        System.debug('-----------------------------------------finish------------------------------------------');

        String title = '';
        String body = '';

        if(isFailed) { //실패
            title = 'S&I: ['+ this.copyObjLabel + '] 업로드 실패';
            body = 'ObjectCopy_ba :::::: ' + this.ERROR_MSG;
        } else { //성공
            title = 'S&I: ['+ this.copyObjLabel + '] 업로드 완료';
            body = '['+ this.copyObjLabel + '] 으로 업로드 되었습니다.';
        }

        EmailController.sendEmail(title, body);
    }

    public String getQuerySelect() {
        SObjectType sObjType = ((SObject) Type.forName(this.targetAPIKey).newInstance())
                                    .getSObjectType();

        Set<String> fields = sObjType.getDescribe().fields.getMap().keySet();
        String query_select = ' SELECT ' + String.join((Iterable<String>)fields, ',');

        //2023.06.07 dgchoi 소유자(유저) 필드 조회 추가
        switch on this.targetAPIKey {
            when 'Opportunity' {
                query_select += ' , Owner.IsActive ';
            }
            when 'Opportunity_Amount__c' {
                query_select += ' , Opportunityname__r.Opportunity_code__c, OwnerId__r.IsActive ';
            }
            when else {}
        }

//        if(this.targetAPIKey == 'Opportunity_Amount__c') {
//            query_select += ' , Opportunityname__r.Opportunity_code__c ';
//        }

        query_select += ' FROM ' + sObjType;

        return query_select;
    }

    public void copyOpportunity(List<sObject> scope) {
        List<opportunity_Performance__c> upsertList = new List<opportunity_Performance__c>();

        for(Opportunity copyOppty : (List<Opportunity>) scope) {
            //영업물건관리 - 실적(영업수주) 매핑
            opportunity_Performance__c tmpObj = new opportunity_Performance__c();
            tmpObj.Oppty_Performance_External_ID__c = copyOppty.Opportunity_code__c + '-'  //수주코드-계약체결시기년도-계약체결시기월
                                                    + copyOppty.contract_closingdate__c.year() + '-'
                                                    + copyOppty.contract_closingdate__c.month();

            //매핑
            if(copyOppty.OwnerId != null && copyOppty.Owner.IsActive) {
                tmpObj.OwnerId = copyOppty.OwnerId;
                tmpObj.Salesreps__c = copyOppty.OwnerId;
            }
            if(copyOppty.Name != null)                                tmpObj.Name                                = copyOppty.Name;
            if(copyOppty.AccountId != null)                           tmpObj.AccountId__c                        = copyOppty.AccountId;
            if(copyOppty.Budget_Confirmed__c != null)                 tmpObj.Budget_Confirmed__c                 = copyOppty.Budget_Confirmed__c;
            if(copyOppty.CloseDate != null)                           tmpObj.CloseDate__c                        = copyOppty.CloseDate;
            if(copyOppty.CampaignId != null)                          tmpObj.CampaignId__c                       = copyOppty.CampaignId;
            //IsClosed__c
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
            if(copyOppty.ROI_Analysis_Completed__c != null)           tmpObj.ROI_Analysis_Completed__c           = copyOppty.ROI_Analysis_Completed__c;
            if(copyOppty.StageName != null)                           tmpObj.StageName__c                        = copyOppty.StageName;
            if(copyOppty.WIN_LOSS_reason__c != null)                  tmpObj.WIN_LOSS_reason__c                  = copyOppty.WIN_LOSS_reason__c;
            if(copyOppty.Competitors__c != null)                      tmpObj.Competitors__c                      = copyOppty.Competitors__c;
            if(copyOppty.Competitors_etc__c != null)                  tmpObj.Competitors_etc__c                  = copyOppty.Competitors_etc__c;
            if(copyOppty.ContractMethod__c != null)                   tmpObj.ContractMethod__c                   = copyOppty.ContractMethod__c;
            if(copyOppty.Amount != null)                              tmpObj.Amount__c                           = copyOppty.Amount;
            if(copyOppty.contract_closingdate__c != null)             tmpObj.contract_closingdate__c             = copyOppty.contract_closingdate__c;
            if(copyOppty.Construction__c != null)                     tmpObj.Construction__c                     = copyOppty.Construction__c;
            if(copyOppty.ManagementOrNon__c != null)                  tmpObj.ManagementOrNon__c                  = copyOppty.ManagementOrNon__c;
            if(copyOppty.Supplier__c != null)                         tmpObj.Supplier__c                         = copyOppty.Supplier__c;
            if(copyOppty.Regional_Headquarters__c != null)            tmpObj.Regional_Headquarters__c            = copyOppty.Regional_Headquarters__c;
            if(copyOppty.opportunity_report__c != null)               tmpObj.Opportunity_actionplan_report__c    = copyOppty.opportunity_report__c;
            if(copyOppty.Gross_Profit_rate__c != null)                tmpObj.ActionPlan_GrossProfit_Percent__c   = copyOppty.Gross_Profit_rate__c;
            if(copyOppty.amount_occur_date__c != null)                tmpObj.amount_occur_date__c                = copyOppty.amount_occur_date__c;
            if(copyOppty.ServiceForm__c != null)                      tmpObj.ServiceForm__c                      = copyOppty.ServiceForm__c;
            if(copyOppty.Possibility_of_closed_won__c != null)        tmpObj.Possibility_of_closed_won__c        = copyOppty.Possibility_of_closed_won__c;
            if(copyOppty.Annual_sales_accrual_amount__c != null)      tmpObj.Annual_sales_accrual_amount__c      = copyOppty.Annual_sales_accrual_amount__c;
            if(copyOppty.Type != null)                                tmpObj.Type__c                             = copyOppty.Type;
            if(copyOppty.Check_sales_target__c != null)               tmpObj.Check_sales_target__c               = copyOppty.Check_sales_target__c;
            if(copyOppty.Id != null)                                  tmpObj.Opportunity_actual__c               = copyOppty.Id;
            if(copyOppty.Reason_of_nontarget__c != null)              tmpObj.Reason_of_nontarget__c              = copyOppty.Reason_of_nontarget__c;
            if(copyOppty.estimatedorederamount__c != null)            tmpObj.estimatedorederamount__c            = copyOppty.estimatedorederamount__c;
            if(copyOppty.Expect_date_of_closed__c != null)            tmpObj.Expect_date_of_closed__c            = copyOppty.Expect_date_of_closed__c;
            if(copyOppty.Number__c != null)                           tmpObj.Number__c                           = copyOppty.Number__c;
            if(copyOppty.information_route__c != null)                tmpObj.information_route__c                = copyOppty.information_route__c;
            if(copyOppty.SceneName__c != null)                        tmpObj.SceneName__c                        = copyOppty.SceneName__c;
            if(copyOppty.Parent_Opportunity__c != null)               tmpObj.Parent_Opportunity__c               = copyOppty.Parent_Opportunity__c;
            if(copyOppty.Type2__c != null)                            tmpObj.Type2__c                            = copyOppty.Type2__c;
            if(copyOppty.WBS_CC__c != null)                           tmpObj.WBS_CC__c                           = copyOppty.WBS_CC__c; //zf구분이 wbs인가여
            if(copyOppty.FMcompany__c != null)                        tmpObj.FMcompany__c                        = copyOppty.FMcompany__c;
            if(copyOppty.PMcompany__c != null)                        tmpObj.PMcompany__c                        = copyOppty.PMcompany__c;
            if(copyOppty.DROP_REASON__c != null)                      tmpObj.DROP_REASON__c                      = copyOppty.DROP_REASON__c;
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

            //마감필드 추가
            if(copyOppty.Drop_stage__c != null)                       tmpObj.Drop_stage__c                       = copyOppty.Drop_stage__c;
            if(copyOppty.Status__c != null)                           tmpObj.Status__c                           = copyOppty.Status__c;
            if(copyOppty.Totalmonthlyamount__c != null)               tmpObj.Totalmonthlyamount__c               = copyOppty.Totalmonthlyamount__c;

            //누락매핑....
            if(copyOppty.Recordtype__c != null)                       tmpObj.Recordtype__c                       = copyOppty.Recordtype__c;

            //추가....
            if(copyOppty.StoreExclude__c != null)                     tmpObj.StoreExclude__c                     = copyOppty.StoreExclude__c; //지점 제외
            if(copyOppty.Child_opportunity_count__c != null)          tmpObj.Child_opportunity_count__c          = copyOppty.Child_opportunity_count__c; //하위 지점 수
            if(copyOppty.TotalAmount_SumofSore__c != null)            tmpObj.TotalAmount_SumofSore__c            = copyOppty.TotalAmount_SumofSore__c; //총 매출 발생 금액(지점 합계)
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

            //제공서비스
            //if(copyOppty.FM__c != null)                            tmpObj.FM__c                               = copyOppty.FM__c;
            //if(copyOppty.PM__c != null)                            tmpObj.PM__c                               = copyOppty.PM__c;
            //if(copyOppty.FM_etc__c != null)                        tmpObj.FM_etc__c                           = copyOppty.FM_etc__c;

            //VRB
            //if(copyOppty.VRB_1__c != null)                         tmpObj.VRB_1__c                            = copyOppty.VRB_1__c;
            //if(copyOppty.VRB_2__c != null)                         tmpObj.VRB_2__c                            = copyOppty.VRB_2__c;

            //입찰 일정
            //if(copyOppty.RFPdate__c != null)                       tmpObj.RFPdate__c                          = copyOppty.RFPdate__c;
            //if(copyOppty.ProposalPTdate__c != null)                tmpObj.ProposalPTdate__c                   = copyOppty.ProposalPTdate__c;
            //if(copyOppty.Fieldsessiondate__c != null)              tmpObj.Fieldsessiondate__c                 = copyOppty.Fieldsessiondate__c;
            //if(copyOppty.Preferred_date_of_negotiation__c != null) tmpObj.Preferred_date_of_negotiation__c    = copyOppty.Preferred_date_of_negotiation__c;
            //if(copyOppty.Proposalsubmissiondate__c != null)        tmpObj.Proposalsubmissiondate__c           = copyOppty.Proposalsubmissiondate__c;
            //if(copyOppty.Estimated_contract_date__c != null)       tmpObj.Estimated_contract_date__c          = copyOppty.Estimated_contract_date__c;

            //서비스공급계획
            //if(copyOppty.RMS_month__c != null)                     tmpObj.RMS_month__c                        = copyOppty.RMS_month__c;
            //if(copyOppty.AI_CCTV_month__c != null)                 tmpObj.AI_CCTV_month__c                    = copyOppty.AI_CCTV_month__c;
            //if(copyOppty.Parking_month__c != null)                 tmpObj.Parking_month__c                    = copyOppty.Parking_month__c;
            //if(copyOppty.security_robot_date__c != null)           tmpObj.security_robot_date__c              = copyOppty.security_robot_date__c;
            //if(copyOppty.pineapple_month__c != null)               tmpObj.pineapple_month__c                  = copyOppty.pineapple_month__c;
            //if(copyOppty.Cleaning_robot_month__c != null)          tmpObj.Cleaning_robot_month__c             = copyOppty.Cleaning_robot_month__c;
            //if(copyOppty.air_quality_month__c != null)             tmpObj.air_quality_month__c                = copyOppty.air_quality_month__c;

            //건물/매장 정보
            //if(copyOppty.Architecturaltype__c != null)             tmpObj.Architecturaltype__c                = copyOppty.Architecturaltype__c;
            //if(copyOppty.feet__c != null)                          tmpObj.feet__c                             = copyOppty.feet__c;
            //if(copyOppty.construct_type__c != null)                tmpObj.construct_type__c                   = copyOppty.construct_type__c;
            //if(copyOppty.purpose__c != null)                       tmpObj.purpose__c                          = copyOppty.purpose__c;
            //if(copyOppty.purpose_etc__c != null)                   tmpObj.purpose_etc__c                      = copyOppty.purpose_etc__c;
            //if(copyOppty.NewConstructionDuedate__c != null)        tmpObj.NewConstructionDuedate__c           = copyOppty.NewConstructionDuedate__c;
            //if(copyOppty.Numberofstore__c != null)                 tmpObj.Numberofstore__c                    = copyOppty.Numberofstore__c;
            //if(copyOppty.Location__c != null)                      tmpObj.Location__c                         = copyOppty.Location__c;

            /*
            if(copyOppty.StageName == 'Closed Won') {
                //계약금액 복제
                if(copyOppty.Amount != null)                         tmpObj.Amount__c                           = copyOppty.Amount;
            } else {
                //계약금액 0
                tmpObj.Amount__c = 0;
            }
             */

            upsertList.add(tmpObj);
        }

        upsert upsertList Oppty_Performance_External_ID__c;
    }

    public void copyOpportunityAmount(List<sObject> scope) {
        List<opportunity_amount_Performance__c> upsertList = new List<opportunity_amount_Performance__c>();

        for(Opportunity_Amount__c copyOpptyAmt : (List<Opportunity_Amount__c>) scope) {
            //영업매출현황 - 실적(영업매출) 매핑
            opportunity_amount_Performance__c tmpObj = new opportunity_amount_Performance__c();
            tmpObj.Oppty_Amount_Performance_External_ID__c = copyOpptyAmt.OpportunityName__r.Opportunity_code__c + '-'
                                                           + copyOpptyAmt.CalculateDate__c.year() + '-'
                                                           + copyOpptyAmt.CalculateDate__c.month() ; //수주코드-매출발생시기년도-매출발생시기월

            //매핑
            if(copyOpptyAmt.Name != null)                            tmpObj.Name                                       = copyOpptyAmt.Name;
            if(copyOpptyAmt.AI_CCTV_month__c != null)                tmpObj.AI_CCTV_month__c                           = copyOpptyAmt.AI_CCTV_month__c;
            if(copyOpptyAmt.Budget_Confirmed__c != null)             tmpObj.Budget_Confirmed__c                        = copyOpptyAmt.Budget_Confirmed__c;
            if(copyOpptyAmt.CampaignId__c != null)                   tmpObj.CampaignId__c                              = copyOpptyAmt.CampaignId__c;
            if(copyOpptyAmt.CloseDate__c != null)                    tmpObj.CloseDate__c                               = copyOpptyAmt.CloseDate__c;
            if(copyOpptyAmt.IsClosed__c != null)                     tmpObj.IsClosed__c                                = copyOpptyAmt.IsClosed__c;
            if(copyOpptyAmt.IsDeleted__c != null)                    tmpObj.IsDeleted__c                               = copyOpptyAmt.IsDeleted__c;
            if(copyOpptyAmt.Discovery_Completed__c != null)          tmpObj.Discovery_Completed__c                     = copyOpptyAmt.Discovery_Completed__c;
            if(copyOpptyAmt.ExpectedRevenue__c != null)              tmpObj.ExpectedRevenue__c                         = copyOpptyAmt.ExpectedRevenue__c;
            if(copyOpptyAmt.Fiscal__c != null)                       tmpObj.Fiscal__c                                  = copyOpptyAmt.Fiscal__c;
            if(copyOpptyAmt.FiscalQuarter__c != null)                tmpObj.FiscalQuarter__c                           = copyOpptyAmt.FiscalQuarter__c;
            if(copyOpptyAmt.FiscalYear__c != null)                   tmpObj.FiscalYear__c                              = copyOpptyAmt.FiscalYear__c;
            if(copyOpptyAmt.ForecastCategory__c != null)             tmpObj.ForecastCategory__c                        = copyOpptyAmt.ForecastCategory__c;
            if(copyOpptyAmt.ForecastCategoryName__c != null)         tmpObj.ForecastCategoryName__c                    = copyOpptyAmt.ForecastCategoryName__c;
            if(copyOpptyAmt.HasOpportunityLineItem__c != null)       tmpObj.HasOpportunityLineItem__c                  = copyOpptyAmt.HasOpportunityLineItem__c;
            if(copyOpptyAmt.HasOpenActivity__c != null)              tmpObj.HasOpenActivity__c                         = copyOpptyAmt.HasOpenActivity__c;
            if(copyOpptyAmt.HasOverdueTask__c != null)               tmpObj.HasOverdueTask__c                          = copyOpptyAmt.HasOverdueTask__c;
            if(copyOpptyAmt.LeadSource__c != null)                   tmpObj.LeadSource__c                              = copyOpptyAmt.LeadSource__c;
            if(copyOpptyAmt.Loss_Reason__c != null)                  tmpObj.Loss_Reason__c                             = copyOpptyAmt.Loss_Reason__c;
            if(copyOpptyAmt.NextStep__c != null)                     tmpObj.NextStep__c                                = copyOpptyAmt.NextStep__c;
            if(copyOpptyAmt.Parent_Opportunity__c != null)           tmpObj.parent_Opportunity__c                      = copyOpptyAmt.Parent_Opportunity__c;
            if(copyOpptyAmt.Pricebook2Id__c != null)                 tmpObj.Pricebook2Id__c                            = copyOpptyAmt.Pricebook2Id__c;
            if(copyOpptyAmt.IsPrivate__c != null)                    tmpObj.IsPrivate__c                               = copyOpptyAmt.IsPrivate__c;
            if(copyOpptyAmt.Probability__c != null)                  tmpObj.Probability__c                             = copyOpptyAmt.Probability__c;
            if(copyOpptyAmt.ProductDivision__c != null)              tmpObj.ProductDivision__c                         = copyOpptyAmt.ProductDivision__c;
            if(copyOpptyAmt.TotalOpportunityQuantity__c != null)     tmpObj.TotalOpportunityQuantity__c                = copyOpptyAmt.TotalOpportunityQuantity__c;
            if(copyOpptyAmt.SyncedQuoteId__c != null)                tmpObj.SyncedQuoteId__c                           = copyOpptyAmt.SyncedQuoteId__c;
            if(copyOpptyAmt.RFPdate__c != null)                      tmpObj.RFPdate__c                                 = copyOpptyAmt.RFPdate__c;
            if(copyOpptyAmt.RMS_month__c != null)                    tmpObj.RMS_month__c                               = copyOpptyAmt.RMS_month__c;
            if(copyOpptyAmt.ROI_Analysis_Completed__c != null)       tmpObj.ROI_Analysis_Completed__c                  = copyOpptyAmt.ROI_Analysis_Completed__c;
            if(copyOpptyAmt.WIN_LOSS_reason__c != null)              tmpObj.WIN_LOSS_reason__c                         = copyOpptyAmt.WIN_LOSS_reason__c;
            if(copyOpptyAmt.IsWon__c != null)                        tmpObj.IsWon__c                                   = copyOpptyAmt.IsWon__c;
            if(copyOpptyAmt.WBS_CC__c != null)                       tmpObj.WBS_CC__c                                  = copyOpptyAmt.WBS_CC__c;
            if(copyOpptyAmt.feet__c != null)                         tmpObj.feet__c                                    = copyOpptyAmt.feet__c;
            if(copyOpptyAmt.purpose__c != null)                      tmpObj.purpose__c                                 = copyOpptyAmt.purpose__c;
            if(copyOpptyAmt.construct_type__c != null)               tmpObj.construct_type__c                          = copyOpptyAmt.construct_type__c;
            if(copyOpptyAmt.Architecturaltype__c != null)            tmpObj.Architecturaltype__c                       = copyOpptyAmt.Architecturaltype__c;
            if(copyOpptyAmt.Competitors__c != null)                  tmpObj.Competitors__c                             = copyOpptyAmt.Competitors__c;
            if(copyOpptyAmt.Competitors_etc__c != null)              tmpObj.Competitors_etc__c                         = copyOpptyAmt.Competitors_etc__c;
            if(copyOpptyAmt.ContractMethod__c != null)               tmpObj.ContractMethod__c                          = copyOpptyAmt.ContractMethod__c;
            if(copyOpptyAmt.contract_closingdate__c != null)         tmpObj.contract_closingdate__c                    = copyOpptyAmt.contract_closingdate__c;
            if(copyOpptyAmt.AccountId__c != null)                    tmpObj.AccountId__c                               = copyOpptyAmt.AccountId__c;
            if(copyOpptyAmt.air_quality_month__c != null)            tmpObj.air_quality_month__c                       = copyOpptyAmt.air_quality_month__c;
            if(copyOpptyAmt.Construction__c != null)                 tmpObj.Construction__c                            = copyOpptyAmt.Construction__c;
            if(copyOpptyAmt.ManagementOrNon__c != null)              tmpObj.ManagementOrNon__c                         = copyOpptyAmt.ManagementOrNon__c;
            if(copyOpptyAmt.Supplier__c != null)                     tmpObj.Supplier__c                                = copyOpptyAmt.Supplier__c;
            if(copyOpptyAmt.Regional_Headquarters__c != null)        tmpObj.Regional_Headquarters__c                   = copyOpptyAmt.Regional_Headquarters__c;
            if(copyOpptyAmt.Opportunity_amount_report__c != null)    tmpObj.Opportunity_amoun_actionplan_report__c     = copyOpptyAmt.Opportunity_amount_report__c;
            if(copyOpptyAmt.Numberofstore__c != null)                tmpObj.Numberofstore__c                           = copyOpptyAmt.Numberofstore__c;
            //if(copyOpptyAmt.amount_occur_date__c != null)            tmpObj.amount_occur_date__c                       = copyOpptyAmt.amount_occur_date__c;
            if(copyOpptyAmt.security_robot_date__c != null)          tmpObj.security_robot_date__c                     = copyOpptyAmt.security_robot_date__c;
            if(copyOpptyAmt.ServiceForm__c != null)                  tmpObj.ServiceForm__c                             = copyOpptyAmt.ServiceForm__c;
            if(copyOpptyAmt.Description__c != null)                  tmpObj.Description__c                             = copyOpptyAmt.Description__c;
            if(copyOpptyAmt.Location__c != null)                     tmpObj.Location__c                                = copyOpptyAmt.Location__c;
            //if(copyOpptyAmt.OpportunityCheck__c != null)  tmpObj.O pportunityCheck__c = copyOpptyAmt.OpportunityCheck__c;
            if(copyOpptyAmt.Opportunityname__c != null)              tmpObj.Opportunityname__c                         = copyOpptyAmt.Opportunityname__c;
            if(copyOpptyAmt.Annual_sales_accrual_amount__c != null)  tmpObj.Annual_sales_accrual_amount__c             = copyOpptyAmt.Annual_sales_accrual_amount__c;
            if(copyOpptyAmt.CalculateDate__c != null)                tmpObj.CalculateDate__c                           = copyOpptyAmt.CalculateDate__c;
            if(copyOpptyAmt.Recordtype__c != null)                   tmpObj.Recordtype__c                              = copyOpptyAmt.Recordtype__c;
            if(copyOpptyAmt.Monthly_amount__c != null)               tmpObj.Monthly_amount__c                          = copyOpptyAmt.Monthly_amount__c;

            //formula                                                text                                               formula
            if(copyOpptyAmt.Type2f__c != null)                       tmpObj.Type2__c                                   = copyOpptyAmt.Type2f__c;
            if(copyOpptyAmt.Possibility_of_closed_wonf__c != null)   tmpObj.Possibility_of_closed_won__c               = copyOpptyAmt.Possibility_of_closed_wonf__c;
            if(copyOpptyAmt.StageNamef__c != null)                   tmpObj.StageName__c                               = copyOpptyAmt.StageNamef__c;
            if(copyOpptyAmt.Gross_Profit_rate__c != null)            tmpObj.ActionPlan_GrossProfit_Percent__c          = copyOpptyAmt.Gross_Profit_rate__c;
            if(copyOpptyAmt.Gross_Profit__c != null)                 tmpObj.ActionPlan_GrossProfit1_oppty__c           = copyOpptyAmt.Gross_Profit__c;
            if(copyOpptyAmt.Expect_date_of_closedf__c != null)       tmpObj.Expect_date_of_closed__c                   = copyOpptyAmt.Expect_date_of_closedf__c;
            if(copyOpptyAmt.estimatedorederamountf__c != null)       tmpObj.estimatedorederamount__c                   = copyOpptyAmt.estimatedorederamountf__c;
            if(copyOpptyAmt.amount_occur_datef__c != null)           tmpObj.amount_occur_date__c                       = copyOpptyAmt.amount_occur_datef__c;
            if(copyOpptyAmt.Annual_sales_accrual_amountf__c != null) tmpObj.Annual_sales_accrual_amount__c             = copyOpptyAmt.Annual_sales_accrual_amountf__c;
            //월매출금액 복제
            if(copyOpptyAmt.Monthly_amount__c != null)               tmpObj.Monthly_amount__c                          = copyOpptyAmt.Monthly_amount__c;
            //추가...
            if(copyOpptyAmt.StoreExclude__c != null)                 tmpObj.StoreExclude__c                            = copyOpptyAmt.StoreExclude__c; //지점 제외
            if(copyOpptyAmt.Month_Amount_report__c != null)          tmpObj.Month_Amount_report__c                     = copyOpptyAmt.Month_Amount_report__c; //월 매출 금액(레포트용)
            //매핑데이
            if(copyOpptyAmt.Oppty_Amount_sort__c != null)            tmpObj.Oppty_Amount_sort__c                       = copyOpptyAmt.Oppty_Amount_sort__c; //수주/매출 구분
            if(copyOpptyAmt.Real_Data_check__c != null)              tmpObj.Real_Data_check__c                         = copyOpptyAmt.Real_Data_check__c; //실제 데이터 여부
            if(copyOpptyAmt.status__c != null)                       tmpObj.status__c                                  = copyOpptyAmt.status__c; //상태
            if(copyOpptyAmt.OwnerId__c != null && copyOpptyAmt.OwnerId__r.IsActive) { //소유자 매핑
                tmpObj.OwnerId = copyOpptyAmt.OwnerId__c;
                tmpObj.Salesreps__c = copyOpptyAmt.OwnerId__c;
            }
            if(copyOpptyAmt.information_route_etc__c != null)        tmpObj.information_route_etc__c                   = copyOpptyAmt.information_route_etc__c;
            if(copyOpptyAmt.Cost__c != null)                         tmpObj.Cost__c                                    = copyOpptyAmt.Cost__c;
            if(copyOpptyAmt.EBITDA__c != null)                       tmpObj.EBITDA__c                                  = copyOpptyAmt.EBITDA__c;


            /*
            if(copyOpptyAmt.StageNamef__c == 'Closed Won') {
                //월매출금액 복제
                if(copyOpptyAmt.Monthly_amount__c != null)           tmpObj.Monthly_amount__c                          = copyOpptyAmt.Monthly_amount__c;
            } else {
                //월매출금액 0
                tmpObj.Monthly_amount__c = 0;
            }
            */

            upsertList.add(tmpObj);
        }

        System.debug('upserList SIZE :::: ' + upsertList.size());
        System.debug('upserList:::: ' + upsertList);
        upsert upsertList Oppty_Amount_Performance_External_ID__c;
    }


}