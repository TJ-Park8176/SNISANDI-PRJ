public without sharing class SANDI_AccountMergeFlowService {
	
    @InvocableMethod(label='Account Flow Action' category='Account')
    public static List<ResponseContext> calledactionName (List<RequestContext> contexts) {
        List<ResponseContext> responses = new List<ResponseContext>();
      
        if(contexts.size() > 0){
            for(RequestContext context : contexts){
                System.debug(context);
                switch on context.actionName {
                    when 'accountMerge' {
                        ResponseContext response = new ResponseContext();
                        response.isSuccess = accountMergeList(context.masterRecordId ,context.mergeAccountIds);
                        responses.add(response);
                    }
                    when 'accountUserDML' {
                        System.debug(context.actionName);
                        accountUserDML(context.masterRecordId ,'B2B');
                    }
                    when 'shopperUser' {
                        System.debug(context.actionName);
                        accountUserDML(context.masterRecordId ,'D2C');
                    }
                    when 'inactiveUser' {
                        System.debug(context.actionName);
                        accountUserDML(context.masterRecordId ,'inActive');
                    }
                }
            }
        }
        return responses;
    }

    //public static Boolean accountMergeList(List<RequestContext> requests) {
    public static Boolean accountMergeList(String masterId ,List<Id> mergeIdList) {
        Boolean returnVal = false;
        Savepoint sp = Database.setSavepoint();
        
        try {
            if(!mergeIdList.isEmpty()) {
                System.debug('accountMergeList');
                System.debug('masterId | '+masterId);
                System.debug('mergeIdList | '+mergeIdList);
                Id bizRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId();
                Id masterRecordId =masterId; 
                Set<Id> mergeIds = new Set<Id>();
                mergeIds.addAll(mergeIdList);

                System.debug('Merge될 AccountId');
                System.debug(mergeIds);
                //// Merge될 어카운트 정보확인용
                Account[] checkUpdate = [SELECT Id, Name, (SELECT FirstName,LastName From Contacts) FROM Account WHERE Id IN :mergeIds];
                System.debug('checkUpdate >>' +checkUpdate);
                //// 1.Master Account Query 
                System.debug('2. Queries to get the inserted accounts');
                Account masterAcct = [SELECT Id, Name FROM Account WHERE Id =:masterRecordId LIMIT 1];
                System.debug('masterAcct > ' +masterAcct);
                
                //// 2. To Be Merged Accounts Query 
                Account[] mergeAcct = [SELECT Id, Name ,IsActive__c, SANDI_ReasonforInactivity__c FROM Account WHERE Id IN :mergeIds];
                List<Account> delAcct = new List<Account>();
               
                //// 3. Before Merged Account Field Update
                for (Account da : mergeAcct) {
                    da.IsActive__c = False;
                    da.SANDI_ReasonforInactivity__c = '회원병합';
                    delAcct.add(da);
                }
                update delAcct;

                System.debug('mergeAcct Size >' +mergeAcct.size());
                System.debug('mergeAcct > ' +mergeAcct);
                
                //// 4. Merge : single merge only up to 3 records include master record
                if (mergeAcct.size()<=3) {
                    System.debug('mergeAcct.size()<=3');
                    merge masterAcct mergeAcct;
                } else {
                    //3개 이상
                    System.debug('mergeAcct 3개 이상');
                    for (Account mgAcct : mergeAcct) {
                        merge masterAcct mgAcct;
                    }
                }

                //// Verify that the merge record got deleted
                Account[] result = [SELECT Id, Name FROM Account WHERE Id IN :mergeIds];
                System.debug('result size() >> '+ result.size());
                Contact[] resultCon = [SELECT Id, FirstName, LastName FROM Contact WHERE AccountId =:masterRecordId];
                System.debug('resultCon size() >> '+ resultCon.size());
                
                //// 5. Restoring Accounts After Merge (히스토리성) 
                Account[] restoreAccts = [SELECT Id, name,SystemModstamp FROM Account WHERE Id IN :mergeIds ALL ROWS];
                System.debug(restoreAccts);

                If(restoreAccts.size()>0) {
                    undelete restoreAccts;
                }
                
                //// 6. User Profile / Permission set UpDate called @future
                System.debug('Merge Record call @future ---->>');
                accountUserDML(masterRecordId ,'B2B');
              
            }
            System.debug('return isSuccess = true');
            returnVal = true;
        } catch (Exception e) {
            System.debug('errororororororor');
            Database.rollback(sp);
        }

        return returnVal;
    }

    @future
    public static void accountUserDML(String acctId, String fromWhere){
        Savepoint sp = Database.setSavepoint();
     
        try {
            switch on fromWhere {
                when 'B2B' {
                    System.debug('updatetUserProfileWithRole >>>>>>>>>>>');
                    Id proId  = [SELECT Id FROM Profile WHERE Name='Customer Community Plus Login User'].Id;
                    Id roleId = [SELECT Id FROM UserRole WHERE DeveloperName ='CustomerPersonAccount2'].Id; // 현정 고객 개인 계정
                    Id psId   = [SELECT Id FROM PermissionSet WHERE Name='Buyer_PSG'].Id;
                    // User Update

                    System.debug(proId+' | '+roleId+' | '+psId);
                
                    System.debug('Record Users Update Start');
                    User[] userHasAccountId = [SELECT Id, ProfileId, UserRoleId FROM User WHERE AccountId =:acctId AND ProfileId !=:proId];
                    List<User> userP = new List<User>();
                    Id roleIdUs ;
                
                    if(userHasAccountId.size()>0) {
                        if(userHasAccountId.size()>1) {
                            UserRole role = new UserRole();
                            role.portalType = 'CustomerPortal';
                            role.PortalAccountId = acctId;
                            role.OpportunityAccessForAccountOwner = 'None';
                            insert role;
                            roleIdUs = role.Id;

                        }

                        List<PermissionSetAssignment> permission = new List<PermissionSetAssignment>();
                    
                        for (User us : userHasAccountId ) {
                            PermissionSetAssignment psa = new PermissionSetAssignment();

                            us.ProfileId  = proId;
                            us.UserRoleId = roleIdUs == null ? roleId :roleIdUs;
                            userP.add(us);
                            
                            ////////////// Permission ////////////////////
                            psa.PermissionSetId = psId;
                            psa.AssigneeId      = us.Id;
                            permission.add(psa);
                        }
                        // Update User
                        update userP;
                        // Insert Permission
                        insert permission;
                    }
                    System.debug('Users Update Finish -------> Success');
                }
                when 'D2C' { //'D2C'
                    System.debug('D2C >>>>>>>>>>>');
                    // Id proId  = [SELECT Id FROM Profile WHERE Name='Shopper Profile'].Id;
                    Id psId   = [SELECT Id FROM PermissionSet WHERE Name='Shopper_PSG'].Id;
                    // User Update
                    User[] d2cUser = [SELECT Id FROM User WHERE AccountId =:acctId];
                    List<User> d2cUp = new List<User>();
                  
                    if(d2cUser.size()>0) {
                        List<PermissionSetAssignment> dPer = new List<PermissionSetAssignment>();
                    
                        for (User usr : d2cUser ) {
                            PermissionSetAssignment d2cPs = new PermissionSetAssignment();
                           
                            ////////////// Permission ////////////////////
                            d2cPs.PermissionSetId = psId;
                            d2cPs.AssigneeId      = usr.Id;
                            dPer.add(d2cPs);
                        }

                        insert dPer;
                    }
                    System.debug('D2C User Update Finish -------> Success');
                }
                when else { //inActive : Partner User
                    System.debug('Partner User >>>>>>>>>>>');
                    User[] userPartnerId = [SELECT  Id, IsActive, IsPortalEnabled 
                                            FROM    User 
                                            WHERE   AccountId =:acctId 
                                            AND     Profile.Name = 'Custom:Partner Community User'];
                    List<User> partnerUser = new List<User>();

                    if(userPartnerId.size()>0) {
                        for (User up : userPartnerId ) {
                            up.IsActive  = false;
                            up.IsPortalEnabled = false;
                            partnerUser.add(up);
                        }
                        // Update Partner User
                        update partnerUser;
                    }
                    System.debug('Users inActive Finish -------> Success');
                }
            }
            

            System.debug('@future method 성공');

        } catch (Exception e) {
            Database.rollback(sp);
            System.debug('@future method 실패');
        }
    }

    public class RequestContext {
        @Invocablevariable(label='Action Name' required=true) public String actionName;  
		@Invocablevariable(label='Record Id (Master Record Id)' required=true) public Id masterRecordId;    
        @InvocableVariable(label='Account Id\'s to Merge' description='recordId to Merge' required=false) 
        public List<Id> mergeAccountIds;
    }
    
    public class ResponseContext {
		@Invocablevariable(label='isSuccess') public Boolean isSuccess;   
    }
}