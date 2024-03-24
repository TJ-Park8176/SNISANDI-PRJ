/**
 * Created by MZC01-DGCHOI on 2023-07-31.
 */

public with sharing class CCGAPController {

    public static CCGAPInfo ccgapInfo = new CCGAPInfo();

    @AuraEnabled
    public static String createDetails(Id ccGapId) {
        try {
            System.debug('ccGapId :::: ' + ccGapId);
            List<CCGAP_Detail__c> insertList = new List<CCGAP_Detail__c>();

            CCGAP__c ccGap = getCCGap(ccGapId);
            Double plan = 0.0, predict = 0.0, gap = 0.0;

            System.debug('CCGAPInfo.lowerSortInfos ::: ' + ccgapInfo.lowerSortInfos);

            for(CC_GAP_Info__mdt info : ccgapInfo.lowerSortInfos) {
                plan = (Double) ccGap.get(info.PlanField__c); //사업계획
                predict = (Double) ccGap.get(info.PredictField__c); //연간추정
                gap = (Double) ccGap.get(info.GapField__c); //차이금액

                CCGAP_Detail__c detail = new CCGAP_Detail__c();
                detail.CC_GAP_Name__c = ccGap.Id;
                detail.Name = ccGap.Name + '_'
                            + info.AccountSubjectName__c + '_'
                            + Utilities.formatYYMM(ccGap.Start_Date__c) + '_'
                            + Utilities.formatYYMM(ccGap.End_Date__c);
                detail.Start_Date__c = ccGap.Start_Date__c;
                detail.End_Date__c = ccGap.End_Date__c;
                detail.Create_Month__c = ccGap.Create_Month__c;
                detail.AccountSubject_Name__c = info.AccountSubjectName__c;
                detail.Plan__c = plan;
                detail.Predict__c = predict;
                detail.GAP__c = gap;
                detail.OwnerId = ccGap.OwnerId;
                detail.WBS_CC__c = ccGap.WBS_CC__c;
                detail.GAP_Detail__c = (String) ccGap.get(info.GAP_Detail__c); //차이내역 기재

                insertList.add(detail);
            }

            // 총합 - 사업계획
            CCGAP_Detail__c detail_total = new CCGAP_Detail__c();
            detail_total.CC_GAP_Name__c = ccGap.Id;
            detail_total.Name = ccGap.Name + '_총합_'
                              + Utilities.formatYYMM(ccGap.Start_Date__c) + '_'
                              + Utilities.formatYYMM(ccGap.End_Date__c);
            detail_total.Start_Date__c = ccGap.Start_Date__c;
            detail_total.End_Date__c = ccGap.End_Date__c;
            detail_total.Create_Month__c = ccGap.Create_Month__c;
            detail_total.AccountSubject_Name__c = '총합';
            detail_total.Plan__c = ccGap.Plan_Total__c;
            detail_total.Predict__c = ccGap.Predict_Total__c;
            detail_total.GAP__c = ccGap.GAP_Total__c;
            detail_total.OwnerId = ccGap.OwnerId;
            detail_total.WBS_CC__c = ccGap.WBS_CC__c;

            insertList.add(detail_total);

            System.debug(insertList);

            if(insertList.size() > 0) insert insertList;
        } catch (Exception e) {
            System.debug(e.getMessage());
            System.debug(e.getLineNumber());

            return e.getMessage();
        }
        return 'SUCCESS';
    }

    public static CCGAP__c getCCGap(Id ccGapId) { //type : 지원비 구분(법인지원비, 담당지원비)
        //SELECT ALL FIELDS
        Set<String> fields = CCGAP__c.SObjectType.getDescribe().fields.getMap().keySet();
        String query = ' SELECT ' + String.join((Iterable<String>)fields, ',')
                     + ' FROM CCGAP__c '
                     + ' WHERE Id = \''+ ccGapId + '\' '
                     + ' LIMIT 1 ';

        List<CCGAP__c> ccGaps = Database.query(query);

        if(ccGaps.size() > 0) return ccGaps[0];

        return null;
    }

}