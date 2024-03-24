/**
 * 주간예상, 실행계획 개체 복사
 */
public with sharing class ObjectCopy_ba implements Database.Batchable<sObject>, Database.Stateful {

    public String objLabel;
    public String innerObjLabel;

    public String type;
    public String targetAPIKey;
    public String shellObjKey;

    public Date batchDate;

    //실패 처리
    public Boolean isFailed  = false;
    public String  ERROR_MSG = '';

    //그 달에 몇주차
    public Integer batchWeekOfMonth; //월간 주차

    //1년중 몇주차
    public Integer batchWeekOfYear; //연간 주차

    //타겟 데이터 전월 or 당월
    public Boolean isThisMonth = true;

    //3주차인지
    public Boolean isThirdWeek = false;

    /**
     * @param type : weeklyExpect(주간예상), actionPlan(실행계획)
     * @param targetAPIKey : 대상 개체 API명 :::: Amount__c(매출) / Cost__c(매입) / ProfitandLoss__c(손익) / Opportunity(수주) / Opportunity_amount__c(수주매출)
     */
    public ObjectCopy_ba(String type, String targetAPIKey) {
        this.type = type;
        this.targetAPIKey = targetAPIKey;
        this.batchDate = Date.today();
        //this.batchDate = Date.newInstance(2023,11,20);
        this.isThirdWeek = checkThirdWeek(this.batchDate);

        System.debug('@type: ' + type);
        System.debug('@targetAPIKey: ' + targetAPIKey);

        setWeekNumber(batchDate);
        setObjKey();
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        String query_select = getQuerySelect();
        String query_where  = '';

        String calDateLabel = '';

        switch on targetAPIKey {
            when 'Amount__c' { //매출 복사
                calDateLabel = 'CalculateDate__c';
            }
            when 'Cost__c' { //매입 복사
                calDateLabel = 'CalculateDate__c';
            }
            when 'ProfitandLoss__c' { //손익계산
                calDateLabel = 'Calculate_month__c';
            }
            when 'Opportunity' { //영업물건관리
                calDateLabel = 'stdDate__c';
            }
            when 'Opportunity_amount__c' { //영업매출현황
                calDateLabel = 'CalculateDate__c';
            }
            when else {}
        }

        if(type == 'weeklyExpect') { //주간예상
            query_where = ' WHERE CALENDAR_MONTH(' + calDateLabel + ') = '
                        + (isThisMonth == true ? batchDate.month() : batchDate.month()-1); //당월/전월 체크
        } else if(type == 'actionPlan') { //실행계획
            query_where = ' WHERE CALENDAR_MONTH(' + calDateLabel + ') > ' + (batchDate.month()); //당월 초과 THIS_MONTH

            if(targetAPIKey == 'Opportunity') {
                query_where += ' AND ' + calDateLabel + ' != null ';
            }
        }

        if(targetAPIKey == 'Opportunity' || targetAPIKey == 'Opportunity_amount__c') { //수주/수주매출
            query_where += ' AND StoreExclude__c = FALSE '; //지점제외 안된것만(FALSE)
        }

        query_where += ' AND ' + calDateLabel + ' = THIS_YEAR ';

        return Database.getQueryLocator(query_select + query_where);
    }

    /**
     * @description 대상 개체 복제
     */
    public void execute(Database.BatchableContext context, List<SObject> scope) {
        System.debug('@@scope' + scope);
        System.debug('@@scope SIZE: ' + scope.size());
        try {
            if(type == 'weeklyExpect') {
                switch on this.targetAPIKey {
                    when 'Amount__c' { //주간예상(매출) 복사
                        copyWeeklyAmount(scope);
                    }
                    when 'Cost__c' { //주간예상(매입) 복사
                        copyWeeklyCost(scope);
                    }
                    when 'ProfitandLoss__c' {
                        copyWeeklyProfit(scope);
                    }
                    when 'Opportunity' {
                        copyWeeklyOppty(scope);
                    }
                    when 'Opportunity_amount__c' {
                        copyWeeklyOpptyAmount(scope);
                    }
                    when else {}
                }
            } else if(type == 'actionPlan') {
                switch on this.targetAPIKey {
                    when 'Amount__c' { //실행계획(매출) 복사
                        copyActionPlan_amount(scope);
                    }
                    when 'Cost__c' { //실행계획(매입) 복사
                        copyActionPlan_cost(scope);
                    }
                    when 'ProfitandLoss__c' {
                        copyActionPlan_profit(scope);
                    }
                    when 'Opportunity' {
                        copyActionPlan_oppty(scope);
                    }
                    when 'Opportunity_amount__c' {
                        copyActionPlan_opptyAmount(scope);
                    }
                    when else {}
                }
            }

        } catch (Exception e) {
            this.isFailed = true;
            this.ERROR_MSG = e.getMessage();

            System.debug(e.getLineNumber());
            System.debug(e.getMessage());
        }
    }

    /**
     * @description 매출 -> 매입 -> 손익 -> 수주 -> 수주 매출
     */
    public void finish(Database.BatchableContext context) {
        //이메일 전송...
        System.debug('------------------------ObjectCopy_ba finish-----------------------');
        System.debug('type :::: ' + this.type);
        System.debug('targetAPIKey :::: ' + this.targetAPIKey);

        String title = '';
        String body  = '';

        String objName = this.objLabel + '(' + this.innerObjLabel + ')';

        if(!isFailed) {
            String nextTargetAPIKey = '';

            switch on this.targetAPIKey {
                when 'Amount__c' { //매출
                    nextTargetAPIKey = 'Cost__c';

                    System.debug('shellObjKey :::: ' + this.shellObjKey);

                    if(this.type == 'actionPlan') { //실행계획
                        NewWBSShell_ba batch = new NewWBSShell_ba(this.shellObjKey);
                        batch.nextTargetAPIKey = nextTargetAPIKey;
                        if(!Test.isRunningTest()) {
                            Database.executeBatch(batch, 1);
                        } else {
                            Database.executeBatch(batch);
                        }
                    } else if(this.type == 'weeklyExpect') { //주간예상
                        WeeklyWBSShell_ba batch = new WeeklyWBSShell_ba(this.shellObjKey);
                        batch.nextTargetAPIKey = nextTargetAPIKey;
                        if(!Test.isRunningTest()) {
                            Database.executeBatch(batch, 10);
                        } else {
                            Database.executeBatch(batch);
                        }
                    }
                }
                when 'Cost__c' { //매입
                    nextTargetAPIKey = 'ProfitandLoss__c';

                    System.debug('shellObjKey :::: ' + this.shellObjKey);

                    if(this.type == 'actionPlan') { //실행계획
                        NewWBSShell_ba batch = new NewWBSShell_ba(this.shellObjKey);
                        batch.nextTargetAPIKey = nextTargetAPIKey;
                        if(!Test.isRunningTest()) {
                            Database.executeBatch(batch, 1);
                        } else {
                            Database.executeBatch(batch);
                        }
                    } else if(this.type == 'weeklyExpect') { //주간예상
                        WeeklyWBSShell_ba batch = new WeeklyWBSShell_ba(this.shellObjKey);
                        batch.nextTargetAPIKey = nextTargetAPIKey;
                        if(!Test.isRunningTest()) {
                            Database.executeBatch(batch, 10);
                        } else {
                            Database.executeBatch(batch);
                        }
                    }
                }
                when 'ProfitandLoss__c' { //손익
                    //23.07.12 dgchoi - 주간예상일때만 수주쪽 이어지게 조건 추가
                    //24.01.21 dgchoi - 주간예상/실행계획 모두 다음 수주로 이어지게
                    nextTargetAPIKey = 'Opportunity';
                    ct_ObjectCopy.copyObject(this.type, nextTargetAPIKey); //NEXT : 수주
                }
                when 'Opportunity' { //수주
                    nextTargetAPIKey = 'Opportunity_amount__c';
                    ct_ObjectCopy.copyObject(this.type, nextTargetAPIKey); //NEXT : 수주매출
                }
                when 'Opportunity_amount__c' { //수주매출
                    if(this.type == 'weeklyExpect') { //주간예상은 끝나고 수주 Status [기존 -> 진행중] 변경
                        Database.executeBatch(new OpptyStatus_ba(), 2000);
                    } else if(this.type == 'actionPlan') { //실행계획
                        title = 'S&I: [실행계획(매출/매입/손익/수주/수주매출) 개체] 업로드 완료';
                        body = '[실행계획(매출/매입/손익/수주/수주매출) 개체] 업로드 되었습니다.';

                        EmailController.sendEmail(title, body);
                    }
                }
                when else {}
            }
        } else {
            title = 'S&I: ['+ objName + '] 업로드 실패';
            body = 'ObjectCopy_ba :::::: ' + this.ERROR_MSG;

            EmailController.sendEmail(title, body);
        }

    }

    /**
     * @description 실행계획(매출) 으로 복사
     */
    public void copyActionPlan_amount(List<sObject> objList) {

        List<Amount_Action_Plan__c> upsertList = new List<Amount_Action_Plan__c>();
        //복제할 매출 scope
        for(Amount__c copyAmt : (List<Amount__c>) objList) {
            Amount_Action_Plan__c tmpObj = new Amount_Action_Plan__c();


            //24.01.21 dgchoi - 실행계획(매출/매입/손익) 주차로 변경
            tmpObj.Weekly__c        = this.batchWeekOfYear;
            tmpObj.Weekly_date__c   = this.batchDate;
            tmpObj.Monthly_Order__c = String.valueOf(this.batchWeekOfMonth);

            tmpObj.Latest_Data_Check__c = true; //최신 데이터 여부
            tmpObj.TimeDate__c = this.batchDate; //시점일자
            tmpObj.Amount_Action_Plan_External_ID__c = copyAmt.Itemmanagement_code__c + '-'
                                                     + copyAmt.CalculateDate__c.year() + '-'
                                                     + copyAmt.CalculateDate__c.month() + '-'
                                                     + this.batchWeekOfYear;
            //매핑
            if(copyAmt.Name != null)                    tmpObj.Name                    = copyAmt.Name;
            if(copyAmt.Status__c != null)               tmpObj.Status__c               = copyAmt.Status__c;
            if(copyAmt.SalesSort__c != null)            tmpObj.SalesSort__c            = copyAmt.SalesSort__c;
            if(copyAmt.AmountDivision__c != null)       tmpObj.AmountDivision__c       = copyAmt.AmountDivision__c;
            if(copyAmt.Itemmanagement__c != null)       tmpObj.Itemmanagement__c       = copyAmt.Itemmanagement__c;
            if(copyAmt.AmountType__c != null)           tmpObj.AmountType__c           = copyAmt.AmountType__c;
            if(copyAmt.CalculateDate__c != null)        tmpObj.CalculateDate__c        = copyAmt.CalculateDate__c;
            if(copyAmt.PredictAmount__c != null)        tmpObj.ActionPlanAmount__c     = copyAmt.PredictAmount__c;
            if(copyAmt.Account__c != null)              tmpObj.Account__c              = copyAmt.Account__c;
            if(copyAmt.AccountSubjectselect__c != null) tmpObj.AccountSubjectselect__c = copyAmt.AccountSubjectselect__c;
            if(copyAmt.WBS__c != null)                  tmpObj.WBS__c                  = copyAmt.WBS__c;
            if(copyAmt.User__c != null && copyAmt.User__r.isActive) { //2023.06.07 dgchoi 조건 추가 : Active된 유저만 복제
                tmpObj.User__c = copyAmt.User__c;
                tmpObj.OwnerId = copyAmt.User__c;
            }

            upsertList.add(tmpObj);
        }

        System.debug('@@@upsert LIST: ' + upsertList);
        System.debug('@@@upsert LIST SIZE: ' + upsertList.size());
        if(upsertList.size() > 0) upsert upsertList Amount_Action_Plan_External_ID__c;
    }

    /**
     * @description 실행계획(매입) 으로 복사
     */
    public void copyActionPlan_cost(List<sObject> objList) {

        List<Cost_Action_Plan__C> upsertList = new List<Cost_Action_Plan__c>();
        //해당 월 매입 scope
        for(Cost__c copyCst : (List<Cost__c>) objList) {
            Cost_Action_Plan__c tmpObj = new Cost_Action_Plan__c();

            //24.01.21 dgchoi - 실행계획(매출/매입/손익) 주차로 변경
            tmpObj.Weekly__c        = this.batchWeekOfYear;
            tmpObj.Weekly_date__c   = this.batchDate;
            tmpObj.Monthly_Order__c = String.valueOf(this.batchWeekOfMonth);

            tmpObj.Latest_Data_Check__c = true; //최신 데이터 체크
            tmpObj.TimeDate__c = this.batchDate; //시점일자
            tmpObj.Cost_Action_Plan_External_ID__c = copyCst.Itemmanagement_code__c + '-'
                                                   + copyCst.AccountSubjectCodea__c + '-'
                                                   + copyCst.CalculateDate__c.year() + '-'
                                                   + copyCst.CalculateDate__c.month() + '-'
                                                   + this.batchWeekOfYear;
            //매핑
            if(copyCst.Name != null)                    tmpObj.Name                        = copyCst.Name;
            if(copyCst.WBS__c != null)                  tmpObj.WBS__c                      = copyCst.WBS__c;
            if(copyCst.AccountSubjectselect__c != null) tmpObj.AccountSubjectselect__c     = copyCst.AccountSubjectselect__c;
            if(copyCst.ItemManagement__c != null)       tmpObj.ItemManagement__c           = copyCst.ItemManagement__c;
            if(copyCst.PurchaseAmount__c != null)       tmpObj.ActionPlanPurchaseAmount__c = copyCst.PurchaseAmount__c;
            if(copyCst.CalculateDate__c != null)        tmpObj.CalculateDate__c            = copyCst.CalculateDate__c;
            if(copyCst.Owner__c != null && copyCst.Owner__r.IsActive) { //2023.06.07 dgchoi 조건 추가 : Active된 유저만 복제
                tmpObj.Owner__c = copyCst.Owner__c;
                tmpObj.OwnerId = copyCst.Owner__c;
            }

            upsertList.add(tmpObj);
        }

        System.debug('@@@upsert LIST: ' + upsertList);
        System.debug('@@@upsert LIST SIZE: ' + upsertList.size());
        if(upsertList.size() > 0) upsert upsertList Cost_Action_Plan_External_ID__c;
    }

    /**
     * @description 실행계획(손익) 으로 복사
     */
    public void copyActionPlan_profit(List<sObject> objList) {
        List<ProfitandLoss_ActionPlan__c> upsertList = new List<ProfitandLoss_ActionPlan__c>();

        //해당 월 매입 scope
        for(ProfitandLoss__c copyPro : (List<ProfitandLoss__c>) objList) {
            String mapKey = copyPro.WBS__c + '-' + copyPro.AccountSubjectselect__c + '-' + copyPro.Calculate_month__c.month();
            ProfitandLoss_ActionPlan__c tmpObj = new ProfitandLoss_ActionPlan__c();

            //24.01.21 dgchoi - 실행계획(매출/매입/손익) 주차로 변경
            tmpObj.Weekly__c        = this.batchWeekOfYear;
            tmpObj.Weekly_date__c   = this.batchDate;
            tmpObj.Monthly_Order__c = String.valueOf(this.batchWeekOfMonth);

            tmpObj.Latest_Data_Check__c = true;
            tmpObj.TimeDate__c = this.batchDate;
            tmpObj.ProfitandLoss_ActionPlan_External_ID__c = copyPro.WBS_Code__c + '-'
                                                           + copyPro.AccountSubjectCodea__c + '-'
                                                           + copyPro.Calculate_month__c.year() + '-'
                                                           + copyPro.Calculate_month__c.month() + '-'
                                                           + this.batchWeekOfYear;
            //매핑
            if(copyPro.Name != null)                              tmpObj.Name                    = copyPro.Name;
            if(copyPro.WBS__c != null)                            tmpObj.WBS__c                  = copyPro.WBS__c;
            if(copyPro.AccountSubjectselect__c != null)           tmpObj.AccountSubjectselect__c = copyPro.AccountSubjectselect__c;
            if(copyPro.OwnerId != null && copyPro.Owner.isActive) tmpObj.OwnerId                 = copyPro.OwnerId; //2023.06.07 dgchoi 조건 추가 : Active된 유저만 복제
            if(copyPro.Amount__c != null)                         tmpObj.ProfitandLossAmount__c  = copyPro.Amount__c;
            if(copyPro.Calculate_month__c != null)                tmpObj.Calculate_month__c      = copyPro.Calculate_month__c;
            if(copyPro.ProfitandLoss_Type__c != null)             tmpObj.ProfitandLoss_Type__c   = copyPro.ProfitandLoss_Type__c;

            upsertList.add(tmpObj);
        }

        System.debug('@@@upsert LIST: ' + upsertList);
        System.debug('@@@upsert LIST SIZE: ' + upsertList.size());
        if(upsertList.size() > 0) upsert upsertList ProfitandLoss_ActionPlan_External_ID__c;
    }

    /**
     * @description 실행계획(영업수주) 으로 복사
     */
    public void copyActionPlan_oppty(List<SObject> objList) {
        List<Opportunity_actionplan__c> upsertList = new List<Opportunity_actionplan__c>();

        for(Opportunity copyOppty : (List<Opportunity>) objList) {
            Opportunity_actionplan__c tmpObj = new Opportunity_actionplan__c();

            //23.10.25 dgchoi - Third_Week_Index__c 필드 추가
            //tmpObj.Third_Week_Index__c = this.isThirdWeek;

            //23.07.13 dgchoi - 주차 정보 추가
            tmpObj.Weekly__c      = this.batchWeekOfYear;
            tmpObj.Weekly_date__c = this.batchDate;

            tmpObj.Latest_Data_Check__c = true;
            tmpObj.TimeDate__c = this.batchDate;
            tmpObj.Opportunity_actionplan_External_ID__c = copyOppty.Opportunity_code__c + '-'
                                                         + copyOppty.stdDate__c.year() + '-'
                                                         + copyOppty.stdDate__c.month() + '-'
                                                         + this.batchWeekOfYear;
            //매핑
            if(copyOppty.OwnerId != null && copyOppty.Owner.IsActive) { //소유자 매핑 //2023.06.07 dgchoi 조건 추가 : Active된 유저만 복제
                tmpObj.OwnerId = copyOppty.OwnerId;
                tmpObj.Salesreps__c = copyOppty.OwnerId;
            }
            if(copyOppty.Name != null)                                tmpObj.Name                                = copyOppty.Name;
            if(copyOppty.AccountId != null)                           tmpObj.AccountId__c                        = copyOppty.AccountId;
            if(copyOppty.AI_CCTV_month__c != null)                    tmpObj.AI_CCTV_month__c                    = copyOppty.AI_CCTV_month__c;
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
            if(copyOppty.opportunity_report__c != null)               tmpObj.Opportunity_actionplan_report__c    = copyOppty.opportunity_report__c;
            if(copyOppty.Numberofstore__c != null)                    tmpObj.Numberofstore__c                    = copyOppty.Numberofstore__c;
            if(copyOppty.Gross_Profit_rate__c != null)                tmpObj.ActionPlan_GrossProfit_Percent__c   = copyOppty.Gross_Profit_rate__c;
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
            //추가
            if(copyOppty.Parent_Opportunity__c != null)               tmpObj.Parent_Opportunity__c               = copyOppty.Parent_Opportunity__c;
            if(copyOppty.Type2__c != null)                            tmpObj.Type2__c                            = copyOppty.Type2__c;
            if(copyOppty.WBS_CC__c != null)                           tmpObj.WBS_CC__c                           = copyOppty.WBS_CC__c; //zf구분이 wbs인가여
            if(copyOppty.purpose__c != null)                          tmpObj.purpose__c                          = copyOppty.purpose__c;

            //추가필드
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
            //24.03.08 Sanghee 추가필드
            if(copyOppty.Product_NPD__c != null)                      tmpObj.Product_NPD__c                      = copyOppty.Product_NPD__c;

            //마감필드 추가
            if(copyOppty.Drop_stage__c != null)                       tmpObj.Drop_stage__c                       = copyOppty.Drop_stage__c;
            if(copyOppty.Status__c != null)                           tmpObj.Status__c                           = copyOppty.Status__c;
            if(copyOppty.Totalmonthlyamount__c != null)               tmpObj.Totalmonthlyamount__c               = copyOppty.Totalmonthlyamount__c;
            //기준필드 추가
            if(copyOppty.stdDate__c != null)                          tmpObj.stdDate__c                          = copyOppty.stdDate__c;
            //추가....
            if(copyOppty.StoreExclude__c != null)                     tmpObj.StoreExclude__c                     = copyOppty.StoreExclude__c; //지점 제외
            if(copyOppty.Child_opportunity_count__c != null)          tmpObj.Child_opportunity_count__c          = copyOppty.Child_opportunity_count__c; //하위 지점 수
            if(copyOppty.TotalAmount_SumofSore__c != null)            tmpObj.TotalAmount_SumofSore__c            = copyOppty.TotalAmount_SumofSore__c; //총 매출 발생 금액(지점 합계)
            if(copyOppty.recordtype__c != null)                       tmpObj.recordtype__c                       = copyOppty.recordtype__c;

            //매핑데이
            if(copyOppty.WBS_CC__c != null)                           tmpObj.WBS_CC__c                           = copyOppty.WBS_CC__c;
            //if(copyOppty.Responsibily_Area__c != null)                tmpObj.Responsibily_Area__c                = copyOppty.Responsibily_Area__c; //formula
            //if(copyOppty.ZF_Code__c != null)                          tmpObj.ZF_Code__c                          = copyOppty.ZF_Code__c;
            //if(copyOppty.Opportunity_code__c != null)                 tmpObj.Opportunity_code__c                 = copyOppty.Opportunity_code__c;
            //if(copyOppty.Expect_Month_of_closed__c != null)           tmpObj.Expect_month_of_closed__c           = copyOppty.Expect_Month_of_closed__c;
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

            upsertList.add(tmpObj);
        }

        System.debug('@@@upsert LIST: ' + upsertList);
        System.debug('@@@upsert LIST SIZE: ' + upsertList.size());
        if(upsertList.size() > 0) upsert upsertList Opportunity_actionplan_External_ID__c;
    }

    /**
     * @description 실행계획(영업매출) 으로 복사
     */
    public void copyActionPlan_opptyAmount(List<sObject> objList) {
        List<Opportunity_amount_actionplan__c> upsertList = new List<Opportunity_amount_actionplan__c>();


        for(Opportunity_Amount__c copyOpptyAmt : (List<Opportunity_Amount__c>) objList) {
            Opportunity_amount_actionplan__c tmpObj = new Opportunity_amount_actionplan__c();

            //23.10.25 dgchoi - Third_Week_Index__c 필드 추가
            //tmpObj.Third_Week_Index__c = this.isThirdWeek ? true : false;

            //23.07.13 dgchoi - 주차 정보 추가
            tmpObj.Weekly__c      = this.batchWeekOfYear;
            tmpObj.Weekly_date__c = this.batchDate;

            tmpObj.Latest_Data_Check__c = true;
            tmpObj.TimeDate__c = this.batchDate;
            tmpObj.Oppty_amount_actionplan_External_ID__c = copyOpptyAmt.OpportunityName__r.Opportunity_code__c + '-'
                                                          + copyOpptyAmt.CalculateDate__c.year() + '-'
                                                          + copyOpptyAmt.CalculateDate__c.month() + '-'
                                                          + this.batchWeekOfYear;
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
            if(copyOpptyAmt.Parent_Opportunity__c != null)          tmpObj.parent_Opportunity__c                      = copyOpptyAmt.Parent_Opportunity__c;
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
            if(copyOpptyAmt.Opportunity_amount_report__c != null)   tmpObj.Opportunity_amoun_actionplan_report__c     = copyOpptyAmt.Opportunity_amount_report__c;
            if(copyOpptyAmt.Numberofstore__c != null)               tmpObj.Numberofstore__c                           = copyOpptyAmt.Numberofstore__c;
            //if(copyOpptyAmt.amount_occur_date__c != null)           tmpObj.amount_occur_date__c                       = copyOpptyAmt.amount_occur_date__c;
            if(copyOpptyAmt.security_robot_date__c != null)         tmpObj.security_robot_date__c                     = copyOpptyAmt.security_robot_date__c;
            if(copyOpptyAmt.ServiceForm__c != null)                 tmpObj.ServiceForm__c                             = copyOpptyAmt.ServiceForm__c;
            if(copyOpptyAmt.Description__c != null)                 tmpObj.Description__c                             = copyOpptyAmt.Description__c;
            if(copyOpptyAmt.Location__c != null)                    tmpObj.Location__c                                = copyOpptyAmt.Location__c;
            //if(copyOpptyAmt.OpportunityCheck__c != null)  tmpObj.OpportunityCheck__c = copyOpptyAmt.OpportunityCheck__c;
            if(copyOpptyAmt.Opportunityname__c != null)             tmpObj.Opportunityname__c                         = copyOpptyAmt.Opportunityname__c;
            if(copyOpptyAmt.Annual_sales_accrual_amount__c != null) tmpObj.Annual_sales_accrual_amount__c             = copyOpptyAmt.Annual_sales_accrual_amount__c;
            if(copyOpptyAmt.CalculateDate__c != null)               tmpObj.CalculateDate__c                           = copyOpptyAmt.CalculateDate__c;
            if(copyOpptyAmt.Recordtype__c != null)                  tmpObj.Recordtype__c                              = copyOpptyAmt.Recordtype__c;
            if(copyOpptyAmt.Monthly_amount__c != null)              tmpObj.Monthly_amount__c                          = copyOpptyAmt.Monthly_amount__c;

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
            //추가...
            if(copyOpptyAmt.StoreExclude__c != null)                 tmpObj.StoreExclude__c                            = copyOpptyAmt.StoreExclude__c; //지점 제외
            if(copyOpptyAmt.Month_Amount_report__c != null)          tmpObj.Month_Amount_report__c                     = copyOpptyAmt.Month_Amount_report__c; //월 매출 금액(레포트용)

            //매핑데이
            if(copyOpptyAmt.Month_Profit_report__c != null)          tmpObj.Month_Profit_report__c                     = copyOpptyAmt.Month_Profit_report__c; //매출총이익1(레포트용)
            if(copyOpptyAmt.Oppty_Amount_sort__c != null)            tmpObj.Oppty_Amount_sort__c                       = copyOpptyAmt.Oppty_Amount_sort__c; //수주/매출 구분
            if(copyOpptyAmt.Real_Data_check__c != null)              tmpObj.Real_Data_check__c                         = copyOpptyAmt.Real_Data_check__c; //실제 데이터 여부
            if(copyOpptyAmt.status__c != null)                       tmpObj.status__c                                  = copyOpptyAmt.status__c; //상태
            if(copyOpptyAmt.OwnerId__c != null && copyOpptyAmt.OwnerId__r.IsActive) { //소유자 매핑 //2023.06.07 dgchoi 조건 추가 : Active된 유저만 복제
                tmpObj.OwnerId = copyOpptyAmt.OwnerId__c;
                tmpObj.Salesreps__c = copyOpptyAmt.OwnerId__c;
            }
            if(copyOpptyAmt.information_route_etc__c != null)        tmpObj.information_route_etc__c                   = copyOpptyAmt.information_route_etc__c;

            upsertList.add(tmpObj);
        }

        System.debug('@@@upsert LIST: ' + upsertList);
        System.debug('@@@upsert LIST SIZE: ' + upsertList.size());
        if(upsertList.size() > 0) upsert upsertList Oppty_amount_actionplan_External_ID__c;
    }

    /**
     * @description 주간예상(매출) 으로 복사
     */
    public void copyWeeklyAmount(List<sObject> objList) {
        List<weekly_amount_expect__c> upsertList = new List<weekly_amount_expect__c>();
        //해당 월 매출 scope
        for(Amount__c copyAmt : (List<Amount__c>) objList) {
            weekly_amount_expect__c tmpObj = new weekly_amount_expect__c();

            tmpObj.Weekly_date__c = this.batchDate; //주차일자 Update
            tmpObj.Weekly__c = this.batchWeekOfYear; //주차 update
            tmpObj.Monthly_Order__c = String.valueOf(this.batchWeekOfMonth);
            tmpObj.Latest_Data_Check__c = true; //최신 데이터 여부
            tmpObj.Weekly_Amount_Expect_External_ID__c = copyAmt.Itemmanagement_code__c + '-'
                                                       + copyAmt.CalculateDate__c.year() + '-'
                                                       + copyAmt.CalculateDate__c.month() + '-'
                                                       + this.batchWeekOfYear;
            //매핑
            if(copyAmt.WBS__c != null)                  tmpObj.WBS__c                  = copyAmt.WBS__c;
            if(copyAmt.AccountSubjectselect__c != null) tmpObj.AccountSubjectselect__c = copyAmt.AccountSubjectselect__c;
            if(copyAmt.Itemmanagement__c != null)       tmpObj.Itemmanagement__c       = copyAmt.Itemmanagement__c;
            if(copyAmt.PredictAmount__c != null)        tmpObj.PredictAmount__c        = copyAmt.PredictAmount__c;
            if(copyAmt.Name != null)                    tmpObj.Name                    = copyAmt.Name;
            if(copyAmt.CalculateDate__c != null)        tmpObj.CalculateDate__c        = copyAmt.CalculateDate__c;
            if(copyAmt.Status__c != null)               tmpObj.Status__c               = copyAmt.Status__c;
            if(copyAmt.Account__c != null)              tmpObj.Account__c              = copyAmt.Account__c;
            if(copyAmt.AmountType__c != null)           tmpObj.AmountType__c           = copyAmt.AmountType__c;
            if(copyAmt.SalesSort__c != null)            tmpObj.SalesSort__c            = copyAmt.SalesSort__c;
            if(copyAmt.AmountDivision__c != null)       tmpObj.AmountDivision__c       = copyAmt.AmountDivision__c;
            if(copyAmt.User__c != null && copyAmt.User__r.IsActive) { //2023.06.07 dgchoi 조건 추가 : Active된 유저만 복제
                tmpObj.User__c = copyAmt.User__c;
                tmpObj.OwnerId = copyAmt.User__c;
            }

            upsertList.add(tmpObj);
        }

        System.debug('@@@upsert LIST: ' + upsertList);
        System.debug('@@@upsert LIST SIZE: ' + upsertList.size());
        if(upsertList.size() > 0) upsert upsertList Weekly_Amount_Expect_External_ID__c;
    }

    /**
     * @description 주간예상(매입) 으로 복사
     */
    public void copyWeeklyCost(List<sObject> objList) {
        List<Weekly_cost_expect__c> upsertList = new List<Weekly_cost_expect__c>();

        //해당 월 매입 scope
        for(Cost__c copyCst : (List<Cost__c>) objList) {
            Weekly_cost_expect__c tmpObj = new Weekly_cost_expect__c();

            tmpObj.Weekly_date__c = this.batchDate; //주차일자
            tmpObj.Weekly__c = this.batchWeekOfYear;
            tmpObj.Monthly_Order__c = String.valueOf(this.batchWeekOfMonth);
            tmpObj.Latest_Data_Check__c = true;
            tmpObj.Weekly_Cost_Expect_External_ID__c = copyCst.Itemmanagement_code__c + '-'
                                                     + copyCst.AccountSubjectCodea__c + '-'
                                                     + copyCst.CalculateDate__c.year() + '-'
                                                     + copyCst.CalculateDate__c.month() + '-'
                                                     + this.batchWeekOfYear;

            //매핑
            if(copyCst.WBS__c != null)                  tmpObj.WBS__c                  = copyCst.WBS__c;
            if(copyCst.AccountSubjectselect__c != null) tmpObj.AccountSubjectselect__c = copyCst.AccountSubjectselect__c;
            if(copyCst.ItemManagement__c != null)       tmpObj.ItemManagement__c       = copyCst.ItemManagement__c;
            if(copyCst.PurchaseAmount__c != null)       tmpObj.PurchaseAmount__c       = copyCst.PurchaseAmount__c;
            if(copyCst.Name != null)                    tmpObj.Name                    = copyCst.Name;
            if(copyCst.CalculateDate__c != null)        tmpObj.CalculateDate__c        = copyCst.CalculateDate__c;
            if(copyCst.Owner__c != null && copyCst.Owner__r.IsActive) { //2023.06.07 dgchoi 조건 추가 : Active된 유저만 복제
                tmpObj.Owner__c = copyCst.Owner__c;
                tmpObj.OwnerId = copyCst.Owner__c;
            }

            //targetMap.put(mapKey, tmpObj);
            upsertList.add(tmpObj);
        }

        System.debug('@@@upsert LIST: ' + upsertList);
        System.debug('@@@upsert LIST SIZE: ' + upsertList.size());
        if(upsertList.size() > 0) upsert upsertList Weekly_Cost_Expect_External_ID__c;
    }

    /**
     * @description 주간예상(손익)으로 복사
     */
    public void copyWeeklyProfit(List<sObject> objList) {
        List<Weekly_profitandloss_expect__c> upsertList = new List<Weekly_profitandloss_expect__c>();
        //해당 월 매입 scope
        for(ProfitandLoss__c copyPro : (List<ProfitandLoss__c>) objList) {
            Weekly_profitandloss_expect__c tmpObj = new Weekly_profitandloss_expect__c();

            tmpObj.Weekly_date__c = this.batchDate; //주차일자
            tmpObj.Weekly__c = this.batchWeekOfYear;
            tmpObj.Monthly_Order__c = String.valueOf(this.batchWeekOfMonth);
            tmpObj.Latest_Data_Check__c = true;
            tmpObj.Weekly_profitandloss_expect_External_ID__c = copyPro.WBS_Code__c + '-'
                                                              + copyPro.AccountSubjectCodea__c + '-'
                                                              + copyPro.Calculate_month__c.year() + '-'
                                                              + copyPro.Calculate_month__c.month() + '-'
                                                              + this.batchWeekOfYear;
            //매핑
            if(copyPro.WBS__c != null)                            tmpObj.WBS__c                  = copyPro.WBS__c;
            if(copyPro.AccountSubjectselect__c != null)           tmpObj.AccountSubjectselect__c = copyPro.AccountSubjectselect__c;
            if(copyPro.OwnerId != null && copyPro.Owner.IsActive) tmpObj.OwnerId                 = copyPro.OwnerId; //2023.06.07 dgchoi 조건 추가 : Active된 유저만 복제
            if(copyPro.Amount__c != null)                         tmpObj.Amount__c               = copyPro.Amount__c;
            if(copyPro.Name != null)                              tmpObj.Name                    = copyPro.Name;
            if(copyPro.Calculate_month__c != null)                tmpObj.Calculate_month__c      = copyPro.Calculate_month__c;
            if(copyPro.ProfitandLoss_Type__c != null)             tmpObj.ProfitandLoss_Type__c   = copyPro.ProfitandLoss_Type__c;

            //targetMap.put(mapKey, tmpObj);
            upsertList.add(tmpObj);
        }

        System.debug('@@@upsert LIST: ' + upsertList);
        System.debug('@@@upsert LIST SIZE: ' + upsertList.size());
        if(upsertList.size() > 0) upsert upsertList Weekly_profitandloss_expect_External_ID__c;
    }

    /**
     * @description 주간예상(영업수주) 으로 복사
     */
    public void copyWeeklyOppty(List<sObject> objList) {
        List<weekly_opportunity_expect__c> upsertList = new List<weekly_opportunity_expect__c>();

        for(Opportunity copyOppty : (List<Opportunity>) objList) {
            weekly_opportunity_expect__c tmpObj = new weekly_opportunity_expect__c();

            tmpObj.Weekly_date__c = this.batchDate; //주차일자
            tmpObj.Weekly__c = this.batchWeekOfYear;
            tmpObj.Monthly_Order__c = String.valueOf(this.batchWeekOfMonth);
            tmpObj.Latest_Data_Check__c = true;
            tmpObj.Weekly_opportunity_expect_External_ID__c = copyOppty.Opportunity_code__c + '-'
                                                            + copyOppty.stdDate__c.year() + '-'
                                                            + copyOppty.stdDate__c.month() + '-'
                                                            + this.batchWeekOfYear;
            //매핑
            if(copyOppty.OwnerId != null && copyOppty.Owner.IsActive) { //소유자 매핑 //2023.06.07 dgchoi 조건 추가 : Active된 유저만 복제
                tmpObj.OwnerId = copyOppty.OwnerId;
                tmpObj.Salesreps__c = copyOppty.OwnerId;
            }
            if(copyOppty.Name != null)                                tmpObj.Name                                = copyOppty.Name;
            if(copyOppty.AccountId != null)                           tmpObj.AccountId__c                        = copyOppty.AccountId;
            if(copyOppty.AI_CCTV_month__c != null)                    tmpObj.AI_CCTV_month__c                    = copyOppty.AI_CCTV_month__c;
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
            //추가필드
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
            if(copyOppty.parent_Opportunity__c != null)               tmpObj.Parent_Opportunity__c               = copyOppty.Parent_Opportunity__c;
            //24.03.08 Sanghee 추가필드
            if(copyOppty.Product_NPD__c != null)                      tmpObj.Product_NPD__c                      = copyOppty.Product_NPD__c;

            //마감필드 추가
            if(copyOppty.Drop_stage__c != null)                       tmpObj.Drop_stage__c                       = copyOppty.Drop_stage__c;
            if(copyOppty.Status__c != null)                           tmpObj.Status__c                           = copyOppty.Status__c;
            if(copyOppty.Totalmonthlyamount__c != null)               tmpObj.Totalmonthlyamount__c               = copyOppty.Totalmonthlyamount__c;
            //기준필드 추가
            if(copyOppty.stdDate__c != null)                          tmpObj.stdDate__c                          = copyOppty.stdDate__c;
            //추가....
            if(copyOppty.StoreExclude__c != null)                     tmpObj.StoreExclude__c                     = copyOppty.StoreExclude__c; //지점 제외
            if(copyOppty.Child_opportunity_count__c != null)          tmpObj.Child_opportunity_count__c          = copyOppty.Child_opportunity_count__c; //하위 지점 수
            if(copyOppty.TotalAmount_SumofSore__c != null)            tmpObj.TotalAmount_SumofSore__c            = copyOppty.TotalAmount_SumofSore__c; //총 매출 발생 금액(지점 합계)
            if(copyOppty.recordtype__c != null)                       tmpObj.recordtype__c                       = copyOppty.recordtype__c;

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
            //if(copyOppty.RecordTypeId != null)                        tmpObj.RecordTypeId                        = copyOppty.RecordTypeId;
            if(copyOppty.Yearly_total_opportunity_amount__c != null)  tmpObj.Yearly_total_opportunity_amount__c  = copyOppty.Yearly_total_opportunity_amount__c;
            if(copyOppty.Building_Owner__c != null)                   tmpObj.Building_Owner__c                   = copyOppty.Building_Owner__c;
            if(copyOppty.information_route_etc__c != null)            tmpObj.information_route_etc__c            = copyOppty.information_route_etc__c;
            if(copyOppty.Type2__c != null)                            tmpObj.Type2__c                            = copyOppty.Type2__c;


            //targetMap.put(mapKey, tmpObj);
            upsertList.add(tmpObj);
        }

        System.debug('@@@upsert LIST: ' + upsertList);
        System.debug('@@@upsert LIST SIZE: ' + upsertList.size());
        if(upsertList.size() > 0) upsert upsertList Weekly_opportunity_expect_External_ID__c;
    }

    /**
     * @description 주간예상(영업매출) 으로 복사
     */
    public void copyWeeklyOpptyAmount(List<sObject> objList) {
        List<weekly_opportunity_amount_expect__c> upsertList = new List<weekly_opportunity_amount_expect__c>();

        for(Opportunity_Amount__c copyOpptyAmt : (List<Opportunity_Amount__c>) objList) {
            weekly_opportunity_amount_expect__c tmpObj = new weekly_opportunity_amount_expect__c();

            tmpObj.Weekly_date__c = this.batchDate; //주차일자
            tmpObj.Weekly__c = this.batchWeekOfYear;
            tmpObj.Monthly_Order__c = String.valueOf(this.batchWeekOfMonth);
            tmpObj.Latest_Data_Check__c = true;
            tmpObj.weekly_oppty_amount_expect_External_ID__c = copyOpptyAmt.OpportunityName__r.Opportunity_code__c + '-'
                                                             + copyOpptyAmt.CalculateDate__c.year() + '-'
                                                             + copyOpptyAmt.CalculateDate__c.month() + '-'
                                                             + this.batchWeekOfYear;
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
            //if(copyOpptyAmt.amount_occur_date__c != null)           tmpObj.amount_occur_date__c                       = copyOpptyAmt.amount_occur_date__c;
            if(copyOpptyAmt.security_robot_date__c != null)         tmpObj.security_robot_date__c                     = copyOpptyAmt.security_robot_date__c;
            if(copyOpptyAmt.ServiceForm__c != null)                 tmpObj.ServiceForm__c                             = copyOpptyAmt.ServiceForm__c;
            if(copyOpptyAmt.Description__c != null)                 tmpObj.Description__c                             = copyOpptyAmt.Description__c;
            if(copyOpptyAmt.Location__c != null)                    tmpObj.Location__c                                = copyOpptyAmt.Location__c;
            //if(copyOpptyAmt.OpportunityCheck__c != null)  tmpObj.OpportunityCheck__c = copyOpptyAmt.OpportunityCheck__c;
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
            if(copyOpptyAmt.Month_Profit_report__c != null)          tmpObj.Month_Profit_report__c                     = copyOpptyAmt.Month_Profit_report__c; //매출총이익1(레포트용)
            if(copyOpptyAmt.Oppty_Amount_sort__c != null)            tmpObj.Oppty_Amount_sort__c                       = copyOpptyAmt.Oppty_Amount_sort__c; //수주/매출 구분
            if(copyOpptyAmt.Real_Data_check__c != null)              tmpObj.Real_Data_check__c                         = copyOpptyAmt.Real_Data_check__c; //실제 데이터 여부
            if(copyOpptyAmt.status__c != null)                       tmpObj.status__c                                  = copyOpptyAmt.status__c; //상태
            if(copyOpptyAmt.OwnerId__c != null && copyOpptyAmt.OwnerId__r.IsActive) { //소유자 매핑 //2023.06.07 dgchoi 조건 추가 : Active된 유저만 복제
                tmpObj.OwnerId = copyOpptyAmt.OwnerId__c;
                tmpObj.Salesreps__c = copyOpptyAmt.OwnerId__c;
            }
            if(copyOpptyAmt.information_route_etc__c != null)       tmpObj.information_route_etc__c                    = copyOpptyAmt.information_route_etc__c;

            upsertList.add(tmpObj);
        }

        System.debug('@@@upsert LIST: ' + upsertList);
        System.debug('@@@upsert LIST SIZE: ' + upsertList.size());
        if(upsertList.size() > 0) upsert upsertList weekly_oppty_amount_expect_External_ID__c;
    }

    /*
    //N(0~53)주차 GET
    private void setBatchWeekOfYear() {
        //기준: 월  ~ 일
        DateTime batchDateTime = DateTime.now(); //DateTime.now()로 바꿔야함

        Integer dayOfWeek = Integer.valueOf(batchDateTime.format('u')) - 1; //0:월요일 - 6:일요일
        Integer dayOfYear = batchDate.dayOfYear(); //365일 중 몇일?

        DateTime initDate      = DateTime.newInstance(batchDate.year(), 1,1);
        Integer  initDayOfWeek = Integer.valueOf(initDate.format('u')) - 1; //1.1일이 무슨요일인지

        if(initDayOfWeek != 6) { //1.1이 월~토요일인 경우
            this.batchWeekOfYear = (dayOfYear<=7-initDayOfWeek) ? 1 : (dayOfYear + (initDayOfWeek-1) -dayOfWeek)/7 + 1;
        } else { //1.1이 일요일인 경우
            this.batchWeekOfYear = (dayOfYear<=8)? 1 : (dayOfYear-dayOfWeek-1)/7 + 1;
        }

        System.debug('오늘몇요일: '+ dayOfWeek);
        System.debug('오늘 365중 몇일: ' + dayOfYear);
        System.debug('1년 중 몇주차야? ' + this.batchWeekOfYear);

        setBatchWeekOfMonth();
    }

    //해당 월에 몇번째 주차인지....(월요일 시작 기준)
    private void setBatchWeekOfMonth() {
        if(batchDate.month() == 1) { //1월일 경우
            this.batchWeekOfMonth = this.batchWeekOfYear;
            return;
        }

        Datetime firstDate = Datetime.newInstance(batchDate.year(), batchDate.month(), 1); //해당 월 1일
        Integer firstDayOfWeek = Integer.valueOf(firstDate.format('u')) - 1; //해당 월 1일이 무슨 요일인지

        Integer batchDayOfMonth = batchDate.day(); //오늘이 해당 월 몇일인지

        Integer calcNum = firstDayOfWeek + batchDayOfMonth - 8; //첫 월요일이 0, 전 월의 주차로 해야할 경우에는 음수(-)

        System.debug('당월 calcNum: ' + calcNum);
        if(calcNum < 0) {
            this.isThisMonth = false;
            Datetime prevFirstDate = Datetime.newInstance(batchDate.year(), batchDate.month()-1, 1); //전 월 1일
            Integer prevfirstDayOfWeek = Integer.valueOf(prevFirstDate.format('u')) - 1; //전 월 1일이 무슨 요일인지

            Integer prevNumberOfDays = Date.daysInMonth(batchDate.year(), batchDate.month()-1); // 전 월 마지막 일
            calcNum = prevfirstDayOfWeek + prevNumberOfDays - 8;
            //calcNum 계산 검증 필요
            System.debug('prevNumberOfDays: ' + prevNumberOfDays);
            System.debug('전월 calcNum: ' + calcNum);
        }

        this.batchWeekOfMonth = Integer.valueOf(Math.floor(calcNum / 7)) + 1;

        System.debug('이 달의 N주차: ' + batchWeekOfMonth);
        System.debug('타겟데이터 당월이야?: ' + this.isThisMonth);
    }
     */

    /**
     * @description shellObjKey(dummy 개체 API Key) & innerObjLabel(Object Label) Set
     */
    public void setObjKey() {
        if(this.type == 'weeklyExpect') {
            this.objLabel = '주간예상';
            switch on this.targetAPIKey {
                when 'Amount__c' { //주간예상(매출) 복사
                    this.innerObjLabel = '매출';
                    this.shellObjKey = 'Weekly_Amount_Expect__c';
                }
                when 'Cost__c' { //주간예상(매입) 복사
                    this.innerObjLabel = '매입';
                    this.shellObjKey = 'Weekly_Cost_Expect__c';
                }
                when 'ProfitandLoss__c' {
                    this.innerObjLabel = '손익';
                }
                when 'Opportunity' {
                    this.innerObjLabel = '영업수주';
                }
                when 'Opportunity_amount__c' {
                    this.innerObjLabel = '영업매출';
                }
                when else {}
            }
        } else if(this.type == 'actionPlan') {
            this.objLabel = '실행계획';
            switch on this.targetAPIKey {
                when 'Amount__c' { //실행계획(매출) 복사
                    this.innerObjLabel = '매출';
                    this.shellObjKey = 'Amount_Action_Plan__c';
                }
                when 'Cost__c' { //실행계획(매입) 복사
                    this.innerObjLabel = '매입';
                    this.shellObjKey = 'Cost_Action_Plan__c';
                }
                when 'ProfitandLoss__c' {
                    this.innerObjLabel = '손익';
                }
                when 'Opportunity' {
                    this.innerObjLabel = '영업수주';
                }
                when 'Opportunity_amount__c' {
                    this.innerObjLabel = '영업매출';
                }
                when else {}
            }
        }
    }

    public String getQuerySelect() {
        Schema.SObjectType sObjType = Schema.getGlobalDescribe().get(this.targetAPIKey);

        Set<String> fields = sObjType.getDescribe().fields.getMap().keySet();
        String query_select = ' SELECT ' + String.join((Iterable<String>)fields, ',');

        //2023.06.07 dgchoi 소유자(유저) 필드 조회 추가
        switch on this.targetAPIKey {
            when 'Amount__c' {
                query_select += ' , User__r.isActive ';
            }
            when 'Cost__c' {
                query_select += ' , Owner__r.isActive ';
            }
            when 'ProfitandLoss__c' {
                query_select += ' , Owner.isActive ';
            }
            when 'Opportunity' {
                query_select += ' , Owner.IsActive ';
            }
            when 'Opportunity_amount__c' {
                query_select += ' , Opportunityname__r.Opportunity_code__c, OwnerId__r.IsActive ';
            }
            when else {}
        }

        query_select += ' FROM ' + this.targetAPIKey;

        return query_select;
    }

    public void setWeekNumber(Date stdDate) {
        WeekNumber weekNumber = new WeekNumber(stdDate);
        this.batchWeekOfMonth = weekNumber.batchWeekOfMonth;
        this.batchWeekOfYear = weekNumber.batchWeekOfYear;
        this.isThisMonth = weekNumber.isThisMonth;
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

    /**
     * @param stdDate 기준 날짜
     *
     * @return 기준 날짜가 3주차일때 True
     */
    public Boolean checkThirdWeek(Date stdDate) {
        WeekNumber weekNumber = new WeekNumber(stdDate);
        return (weekNumber.batchWeekOfMonth == 3 ? true : false);
    }




}