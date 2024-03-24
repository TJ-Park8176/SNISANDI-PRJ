/**
 * Created by MZC01-DGCHOI on 2023-01-02.
 */

@isTest
public with sharing class CalcDistribRate_Batch_Test {
    static WBSandCC__c wbs; 
    static Sender_Receiver__c sender;
    static Sender_Receiver__c receiver;
    static Group__c g;
    static String nowVersion;
    static Date currDate;

    static {
        nowVersion = System.today().year()+'_1';
        currDate   = Date.newInstance(2022,12,1);

        //CalcDistribRate_Batch TEST DATA
        List<WBSandCC__c> wbsList = new List<WBSandCC__c>();
        WBSandCC__c wbs_1 = new WBSandCC__c();
        wbs_1.Name = 'testWBS';
        wbs_1.WBS_Code__c = 'F00001';
        wbs_1.Check_WBS_CC_ZF__c = 'WBS';
        wbs_1.General__c = '사업총괄';
        wbs_1.OperationsHeadquarters__c = '서울1본부';
        wbsList.add(wbs_1);

        WBSandCC__c wbs_2 = new WBSandCC__c();
        wbs_2.Name = 'testWBS';
        wbs_2.WBS_Code__c = 'F00002';
        wbs_2.Check_WBS_CC_ZF__c = 'WBS';
        wbs_2.General__c = '리노베이션총괄';
        wbs_2.Team__c = '리노베이션팀';
        wbsList.add(wbs_2);

        WBSandCC__c wbs_3 = new WBSandCC__c();
        wbs_3.Name = 'testWBS';
        wbs_3.WBS_Code__c = 'F00003';
        wbs_3.Check_WBS_CC_ZF__c = 'WBS';
        wbs_3.General__c = '영업총괄';
        wbs_3.Team__c = 'PM사업2팀';
        wbsList.add(wbs_3);

        insert wbsList;

        //wbs 생성일자 어제로....
        Datetime yesterday = Datetime.now().addDays(-1);
        for(WBSandCC__c w : wbsList) {
            Test.setCreatedDate(w.Id, yesterday);
        }

        //실적 배부 비율
//        List<Performance_Distribute_Rate__c> pdrList = new List<Performance_Distribute_Rate__c>();
//        for(WBSandCC__c wbs : wbsList) {
//            for (Integer i = Date.today().month(); i <= 12; i++) {
//                Performance_Distribute_Rate__c pdr = new Performance_Distribute_Rate__c();
//                pdr.Name = i + '월_' + wbs_1.Name;
//                pdr.Calculate_month__c = Date.newInstance(Date.today().year(), i, 1);
//                pdr.WBS_CC__c = wbs_1.Id;
//                pdrList.add(pdr);
//            }
//        }
//        insert pdrList;

        //WBS
        WBSandCC__c wbs_11 = new WBSandCC__c();
        wbs_11.Name = 'testWBS';
        wbs_11.WBS_Code__c = 'F00011';
        wbs_11.Check_WBS_CC_ZF__c = 'CC';
        wbs_11.Ebitda_target__c = '법인(기타)';
        wbs_11.AccountSubjectSort__c = '판';
        insert wbs_11;

        ProfitandLoss__c pl = new ProfitandLoss__c();
        Pl.ProfitandLoss_Type__c = 'EBITDA';
        pl.Name               = '손익현황';
        pl.WBS__c             = wbs_11.Id;
        pl.Calculate_month__c = Date.newInstance(Date.today().year(), 1, 1);
        insert pl;

        WBSandCC__c wbs_12 = new WBSandCC__c();
        wbs_12.Name = 'testWBS';
        wbs_12.WBS_Code__c = 'F00012';
        wbs_12.Check_WBS_CC_ZF__c = 'CC';
        wbs_12.Ebitda_target__c = '법인(안전)';
        insert wbs_12;

        WBSandCC__c wbs_13 = new WBSandCC__c();
        wbs_13.Name = 'testWBS';
        wbs_13.WBS_Code__c = 'F00013';
        wbs_13.Check_WBS_CC_ZF__c = 'CC';
        wbs_13.Ebitda_target__c = '총괄';
        wbs_13.General__c = '사업총괄';
        insert wbs_13;

        WBSandCC__c wbs_14 = new WBSandCC__c();
        wbs_14.Name = 'testWBS';
        wbs_14.WBS_Code__c = 'F00014';
        wbs_14.Check_WBS_CC_ZF__c = 'CC';
        wbs_14.Ebitda_target__c = '본부';
        wbs_14.OperationsHeadquarters__c = '서울1본부';
        insert wbs_14;

        WBSandCC__c wbs_15 = new WBSandCC__c();
        wbs_15.Name = 'testWBS';
        wbs_15.WBS_Code__c = 'F00015';
        wbs_15.Check_WBS_CC_ZF__c = 'CC';
        wbs_15.Ebitda_target__c = '팀';
        wbs_15.General__c = '영업총괄';
        wbs_15.Team__c = 'PM사업2팀';
        insert wbs_15;

        WBSandCC__c wbs_16 = new WBSandCC__c();
        wbs_16.Name = 'testWBS';
        wbs_16.WBS_Code__c = 'F00016';
        wbs_16.Check_WBS_CC_ZF__c = 'CC';
        wbs_16.Ebitda_target__c = '팀';
        wbs_16.General__c = '리노베이션총괄';
        wbs_16.Team__c = '리노베이션팀';
        insert wbs_16;

        //아이템관리
        ItemManagement__c item = new ItemManagement__c();
        item.Name = '아이템관리';
        item.WBS_CC__c = wbs_11.Id;
        insert item;

        //계정 과목 - 판매비와관리비
        AccountSubject__c accSub_1 = new AccountSubject__c();
        accSub_1.UpperSort__c = '판매비와관리비';
        accSub_1.LowerSort__c = '(판)감가상각비';
        insert accSub_1;

        //계정 과목 - 총매출원가
        AccountSubject__c accSub_2 = new AccountSubject__c();
        accSub_2.UpperSort__c = '총매출원가';
        insert accSub_2;


        //매입 - 법인지원비(기타)
        Cost__c c_1 = new Cost__c();
        c_1.Itemmanagementcheck__c = true;
        c_1.Itemmanagement__c = item.Id;
        c_1.WBS__c = wbs_11.Id;
        c_1.CalculateDate__c = Date.newInstance(Date.today().year(), 1, 1);
        c_1.AccountSubjectselect__c = accSub_1.Id;
        c_1.PurchaseAmount__c = 100;
        c_1.Name = '매입';
        insert c_1;

        Cost__c c_2 = new Cost__c();
        c_2.Itemmanagementcheck__c = true;
        c_2.Itemmanagement__c = item.Id;
        c_2.WBS__c = wbs_12.Id;
        c_2.CalculateDate__c = Date.newInstance(Date.today().year(), 2, 1);
        c_2.AccountSubjectselect__c = accSub_1.Id;
        c_2.PurchaseAmount__c = 100;
        c_2.Name = '매입';
        insert c_2;

        Cost__c c_3 = new Cost__c();
        c_3.Itemmanagementcheck__c = true;
        c_3.Itemmanagement__c = item.Id;
        c_3.WBS__c = wbs_13.Id;
        c_3.CalculateDate__c = Date.newInstance(Date.today().year(), 3, 1);
        c_3.AccountSubjectselect__c = accSub_2.Id;
        c_3.PurchaseAmount__c = 100;
        c_3.Name = '매입';
        insert c_3;

        Cost__c c_4 = new Cost__c();
        c_4.Itemmanagementcheck__c = true;
        c_4.Itemmanagement__c = item.Id;
        c_4.WBS__c = wbs_14.Id;
        c_4.CalculateDate__c = Date.newInstance(Date.today().year(), 4, 1);
        c_4.AccountSubjectselect__c = accSub_2.Id;
        c_4.PurchaseAmount__c = 100;
        c_4.Name = '매입';
        insert c_4;

        Cost__c c_5 = new Cost__c();
        c_5.Itemmanagementcheck__c = true;
        c_5.Itemmanagement__c = item.Id;
        c_5.WBS__c = wbs_15.Id;
        c_5.CalculateDate__c = Date.newInstance(Date.today().year(), 5, 1);
        c_5.AccountSubjectselect__c = accSub_2.Id;
        c_5.PurchaseAmount__c = 100;
        c_5.Name = '매입';
        insert c_5;

        Cost__c c_6 = new Cost__c();
        c_6.Itemmanagementcheck__c = true;
        c_6.Itemmanagement__c = item.Id;
        c_6.WBS__c = wbs_16.Id;
        c_6.CalculateDate__c = Date.newInstance(Date.today().year(), 6, 1);
        c_6.AccountSubjectselect__c = accSub_2.Id;
        c_6.PurchaseAmount__c = 100;
        c_6.Name = '매입';
        insert c_6;


        //WBS
        List<WBSandCC__c> newWbsList = new List<WBSandCC__c>();
        newWbsList.add(wbs_1);

        //계정 과목 - 매출액
        AccountSubject__c accSub_11 = new AccountSubject__c();
        accSub_11.AccountSubjectCode__c = 'A1';
        accSub_11.UpperSort__c = '매출액';
        insert accSub_11;

        //계정 과목 - 총매출원가
        AccountSubject__c accSub_22 = new AccountSubject__c();
        accSub_11.AccountSubjectCode__c = 'A2';
        accSub_22.UpperSort__c = '총매출원가';
        insert accSub_22;

        //계정 과목 - (용)감가상각비
        AccountSubject__c accSub_33 = new AccountSubject__c();
        accSub_11.AccountSubjectCode__c = 'A3';
        accSub_33.LowerSort__c = '(용)감가상각비';
        insert accSub_33;

        //매입 - 매출액
        Cost__c c_11 = new Cost__c();
        c_11.Itemmanagementcheck__c = true;
        c_11.Itemmanagement__c = item.Id;
        c_11.WBS__c = wbs_1.Id;
        c_11.CalculateDate__c = Date.newInstance(Date.today().year(), 1, 1);
        c_11.AccountSubjectselect__c = accSub_11.Id;
        c_11.PurchaseAmount__c = 100;
        c_11.Name = '매입-매출액';
        insert c_11;

        //매입 - 총매출원가
        Cost__c c_22 = new Cost__c();
        c_22.Itemmanagementcheck__c = true;
        c_22.Itemmanagement__c = item.Id;
        c_22.WBS__c = wbs_1.Id;
        c_22.CalculateDate__c = Date.newInstance(Date.today().year(), 10, 1);
        c_22.AccountSubjectselect__c = accSub_22.Id;
        c_22.PurchaseAmount__c = 100;
        c_22.Name = '매입-총매출원가';
        insert c_22;

        //매입 - (용)감가상각비
        Cost__c c_33 = new Cost__c();
        c_33.Itemmanagementcheck__c = true;
        c_33.Itemmanagement__c = item.Id;
        c_33.WBS__c = wbs_1.Id;
        c_33.CalculateDate__c = Date.newInstance(Date.today().year(), 11, 1);
        c_33.AccountSubjectselect__c = accSub_33.Id;
        c_33.PurchaseAmount__c = 100;
        c_33.Name = '매입';
        insert c_33;

        //실적 배부 비율
        List<Performance_Distribute_Rate__c> pdrList2 = new List<Performance_Distribute_Rate__c>();
        for(Integer i=1; i<=12; i++) {
            Performance_Distribute_Rate__c pdr = new Performance_Distribute_Rate__c();
            pdr.WBS_CC__c = wbs_1.id;
            pdr.Calculate_month__c = Date.newInstance(Date.today().year(), i, 1);
            pdr.Allocation_rate__c = 50;
            pdr.Wages_salaries_rate__c = 10;
            pdr.Amount_rate__c = 30;
            pdrList2.add(pdr);
        }
        if(pdrList2.size() > 0) insert pdrList2;

        //간접비 배부액
        List<Ebitda_Tmp__c> ebitdaTmpList2 = new List<Ebitda_Tmp__c>();
        for(Integer i=1; i<=12; i++) {
            Ebitda_Tmp__c ebitdaTmp = new Ebitda_Tmp__c();
            ebitdaTmp.Ebitda_Type__c = '법인지원비(기타)';
            ebitdaTmp.CalculateDate__c = Date.newInstance(Date.today().year(), i, 1);
            ebitdaTmpList2.add(ebitdaTmp);

            Ebitda_Tmp__c ebitdaTmp_2 = new Ebitda_Tmp__c();
            ebitdaTmp_2.Ebitda_Type__c = '법인지원비(안전)';
            ebitdaTmp_2.CalculateDate__c = Date.newInstance(Date.today().year(), i, 1);
            ebitdaTmpList2.add(ebitdaTmp_2);

            Ebitda_Tmp__c ebitdaTmp_3 = new Ebitda_Tmp__c();
            ebitdaTmp_3.Ebitda_Type__c = '담당지원비';
            ebitdaTmp_3.CalculateDate__c = Date.newInstance(Date.today().year(), i, 1);
            ebitdaTmpList2.add(ebitdaTmp_3);

            Ebitda_Tmp__c ebitdaTmp_4 = new Ebitda_Tmp__c();
            ebitdaTmp_4.Ebitda_Type__c = '팀지원비';
            ebitdaTmp_4.CalculateDate__c = Date.newInstance(Date.today().year(), i, 1);
            ebitdaTmpList2.add(ebitdaTmp_4);
        }
        if(ebitdaTmpList2.size() > 0) insert ebitdaTmpList2;

        //WBS 생성
        wbs								= new WBSandCC__c();
        wbs.Name 						= 'test';
        wbs.WBS_Code__c 				= 'F00111';
        wbs.Plan_Distribution_Ratio__c 	= 0;
        wbs.Receiver_Target_CC__c		= true;
        wbs.Check_WBS_CC_ZF__c 			= 'CC';
        wbs.AccountSubjectSort__c 		= '용';
        insert wbs;
        
        //WBS 생성
        WBSandCC__c wbs2				= new WBSandCC__c();
        wbs2.Name 						= 'test2';
        wbs2.WBS_Code__c 				= 'F00222';
        wbs2.Plan_Distribution_Ratio__c = 0;
        wbs2.Receiver_Target_CC__c		= true;
        wbs2.Check_WBS_CC_ZF__c			= 'CC';
        wbs2.AccountSubjectSort__c 		= '판';
        insert wbs2;
        
        WBSandCC__c wbs3				= new WBSandCC__c();
        wbs3.Name 						= 'test3';
        wbs3.WBS_Code__c 				= 'F00333';
        wbs3.Plan_Distribution_Ratio__c = 0;
        wbs3.Receiver_Target_CC__c		= true;
        wbs3.Check_WBS_CC_ZF__c			= 'CC';
        wbs3.AccountSubjectSort__c 		= '용';
		insert wbs3;
        
        WBSandCC__c wbs4				= new WBSandCC__c();
        wbs4.Name 						= 'test4';
        wbs4.WBS_Code__c 				= 'F00444';
        wbs4.Plan_Distribution_Ratio__c = 0;
        wbs4.Receiver_Target_CC__c		= true;
        wbs4.Check_WBS_CC_ZF__c			= 'CC';
        wbs4.AccountSubjectSort__c 		= '용';
        insert wbs4;
        
        //WBS
        WBSandCC__c wbs5				= new WBSandCC__c();
        wbs5.Name 						= 'test5';
        wbs5.WBS_Code__c 				= 'F00555';
        wbs5.Plan_Distribution_Ratio__c = 0;
        wbs5.Receiver_Target_CC__c		= true;
        wbs5.Check_WBS_CC_ZF__c			= 'WBS';
        wbs5.AccountSubjectSort__c 		= '용';
        wbs5.OperationsHeadquarters__c  = '서울1본부';
        wbs5.General__c                 = '사업총괄';
        insert wbs5;

        //WBS
        WBSandCC__c wbs6				= new WBSandCC__c();
        wbs6.Name 						= 'test6';
        wbs6.WBS_Code__c 				= 'F00666';
        wbs6.Plan_Distribution_Ratio__c = 0;
        wbs6.Receiver_Target_CC__c		= true;
        wbs6.Check_WBS_CC_ZF__c			= 'WBS';
        wbs6.AccountSubjectSort__c 		= '판';
        wbs6.OperationsHeadquarters__c  = '서울1본부';
        wbs6.General__c                 = '사업총괄';
        insert wbs6;

        //Sender_Receiver__c sender
        sender                          = new Sender_Receiver__c();
        sender.Name                     = 'testSender';
        sender.Type__c                  = 'Sender';
        insert sender;     
        
        //Sender_Receiver__c sender2
        Sender_Receiver__c sender2 		= new Sender_Receiver__c();
        sender2.Name 					= 'testSender2';
        sender2.Type__c 				= 'Sender';
        insert sender2;   
        
        //Sender_Receiver__c receiver
        receiver                        = new Sender_Receiver__c();
        receiver.Name 					= 'testReceiver';
        receiver.Type__c 				= 'Receiver';
        insert receiver;
    
        //Sender_Receiver__c receiver2
        Sender_Receiver__c receiver2 		= new Sender_Receiver__c();
        receiver2.Name 						= 'testReceiver2';
        receiver2.Type__c 					= 'Receiver';
        insert receiver2;
        
        //Group__c
        g                           = new Group__c();
        g.Name                      = 'testGroup';
        g.Sender__c                 = sender.Id;
        g.Recevier__c               = receiver.Id;
        insert g;
        
        //Sender_Receiver_Team_Member__c sender
        Sender_Receiver_Team_Member__c srTeamMember = new Sender_Receiver_Team_Member__c();
        srTeamMember.Group__c                       = g.Id;
        srTeamMember.Sender_Receiver__c             = sender.Id;
        srTeamMember.CC__c                          = wbs.Id;
        insert srTeamMember;
        
        //Sender_Receiver_Team_Member__c receiver
        Sender_Receiver_Team_Member__c srTeamMember2    = new Sender_Receiver_Team_Member__c();
        srTeamMember2.Group__c                          = g.Id;
        srTeamMember2.Sender_Receiver__c                = receiver.Id;
        srTeamMember2.CC__c                             = wbs2.Id;
        insert srTeamMember2;
        
        //Sender_Receiver_Team_Member__c sender2
        Sender_Receiver_Team_Member__c srTeamMember3    = new Sender_Receiver_Team_Member__c();
        srTeamMember3.Group__c                          = g.Id;
        srTeamMember3.Sender_Receiver__c                = sender.Id;
        srTeamMember3.CC__c                             = wbs3.Id;
        insert srTeamMember3;
        
        //Sender_Receiver_Team_Member__c sender2
        Sender_Receiver_Team_Member__c srTeamMember4    = new Sender_Receiver_Team_Member__c();
        srTeamMember4.Group__c                          = g.Id;
        srTeamMember4.Sender_Receiver__c                = receiver.Id;
        srTeamMember4.CC__c                             = wbs4.Id;
        insert srTeamMember4;

    }

    @IsTest
    static void test() {
        Test.startTest();

        DistributeRateController.groupConfirm();

        CalcDistribRate_Batch batch = new CalcDistribRate_Batch();
        Database.executeBatch(batch, 10);
        // SniDaily_sc sc_daily = new SniDaily_sc();
        // sc_daily.execute(null);

        Test.stopTest();
    }
}