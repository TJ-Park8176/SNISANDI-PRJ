/**
 * Created by MZC01-DGCHOI on 2023-07-31.
 */

public with sharing class CCGAPInfo {

    public List<CC_GAP_Info__mdt> lowerSortInfos = new List<CC_GAP_Info__mdt>();
    public Set<String> lowerSortSet = new Set<String>();

    public CCGAPInfo() {
        setLowerSortInfo();
    }

    /**
     * @description CCGAP 계정과목 LowerSort Set
     */
    public void setLowerSortInfo() {
        this.lowerSortInfos = [
                SELECT Id, LowerSort__c, PlanField__c, PredictField__c, GapField__c, AccountSubjectName__c, GAP_Detail__c
                FROM CC_GAP_Info__mdt
                WHERE Label = 'LowerSort'
        ];

        for(CC_GAP_Info__mdt info : lowerSortInfos) {
            this.lowerSortSet.add(info.LowerSort__c);
        }
    }

}