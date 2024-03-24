@isTest
public with sharing class SenderReceiverTeamMember_tr_Test {
    
    @isTest
    static void test() {    
        Test.startTest();

        //WBS 생성
        WBSandCC__c wbs  				= new WBSandCC__c();
        wbs.Name 						= 'test';
        wbs.WBS_Code__c 				= 'F00111';
        wbs.Plan_Distribution_Ratio__c 	= 0;
        wbs.Receiver_Target_CC__c		= true;
        wbs.Check_WBS_CC_ZF__c 			= 'CC';
        wbs.AccountSubjectSort__c 		= '용';
        insert wbs;

        
        //Sender_Receiver__c sender2
        Sender_Receiver__c sender 		= new Sender_Receiver__c();
        sender.Name 					= 'testSender2';
        sender.Type__c 				    = 'Sender';
        insert sender;   
        
        //Sender_Receiver__c receiver
        Sender_Receiver__c receiver     = new Sender_Receiver__c();
        receiver.Name 					= 'testReceiver';
        receiver.Type__c 				= 'Receiver';
        insert receiver;
    
        //Sender_Receiver__c receiver2
        Sender_Receiver__c receiver2 	= new Sender_Receiver__c();
        receiver2.Name 					= 'testReceiver2';
        receiver2.Type__c 				= 'Receiver';
        insert receiver2;
        
        //Group__c
        Group__c g                  = new Group__c();
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


        Test.stopTest();
    }
}