/**
 * Created by MZC01-DGCHOI on 2023-12-04.
 */

/**
 * 1. 통합 모든 수주 잠재고객 필수 필드만 생성 - 잠재고객으로
   2. 통합 모든 수주 나머지 필드 업데이트 - 통합 수주명 매핑
   3. 통합 아닌 모든 수주 잠재고객 필수 필드만 생성 - 잠재고객으로
   4. 통합 아닌 모든 수주 나머지 필드 업데이트 - 통합 수주명 매핑
   5. 사업계획 Opportunity_actual__c 필드 매핑 - 매핑필드 기준으로 매핑
   6. 수주매출은 그냥 생성
 */
public with sharing class BizPlanCopyOppty_ba implements Database.Batchable<SObject>, Database.Stateful {

    public String  type         = '';
    public Boolean isIntegrated = true;
    public String  baseYear     = '';
    public Map<String, String> targetObjKeyMap = new Map<String, String>();
    public Map<String, String> copyObjKeyMap   = new Map<String, String>();

    //실패 처리
    public Boolean isFailed = false;
    public String ERROR_MSG = '';

    public BizPlanCopyOppty_ba(String type, String baseYear) {
        this.type = type;
        this.baseYear = baseYear;

        System.debug('@type :     ' + type);
        System.debug('@baseYear : ' + baseYear);

        setTargetObjKeyMap();
        setCopyObjKeyMap();
    }

    public BizPlanCopyOppty_ba(String type, Boolean isIntegrated, String baseYear) {
        this.type         = type;
        this.isIntegrated = isIntegrated;
        this.baseYear     = baseYear;

        System.debug('@type :         ' + type);
        System.debug('@isIntegrated : ' + isIntegrated);
        System.debug('@baseYear :     ' + baseYear);

        setTargetObjKeyMap();
        setCopyObjKeyMap();
    }

    /**
     * @return type별 복제 대상 오브젝트 전체 레코드
     */
    public Database.QueryLocator start(Database.BatchableContext context) {
        //where 절 추가해야할 수 있음... 내년것만 복제인지??
        String query = getQuerySelect();

        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext context, List<SObject> scope) {
        try {
            switch on this.type {
                when '수주' {
                    copyOpportunity(scope);
                }
                when '수주매출' {
                    copyOpportunityAmount(scope);
                }
            }
        } catch(Exception e) {
            this.isFailed = true;
            this.ERROR_MSG = e.getMessage();

            System.debug(e.getMessage());
            System.debug(e.getLineNumber());
        }
    }

    /**
     * @description 수주(통합) -> 수주(!통합) -> 수주매출
     */
    public void finish(Database.BatchableContext context) {
        System.debug('------------------- BizPlanCopy_ba finish() -------------------');

        String title = '';
        String body = '';

        if(!isFailed) {
            switch on this.type {
                when '수주' {
                    if(isIntegrated) { //통합 일때
                        Database.executeBatch(new BizPlanCopyOppty_ba('수주', false, this.baseYear), 500); //batchSize 는 생각하자
                    } else { //통합 아닐때
                        Database.executeBatch(new BizPlanCopyOppty_ba('수주매출', this.baseYear), 500);
                    }
                }
                when '수주매출' {
                    title = 'S&I: [사업계획(수주/수주매출)] 복제 완료';
                    body = '사업계획(수주/수주매출)] 복제 완료되었습니다.';

                    EmailController.sendEmail(title, body);
                }
            }
        } else {
            title = 'S&I: [사업계획(' + this.type + ')] 복제 실패';
            body = 'BizPlanCopy_ba :::::: ' + this.ERROR_MSG;

            EmailController.sendEmail(title, body);
        }
    }

    /**
     * @param oppPlanList 복제할 Opportunity Plan
     * @description 복제 : 사업계획(영업수주) -> 영업물건관리
     */
    public void copyOpportunity(List<SObject> oppPlanList) {
        try {
            //0. MappingCode - 사업계획 Map
            Map<String, Opportunity_plan__c> oppPlanMap = new Map<String, Opportunity_plan__c>();
            Map<String, Id> MappingCodeOppIdMap         = new Map<String, Id>(); //key: MappingCode__c, value: Opportunity Id
            Set<Id> oppPlanIdSet                        = new Set<Id>();
            Map<Id, String>  OppPlanRecordTypeMap       = Utilities.getRecordTypeDevNameBySObject('Opportunity_plan__c'); //Id - DevName
            Map<String, Id>  OppRecordTypeMap           = Utilities.getRecordTypeBySObject('Opportunity');  //DevName - Id


            for(Opportunity_plan__c oppPlan : (List<Opportunity_plan__c>) oppPlanList) {
                oppPlanMap.put(oppPlan.MappingCode__c, oppPlan);
                oppPlanIdSet.add(oppPlan.Id);
            }

            //1. 통합 모든 수주 잠재고객 필수 필드만 생성 - 잠재고객으로
            //   통합 아닌 모든 수주 잠재고객 필수 필드만 생성 - 잠재고객으로
            List<Opportunity> oppList = new List<Opportunity>();

            for(Opportunity_plan__c oppPlan : (List<Opportunity_plan__c>) oppPlanList) {
                //생성 필수 필드
                Opportunity opp = new Opportunity();
                opp.Name                         = oppPlan.Name;
                opp.WBS_CC__c                    = oppPlan.WBS_CC__c;
                opp.WBS_Code__c                  = oppPlan.WBS_Code__c;
                opp.Possibility_of_closed_won__c = oppPlan.Possibility_of_closed_won__c;
                opp.information_route__c         = oppPlan.information_route__c;
                opp.CloseDate                    = oppPlan.CloseDate__c;
                opp.MappingCode__c               = oppPlan.MappingCode__c;

                //필수필드아님. vali에 걸리는 필드
                opp.Expect_date_of_closed__c     = oppPlan.Expect_date_of_closed__c;
                opp.Estimated_contract_period__c = oppPlan.Estimated_contract_period__c;
                opp.amount_occur_date__c         = oppPlan.amount_occur_date__c;
                opp.Gross_Profit_rate__c         = oppPlan.Plan_GrossProfit_Percent__c;
                opp.estimatedorederamount__c     = oppPlan.estimatedorederamount__c;
                opp.Contract_startdate__c        = oppPlan.Contract_startdate__c;
                opp.Contract_enddate__c          = oppPlan.Contract_enddate__c;
                opp.General_p__c                 = oppPlan.General_p__c;

                opp.StageName                    = '잠재고객';

                oppList.add(opp);
            }
            if(oppList.size() > 0) insert oppList;

            //MappingCode - 영업물건관리 매핑
            for(Opportunity opp : oppList) {
                MappingCodeOppIdMap.put(opp.MappingCode__c, opp.Id);
            }

            //2. 사업계획 Opportunity_actual__c 필드 매핑 - 매핑필드 기준으로 매핑
            for(Opportunity_plan__c oppPlan : (List<Opportunity_plan__c>) oppPlanList) {
                oppPlan.Opportunity_actual__c
                        = MappingCodeOppIdMap.containsKey(oppPlan.MappingCode__c)
                        ? MappingCodeOppIdMap.get(oppPlan.MappingCode__c)
                        : null;
                System.debug(oppPlan.Opportunity_actual__c);
            }

            if(oppPlanList.size()>0) update oppPlanList;

            //3.연락처 업데이트
            updateContact();

            //4. 통합 모든 수주 나머지 필드 업데이트 - 통합 수주명 매핑
            //   통합 아닌 모든 수주 나머지 필드 업데이트 - 통합 수주명 매핑
            System.debug('@before oppList size : ' + oppList.size());
            for(Opportunity opp : oppList) {
                //지옥의 수주 매핑 (업데이트)
                Opportunity_plan__c targetPlan = oppPlanMap.get(opp.MappingCode__c);
                System.debug('targetPlan: ' + targetPlan);

                if(targetPlan.OwnerId != null && targetPlan.Owner.IsActive) {
                    opp.OwnerId      = targetPlan.OwnerId; //소유자 매핑 - Active된 유저만 복제
                }
                if(targetPlan.Name != null)                                   opp.Name                                = targetPlan.Name;
                if(targetPlan.AI_CCTV_month__c != null)                       opp.AI_CCTV_month__c                    = targetPlan.AI_CCTV_month__c;
                if(targetPlan.Budget_Confirmed__c != null)                    opp.Budget_Confirmed__c                 = targetPlan.Budget_Confirmed__c;
                if(targetPlan.Discovery_Completed__c != null)                 opp.Discovery_Completed__c              = targetPlan.Discovery_Completed__c;
                if(targetPlan.Loss_Reason__c != null)                         opp.Loss_Reason__c                      = targetPlan.Loss_Reason__c;
                if(targetPlan.ProductDivision__c != null)                     opp.ProductDivision__c                  = targetPlan.ProductDivision__c;
                if(targetPlan.RFPdate__c != null)                             opp.RFPdate__c                          = targetPlan.RFPdate__c;
                if(targetPlan.RMS_month__c != null)                           opp.RMS_month__c                        = targetPlan.RMS_month__c;
                if(targetPlan.ROI_Analysis_Completed__c != null)              opp.ROI_Analysis_Completed__c           = targetPlan.ROI_Analysis_Completed__c;
                if(targetPlan.WIN_LOSS_reason__c != null)                     opp.WIN_LOSS_reason__c                  = targetPlan.WIN_LOSS_reason__c;
                if(targetPlan.feet__c != null)                                opp.feet__c                             = targetPlan.feet__c;
                if(targetPlan.construct_type__c != null)                      opp.construct_type__c                   = targetPlan.construct_type__c;
                if(targetPlan.Architecturaltype__c != null)                   opp.Architecturaltype__c                = targetPlan.Architecturaltype__c;
                if(targetPlan.Competitors__c != null)                         opp.Competitors__c                      = targetPlan.Competitors__c;
                if(targetPlan.Competitors_etc__c != null)                     opp.Competitors_etc__c                  = targetPlan.Competitors_etc__c;
                if(targetPlan.ContractMethod__c != null)                      opp.ContractMethod__c                   = targetPlan.ContractMethod__c;
                if(targetPlan.contract_closingdate__c != null)                opp.contract_closingdate__c             = targetPlan.contract_closingdate__c;
                if(targetPlan.air_quality_month__c != null)                   opp.air_quality_month__c                = targetPlan.air_quality_month__c;
                if(targetPlan.Construction__c != null)                        opp.Construction__c                     = targetPlan.Construction__c;
                if(targetPlan.ManagementOrNon__c != null)                     opp.ManagementOrNon__c                  = targetPlan.ManagementOrNon__c;
                if(targetPlan.Supplier__c != null)                            opp.Supplier__c                         = targetPlan.Supplier__c;
                if(targetPlan.Regional_Headquarters__c != null)               opp.Regional_Headquarters__c            = targetPlan.Regional_Headquarters__c;
                if(targetPlan.Numberofstore__c != null)                       opp.Numberofstore__c                    = targetPlan.Numberofstore__c;
                if(targetPlan.amount_occur_date__c != null)                   opp.amount_occur_date__c                = targetPlan.amount_occur_date__c;
                if(targetPlan.security_robot_date__c != null)                 opp.security_robot_date__c              = targetPlan.security_robot_date__c;
                if(targetPlan.ServiceForm__c != null)                         opp.ServiceForm__c                      = targetPlan.ServiceForm__c;
                if(targetPlan.Location__c != null)                            opp.Location__c                         = targetPlan.Location__c;
                if(targetPlan.Possibility_of_closed_won__c != null)           opp.Possibility_of_closed_won__c        = targetPlan.Possibility_of_closed_won__c;
                if(targetPlan.Annual_sales_accrual_amount__c != null   )      opp.Annual_sales_accrual_amount__c      = targetPlan.Annual_sales_accrual_amount__c;
                if(targetPlan.Check_sales_target__c != null)                  opp.Check_sales_target__c               = targetPlan.Check_sales_target__c;
                if(targetPlan.Reason_of_nontarget__c != null)                 opp.Reason_of_nontarget__c              = targetPlan.Reason_of_nontarget__c;
                if(targetPlan.Estimated_contract_date__c != null)             opp.Estimated_contract_date__c          = targetPlan.Estimated_contract_date__c;
                if(targetPlan.estimatedorederamount__c != null)               opp.estimatedorederamount__c            = targetPlan.estimatedorederamount__c;
                if(targetPlan.Expect_date_of_closed__c != null)               opp.Expect_date_of_closed__c            = targetPlan.Expect_date_of_closed__c;
                if(targetPlan.Preferred_date_of_negotiation__c != null)       opp.Preferred_date_of_negotiation__c    = targetPlan.Preferred_date_of_negotiation__c;
                if(targetPlan.Number__c != null)                              opp.Number__c                           = targetPlan.Number__c;
                if(targetPlan.information_route__c != null)                   opp.information_route__c                = targetPlan.information_route__c;
                if(targetPlan.FM__c != null)                                  opp.FM__c                               = targetPlan.FM__c;
                if(targetPlan.PM__c != null)                                  opp.PM__c                               = targetPlan.PM__c;
                if(targetPlan.ProposalPTdate__c != null)                      opp.ProposalPTdate__c                   = targetPlan.ProposalPTdate__c;
                if(targetPlan.Proposalsubmissiondate__c != null)              opp.Proposalsubmissiondate__c           = targetPlan.Proposalsubmissiondate__c;
                if(targetPlan.Parking_month__c != null)                       opp.Parking_month__c                    = targetPlan.Parking_month__c;
                if(targetPlan.Cleaning_robot_month__c != null)                opp.Cleaning_robot_month__c             = targetPlan.Cleaning_robot_month__c;
                if(targetPlan.pineapple_month__c != null)                     opp.pineapple_month__c                  = targetPlan.pineapple_month__c;
                if(targetPlan.SceneName__c != null)                           opp.SceneName__c                        = targetPlan.SceneName__c;
                if(targetPlan.Fieldsessiondate__c != null)                    opp.Fieldsessiondate__c                 = targetPlan.Fieldsessiondate__c;
                if(targetPlan.FMcompany__c != null)                           opp.FMcompany__c                        = targetPlan.FMcompany__c;
                if(targetPlan.PMcompany__c != null)                           opp.PMcompany__c                        = targetPlan.PMcompany__c;
                if(targetPlan.VRB_1__c != null)                               opp.VRB_1__c                            = targetPlan.VRB_1__c;
                if(targetPlan.VRB_2__c != null)                               opp.VRB_2__c                            = targetPlan.VRB_2__c;
                if(targetPlan.FM_etc__c != null)                              opp.FM_etc__c                           = targetPlan.FM_etc__c;
                if(targetPlan.DROP_REASON__c != null)                         opp.DROP_REASON__c                      = targetPlan.DROP_REASON__c;
                if(targetPlan.NewConstructionDuedate__c != null)              opp.NewConstructionDuedate__c           = targetPlan.NewConstructionDuedate__c;
                if(targetPlan.purpose_etc__c != null)                         opp.purpose_etc__c                      = targetPlan.purpose_etc__c;
                if(targetPlan.Department__c != null)                          opp.Department__c                       = targetPlan.Department__c;
                if(targetPlan.AccountPersonInChargeName__c != null)           opp.AccountPersonInChargeName__c        = targetPlan.AccountPersonInChargeName__c;
                if(targetPlan.AccountPersonInChargeEmail__c != null)          opp.AccountPersonInChargeEmail__c       = targetPlan.AccountPersonInChargeEmail__c;
                if(targetPlan.AccountPersonInChargePhoneNumber__c != null)    opp.AccountPersonInChargePhoneNumber__c = targetPlan.AccountPersonInChargePhoneNumber__c;
                if(targetPlan.Contract_startdate__c != null)                  opp.Contract_startdate__c               = targetPlan.Contract_startdate__c;
                if(targetPlan.Contract_enddate__c != null)                    opp.Contract_enddate__c                 = targetPlan.Contract_enddate__c;
                if(targetPlan.ContractYear__c != null)                        opp.ContractYear__c                     = targetPlan.ContractYear__c;
                if(targetPlan.ContractMonth__c != null)                       opp.ContractMonth__c                    = targetPlan.ContractMonth__c;
                if(targetPlan.Closing_company__c != null)                     opp.Closing_company__c                  = targetPlan.Closing_company__c;
                if(targetPlan.Closing_company_etc__c != null)                 opp.Closing_company_etc__c              = targetPlan.Closing_company_etc__c;
                if(targetPlan.Lessons_Learned__c != null)                     opp.Lessons_Learned__c                  = targetPlan.Lessons_Learned__c;
                if(targetPlan.Estimated_contract_period__c != null)           opp.Estimated_contract_period__c        = targetPlan.Estimated_contract_period__c;
                if(targetPlan.Drop_stage__c != null)                          opp.Drop_stage__c                       = targetPlan.Drop_stage__c;
                if(targetPlan.Status__c != null)                              opp.Status__c                           = targetPlan.Status__c;
                if(targetPlan.StoreExclude__c != null)                        opp.StoreExclude__c                     = targetPlan.StoreExclude__c; //지점 제외 = targetPlan.StoreExclude__c;
                if(targetPlan.Child_opportunity_count__c != null)             opp.Child_opportunity_count__c          = targetPlan.Child_opportunity_count__c; //하위 지점 수 = targetPlan.Child_opportunity_count__c;
                if(targetPlan.TotalAmount_SumofSore__c != null)               opp.TotalAmount_SumofSore__c            = targetPlan.TotalAmount_SumofSore__c; //총 매출 발생 금액(지점 합계) = targetPlan.TotalAmount_SumofSore__c;
                if(targetPlan.WBS_CC__c != null)                              opp.WBS_CC__c                           = targetPlan.WBS_CC__c;
                if(targetPlan.Oppty_Amount_sort__c != null)                   opp.Oppty_Amount_sort__c                = targetPlan.Oppty_Amount_sort__c;
                if(targetPlan.UpperSort__c != null)                           opp.UpperSort__c                        = targetPlan.UpperSort__c;
                if(targetPlan.Service_construction__c != null)                opp.Service_construction__c             = targetPlan.Service_construction__c;
                if(targetPlan.Service_Product__c != null)                     opp.Service_Product__c                  = targetPlan.Service_Product__c;
                if(targetPlan.Building_Owner__c != null)                      opp.Building_Owner__c                   = targetPlan.Building_Owner__c;
                if(targetPlan.information_route_etc__c != null)               opp.information_route_etc__c            = targetPlan.information_route_etc__c;
                if(targetPlan.Type2__c != null)                               opp.Type2__c                            = targetPlan.Type2__c;

                //필드 이름 서로 다른거
                if(targetPlan.AccountId__c != null)                           opp.AccountId                           = targetPlan.AccountId__c;
                if(targetPlan.CloseDate__c != null)                           opp.CloseDate                           = targetPlan.CloseDate__c;
                if(targetPlan.CampaignId__c != null)                          opp.CampaignId                          = targetPlan.CampaignId__c;
                if(targetPlan.ContractId__c != null)                          opp.ContractId                          = targetPlan.ContractId__c;
                if(targetPlan.Description__c != null)                         opp.Description                         = targetPlan.Description__c;
                if(targetPlan.ForecastCategoryName__c != null)                opp.ForecastCategoryName                = targetPlan.ForecastCategoryName__c;
                if(targetPlan.ForecastCategory__c != null)                    opp.ForecastCategoryName                = targetPlan.ForecastCategory__c;
                if(targetPlan.ForecastCategory__c != null)                    opp.ForecastCategoryName                = targetPlan.ForecastCategory__c;
                if(targetPlan.LeadSource__c != null)                          opp.LeadSource                          = targetPlan.LeadSource__c;
                if(targetPlan.NextStep__c != null)                            opp.NextStep                            = targetPlan.NextStep__c;
                if(targetPlan.IsPrivate__c != null)                           opp.IsPrivate                           = targetPlan.IsPrivate__c;
                if(targetPlan.Probability__c != null)                         opp.Probability                         = targetPlan.Probability__c;
                if(targetPlan.TotalOpportunityQuantity__c != null)            opp.TotalOpportunityQuantity            = targetPlan.TotalOpportunityQuantity__c;
                if(targetPlan.StageName__c != null)                           opp.StageName                           = targetPlan.StageName__c;
                if(targetPlan.Amount__c != null)                              opp.Amount                              = targetPlan.Amount__c;
                if(targetPlan.Plan_GrossProfit_Percent__c != null)            opp.Gross_Profit_rate__c                = targetPlan.Plan_GrossProfit_Percent__c;
                if(targetPlan.Type__c != null)                                opp.Type                                = targetPlan.Type__c;

                //formula
                //if(targetPlan.ExpectedRevenue__c != null)                     opp.ExpectedRevenue                     = targetPlan.ExpectedRevenue__c;
                //if(targetPlan.ThisYear_total_Amount_Formula__c != null)       opp.ThisYear_total_Amount_Formula__c    = targetPlan.ThisYear_total_Amount_Formula__c;
                //if(targetPlan.Conversion_amount__c != null)                   opp.Conversion_amount__c                = targetPlan.Conversion_amount__c;
                //if(targetPlan.Totalmonthlyamount_Formula__c != null)          opp.Totalmonthlyamount_Formula__c       = targetPlan.Totalmonthlyamount_Formula__c;
                //if(targetPlan.Sort__c != null)                                opp.Sort__c                             = targetPlan.Sort__c;
                //if(targetPlan.Totalmonthlyamount__c != null)                  opp.Totalmonthlyamount__c               = targetPlan.Totalmonthlyamount__c;
                //if(targetPlan.stdDate__c != null)                             opp.stdDate__c                          = targetPlan.stdDate__c;
                //if(targetPlan.Validation__c != null)                          opp.Validation__c                       = targetPlan.Validation__c;
                //if(targetPlan.Yearly_total_opportunity_amount__c != null)     opp.Yearly_total_opportunity_amount__c  = targetPlan.Yearly_total_opportunity_amount__c;
                //if(targetPlan.recordtype__c != null)                          opp.recordtype__c                       = targetPlan.recordtype__c;

                //추가
                if(targetPlan.Real_Data_check__c != null)                     opp.Real_Data_check__c                  = true;
                if(targetPlan.Opportunity_plan_report__c != null)             opp.opportunity_report__c               = true;
                if(targetPlan.Parent_Opportunity__c != null)                  opp.parent_Opportunity__c               = targetPlan.Parent_Opportunity__r.Opportunity_actual__c;
                if(targetPlan.recordtype__c != null)                          opp.RecordTypeId                        = OppRecordTypeMap.get(OppPlanRecordTypeMap.get(targetPlan.RecordTypeId));
            }
            if(oppList.size() > 0) update oppList;
            System.debug('@update oppList: ' + oppList);

        } catch(Exception e) {
            this.isFailed = true;
            this.ERROR_MSG = e.getMessage();
            System.debug(e.getLineNumber());
            System.debug(e.getMessage());
        }

    }

    /**
     * @param oppAmtPlanList 복제할 Opportunity Amount Plan
     * @description 복제 : 사업계획(영업매출) -> 영업매출현황
     */
    public void copyOpportunityAmount(List<SObject> oppAmtPlanList) {
        try {
            //영업물건관리랑 매핑
            List<Opportunity_amount__c> oppAmtList = new List<Opportunity_amount__c>();
            for(opportunity_amount_plan__c oppAmtPlan : (List<opportunity_amount_plan__c>) oppAmtPlanList) {
                Opportunity_amount__c oppAmt = new Opportunity_amount__c();
                if(oppAmtPlan.Name != null)                                oppAmt.Name                            = oppAmtPlan.Name;
                if(oppAmtPlan.AI_CCTV_month__c != null)                    oppAmt.AI_CCTV_month__c                = oppAmtPlan.AI_CCTV_month__c;
                if(oppAmtPlan.Budget_Confirmed__c != null)                 oppAmt.Budget_Confirmed__c             = oppAmtPlan.Budget_Confirmed__c;
                if(oppAmtPlan.CampaignId__c != null)                       oppAmt.CampaignId__c                   = oppAmtPlan.CampaignId__c;
                if(oppAmtPlan.CloseDate__c != null)                        oppAmt.CloseDate__c                    = oppAmtPlan.CloseDate__c;
                if(oppAmtPlan.IsClosed__c != null)                         oppAmt.IsClosed__c                     = oppAmtPlan.IsClosed__c;
                if(oppAmtPlan.IsDeleted__c != null)                        oppAmt.IsDeleted__c                    = oppAmtPlan.IsDeleted__c;
                if(oppAmtPlan.Discovery_Completed__c != null)              oppAmt.Discovery_Completed__c          = oppAmtPlan.Discovery_Completed__c;
                if(oppAmtPlan.ExpectedRevenue__c != null)                  oppAmt.ExpectedRevenue__c              = oppAmtPlan.ExpectedRevenue__c;
                if(oppAmtPlan.Fiscal__c != null)                           oppAmt.Fiscal__c                       = oppAmtPlan.Fiscal__c;
                if(oppAmtPlan.FiscalQuarter__c != null)                    oppAmt.FiscalQuarter__c                = oppAmtPlan.FiscalQuarter__c;
                if(oppAmtPlan.FiscalYear__c != null)                       oppAmt.FiscalYear__c                   = oppAmtPlan.FiscalYear__c;
                if(oppAmtPlan.ForecastCategory__c != null)                 oppAmt.ForecastCategory__c             = oppAmtPlan.ForecastCategory__c;
                if(oppAmtPlan.ForecastCategoryName__c != null)             oppAmt.ForecastCategoryName__c         = oppAmtPlan.ForecastCategoryName__c;
                if(oppAmtPlan.HasOpportunityLineItem__c != null)           oppAmt.HasOpportunityLineItem__c       = oppAmtPlan.HasOpportunityLineItem__c;
                if(oppAmtPlan.HasOpenActivity__c != null)                  oppAmt.HasOpenActivity__c              = oppAmtPlan.HasOpenActivity__c;
                if(oppAmtPlan.HasOverdueTask__c != null)                   oppAmt.HasOverdueTask__c               = oppAmtPlan.HasOverdueTask__c;
                if(oppAmtPlan.LeadSource__c != null)                       oppAmt.LeadSource__c                   = oppAmtPlan.LeadSource__c;
                if(oppAmtPlan.Loss_Reason__c != null)                      oppAmt.Loss_Reason__c                  = oppAmtPlan.Loss_Reason__c;
                if(oppAmtPlan.NextStep__c != null)                         oppAmt.NextStep__c                     = oppAmtPlan.NextStep__c;
                if(oppAmtPlan.Parent_Opportunity__c != null)               oppAmt.Parent_Opportunity__c           = oppAmtPlan.Parent_Opportunity__c;
                if(oppAmtPlan.Pricebook2Id__c != null)                     oppAmt.Pricebook2Id__c                 = oppAmtPlan.Pricebook2Id__c;
                if(oppAmtPlan.IsPrivate__c != null)                        oppAmt.IsPrivate__c                    = oppAmtPlan.IsPrivate__c;
                if(oppAmtPlan.Probability__c != null)                      oppAmt.Probability__c                  = oppAmtPlan.Probability__c;
                if(oppAmtPlan.ProductDivision__c != null)                  oppAmt.ProductDivision__c              = oppAmtPlan.ProductDivision__c;
                if(oppAmtPlan.TotalOpportunityQuantity__c != null)         oppAmt.TotalOpportunityQuantity__c     = oppAmtPlan.TotalOpportunityQuantity__c;
                if(oppAmtPlan.SyncedQuoteId__c != null)                    oppAmt.SyncedQuoteId__c                = oppAmtPlan.SyncedQuoteId__c;
                if(oppAmtPlan.RFPdate__c != null)                          oppAmt.RFPdate__c                      = oppAmtPlan.RFPdate__c;
                if(oppAmtPlan.RMS_month__c != null)                        oppAmt.RMS_month__c                    = oppAmtPlan.RMS_month__c;
                if(oppAmtPlan.ROI_Analysis_Completed__c != null)           oppAmt.ROI_Analysis_Completed__c       = oppAmtPlan.ROI_Analysis_Completed__c;
                if(oppAmtPlan.WIN_LOSS_reason__c != null)                  oppAmt.WIN_LOSS_reason__c              = oppAmtPlan.WIN_LOSS_reason__c;
                if(oppAmtPlan.IsWon__c != null)                            oppAmt.IsWon__c                        = oppAmtPlan.IsWon__c;
                if(oppAmtPlan.WBS_CC__c != null)                           oppAmt.WBS_CC__c                       = oppAmtPlan.WBS_CC__c;
                if(oppAmtPlan.feet__c != null)                             oppAmt.feet__c                         = oppAmtPlan.feet__c;
                if(oppAmtPlan.purpose__c != null)                          oppAmt.purpose__c                      = oppAmtPlan.purpose__c;
                if(oppAmtPlan.construct_type__c != null)                   oppAmt.construct_type__c               = oppAmtPlan.construct_type__c;
                if(oppAmtPlan.Architecturaltype__c != null)                oppAmt.Architecturaltype__c            = oppAmtPlan.Architecturaltype__c;
                if(oppAmtPlan.Competitors__c != null)                      oppAmt.Competitors__c                  = oppAmtPlan.Competitors__c;
                if(oppAmtPlan.Competitors_etc__c != null)                  oppAmt.Competitors_etc__c              = oppAmtPlan.Competitors_etc__c;
                if(oppAmtPlan.ContractMethod__c != null)                   oppAmt.ContractMethod__c               = oppAmtPlan.ContractMethod__c;
                if(oppAmtPlan.Amount__c != null)                           oppAmt.Amount__c                       = oppAmtPlan.Amount__c;
                if(oppAmtPlan.contract_closingdate__c != null)             oppAmt.contract_closingdate__c         = oppAmtPlan.contract_closingdate__c;
                if(oppAmtPlan.AccountId__c != null)                        oppAmt.AccountId__c                    = oppAmtPlan.AccountId__c;
                if(oppAmtPlan.air_quality_month__c != null)                oppAmt.air_quality_month__c            = oppAmtPlan.air_quality_month__c;
                if(oppAmtPlan.Construction__c != null)                     oppAmt.Construction__c                 = oppAmtPlan.Construction__c;
                if(oppAmtPlan.ManagementOrNon__c != null)                  oppAmt.ManagementOrNon__c              = oppAmtPlan.ManagementOrNon__c;
                if(oppAmtPlan.Supplier__c != null)                         oppAmt.Supplier__c                     = oppAmtPlan.Supplier__c;
                if(oppAmtPlan.Regional_Headquarters__c != null)            oppAmt.Regional_Headquarters__c        = oppAmtPlan.Regional_Headquarters__c;
                if(oppAmtPlan.Numberofstore__c != null)                    oppAmt.Numberofstore__c                = oppAmtPlan.Numberofstore__c;
                if(oppAmtPlan.security_robot_date__c != null)              oppAmt.security_robot_date__c          = oppAmtPlan.security_robot_date__c;
                if(oppAmtPlan.UpperSort__c != null)                        oppAmt.UpperSort__c                    = oppAmtPlan.UpperSort__c;
                if(oppAmtPlan.ServiceForm__c != null)                      oppAmt.ServiceForm__c                  = oppAmtPlan.ServiceForm__c;
                if(oppAmtPlan.Description__c != null)                      oppAmt.Description__c                  = oppAmtPlan.Description__c;
                if(oppAmtPlan.Location__c != null)                         oppAmt.Location__c                     = oppAmtPlan.Location__c;
                if(oppAmtPlan.Annual_sales_accrual_amount__c != null)      oppAmt.Annual_sales_accrual_amount__c  = oppAmtPlan.Annual_sales_accrual_amount__c;
                if(oppAmtPlan.Type__c != null)                             oppAmt.Type__c                         = oppAmtPlan.Type__c;
                if(oppAmtPlan.CalculateDate__c != null)                    oppAmt.CalculateDate__c                = oppAmtPlan.CalculateDate__c;
                if(oppAmtPlan.Monthly_amount__c != null)                   oppAmt.Monthly_amount__c               = oppAmtPlan.Monthly_amount__c;
                if(oppAmtPlan.Oppty_Amount_sort__c != null)                oppAmt.Oppty_Amount_sort__c            = oppAmtPlan.Oppty_Amount_sort__c;


                //formula                                                  text                                   formula
                /*
                if(oppAmtPlan.Type2f__c != null)                           oppAmt.Type2f__c                       = oppAmtPlan.Type2f__c;
                if(oppAmtPlan.Possibility_of_closed_wonf__c != null)       oppAmt.Possibility_of_closed_wonf__c   = oppAmtPlan.Possibility_of_closed_wonf__c;
                if(oppAmtPlan.StageNamef__c != null)                       oppAmt.StageNamef__c                   = oppAmtPlan.StageName__c;
                if(oppAmtPlan.Plan_GrossProfit_Percent_Formula__c != null) oppAmt.Gross_Profit_rate__c            = oppAmtPlan.Plan_GrossProfit_Percent_Formula__c;
                if(oppAmtPlan.Plan_GrossProfit1_opty_Formula__c != null)   oppAmt.Gross_Profit__c                 = oppAmtPlan.Plan_GrossProfit1_opty_Formula__c;
                if(oppAmtPlan.Expect_date_of_closedf__c != null)           oppAmt.Expect_date_of_closedf__c       = oppAmtPlan.Expect_date_of_closed__c;
                if(oppAmtPlan.estimatedorederamountf__c != null)           oppAmt.estimatedorederamountf__c       = oppAmtPlan.estimatedorederamount__c;
                if(oppAmtPlan.amount_occur_datef__c != null)               oppAmt.amount_occur_datef__c           = oppAmtPlan.amount_occur_datef__c;
                if(oppAmtPlan.Annual_sales_accrual_amountf__c != null)     oppAmt.Annual_sales_accrual_amountf__c = oppAmtPlan.Annual_sales_accrual_amount__c;
                if(oppAmtPlan.StoreExclude__c != null)                     oppAmt.StoreExclude__c                 = oppAmtPlan.StoreExclude__c;
                if(oppAmtPlan.status_Formula__c != null)                   oppAmt.status__c                       = oppAmtPlan.status_Formula__c;
                if(oppAmt.information_route_etc__c != null)                oppAmt.information_route_etc__c        = oppAmtPlan.information_route_etc__c;
                if(oppAmtPlan.Recordtype_Formula__c != null)               oppAmt.Recordtype__c                   = oppAmtPlan.Recordtype_Formula__c;
                 */

                //추가
                if(oppAmtPlan.opportunity_amount_plan_report__c != null)   oppAmt.Opportunity_amount_report__c    = true;
                if(oppAmtPlan.OpportunityCheck__c != null)                 oppAmt.OpportunityCheck__c             = true;
                if(oppAmtPlan.Real_Data_check__c != null)                  oppAmt.Real_Data_check__c              = true;
                if(oppAmtPlan.MappingCode__c != null)                      oppAmt.MappingCode__c                  = oppAmtPlan.MappingCode__c;
                if(oppAmtPlan.Opportunityplan_name__c != null)             oppAmt.Opportunityname__c              = oppAmtPlan.Opportunityplan_name__r.Opportunity_actual__c; //사업계획에 매핑된 수주 매핑
                if(oppAmtPlan.Parent_Opportunity__c != null)               oppAmt.Parent_Opportunity__c           = oppAmtPlan.Parent_Opportunity__r.Opportunity_actual__c;   //사업계획에 매핑된 수주 매핑
                if(oppAmtPlan.OwnerId__c != null && oppAmt.OwnerId__r.IsActive) { //소유자 매핑 : Active된 유저만 복제
                    oppAmt.OwnerId__c = oppAmtPlan.OwnerId__c;
                }

                oppAmtList.add(oppAmt);
            }

            if(oppAmtList.size() > 0) insert oppAmtList;
        } catch (Exception e) {
            this.isFailed = true;
            this.ERROR_MSG = e.getMessage();

            System.debug(e.getLineNumber());
            System.debug(e.getMessage());
        }
    }

    public void updateContact() {
        try {
            List<Contact> updateContactList = [
                    SELECT Id, Opportunity_Plan__r.Opportunity_actual__c
                    FROM Contact
                    WHERE Opportunity_Plan__c != NULL
                    AND Opportunity__c = NULL
            ];

            for (Contact con : updateContactList) {
                con.Opportunity__c = con.Opportunity_Plan__r.Opportunity_actual__c;
            }

            if (updateContactList.size() > 0) update updateContactList;
        } catch (Exception e) {
            this.isFailed = true;
            this.ERROR_MSG = e.getMessage();

            System.debug(e.getLineNumber());
            System.debug(e.getMessage());
        }
    }

    public String getQuerySelect() { //통합수주
        String             objectKey = targetObjKeyMap.get(this.type);
        Schema.SObjectType sObjType  = Schema.getGlobalDescribe().get(objectKey);
        Set<String>        fields    = sObjType.getDescribe().fields.getMap().keySet();

        String query_select = '',
               query_where  = '';

        query_select = ' SELECT ' + String.join((Iterable<String>)fields, ',')
                     + (this.type == '수주' ? ', Owner.IsActive ' : '')
                     + (this.type == '수주매출' ? ' , Opportunityplan_name__r.Opportunity_actual__c, OwnerId__r.IsActive ' : '')
                     + ', Parent_Opportunity__r.Opportunity_actual__c '
                     + ' FROM ' + objectKey;


        System.debug('@query_select: ' + query_select);

        /**
         * 필드 구분
         * 사업계획(영업수주) : Type2__c
         * 사업계획(영업매출) : Type2f__c
         */
        String typeFieldName = '';
        switch on this.type {
            when '수주' {
                typeFieldName = 'Type2__c';
                if(this.isIntegrated) {
                    query_where = ' WHERE ' + typeFieldName + ' = \'통합\''; //통합인 경우
                } else {
                    query_where = ' WHERE ' + typeFieldName + ' != \'통합\''; //통합이 아닌 경우
                }
                query_where += ' AND BaseYear__c = \'' + this.baseYear + '\'';
            }
            when '수주매출' {
                query_where = ' WHERE BaseYear__c = \'' + this.baseYear + '\'';
            }
        }

        return query_select + query_where;
    }

    /**
     * @description 복제 대상 ObjectKey 매핑
     */
    public void setTargetObjKeyMap() {
        targetObjKeyMap.put('수주',    'Opportunity_plan__c');
        targetObjKeyMap.put('수주매출', 'opportunity_amount_plan__c');
    }

    /**
     * @description 복제될 ObjectKey 매핑
     */
    public void setCopyObjKeyMap() {
        copyObjKeyMap.put('수주',    'Opportunity');
        copyObjKeyMap.put('수주매출', 'Opportunity_amount__c');
    }


}