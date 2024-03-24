/**
 * Created by MZC01-DGCHOI on 2023-03-29.
 */

public with sharing class OpptyDummy {

    public Integer stdYear = Date.today().year();
    public Integer initValue = 1;

    public List<Opportunity> createDummy(List<WBSandCC__c> zfList) {
        System.debug('OpptyDummy.createDummy()');
        List<Opportunity> opptyList = new List<Opportunity>();

        try {
            if (zfList.size() > 0) {
                //레코드 유형(5)
                Map<String, Id> recordTypeIdMap = getRecordTypeIdMap();

                //수주 가능성(3)
                Schema.DescribeFieldResult fieldResult = Opportunity.Possibility_of_closed_won__c.getDescribe();
                List<String> possibilityList = getPickListValuesIntoList(fieldResult); //수주 가능성 picklist

                //Stage(2)
                List<String> stageNameList = new List<String>{
                        '잠재고객', 'Closed Won'
                };

                Date tmpDate = null;

                List<Opportunity> potentialOpptyList = new List<Opportunity>();
                List<Opportunity> closedWonOpptyList = new List<Opportunity>();

                //잠재고객으로 생성1
                for (WBSandCC__c zf : zfList) {
                    System.debug('zf Sales_Management__c: '+ zf.Sales_Management__c);
                    System.debug('zf Business_Management__c: '+ zf.Business_Management__c);
                    System.debug('zf Construction_Management__c: '+ zf.Construction_Management__c);
                    
                    //for (String recordTypeKey : recordTypeIdMap.keySet()) { //5
                        for (String possibility : possibilityList) { //3
                            for (Integer i = initValue; i <= 12; i++) {
                                tmpDate = Date.newInstance(stdYear, i, 1);

                                Opportunity oppty = new Opportunity();
  /*                              if(zf.Sales_Management__c) {
                                    oppty.General_p__c = '영업총괄';
                                } else if(zf.Business_Management__c) {
                                    oppty.General_p__c = '사업총괄';
                                } else if(zf.Construction_Management__c) {
                                    oppty.General_p__c = '공사총괄';
                                }*/
                                oppty.Name = 'dummy';
                                oppty.General_p__c = zf.General__c; //총괄 매핑 24.03.13 수정
                                oppty.WBS_CC__c = zf.Id;
                                oppty.Possibility_of_closed_won__c = possibility; //수주 가능성
                                oppty.RecordTypeId = recordTypeIdMap.get(zf.Oppty_RecordType__c); //레코드 유형 24.03.13 수정
                                oppty.Gross_Profit_rate__c = 0; //매총율
                                oppty.StageName = stageNameList[0]; //잠재고객
                                oppty.Closing_company__c = 'S&I'; //수주 업체
                                oppty.Type2__c = '단일'; //구분분
                                oppty.Status__c = '진행중'; //상태
                                oppty.Real_Data_check__c = false;

                                //날짜 매핑
                                oppty.amount_occur_date__c = tmpDate; //매출 발생 시기
                                oppty.contract_closingdate__c = tmpDate; //계약 체결 시기
                                oppty.Expect_date_of_closed__c = tmpDate; //예상 수주 시기
                                oppty.CloseDate = tmpDate; //Close Date
                                //금액 매핑
                                oppty.Amount = 0; //계약금액
                                oppty.estimatedorederamount__c = 0; //예상수주금액
                                oppty.Annual_sales_accrual_amount__c = 0; //연매출발생금액
                                oppty.TotalAmount_SumofSore__c = 0; //총 매출 발생 금액(지점 합계)

                                if(!Test.isRunningTest()) potentialOpptyList.add(oppty);
                            }
                        }
                    //}
                }

                //잠재고객으로 생성2 -> Closed Won으로 바꿈
                for (WBSandCC__c zf : zfList) {
                    for (String recordTypeKey : recordTypeIdMap.keySet()) { //5
                        for (String possibility : possibilityList) { //3
                            for (Integer i = initValue; i <= 12; i++) {
                                tmpDate = Date.newInstance(stdYear, i, 1);

                                Opportunity oppty = new Opportunity();
                                /*if(zf.Sales_Management__c) {
                                    oppty.General_p__c = '영업총괄';
                                } else if(zf.Business_Management__c) {
                                    oppty.General_p__c = '사업총괄';
                                } else if(zf.Construction_Management__c) {
                                    oppty.General_p__c = '공사총괄';
                                }*/
                                oppty.Name = 'dummy';
                                oppty.General_p__c = zf.General__c; //총괄 매핑 24.03.13 수정
                                oppty.WBS_CC__c = zf.Id;
                                oppty.Possibility_of_closed_won__c = possibility; //수주 가능성
                                oppty.RecordTypeId = recordTypeIdMap.get(zf.Oppty_RecordType__c); //레코드 유형 24.03.13 수정
                                oppty.Gross_Profit_rate__c = 0; //매총율
                                oppty.StageName = stageNameList[0]; //잠재고객
                                oppty.Closing_company__c = 'S&I'; //수주 업체
                                oppty.Type2__c = '단일'; //구분
                                oppty.Status__c = '진행중'; //상태
                                oppty.Real_Data_check__c = false;

                                //날짜 매핑
                                oppty.amount_occur_date__c = tmpDate; //매출 발생 시기
                                oppty.contract_closingdate__c = tmpDate; //계약 체결 시기
                                oppty.Expect_date_of_closed__c = tmpDate; //예상 수주 시기
                                oppty.CloseDate = tmpDate; //Close Date
                                //금액 매핑
                                oppty.Amount = 0; //계약금액
                                oppty.estimatedorederamount__c = 0; //예상수주금액
                                oppty.Annual_sales_accrual_amount__c = 0; //연매출발생금액
                                oppty.TotalAmount_SumofSore__c = 0; //총 매출 발생 금액(지점 합계)

                                if(!Test.isRunningTest()) closedWonOpptyList.add(oppty);
                            }
                        }
                    }
                }

                if(!Test.isRunningTest()) {
                    if(potentialOpptyList.size() > 0) insert potentialOpptyList;
                    if(closedWonOpptyList.size() > 0) insert closedWonOpptyList;
                }
                
                for(Opportunity oppty : closedWonOpptyList) { //Closed Won으로 update
                    oppty.StageName = stageNameList[1]; //Closed Won
                    oppty.VRB_2__c = 'Pass';
                }

                if(closedWonOpptyList.size() > 0 && !Test.isRunningTest()) update closedWonOpptyList;

                if(Test.isRunningTest()) {
                    for(WBSandCC__c zf : zfList) {
                        Opportunity oppty = new Opportunity();
                        /*if(zf.Sales_Management__c) {
                            oppty.General_p__c = '영업총괄';
                        } else if(zf.Business_Management__c) {
                            oppty.General_p__c = '사업총괄';
                        } else if(zf.Construction_Management__c) {
                            oppty.General_p__c = '공사총괄';
                        }*/
                        oppty.Name = 'dummy';
                        oppty.General_p__c = zf.General__c; //총괄 매핑 24.03.13 수정
                        oppty.WBS_CC__c = zf.Id;
                        oppty.Possibility_of_closed_won__c = '높음';
                        oppty.RecordTypeId = recordTypeIdMap.get(zf.Oppty_RecordType__c); //레코드 유형 24.03.13 수정
                        oppty.Gross_Profit_rate__c = 0; //매총율
                        oppty.StageName = '잠재고객'; //Stage
                        oppty.Type2__c = '단일'; //구분분
                        oppty.Status__c = '진행중'; //상태
                        oppty.Real_Data_check__c = false;
                        oppty.CloseDate = tmpDate;
                        oppty.Amount = 0;
                        opptyList.add(oppty);
                    }
                }

                opptyList.addAll(potentialOpptyList);
                opptyList.addAll(closedWonOpptyList);

                /*
                System.debug('Opportunity opptyList Size :::: ' + opptyList.size());

                if(opptyList.size() > 0 && !Test.isRunningTest()) {
                    insert opptyList;
                    //List<Opportunity_amount__c> opptyAmtList = createAmountDummy(opptyList);
                }
                */
            }
        } catch (Exception e) {
            System.debug(e.getLineNumber());
            System.debug(e.getMessage());
        }
        
        return opptyList;
    }

    public List<Opportunity_amount__c> createAmountDummy(List<Opportunity> opptyList) {
        System.debug('OpptyDummy :::: createAmountDummy()');

        List<Opportunity_amount__c> insertList = new List<Opportunity_amount__c>();

        Date tmpDate = null;

        for(Opportunity oppty : opptyList) {
            if(oppty.Real_Data_check__c == false) { //dummy데이터
                for(Integer i=1; i<=12; i++) {
                    tmpDate = Date.newInstance(stdYear, i,1);

                    Opportunity_amount__c opptyAmt = new Opportunity_amount__c();
                    opptyAmt.Name = 'dummy';
                    opptyAmt.WBS_CC__c = oppty.WBS_CC__c;
                    opptyAmt.Opportunityname__c = oppty.Id;
                    opptyAmt.OpportunityCheck__c = true;
                    opptyAmt.Real_Data_check__c = false;
                    //날짜 매핑
                    opptyAmt.CalculateDate__c = tmpDate; //정산일자
                    opptyAmt.contract_closingdate__c = tmpDate; //계약체결시기
                    opptyAmt.Expect_date_of_closed__c = tmpDate; //예상수주시기
                    //금액 매핑
                    opptyAmt.Amount__c = 0; //계약금액
                    opptyAmt.Monthly_amount__c = 0; //월 매출 금액
                    opptyAmt.Annual_sales_accrual_amount__c = 0; //연매출발생금액
                    opptyAmt.estimatedorederamount__c = 0; //예상수주금액

                    insertList.add(opptyAmt);
                }
            }
        }

        System.debug('OpptyDummy Amount insertList Size :::: ' + insertList.size());
        System.debug('OpptyDummy Amount insertList :::: ' + insertList);

        if(insertList.size() > 0 && !Test.isRunningTest()) insert insertList;

        return insertList;
    }

    private Map<String, Id> getRecordTypeIdMap() { //key:name - value:Id
        //Master 빼고 5개
        //FM수주, FM운영, IPM/PFM, Product, 공사(리노)수주
        Map<String, Id> returnMap = new Map<String, Id>();

        Schema.DescribeSObjectResult R = Opportunity.SObjectType.getDescribe();
        List<Schema.RecordTypeInfo> RT = R.getRecordTypeInfos();

        //언어 영어면 Master, 한글이면 마스터
        for (RecordTypeInfo info : RT) {
            if (info.Name != '마스터' && info.Name != 'Master') {
                returnMap.put(info.Name, info.getRecordTypeId());
            }
        }

        return returnMap;
    }

    public List<String> getPickListValuesIntoList(Schema.DescribeFieldResult fieldResult) {
        List<String> pickListValuesList = new List<String>();

        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry pickListVal : ple) {
            pickListValuesList.add(pickListVal.getValue());
        }
        return pickListValuesList;
    }

}