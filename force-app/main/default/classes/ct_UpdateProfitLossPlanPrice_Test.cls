@isTest
public with sharing class ct_UpdateProfitLossPlanPrice_Test {
    static WBSandCC__c wbs; 
    static Sender_Receiver__c sender;
    static Sender_Receiver__c receiver;
    static Group__c g;
    static String nowVersion;
    static Date currDate;
    
    static {
        nowVersion = System.today().year()+'_1';
        currDate   = Date.newInstance(2022,12,1);

        //계정 과목
        AccountSubject__c accSubP = new AccountSubject__c();
        accSubP.Name = '매출액';
        accSubP.UpperSort__c = '매출액';
        accSubP.MiddleSort__c = '매출액';
        accSubP.LowerSort__c = '(판)감가상각비';
        accSubP.AccountSubjectsort__c = '판';
        insert accSubP;

        //계정 과목
        AccountSubject__c accSubY = new AccountSubject__c();
        accSubY.Name = '매출액';
        accSubY.UpperSort__c = '매출액';
        accSubY.MiddleSort__c = '매출액';
        accSubY.LowerSort__c = '(용)감가상각비';
        accSubY.AccountSubjectsort__c = '용';
        insert accSubY;
        
        //WBS 생성
        wbs								= new WBSandCC__c();
        wbs.Name 						= 'test';
        wbs.WBS_Code__c 				= 'F00001';
        wbs.Plan_Distribution_Ratio__c 	= 0;
        wbs.Receiver_Target_CC__c		= true;
        wbs.Check_WBS_CC_ZF__c 			= 'CC';
        wbs.AccountSubjectSort__c 		= '용';
        insert wbs;
        
        //WBS 생성
        WBSandCC__c wbs2				= new WBSandCC__c();
        wbs2.Name 						= 'test2';
        wbs2.WBS_Code__c 				= 'F00002';
        wbs2.Plan_Distribution_Ratio__c = 0;
        wbs2.Receiver_Target_CC__c		= true;
        wbs2.Check_WBS_CC_ZF__c			= 'CC';
        wbs2.AccountSubjectSort__c 		= '판';
        insert wbs2;
        
        WBSandCC__c wbs3				= new WBSandCC__c();
        wbs3.Name 						= 'test3';
        wbs3.WBS_Code__c 				= 'F00003';
        wbs3.Plan_Distribution_Ratio__c = 0;
        wbs3.Receiver_Target_CC__c		= true;
        wbs3.Check_WBS_CC_ZF__c			= 'CC';
        wbs3.AccountSubjectSort__c 		= '용';
		insert wbs3;
        
        WBSandCC__c wbs4				= new WBSandCC__c();
        wbs4.Name 						= 'test4';
        wbs4.WBS_Code__c 				= 'F00004';
        wbs4.Plan_Distribution_Ratio__c = 0;
        wbs4.Receiver_Target_CC__c		= true;
        wbs4.Check_WBS_CC_ZF__c			= 'CC';
        wbs4.AccountSubjectSort__c 		= '용';
        insert wbs4;
        
        //WBS
        WBSandCC__c wbs5				= new WBSandCC__c();
        wbs5.Name 						= 'test5';
        wbs5.WBS_Code__c 				= 'F00005';
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
        wbs6.WBS_Code__c 				= 'F00006';
        wbs6.Plan_Distribution_Ratio__c = 0;
        wbs6.Receiver_Target_CC__c		= true;
        wbs6.Check_WBS_CC_ZF__c			= 'WBS';
        wbs6.AccountSubjectSort__c 		= '판';
        wbs6.OperationsHeadquarters__c  = '서울1본부';
        wbs6.General__c                 = '사업총괄';
        insert wbs6;

        //사업계획(아이템관리)
        ItemManagement_Plan__c itemMng = new ItemManagement_Plan__c();
        itemMng.Name = '아이템관리 TEST';
        itemMng.WBS_CC__c = wbs.id;
        insert itemMng;

        //사업계획(매입)
        Cost_Plan__c cstPlan = new Cost_Plan__c();
        cstPlan.WBS__c                  = wbs.Id;
        cstPlan.AccountSubjectselect__c = accSubP.Id;
        cstPlan.ItemManagement_Plan__c  = itemMng.Id;
        cstPlan.PlanPurchaseAmount__c   = 100;
        cstPlan.CalculateDate__c        = currDate;
        cstPlan.Itemmanagementcheck__c  = true;
        insert cstPlan;

        
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


    @isTest
    static void test() { 
        Test.startTest();

        DistributeRateController.groupConfirm();

        ct_UpdateProfitLossPlanPrice.updatePrice('2024');

        Test.stopTest();
    }
}