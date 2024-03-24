/****************************************************************************************
  * @filename      : KDCE_ExpireCoupon_ba
  * @projectname   : Omni Channel/Rating and Review
  * @author        : Megazone Cloud_Sungheum Park
  * @date          : 2022-09-01 오전 11:43
  * @group         :
  * @group-content :
  * @description   : 만료 쿠폰 처리 배치
  * @tester        :
  * @reference     :
  * @modification Log
  * =========================================================================
  * ver     date                    author                    description
  * =========================================================================
    0.1     2022-09-01 오전 11:43     Megazone Cloud_Sungheum Park        Create
****************************************************************************************/

@IsTest
private class temp_CostPlan_ba_ts {

    @IsTest
    static void testBehavior() {

        WBSandCC__c wbs1 = new WBSandCC__c();
        wbs1.Name = 'tesasdt';
        wbs1.WBS_Code__c = 'F00002';
        wbs1.Check_WBS_CC_ZF__c = 'wbs';
        insert wbs1;

        WBSandCC__c wbs = new WBSandCC__c();
        wbs.Name = 'test';
        wbs.WBS_Code__c = 'F00001';
        wbs.Check_WBS_CC_ZF__c = 'wbs';
        insert wbs;

        ItemManagement_Plan__c itemMng = new ItemManagement_Plan__c();
        itemMng.Name = '아이템관리 TEST';
        itemMng.WBS_CC__c = wbs.id;
        insert itemMng;

        //Cost_action_plan__c 생성 - 총매출원가, 공통비배부(용), 판매비와관리비, 공통비배부(판)
        List<String> uppList = new List<String> {'총매출원가', '공통비배부(용)', '판매비와관리비', '공통비배부(판)'};

        List<AccountSubject__c> accSubList = new List<AccountSubject__c>();
        for(Integer i=0; i<uppList.size(); i++) {
            AccountSubject__c accSub = new AccountSubject__c();
            accSub.Name = uppList[i];
            accSub.UpperSort__c = uppList[i];
            accSub.AccountSubjectCode__c = 'A' + i;
            accSubList.add(accSub);
        }
        insert accSubList;

        List<Cost_plan__c> cpList = new List<Cost_plan__c>(); //Cost_plan__c 생성 - 총매출원가, 공통비배부(용), 판매비와관리비, 공통비배부(판)
        for(AccountSubject__c accSub : accSubList) {

            Cost_plan__c cp = new Cost_plan__c();
            cp.Name = '매입계획';
            cp.WBS__c = wbs1.Id;
            cp.Itemmanagement_Plan__c = itemMng.Id;
            cp.calculateDate__c = Date.newInstance(2022, 1, 1);
            cp.PlanPurchaseAmount__c = 100;
            cp.AccountSubjectselect__c = accSub.Id;
            cp.Itemmanagementcheck__c = true;
            cp.calculateDate__c = system.today();
            cpList.add(cp);
        }

        insert cpList;



        Test.startTest();
        temp_CostPlan_ba batch = new temp_CostPlan_ba();
        Database.executeBatch(batch, 200);
        Test.stopTest();

    }
}