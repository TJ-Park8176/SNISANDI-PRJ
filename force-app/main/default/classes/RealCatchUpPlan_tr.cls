public with sharing class RealCatchUpPlan_tr extends TriggerHandler {
    private List<Real_catch_up_plan__c> listNew = (List<Real_catch_up_plan__c>) Trigger.new;
    private List<Real_catch_up_plan__c> listOld = (List<Real_catch_up_plan__c>) Trigger.old;
    private Map<Id, Real_catch_up_plan__c> mapNew = (Map<Id, Real_catch_up_plan__c>) Trigger.newMap;
    private Map<Id, Real_catch_up_plan__c> mapOld = (Map<Id, Real_catch_up_plan__c>) Trigger.oldMap;

    public override void beforeInsert() {
        Date tempDate = Date.today();
        WeekNumber weekNumber = new WeekNumber(tempDate);
        for(Real_catch_up_plan__c rcup : listNew) {
            if(rcup.Record_Type__c.equals('월간(주간 회의용)')) {
                rcup.Gap_Occur_date__c = Date.newInstance(Date.today().year(), weekNumber.batchMonth, 1);
                rcup.Monthly_Order__c = String.valueOf(weekNumber.batchWeekOfMonth);
                if(rcup.GAP_WBS__c != null) {
                    //PredictAmount
                    Map<String, Decimal> gapPredict = getGapPredict(rcup.GAP_WBS__c, weekNumber);
                    rcup.PredictAmount__c = gapPredict.get(rcup.GAP_WBS__c);
                    //ActionPlan
                    Map<String, Decimal> gapAction = getGapAction(rcup.GAP_WBS__c, weekNumber);
                    rcup.ActionPlan__c = gapAction.get(rcup.GAP_WBS__c);
                }
                else {
                    rcup.PredictAmount__c = null;
                    rcup.ActionPlan__c = null;
                }
            }
            else {
                rcup.Gap_Occur_date__c = Date.newInstance(Date.today().year(), weekNumber.batchMonth, 1);
                if(rcup.GAP_WBS__c != null) {
                    //PlanAmount
                    Map<String, Decimal> gapPlan = getGapPlan(rcup.GAP_WBS__c, weekNumber);
                    rcup.PlanAmount__c = gapPlan.get(rcup.GAP_WBS__c);
                }
                else {
                    rcup.PlanAmount__c = null;
                }
                //Copy yearly_performance_formul__c to yealrly_performance__c
                rcup.Replace_item1_yearly_performance__c = rcup.Replace_item1_yearly_performance_formul__c;
                rcup.Replace_item2_yearly_performance__c = rcup.Replace_item2_yearly_performance_formul__c;
                rcup.Replace_item3_yearly_performance__c = rcup.Replace_item3_yearly_performance_formul__c;
                rcup.Replace_item4_yearly_performance__c = rcup.Replace_item4_yearly_performance_formul__c;
                rcup.Replace_item5_yearly_performance__c = rcup.Replace_item5_yearly_performance_formul__c;
            }
        }
    }

    public override void beforeUpdate() {
        for(Real_catch_up_plan__c rcup : listNew) {
            WeekNumber weekNumber = new WeekNumber(Date.valueOf(rcup.CreatedDate));
            if(rcup.Record_Type__c.equals('월간(주간 회의용)')) {
                if (rcup.GAP_WBS__c != null) {
                    //PredictAmount
                    Map<String, Decimal> gapPredict = getGapPredict(rcup.GAP_WBS__c, weekNumber);
                    rcup.PredictAmount__c = gapPredict.get(rcup.GAP_WBS__c);
                    //ActionPlan
                    Map<String, Decimal> gapAction = getGapAction(rcup.GAP_WBS__c, weekNumber);
                    rcup.ActionPlan__c = gapAction.get(rcup.GAP_WBS__c);
                }
                else {
                    rcup.PredictAmount__c = null;
                    rcup.ActionPlan__c = null;
                }
            }
            else {
                if(rcup.GAP_WBS__c != null) {
                    //PlanAmount
                    Map<String, Decimal> gapPlan = getGapPlan(rcup.GAP_WBS__c, weekNumber);
                    rcup.PlanAmount__c = gapPlan.get(rcup.GAP_WBS__c);
                }
                else {
                    rcup.PlanAmount__c = null;
                }
                //Copy yearly_performance_formul__c to yealrly_performance__c
                Real_catch_up_plan__c old = mapOld.get(rcup.Id);
                if(old.Replace_Item1_Yearly__c != rcup.Replace_Item1_Yearly__c) rcup.Replace_item1_yearly_performance__c = rcup.Replace_item1_yearly_performance_formul__c;
                if(old.Replace_Item2_Yearly__c != rcup.Replace_Item2_Yearly__c) rcup.Replace_item2_yearly_performance__c = rcup.Replace_item2_yearly_performance_formul__c;
                if(old.Replace_Item3_Yearly__c != rcup.Replace_Item3_Yearly__c) rcup.Replace_item3_yearly_performance__c = rcup.Replace_item3_yearly_performance_formul__c;
                if(old.Replace_Item4_Yearly__c != rcup.Replace_Item4_Yearly__c) rcup.Replace_item4_yearly_performance__c = rcup.Replace_item4_yearly_performance_formul__c;
                if(old.Replace_Item5_Yearly__c != rcup.Replace_Item5_Yearly__c) rcup.Replace_item5_yearly_performance__c = rcup.Replace_item5_yearly_performance_formul__c;
            }
        }
    }

    public Map<String, Decimal> getGapPredict(String wbsId, WeekNumber weekNumber) {
        Map<String, Decimal> returnMap = new Map<String, Decimal>();

        List<AggregateResult> aggPredict = [
                SELECT WBS__c, SUM(PredictAmount__c) GAP_Predict
                FROM weekly_amount_expect__c
                WHERE WBS__c =: wbsId
                AND Monthly_Order__c =: String.valueOf(weekNumber.batchWeekOfMonth)
                AND Amount_Calculate_month__c =: weekNumber.batchMonth
                GROUP BY WBS__c
        ];

        System.debug(String.format('Predict: {0}, {1}, {2}', new List<String>{wbsId, String.valueOf(weekNumber.batchWeekOfMonth), String.valueOf(weekNumber.batchMonth)}));

        for(AggregateResult arg : aggPredict) {
            returnMap.put(String.valueOf(arg.get('WBS__c')), Decimal.valueOf(String.valueOf(arg.get('GAP_Predict'))));
        }

        return returnMap;
    }

    public Map<String, Decimal> getGapAction(String wbsId, WeekNumber weekNumber) {
        Map<String, Decimal> returnMap = new Map<String, Decimal>();

        List<AggregateResult> aggAction = [
                SELECT WBS__c, SUM(ActionPlanAmount__c) GAP_Action
                FROM Amount_Action_Plan__c
                WHERE WBS__c =: wbsId
                AND Calculate_month__c =: weekNumber.batchMonth
                AND Latest_Data_Check__c = TRUE
                GROUP BY WBS__c
        ];

        System.debug(String.format('Action: {0}, {1}, {2}', new List<String>{wbsId, String.valueOf(weekNumber.batchWeekOfMonth), String.valueOf(weekNumber.batchMonth)}));

        for(AggregateResult arg: aggAction) {
            returnMap.put(String.valueOf(arg.get('WBS__c')), Decimal.valueOf(String.valueOf(arg.get('GAP_Action'))));
        }

        return returnMap;
    }

    public Map<String, Decimal> getGapPlan(String wbsId, WeekNumber weekNumber) {
        Map<String, Decimal> returnMap = new Map<String, Decimal>();

        List<AggregateResult> aggPlan = [
                SELECT WBS__c, SUM(PlanAmount__c) GAP_Plan
                FROM Amount_plan__c
                WHERE WBS__c =: wbsId
                GROUP BY WBS__c
        ];

        System.debug(String.format('Plan: {0}, {1}, {2}', new List<String>{wbsId, String.valueOf(weekNumber.batchWeekOfMonth), String.valueOf(weekNumber.batchMonth)}));

        for(AggregateResult arg: aggPlan) {
            returnMap.put(String.valueOf(arg.get('WBS__c')), Decimal.valueOf(String.valueOf(arg.get('GAP_Plan'))));
        }

        return returnMap;
    }
}