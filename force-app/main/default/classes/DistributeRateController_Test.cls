/**
 * @description       : 
 * @author            : jisoolee@mz.co.kr
 * @group             : 
 * @last modified on  : 2023-10-20
 * @last modified by  : jisoolee@mz.co.kr
**/

@IsTest
public class DistributeRateController_Test {
    static WBSandCC__c wbs; 
    static Sender_Receiver__c sender;
    static Sender_Receiver__c receiver;
    static Group__c g;
    static String nowVersion;
    
    static {
        nowVersion = System.today().year()+'_1';
        
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
        wbs2.AccountSubjectSort__c 		= '용';
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
    static void DistributeRateController_Test01() {
        System.debug('----test01 start----');
        Test.startTest();
		DistributeRateController.groupConfirm();

        List<Object> jsonList = new List<Object>();
        Map<String, Object> jsonMap = new Map<String, Object>();
        jsonMap.put('cc_id', wbs.Id);
        jsonMap.put('cc_code', wbs.WBS_Code__c);
        jsonMap.put('cc_name', wbs.Name);
        jsonMap.put('cc_distribute_rate', '10');
        jsonMap.put('cc_link', 'testlink');
        jsonList.add(jsonMap);
        
        DistributeRateController.getPickListValue();
        DistributeRateController.getWBSCCList();
        DistributeRateController.updateRatio(JSON.serialize(jsonList));
        
		// receiver.size() == sender.size()
		
        // Plan_Distribution_Ratio__c SUM == 0
        DistributeRateController.getGroupList('test');
        DistributeRateController.getGroupList(nowVersion);
        
        // Plan_Distribution_Ratio__c SUM > 100
        List<WBSandCC__c> wbsList = [ SELECT Id, Plan_Distribution_Ratio__c
                                      FROM WBSandCC__c
                                      WHERE Name = 'test2'
                                      LIMIT 1];
        wbsList[0].Plan_Distribution_Ratio__c = 0.13;
        update wbsList;
        DistributeRateController.getGroupList(nowVersion);
        
        // Plan_Distribution_Ratio__c SUM < 100
        wbsList[0].Plan_Distribution_Ratio__c = 0.09;
        update wbsList;
        DistributeRateController.getGroupList(nowVersion);
        Test.stopTest();
    }

    @IsTest
    static void DistributeRateController_Test02() {
        System.debug('----test02 start----');
        Test.startTest();
        
		// receiver.size() < sender.size()
		   
        WBSandCC__c wbs5				= new WBSandCC__c();
        wbs5.Name 						= 'test5';
        wbs5.WBS_Code__c 				= 'F00005';
        wbs5.Plan_Distribution_Ratio__c = 0;
        wbs5.Receiver_Target_CC__c		= true;
        wbs5.Check_WBS_CC_ZF__c			= 'CC';
        wbs5.AccountSubjectSort__c 		= '용';
		insert wbs5;
        
        //Sender_Receiver_Team_Member__c sender2
        Sender_Receiver_Team_Member__c srTeamMember = new Sender_Receiver_Team_Member__c();
        srTeamMember.Group__c = g.Id;
        srTeamMember.Sender_Receiver__c = sender.Id;
        srTeamMember.CC__c = wbs5.Id;
        insert srTeamMember;
        
		DistributeRateController.groupConfirm();
        
        // Plan_Distribution_Ratio__c SUM == 0
        DistributeRateController.getGroupList(nowVersion);
        
        // Plan_Distribution_Ratio__c SUM > 100
        List<WBSandCC__c> wbsList = [ SELECT Id, Plan_Distribution_Ratio__c
                                      FROM WBSandCC__c
                                      WHERE Name = 'test2'
                                      LIMIT 1];
        wbsList[0].Plan_Distribution_Ratio__c = 0.13;
        update wbsList;
        DistributeRateController.getGroupList(nowVersion);
        
        // Plan_Distribution_Ratio__c SUM < 100
        wbsList[0].Plan_Distribution_Ratio__c = 0.02;
        update wbsList;
        DistributeRateController.getGroupList(nowVersion);
        
        Test.stopTest();
    }

    @IsTest
    static void DistributeRateController_Test03() {
        System.debug('----test03 start----');
        Test.startTest();
        
		// receiver.size() > sender.size()	        
        WBSandCC__c wbs6				= new WBSandCC__c();
        wbs6.Name 						= 'test6';
        wbs6.WBS_Code__c 				= 'F00006';
        wbs6.Plan_Distribution_Ratio__c = 0;
        wbs6.Receiver_Target_CC__c		= true;
        wbs6.Check_WBS_CC_ZF__c			= 'CC';
        wbs6.AccountSubjectSort__c 		= '용';
		insert wbs6;
        
        //Sender_Receiver_Team_Member__c sender2
        Sender_Receiver_Team_Member__c srTeamMember = new Sender_Receiver_Team_Member__c();
        srTeamMember.Group__c 						= g.Id;
        srTeamMember.Sender_Receiver__c 			= receiver.Id;
        srTeamMember.CC__c 							= wbs6.Id;
        insert srTeamMember;

		DistributeRateController.groupConfirm();        
        // Plan_Distribution_Ratio__c SUM == 0
        DistributeRateController.getGroupList(nowVersion);
        
        // Plan_Distribution_Ratio__c SUM > 100
        wbs6.Plan_Distribution_Ratio__c = 0.13;
        update wbs6;
        DistributeRateController.getGroupList(nowVersion);
        
        // Plan_Distribution_Ratio__c SUM < 100
        wbs6.Plan_Distribution_Ratio__c = 0.02;
        update wbs6;
        DistributeRateController.getGroupList(nowVersion);
        
        Test.stopTest();
    }
    
    @IsTest
    static void DistributeRateController_Test04(){
        System.debug('----test04 start----');
		DistributeRateController.groupConfirm();
        
        DistributeRateController.updateGroupDistributionRatio(nowVersion);
        
        // Plan_Distribution_Ratio__c SUM != 0
        List<WBSandCC__c> wbsList = [ SELECT Id, Plan_Distribution_Ratio__c
                                      FROM WBSandCC__c
                                      WHERE Name = 'test2'
                                      LIMIT 1];
        wbsList[0].Plan_Distribution_Ratio__c = 0.13;
        update wbsList;
        DistributeRateController.updateGroupDistributionRatio(nowVersion);
    }
    
    @IsTest
    static void DistributeRateController_Test05(){
        System.debug('----test05 start----');
		DistributeRateController.groupConfirm();
        DistributeRateController.getGroupList('test');
        DistributeRateController.updateGroupDistributionRatio('test');
        DistributeRateController.getGroupList('test2');
        DistributeRateController.updateGroupDistributionRatio('test2');
        
        List<Object> jsonList 		= new List<Object>();
        Map<String, Object> jsonMap = new Map<String, Object>();
        jsonMap.put('cc_name', 'exceptionTest');
        jsonList.add(jsonMap);
        DistributeRateController.updateRatio(JSON.serialize(jsonList));
    }
    
    @IsTest
    static void DistributeRateController_Test07(){
        System.debug('----test07 start----');
		DistributeRateController.groupConfirm();
        DistributeRateController.groupReset();
        DistributeRateController.getGroupList(nowVersion);
        
        Plan_Distribution_Version__c version = new Plan_Distribution_Version__c();
        version.Year__c = System.today().year();
        version.Name = System.today().year() + '_1';
        insert version;
		DistributeRateController.groupConfirm();    
		DistributeRateController.groupReset(); 
        
        List<Plan_Distribution_Version__c> versionNameList = [ SELECT Id
                                                               FROM Plan_Distribution_Version__c ];
        delete versionNameList;
        DistributeRateController.getGroupList('exceptionTest');
    }
}