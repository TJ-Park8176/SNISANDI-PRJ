@isTest
public class Group_tr_Test {
    @isTest
    static void Group_tr_Test01(){
        Plan_Distribution_Version__c version = new Plan_Distribution_Version__c();
        version.Name = '2023_1';
        version.Latest_Version__c = true;
        version.Year__c = 2023;
        insert version;

        //Sender_Receiver__c sender
        Sender_Receiver__c sender = new Sender_Receiver__c();
        sender.Name = 'testSender';
        sender.Type__c = 'Sender';
        sender.Plan_Distribution_Version__c = version.Id;
        insert sender;     
        
        //Sender_Receiver__c sender2
        Sender_Receiver__c receiver     = new Sender_Receiver__c();
        receiver.Name 					= 'testReceiver';
        receiver.Type__c 				= 'Receiver';
        receiver.Plan_Distribution_Version__c = version.Id;
        insert receiver; 
        
        //Group__c
        Group__c g = new Group__c();
        g.Name = 'testGroup';
        g.Sender__c = sender.Id;
        g.Recevier__c = receiver.Id;
        g.Plan_Distribution_Version__c = version.Id;
        insert g;
        
        g.Sender__c = null;
        g.Recevier__c = null;
        update g;
    }
}