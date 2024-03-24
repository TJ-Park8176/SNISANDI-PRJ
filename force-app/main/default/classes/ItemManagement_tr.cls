/**
 * Created by MZC01-DGCHOI on 2022-12-12.
 */

public with sharing class ItemManagement_tr extends TriggerHandler{

    private List<ItemManagement__c> listNew = (List<ItemManagement__c>) Trigger.new;

    public override void beforeInsert() {
        basicYear();
        productNPD();
    }

    public override void afterInsert() {
        createAmounts();
    }

    // 23.07.17 Sanghee - 기준년도 필드 당해로 입력 + 24.03.11 아이템명 앞에 기준년도 삽입
    public void basicYear() {
        for (ItemManagement__c target : listNew) {
            String name_field;
            Date thisyear = System.today();
            target.Base_Year__c = String.valueOf(thisyear.year());
            name_field = '[' + target.Base_Year__c + '년] ' +  target.Name;
            target.Name = name_field;
        }
    }

    // 24. 03. 19 Sanghee WBS의 사업유형이 Product이고 사업유형2가 Sandi일 경우, 아이템에 매핑 진행 @TODO 사업계획 아이템관리에도 진행, Validation Rule 추가(수정불가), WBS 사업유형2 수식필드 추가 생성
    public void productNPD() {
        System.debug('***** productNPD ******');
        List<String> Sandi_Category = new List<String>{
                'Sandi Asset',
                'Sandi Interior',
                'Sandi Clean',
                'Sandi Safe',
                'Sandi Life',
                'Sandi Parking'
        };

        Map<WBSandCC__c, List<ItemManagement__c>> WBS_Item_Map = new Map<WBSandCC__c, List<ItemManagement__c>>();
        for (ItemManagement__c target : listNew) {
            if (Sandi_Category.contains(target.WBSType2__c)) {
                target.AmountDivision__c = '변동';
                target.AmountType__c = target.WBSType2__c;
                target.Product_NPD__c = target.WBSType3__c;
            }
        }
    }

    // 24.03.20 Sanghee 매출 구분/유형/유형2 수정 불가 Validation(Sandi 아이템일 경우)
//    public void sandiValidation() {
//        System.debug('***** sandiValidation ******');
//
//        for (ItemManagement__c target : (List<ItemManagement__c>) Trigger.new) {
//            ItemManagement__c oldtarget = (ItemManagement__c) Trigger.oldMap.get(target.Id);
//            if(target.Product_NPD__c != null) {
//                if(target.AmountDivision__c != oldtarget.AmountDivision__c)       target.addError('매출 구분을 수정할 수 없습니다.');
//                else if(target.AmountType__c != oldtarget.AmountType__c)          target.addError('매출 유형을 수정할 수 없습니다.');
//                else if(target.Product_NPD__c != oldtarget.Product_NPD__c)        target.addError('매출 유형2를 수정할 수 없습니다.');
//            }ㅈ
//        }
//    }

    public void createAmounts() {
        //12개 매출 생성 - (안하기로함)
        Id amountRecordTypeId = Schema.SObjectType.ItemManagement__c.getRecordTypeInfosByName().get('매출아이템').getRecordTypeId();
        List<Amount__c> insertAmounts = new List<Amount__c>();

        for(ItemManagement__c target : listNew) {
            System.debug('recordType DevName: ' + target.RecordTypeId);
            if(target.RecordTypeId == amountRecordTypeId) {
                for (Integer i = 1; i <= 12; i++) {
                    Amount__c amt = new Amount__c();

                    amt.Name = i + '월_' + target.Name + '_' + target.AccountSubjecta__c; //N월_아이템관리Name_계정과목Name
                    amt.WBS__c = target.WBS_CC__c;
                    amt.Itemmanagement__c = target.Id;
                    amt.AccountSubjectselect__c = target.AccountSubjectselect__c;
                    amt.CalculateDate__c = Date.newInstance(Date.today().year(), i, 1);
                    amt.PredictAmount__c = 0; //금액 0 초기화

//                    amt.AmountType__c = target.AmountType__c;
//                    amt.AmountDivision__c = target.AmountDivision__c;
//                    amt.SalesSort__c = target.SalesSort__c;
                    insertAmounts.add(amt);
                }
            }
        }

        System.debug('@insertAmounts: ' + insertAmounts);
        //if(insertAmounts.size()>0) insert insertAmounts;
    }
}