/**
 * @description       : 
 * @author            : jisoolee@mz.co.kr
 * @group             : 
 * @last modified on  : 2023-10-31
 * @last modified by  : jisoolee@mz.co.kr
**/

public class DistributeRateController {
    @AuraEnabled(cacheable=true)
    public static List<String> getPickListValue(){
        List<String> returnList = new List<String>();

        try {
            List<Plan_Distribution_Version__c> versionList = [ SELECT Id, Name
                                                               FROM Plan_Distribution_Version__c 
                                                               ORDER BY Index__c DESC ];
            for(Plan_Distribution_Version__c version : versionList){
                returnList.add(version.Name);
            }
        } catch (Exception e) {
            System.debug('e : '+e);
            System.debug('e.getLine : '+e.getLineNumber());
            System.debug('e.message : '+e.getMessage());
        }
        return returnList;
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getWBSCCList() {
        List<Map<String, Object>> result    = new List<Map<String, Object>>();

        try {
            List<WBSandCC__c> wbsccList = [ SELECT Id, WBS_Code__c, Name, Plan_Distribution_Ratio__c
                                            FROM WBSandCC__c
                                            WHERE Receiver_Target_CC__c = true
                                            ORDER BY Plan_Distribution_Ratio__c DESC ];

            if(wbsccList.size() > 0){
                for(WBSandCC__c wbscc : wbsccList){
                    Map<String, Object> returnMap = new Map<String, Object>();

                    returnMap.put('cc_id', wbscc.Id);
                    returnMap.put('cc_code', wbscc.WBS_Code__c);
                    returnMap.put('cc_name', wbscc.Name);
                    returnMap.put('cc_distribute_rate', (wbscc.Plan_Distribution_Ratio__c == null ? 0 : wbscc.Plan_Distribution_Ratio__c * 100));
                    result.add(returnMap);
                }
            }
            return result;
        }catch (Exception e) {
            System.debug('e : '+e);
            System.debug('e.getLine : '+e.getLineNumber());
            System.debug('e.message : '+e.getMessage());
            // check!
            return result;
        }
    }
    
    @AuraEnabled
    public static ReturnWrapper updateRatio(String jsonData){
        System.debug('jsonData: '+ jsonData);
        List<Object> wrapperList        = (List<Object>)JSON.deserializeUntyped(jsonData);
        List<WBSandCC__c> updateList    = new List<WBSandCC__c>();
        ReturnWrapper returnWrapper     = new ReturnWrapper();

        try {
            for(Object wrapper : wrapperList){
                Map<String, Object> wrapperMap = (Map<String, Object>)wrapper;
                
                WBSandCC__c wbscc 					= new WBSandCC__c ();
                wbscc.Id                            = String.valueOf(wrapperMap.get('cc_id'));
                wbscc.Plan_Distribution_Ratio__c    = Double.valueOf(wrapperMap.get('cc_distribute_rate'))  / 100;
                updateList.add(wbscc);
            }
            // update updateList;

            List<Database.SaveResult> saveResultList = Database.update(updateList);
            for(Database.SaveResult saveResult : saveResultList){
                if (saveResult.isSuccess()) {
                    returnWrapper.CODE       = 'SUCCESS';
                    returnWrapper.MESSAGE    = '배부 비율 저장 완료';
                } else {
                    String errorMsg = '';
                    for (Database.Error error : saveResult.getErrors()) {
                        errorMsg += error.getMessage() + '/n';
                    }
                    returnWrapper.CODE       = 'ERROR';
                    returnWrapper.MESSAGE    = errorMsg;
                }
            }
            return returnWrapper;
        } catch (Exception e) {
            System.debug('e : '+e);
            System.debug('e.getLine : '+e.getLineNumber());
            System.debug('e.message : '+e.getMessage());
            // check!
            returnWrapper.CODE       = 'ERROR';
            returnWrapper.MESSAGE    = +e.getMessage();
            return returnWrapper;
        }
    }

    
    @AuraEnabled(cacheable=true)
    public static List<GroupWrapper> getGroupList(String versionName) {
        ReturnWrapper returnWrapper                                         = new ReturnWrapper();
        Map<String, List<Sender_Receiver_Team_Member__c>> senderGroupMap    = new Map<String, List<Sender_Receiver_Team_Member__c>>();
        Map<String, List<Sender_Receiver_Team_Member__c>> receiverGroupMap  = new Map<String, List<Sender_Receiver_Team_Member__c>>();
        Map<String, Double> receiverRatioMap                                = new Map<String, Double>();
        List<Sender_Receiver_Team_Member__c> srGroupList                    = new List<Sender_Receiver_Team_Member__c>();
        List<CCWrapper> ccList                                              = new List<CCWrapper>();
        List<GroupWrapper> returnList                                       = new List<GroupWrapper>();
        List<Sender_Receiver_Team_Member__c> senderTeamMemberList           = new List<Sender_Receiver_Team_Member__c>();
        List<Sender_Receiver_Team_Member__c> receiverTeamMemberList         = new List<Sender_Receiver_Team_Member__c>();
        List<Sender_Receiver_Team_Member__c> srTeamMemberList               = new List<Sender_Receiver_Team_Member__c>();
        List<Group__c> groupList                                            = new List<Group__c>(); 
        String srGroupId                                                    = '';
        String vName                                                        = '';
        Decimal calculateRatio                                              = 0;
        Integer decimalPlaces                                               = 0;
        Decimal roundedCalculateRatio                                       = 0;
		Boolean latestVersion												= false;
        
        try {
            if(Test.isRunningTest() && versionName == 'exceptionTest') throw new DMLException();
            
            List<Plan_Distribution_Version__c> versionNameList = [ SELECT Id, Name, Latest_Version__c 
                                                                   FROM Plan_Distribution_Version__c
                                                                   ORDER BY Latest_Version__c DESC, Name DESC
                                                                   LIMIT 1 ];

            if(versionNameList.size() > 0){
                vName = versionNameList[0].Name;
            }else{
                GroupWrapper groupWrapper   = new GroupWrapper();  
                returnWrapper.CODE          = 'ERROR';
                returnWrapper.MESSAGE       = 'Version 등록이 선행되어야 합니다.';
                groupWrapper.returnWrapper  = returnWrapper;
                returnList.add(groupWrapper);
                return returnList;  
            }

            if(versionName == vName && versionNameList[0].Latest_Version__c == true){
                groupList = [ SELECT Id, Name, Sender__c, Sender__r.Name, Recevier__c, Recevier__r.Name
                              FROM Group__c
                              WHERE Latest_Version__c = true ];
                
                srTeamMemberList = [ SELECT Id, Group__c, Group__r.name, Group_Distribution_Ratio__c,
                                            Sender_Receiver__c, Sender_Receiver__r.Name, Sender_Receiver__r.Type__c, 
                                            CC__c, CC__r.Name, CC__r.WBS_Code__c, CC__r.Plan_Distribution_Ratio__c
                                     FROM Sender_Receiver_Team_Member__c  
                                     WHERE Latest_Version__c = true 
                                     ORDER BY Group__c ];
                
                latestVersion = true;
            }else{
                groupList = [ SELECT Id, Name, Sender__c, Sender__r.Name, Recevier__c, Recevier__r.Name
                              FROM Group__c
                              WHERE Plan_Distribution_Version__r.Name =: versionName ];
                
                srTeamMemberList = [ SELECT Id, Group__c, Group__r.name, Group_Distribution_Ratio__c,
                                            Sender_Receiver__c, Sender_Receiver__r.Name, Sender_Receiver__r.Type__c, 
                                            CC__c, CC__r.Name, CC__r.WBS_Code__c, CC__r.Plan_Distribution_Ratio__c
                                     FROM Sender_Receiver_Team_Member__c  
                                     WHERE Plan_Distribution_Version__r.Name =: versionName  
                                     ORDER BY Group__c ];
            }
    
            
            if(srTeamMemberList.size() > 0){
                for(Sender_Receiver_Team_Member__c srTeamMember : srTeamMemberList){
                    if(srTeamMember.Sender_Receiver__r.Type__c == 'Sender'){
                        if(senderGroupMap.containsKey(srTeamMember.Group__c)){
                            senderTeamMemberList.add(srTeamMember);
                            senderGroupMap.put(srTeamMember.Group__c, senderTeamMemberList);
                        }else{
                            senderTeamMemberList = new List<Sender_Receiver_Team_Member__c>();
                            senderTeamMemberList.add(srTeamMember);
                            senderGroupMap.put(srTeamMember.Group__c, senderTeamMemberList);
                        }
                    }else{
                        if(receiverGroupMap.containsKey(srTeamMember.Group__c)){
                            receiverTeamMemberList.add(srTeamMember);
                            receiverGroupMap.put(srTeamMember.Group__c, receiverTeamMemberList);
                        }else{
                            receiverTeamMemberList = new List<Sender_Receiver_Team_Member__c>();
                            receiverTeamMemberList.add(srTeamMember);
                            receiverGroupMap.put(srTeamMember.Group__c, receiverTeamMemberList);
                        }
                        receiverRatioMap.put(srTeamMember.Group__c + '_' + srTeamMember.CC__r.WBS_Code__c, srTeamMember.Group_Distribution_Ratio__c);
                    }
                }
                System.debug('receiverRatioMap: '+receiverRatioMap);
                
                for(Group__c g : groupList){
                    GroupWrapper groupWrapper   = new GroupWrapper();
                    groupWrapper.latestVersion 	= latestVersion;
                    groupWrapper.group_name     = g.Name;
                    groupWrapper.sender_name    = g.Sender__r.Name;
                    groupWrapper.receiver_name  = g.Recevier__r.Name;
                                            
                    if(senderGroupMap.containsKey(g.Id) && receiverGroupMap.containsKey(g.Id)){
                        ccList = new List<CCWrapper>();
    
                        if(senderGroupMap.get(g.Id).size() > receiverGroupMap.get(g.Id).size()){
                            System.debug('sender > receiver');
                            for(Integer num=0 ; num<senderGroupMap.get(g.Id).size() ; num++){
                                CCWrapper ccWrapper                 = new CCWrapper();  
                                ccWrapper.sender_cc_code            = senderGroupMap.get(g.Id)[num].CC__r.WBS_Code__c;
                                ccWrapper.sender_cc_name            = senderGroupMap.get(g.Id)[num].CC__r.Name;
                                ccWrapper.cc_sender_distribute_rate = String.valueOf(senderGroupMap.get(g.Id)[num].Group_Distribution_Ratio__c);
    
                                if(num < receiverGroupMap.get(g.Id).size()){
                                    ccWrapper.receiver_cc_code = receiverGroupMap.get(g.Id)[num].CC__r.WBS_Code__c;
                                    ccWrapper.receiver_cc_name = receiverGroupMap.get(g.Id)[num].CC__r.Name;
    
                                    if(receiverRatioMap.containsKey(g.Id + '_' + ccWrapper.receiver_cc_code)){
                                        if(receiverRatioMap.get(g.Id + '_' + ccWrapper.receiver_cc_code) == null){
                                            ccWrapper.cc_distribute_rate = '0';
                                        }else{
                                            calculateRatio          = receiverRatioMap.get(g.Id + '_' + ccWrapper.receiver_cc_code)*100;
                                            decimalPlaces           = calculateRatio.scale();
                                            roundedCalculateRatio   = 0;
                    
                                            if(decimalPlaces > 2){
                                                roundedCalculateRatio = calculateRatio.setScale(2);
                                            }else{
                                                roundedCalculateRatio = calculateRatio;
                                            }
                                            ccWrapper.cc_distribute_rate = String.valueOf(roundedCalculateRatio);
                                        }
                                    }    
                                }else{
                                    ccWrapper.receiver_cc_code      = '';
                                    ccWrapper.receiver_cc_name      = '';
                                    ccWrapper.cc_distribute_rate    = null;
                                }
                                ccList.add(ccWrapper);
                            }
                        }else if(senderGroupMap.get(g.Id).size() < receiverGroupMap.get(g.Id).size()){
                            System.debug('sender < receiver');
                            for(Integer num=0 ; num<receiverGroupMap.get(g.Id).size() ; num++){
    
                                CCWrapper ccWrapper         = new CCWrapper();  
                                ccWrapper.receiver_cc_code  = receiverGroupMap.get(g.Id)[num].CC__r.WBS_Code__c;
                                ccWrapper.receiver_cc_name  = receiverGroupMap.get(g.Id)[num].CC__r.Name;
    
                                if(receiverRatioMap.containsKey(g.Id + '_' + ccWrapper.receiver_cc_code)){
                                    if(receiverRatioMap.get(g.Id + '_' + ccWrapper.receiver_cc_code) == null){
                                        ccWrapper.cc_distribute_rate = '0';
                                    }else{
                                        calculateRatio          = receiverRatioMap.get(g.Id + '_' + ccWrapper.receiver_cc_code)*100;
                                        decimalPlaces           = calculateRatio.scale();
                                        roundedCalculateRatio   = 0;
                
                                        if(decimalPlaces > 2){
                                            roundedCalculateRatio = calculateRatio.setScale(2);
                                        }else{
                                            roundedCalculateRatio = calculateRatio;
                                        }
                                        ccWrapper.cc_distribute_rate = String.valueOf(roundedCalculateRatio);
                                    }
                                }    
        
                                if(num < senderGroupMap.get(g.Id).size()){
                                    ccWrapper.sender_cc_code            = senderGroupMap.get(g.Id)[num].CC__r.WBS_Code__c;
                                    ccWrapper.sender_cc_name            = senderGroupMap.get(g.Id)[num].CC__r.Name;
                                    ccWrapper.cc_sender_distribute_rate = String.valueOf(senderGroupMap.get(g.Id)[num].Group_Distribution_Ratio__c);
                                }else{
                                    ccWrapper.sender_cc_code            = '';
                                    ccWrapper.sender_cc_name            = '';
                                    ccWrapper.cc_sender_distribute_rate = '';
                                }
                                ccList.add(ccWrapper);
                            }
                        }else{  //sender, receiver 수가 같을 때 
                            System.debug('sender == receiver');
                            for(Integer num=0 ; num<receiverGroupMap.get(g.Id).size() ; num++){
    
                                CCWrapper ccWrapper         = new CCWrapper();  
                                ccWrapper.receiver_cc_code  = receiverGroupMap.get(g.Id)[num].CC__r.WBS_Code__c;
                                ccWrapper.receiver_cc_name  = receiverGroupMap.get(g.Id)[num].CC__r.Name;
    
                                if(receiverRatioMap.containsKey(g.Id + '_' + ccWrapper.receiver_cc_code)){
                                    if(receiverRatioMap.get(g.Id + '_' + ccWrapper.receiver_cc_code) == null){
                                        ccWrapper.cc_distribute_rate = '0';
                                    }else{
                                        calculateRatio          = receiverRatioMap.get(g.Id + '_' + ccWrapper.receiver_cc_code)*100;
                                        decimalPlaces           = calculateRatio.scale();
                                        roundedCalculateRatio   = 0;
                
                                        if(decimalPlaces > 2){
                                            roundedCalculateRatio = calculateRatio.setScale(2);
                                        }else{
                                            roundedCalculateRatio = calculateRatio;
                                        }
                                        ccWrapper.cc_distribute_rate = String.valueOf(roundedCalculateRatio);
                                    }
                                }    
                                ccWrapper.sender_cc_code            = senderGroupMap.get(g.Id)[num].CC__r.WBS_Code__c;
                                ccWrapper.sender_cc_name            = senderGroupMap.get(g.Id)[num].CC__r.Name;
                                ccWrapper.cc_sender_distribute_rate = String.valueOf(senderGroupMap.get(g.Id)[num].Group_Distribution_Ratio__c);
                                
                                ccList.add(ccWrapper);
                            }
                        }
                        System.debug('ccList: '+ccList);
                        groupWrapper.cc_list        = ccList;
    
                        returnWrapper.CODE          = 'SUCCESS';
                        returnWrapper.MESSAGE       = '[' + versionName + '] 버전의 그룹별 배부 비율 조회 완료';
                        groupWrapper.returnWrapper  = returnWrapper;
                    }     
                    returnList.add(groupWrapper);           
                }
                System.debug('returnList: '+returnList);
                return returnList;
            }else{
                GroupWrapper groupWrapper   = new GroupWrapper();  
                returnWrapper.CODE          = 'ERROR';
                returnWrapper.MESSAGE       = '[' + versionName + '] 버전에 해당하는 데이터가 존재하지 않습니다.';
                groupWrapper.returnWrapper  = returnWrapper;
                returnList.add(groupWrapper);
                return returnList;  
            }
            



        } catch (Exception e) {
            System.debug('e : '+e);
            System.debug('e.getLine : '+e.getLineNumber());
            System.debug('e.message : '+e.getMessage());
            // check!
            GroupWrapper groupWrapper = new GroupWrapper();
            returnWrapper.CODE          = 'ERROR';
            returnWrapper.MESSAGE       = '관리자에게 문의하세요: '+e.getMessage();
            groupWrapper.returnWrapper  = returnWrapper;
            returnList.add(groupWrapper);
            return returnList;  
        }
    }
    
    @AuraEnabled
    public static ReturnWrapper updateGroupDistributionRatio(String versionName){
        System.debug('versionName: '+versionName);
        ReturnWrapper returnWrapper = new ReturnWrapper();

        try {
            List<Sender_Receiver_Team_Member__c> updateList                     = new List<Sender_Receiver_Team_Member__c>();
            List<Sender_Receiver_Team_Member__c> receiverList                   = new List<Sender_Receiver_Team_Member__c>();
            List<Sender_Receiver_Team_Member__c> receiverTeamMemberList         = new List<Sender_Receiver_Team_Member__c>();
            List<String> receiverWbsCodeList                                    = new List<String>();
            Map<String, List<Sender_Receiver_Team_Member__c>> receiverGroupMap  = new Map<String, List<Sender_Receiver_Team_Member__c>>();
            Map<String, Decimal> receiverRatioMap                               = new Map<String, Decimal>();
            Decimal planDistributionRatioSum                                    = 0;
            Decimal groupDistributionRatioSum                                   = 0;
            Decimal calculateRatio                                              = 0;
            Integer decimalPlaces                                               = 0;
            Decimal roundedCalculateRatio                                       = 0;

            List<Sender_Receiver_Team_Member__c> srTeamMemberList = [ SELECT Id, Group__c, Sender_Receiver__r.Type__c, CC__r.WBS_Code__c, Group_Distribution_Ratio__c, Plan_Distribution_Version__c
                                                                      FROM Sender_Receiver_Team_Member__c  
                                                                      WHERE Plan_Distribution_Version__r.Name =: versionName
                                                                      ORDER BY Group__c ];
    
            for(Sender_Receiver_Team_Member__c srTeamMember : srTeamMemberList){
                if(srTeamMember.Sender_Receiver__r.Type__c == 'Receiver'){
                    if(receiverGroupMap.containsKey(srTeamMember.Group__c)){
                        receiverTeamMemberList.add(srTeamMember);
                        receiverGroupMap.put(srTeamMember.Group__c, receiverTeamMemberList);
                    }else{
                        receiverTeamMemberList = new List<Sender_Receiver_Team_Member__c>();
                        receiverTeamMemberList.add(srTeamMember);
                        receiverGroupMap.put(srTeamMember.Group__c, receiverTeamMemberList);
                    }
                    receiverWbsCodeList.add(srTeamMember.CC__r.WBS_Code__c);
                }
            }
                                                
            List<WBSandCC__c > ratioList = [ SELECT Id, WBS_Code__c, Plan_Distribution_Ratio__c 
                                                FROM WBSandCC__c  
                                                WHERE WBS_Code__c IN: receiverWbsCodeList
                                                AND Receiver_Target_CC__c = true ];
            
            for(WBSandCC__c ratio : ratioList){
                if(ratio.Plan_Distribution_Ratio__c == null){
                    ratio.Plan_Distribution_Ratio__c = 0;
                } 
                receiverRatioMap.put(ratio.WBS_Code__c, ratio.Plan_Distribution_Ratio__c);
            }

            for(List<Sender_Receiver_Team_Member__c> receiverGroup : receiverGroupMap.values()){
                planDistributionRatioSum    = 0;
                groupDistributionRatioSum   = 0;
                Integer index = 1;

                for(Sender_Receiver_Team_Member__c receiver : receiverGroup){
                    if(receiverRatioMap.containsKey(receiver.CC__r.WBS_Code__c)){
                        planDistributionRatioSum += receiverRatioMap.get(receiver.CC__r.WBS_Code__c);
                    }
                }
                
                for(Sender_Receiver_Team_Member__c receiver : receiverGroup){
                    if(receiverRatioMap.containsKey(receiver.CC__r.WBS_Code__c)){
                        if(planDistributionRatioSum != 0){
                            calculateRatio = receiverRatioMap.get(receiver.CC__r.WBS_Code__c) * (100 / planDistributionRatioSum);
                            decimalPlaces = calculateRatio.scale();
                            roundedCalculateRatio = 0;

                            if(decimalPlaces > 2){
                                roundedCalculateRatio = calculateRatio.setScale(2);
                            }else{
                                roundedCalculateRatio = calculateRatio;
                            }
                            receiver.Group_Distribution_Ratio__c = roundedCalculateRatio / 100;

                            groupDistributionRatioSum += roundedCalculateRatio;

                            if(index == receiverGroup.size()){
                                if(groupDistributionRatioSum > 100){
                                    receiver.Group_Distribution_Ratio__c = (roundedCalculateRatio - (groupDistributionRatioSum - 100))  / 100;
                                }else if(groupDistributionRatioSum < 100){
                                    receiver.Group_Distribution_Ratio__c = (roundedCalculateRatio + (100 - groupDistributionRatioSum)) / 100;
                                }
                            }
                            index++;
                        }else{
                            receiver.Group_Distribution_Ratio__c = 0;
                        }
                        updateList.add(receiver);
                    }
                }
            }
            System.debug('updateList: '+updateList);
            List<Database.SaveResult> saveResultList = Database.update(updateList);
            for(Database.SaveResult saveResult : saveResultList){
                if (saveResult.isSuccess()) {
                    returnWrapper.CODE       = 'SUCCESS';
                    returnWrapper.MESSAGE    = '그룹별 배부 비율 저장 완료';
                } else {
                    String errorMsg = '';
                    for (Database.Error error : saveResult.getErrors()) {
                        errorMsg += error.getMessage() + '/n';
                    }
                    returnWrapper.CODE       = 'ERROR';
                    returnWrapper.MESSAGE    = '관리자에게 문의하세요: '+errorMsg;
                }
            }
            
        } catch (Exception e) {
            System.debug('e : '+e);
            System.debug('e.getLine : '+e.getLineNumber());
            System.debug('e.message : '+e.getMessage());
            returnWrapper.CODE      = 'Error';
            returnWrapper.MESSAGE   = e.getMessage();
        }
        return returnWrapper;
    }

    @AuraEnabled
    public static ReturnWrapper groupReset(){
        ReturnWrapper returnWrapper = new ReturnWrapper();

        try{
            String versionName = '';
            List<Plan_Distribution_Version__c> versionList = [ SELECT Id, Name, Latest_Version__c
                                                               FROM Plan_Distribution_Version__c
                                                               WHERE Latest_Version__c = true ];
            if(versionList.size() > 0){                                                 
                for(Plan_Distribution_Version__c version : versionList){
                    version.Latest_Version__c = false;
                    versionName = versionList[0].Name;
                }
                update versionList;
    
                List<WBSandCC__c > wbsCCList = [ SELECT Id, Receiver_Target_CC__c 
                                                 FROM WBSandCC__c 
                                                 WHERE Receiver_Target_CC__c  = true ];
                for(WBSandCC__c wbsCC : wbsCCList){
                    wbsCC.Receiver_Target_CC__c         = false;
                    wbsCC.Plan_Distribution_Ratio__c    = null;
                }    
                update wbsCCList;
                
                Savepoint sp = Database.setSavePoint();  
                String errMsg = '';  
                
                List<Database.SaveResult> srList = Database.update(versionList, false);
                
                for(Database.SaveResult sr : srList) {
                    if (!sr.isSuccess()) {
                        errMsg += '관리자에게 문의하세요. Msg : ' + String.valueOf(sr.getErrors())+ '\n';
                        database.rollback(sp);
                        returnWrapper.CODE      = 'ERROR';
                        returnWrapper.MESSAGE   = errMsg;
                        return returnWrapper;
                    }
                }            
                returnWrapper.CODE      = 'SUCCESS';
                returnWrapper.MESSAGE   = '[' + versionName + '] 버전이 리셋 되었습니다.';
                return returnWrapper;
            }else{
                returnWrapper.CODE      = 'ERROR';
                returnWrapper.MESSAGE   = '리셋 가능한 버전이 존재하지 않습니다.';
                return returnWrapper;
            }

        } catch (Exception e) {
            System.debug('e : '+e);
            System.debug('e.getLine : '+e.getLineNumber());
            System.debug('e.message : '+e.getMessage());

            returnWrapper.CODE      = 'ERROR';
            returnWrapper.MESSAGE   = e.getMessage();
            return returnWrapper;
        }
    }

    @AuraEnabled
    public static ReturnWrapper groupConfirm(){
        ReturnWrapper returnWrapper = new ReturnWrapper();

        try{
            Integer year        = System.today().year();
            String versionName  = '';
            List<Plan_Distribution_Version__c> versionList = [ SELECT Id, Name, Latest_Version__c
                                                               FROM Plan_Distribution_Version__c
                                                               WHERE Year__c =: year 
                                                               ORDER BY Name DESC ];
            
            Plan_Distribution_Version__c version = new Plan_Distribution_Version__c ();

            if(versionList.size() > 0){
                version.Name = year + '_' + (Integer.valueOf(versionList[0].Name.split('_')[1])+1);
                version.Latest_Version__c = true;
                version.Year__c = year;
            }else{
                version.Name = year + '_' + 1;
                version.Latest_Version__c = true;
                version.Year__c = year;
            }
            versionName = version.Name;
            insert version;

            List<Group__c> groupList = [ SELECT Id, Plan_Distribution_Version__c, Latest_Version__c 
                                         FROM Group__c
                                         WHERE Plan_Distribution_Version__c = null ];
            for(Group__c g : groupList){
                g.Plan_Distribution_Version__c = version.Id;
            }
    
            List<Sender_Receiver__c > senderReceiverList = [ SELECT Id, Plan_Distribution_Version__c, Latest_Version__c
                                                             FROM Sender_Receiver__c
                                                             WHERE Plan_Distribution_Version__c = null ];
            for(Sender_Receiver__c senderReceiver : senderReceiverList){
                senderReceiver.Plan_Distribution_Version__c = version.Id;
            }                                                
    
            List<Sender_Receiver_Team_Member__c > srTeamMemberList = [ SELECT Id, Plan_Distribution_Version__c, Latest_Version__c
                                                                       FROM Sender_Receiver_Team_Member__c
                                                                       WHERE Plan_Distribution_Version__c = null ];
            for(Sender_Receiver_Team_Member__c srTeamMeber : srTeamMemberList){
                srTeamMeber.Plan_Distribution_Version__c = version.Id;
            }                                                        
    
            List<Sender_Price__c > senderPriceList = [ SELECT Id, Plan_Distribution_Version__c, Latest_Version__c
                                                       FROM Sender_Price__c
                                                       WHERE Plan_Distribution_Version__c = null ];
            for(Sender_Price__c senderPrice : senderPriceList){
                senderPrice.Plan_Distribution_Version__c = version.Id;
            }                                        
    
            List<Receiver_Price__c> receiverPriceList = [ SELECT Id, Plan_Distribution_Version__c, Latest_Version__c
                                                          FROM Receiver_Price__c
                                                          WHERE Plan_Distribution_Version__c = null ];
            for(Receiver_Price__c receiverPrice : receiverPriceList){
                receiverPrice.Plan_Distribution_Version__c = version.Id;
            }  

            Savepoint sp = Database.setSavePoint();        
            String errMsg = '';  


            List<Database.SaveResult> srList = new List<Database.SaveResult>();
            srList.addAll(Database.update(groupList, false));
            srList.addAll(Database.update(senderReceiverList, false));
            srList.addAll(Database.update(srTeamMemberList, false));
            srList.addAll(Database.update(senderPriceList, false));
            srList.addAll(Database.update(receiverPriceList, false));
        
            for(Database.SaveResult sr : srList) {
                if (!sr.isSuccess()) {
                    errMsg += '관리자에게 문의하세요. Msg : ' + String.valueOf(sr.getErrors())+ '\n';
                    database.rollback(sp);
                    returnWrapper.CODE      = 'ERROR';
                    returnWrapper.MESSAGE   = errMsg;
                    return returnWrapper;
                }
            }
            returnWrapper.CODE      = 'SUCCESS';
            returnWrapper.MESSAGE   = '[' + versionName + '] 버전이 저장 되었습니다.';
            return returnWrapper;

        } catch (Exception e) {
            System.debug('e : '+e);
            System.debug('e.getLine : '+e.getLineNumber());
            System.debug('e.message : '+e.getMessage());

            returnWrapper.CODE      = 'ERROR';
            returnWrapper.MESSAGE   = e.getMessage();
            return returnWrapper;
        }
    }

    public class GroupWrapper{
        @AuraEnabled
        public Boolean latestVersion;
        @AuraEnabled
        public String group_name;
        @AuraEnabled
        public String sender_name;
        @AuraEnabled
        public String receiver_name;
        @AuraEnabled
        public List<CCWrapper> cc_list;
        @AuraEnabled
        public ReturnWrapper returnWrapper;
    }

    public class CCWrapper{
        @AuraEnabled
        public String sender_cc_code;
        @AuraEnabled
        public String sender_cc_name;
        @AuraEnabled
        public String receiver_cc_code;
        @AuraEnabled
        public String receiver_cc_name;
        @AuraEnabled
        public String cc_sender_distribute_rate;
        @AuraEnabled
        public String cc_distribute_rate;
    }

    public class ReturnWrapper{
        @AuraEnabled
        public String CODE;
        @AuraEnabled
        public String MESSAGE;
    }
}



            /*
            List<Database.SaveResult> groupResults = Database.update(groupList, false);
            for (Database.SaveResult sr : groupResults) {
                if (!sr.isSuccess()) {
                    errMsg += 'Group 업데이트 오류: ' + String.valueOf(sr.getErrors())+ '\n';
                    database.rollback(sp);
                    returnWrapper.CODE      = 'Error';
                    returnWrapper.MESSAGE   = errMsg;
                    return returnWrapper;
                }
            }
            List<Database.SaveResult> senderReceiverResults = Database.update(senderReceiverList, false);

            for (Database.SaveResult sr : senderReceiverResults) {
                if (!sr.isSuccess()) {
                    errMsg += 'Sender_Receiver__c 업데이트 오류: ' + String.valueOf(sr.getErrors())+ '\n';
                    database.rollback(sp);
                    returnWrapper.CODE      = 'Error';
                    returnWrapper.MESSAGE   = errMsg;
                    return returnWrapper;
                }
            }
            List<Database.SaveResult> srTeamMemberResults = Database.update(srTeamMemberList, false);
            for (Database.SaveResult sr : srTeamMemberResults) {
                if (!sr.isSuccess()) {
                    errMsg += 'Sender_Receiver_Team_Member__c 업데이트 오류: ' + String.valueOf(sr.getErrors())+ '\n';
                    database.rollback(sp);
                    returnWrapper.CODE      = 'Error';
                    returnWrapper.MESSAGE   = errMsg;
                    return returnWrapper;
                }
            }
            List<Database.SaveResult> senderPriceResults = Database.update(senderPriceList, false);
            for (Database.SaveResult sr : senderPriceResults) {
                if (!sr.isSuccess()) {
                    errMsg += 'Sender_Price__c 업데이트 오류: ' + String.valueOf(sr.getErrors())+ '\n';
                    database.rollback(sp);
                    returnWrapper.CODE      = 'Error';
                    returnWrapper.MESSAGE   = errMsg;
                    return returnWrapper;
                }
            }
            List<Database.SaveResult> receiverPriceResults = Database.update(receiverPriceList, false);
            for (Database.SaveResult sr : receiverPriceResults) {
                if (!sr.isSuccess()) {
                    errMsg += 'Receiver_Price__c 업데이트 오류: ' + String.valueOf(sr.getErrors())+ '\n';
                    database.rollback(sp);
                    returnWrapper.CODE      = 'Error';
                    returnWrapper.MESSAGE   = errMsg;
                    return returnWrapper;
                }
            }
            */