@IsTest
public with sharing class RealCatchUpPlan_tr_Test {
    @TestSetup
    static public void doSetup() {
        //Set the AccountSubject__c
        AccountSubject__c newSubj = new AccountSubject__c();
        newSubj.Name = '용역매출-관리용역료';
        newSubj.UpperSort__c = '매출액';
        newSubj.MiddleSort__c = '매출';
        newSubj.LowerSort__c = '용역매출';
        newSubj.AccountSubjectCode__c = '4105110';

        insert newSubj;

        //Set the WBS info
        WBSandCC__c newWbs = new WBSandCC__c();
        newWbs.Name = 'Test1';
        newWbs.WBS_Code__c = 'F00001';
        newWbs.Check_WBS_CC_ZF__c = 'WBS';
        newWbs.AccountSubjectSort__c = '용';

        insert newWbs;

        //Set the weekly_amount_expect__c info
        weekly_amount_expect__c newWeek = new weekly_amount_expect__c();
        newWeek.Name = 'Test1';
        newWeek.CalculateDate__c = Date.newInstance(2023,02,01);
        newWeek.Real_Data_check__c = true;
        newWeek.PredictAmount__c = 20000;
        newWeek.AccountSubjectselect__c = newSubj.id;

        insert newWeek;

        //Set the Amount_Action_Plan__c
        Amount_Action_Plan__c newPlan = new Amount_Action_Plan__c();
        newPlan.Name = 'Test1';
        //newPlan.First_Day_TimeDate__c = Date.newInstance(2023, 01, 01);
        newPlan.WBS__c = newWbs.Id;
        newPlan.CalculateDate__c = Date.newInstance(2023, 01, 01);
        newPlan.Amount_Action_Plan_report__c = true;
        newPlan.Latest_Data_Check__c = true;
        newPlan.ActionPlanAmount__c = 500000;
        newPlan.Real_Data_check__c = true;

        insert newPlan;

        //Set the Amount_plan__c
        List<Amount_plan__c> setPlan = new List<Amount_plan__c>();
        for(Integer i=0; i<12; i++) {
            Amount_plan__c itemPlan = new Amount_plan__c();
            itemPlan.Name = 'Test1';
            itemPlan.WBS__c = newWbs.Id;
            itemPlan.PlanAmount__c = 500000;
            itemPlan.calculateDate__c = Date.newInstance(2023, i+1, 1);
            itemPlan.Amount_Plan_report__c = true;
            itemPlan.Real_Data_check__c = true;
            itemPlan.AccountSubjectselect__c = newSubj.Id;
            setPlan.add(itemPlan);
        }

        insert setPlan;
    }

    @IsTest
    static public void doTest() {
        Real_catch_up_plan__c newRCUP = new Real_catch_up_plan__c();
        newRCUP.RecordTypeId = Schema.SObjectType.Real_catch_up_plan__c.getRecordTypeInfosByName().get('월간(주간 회의용)').getRecordTypeId();
        newRCUP.Name = 'Test1';
        //WBS not set
        insert newRCUP;

        WBSandCC__c getWBS = [SELECT Id FROM WBSandCC__c LIMIT 1];
        newRCUP.GAP_WBS__c = getWBS.Id;
        //WBS update
        update newRCUP;

        Real_catch_up_plan__c newRCUPY = new Real_catch_up_plan__c();
        newRCUPY.RecordTypeId = Schema.SObjectType.Real_catch_up_plan__c.getRecordTypeInfosByName().get('연간(월간 회의용)').getRecordTypeId();
        newRCUPY.Name = 'Test_Y1';
        //WBS not set
        insert newRCUPY;

        newRCUPY.GAP_WBS__c = getWBS.Id;
        //WBS update
        update newRCUPY;

        Real_catch_up_plan__c newRCUP2 = new Real_catch_up_plan__c();
        newRCUP2.RecordTypeId = Schema.SObjectType.Real_catch_up_plan__c.getRecordTypeInfosByName().get('월간(주간 회의용)').getRecordTypeId();
        newRCUP2.Name = 'Test2';
        newRCUP2.GAP_WBS__c = getWBS.Id;
        //WBS set
        insert newRCUP2;

        Real_catch_up_plan__c newRCUPY2 = new Real_catch_up_plan__c();
        newRCUPY2.RecordTypeId = Schema.SObjectType.Real_catch_up_plan__c.getRecordTypeInfosByName().get('연간(월간 회의용)').getRecordTypeId();
        newRCUPY2.Name = 'Test_Y1';
        newRCUPY2.GAP_WBS__c = getWBS.Id;
        //WBS set
        insert newRCUPY2;
    }
}