/**
 * Created by MZC01-DGCHOI on 2023-04-26.
 */

public with sharing class Contact_tr extends TriggerHandler {

    private List<Contact> listOld = (List<Contact>) Trigger.old;
    private List<Contact> listNew = (List<Contact>) Trigger.new;

    public override void afterInsert() {
        updateContactCount();
    }

    public override void afterUpdate() {
        updateContactCount();
    }

    public override void afterDelete() {
        updateContactCount();
    }

    public void updateContactCount() {
        List<Opportunity>         updateList     = new List<Opportunity>();
        List<Opportunity_plan__c> updatePlanList = new List<Opportunity_plan__c>();
        Set<Id> updateIdSet     = new Set<Id>();
        Set<Id> updatePlanIdSet = new Set<Id>(); // 23.12.07 - 사업계획 추가

        if(listOld == null) { //insert
            for(Integer i=0; i<listNew.size(); i++) {
                if(listNew[i].Opportunity__c != null) {
                    updateIdSet.add(listNew[i].Opportunity__c); // 룩업필드 : 상위 아이디(변경 이후)
                }
                if(listNew[i].Opportunity_plan__c != null) { // 23.12.07 - 사업계획 추가
                    updatePlanIdSet.add(listNew[i].Opportunity_plan__c);
                }
            }
        } else if(listNew == null) { //delete
            for(Integer i=0; i<listOld.size(); i++) {
                if(listOld[i].Opportunity__c != null) {
                    updateIdSet.add(listOld[i].Opportunity__c); // 룩업필드 : 상위 아이디(변경 이전)
                }
                if(listOld[i].Opportunity_plan__c != null) { // 23.12.07 - 사업계획 추가
                    updatePlanIdSet.add(listOld[i].Opportunity_plan__c);
                }
            }
        } else { //update
            for (Integer i=0; i<listNew.size(); i++) {
                if (listNew[i].Opportunity__c != null) updateIdSet.add(listNew[i].Opportunity__c); // 룩업필드 : 상위 아이디(변경 이후)
                if (listOld[i].Opportunity__c != null) updateIdSet.add(listOld[i].Opportunity__c); // 룩업필드 : 상위 아이디(변경 이전)
                if (listNew[i].Opportunity_plan__c != null) updatePlanIdSet.add(listNew[i].Opportunity_plan__c); // 23.12.07 - 사업계획 추가
                if (listOld[i].Opportunity_plan__c != null) updatePlanIdSet.add(listOld[i].Opportunity_plan__c); // 23.12.07 - 사업계획 추가
            }
        }

        if(updateIdSet.size() > 0) {
            List<AggregateResult> aggList = [
                    SELECT Opportunity__c, COUNT(Id) CNT
                    FROM Contact
                    WHERE Opportunity__c IN :updateIdSet
                    GROUP BY Opportunity__c
            ];

            System.debug('aggList :::: ' + aggList);

            Set<Id> aggIdSet     = new Set<Id>();

            for(AggregateResult agg : aggList) {
                Opportunity oppty = new Opportunity();
                oppty.Id = (Id) agg.get('Opportunity__c');
                oppty.contact_count__c = Integer.valueOf(agg.get('CNT')); //연락처 수
                updateList.add(oppty);

                aggIdSet.add((Id)agg.get('Opportunity__c'));
            }

            updateIdSet.removeAll(aggIdSet);

            for(Id opptyId : updateIdSet) {
                System.debug('opptyId :::: ' + opptyId);
                Opportunity oppty      = new Opportunity();
                oppty.Id               = opptyId;
                oppty.contact_count__c = 0; //연락처 수
                updateList.add(oppty);
            }

            System.debug('Opportunity_tr UpdateOpList ::: ' + updateList);
        }

        if(updatePlanIdSet.size() > 0) {
            List<AggregateResult> aggPlanList = [
                    SELECT Opportunity_plan__c, COUNT(Id) CNT
                    FROM Contact
                    WHERE Opportunity_plan__c IN :updatePlanIdSet
                    GROUP BY Opportunity_plan__c
            ];

            System.debug('aggList :::: ' + aggPlanList);

            Set<Id> aggPlanIdSet = new Set<Id>();

            for(AggregateResult agg : aggPlanList) {
                Opportunity_plan__c oppPlan = new Opportunity_plan__c();
                oppPlan.Id = (Id) agg.get('Opportunity_plan__c');
                oppPlan.contact_count__c = Integer.valueOf(agg.get('CNT')); //연락처 수
                updatePlanList.add(oppPlan);

                aggPlanIdSet.add((Id)agg.get('Opportunity_plan__c'));
            }

            updatePlanIdSet.removeAll(aggPlanIdSet);

            for(Id oppPlanId : updatePlanIdSet) {
                System.debug('opptyId :::: ' + oppPlanId);
                Opportunity_plan__c oppPlan = new Opportunity_plan__c();
                oppPlan.Id                  = oppPlanId;
                oppPlan.contact_count__c    = 0; //연락처 수
                updatePlanList.add(oppPlan);
            }
        }

        if(updatePlanList.size() > 0) update updatePlanList; //사업계획(영업수주) 업데이트

        // 23.06.30 Sanghee - Pardot Project - Pardot Lead/Contact 싱크 시, Contact Update 로직이 있어 해당 License 제외
        Set<Id> userProfileId = new Set<Id>();
        userProfileId.add(UserInfo.getProfileId());
        List<String> UserLicense = new List<String>();
        if(!userProfileId.isEmpty()) {
            List<Profile> UserProfile = [SELECT Id, Name, UserLicense.Name FROM Profile WHERE Id IN :userProfileId];
            for (Profile pr : UserProfile) {
                UserLicense.add(pr.UserLicense.Name);
            }
        }
        System.debug('@@@@@@@@@@@@@@ Execute User License : ' + UserLicense);
        if(updateList.size() > 0 && !UserLicense.contains('B2BMA Integration User')) update updateList;

    }
}