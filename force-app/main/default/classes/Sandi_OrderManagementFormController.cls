/**
 * @description       : OrderSummary 화면에서 주문취소, 반품, 교환 버튼을 눌렀을 때, 수량과 사유를 선택하는 화면
 * @author            : jisoolee@mz.co.kr
 * @group             : 
 * @last modified on  : 2024-03-20
 * @last modified by  : jisoolee@mz.co.kr
**/

public class Sandi_OrderManagementFormController {
    @AuraEnabled(cacheable=true)
    public static ReturnWrapper getConfirmedOrder(String OrderSummaryId){
        ReturnWrapper returnWrapper                 = new ReturnWrapper();

        try {
            List<ConfirmedOrderWrapper> COWrapperList   = new List<ConfirmedOrderWrapper>();
            List<ConfirmedOrder__c> confirmedOrderList = [ SELECT Id, RecordTypeId, RecordType.Name, ConfirmedOrderNumber__c, Partner__r.Name, Product__r.Name, FinalTotalAmount__c, QuantityOrdered__c, QuantityCanceled__c, Account__c, Status__c, toLabel(Status__c) statusLabel
                                                           FROM ConfirmedOrder__c
                                                           WHERE OrderSummary__c =: OrderSummaryId 
                                                           ORDER BY ConfirmedOrderNumber__c ASC ];
            if(confirmedOrderList.size() > 0){
                for(ConfirmedOrder__c confirmedOrder : ConfirmedOrderList){
                    ConfirmedOrderWrapper COWrapper = new ConfirmedOrderWrapper();
                    COWrapper.confirmedOrderId      = confirmedOrder.Id;
                    COWrapper.confirmedOrderLink    = '/lightning/r/ConfirmedOrder__c/'+confirmedOrder.Id+'/view';
                    COWrapper.recordTypeId          = confirmedOrder.RecordTypeId;
                    COWrapper.partnerName           = confirmedOrder.Partner__r.Name;
                    COWrapper.confirmedOrderNumber  = confirmedOrder.ConfirmedOrderNumber__c;
                    COWrapper.recordTypeName        = confirmedOrder.RecordType.Name;
                    COWrapper.productName           = confirmedOrder.Product__r.Name;
                    COWrapper.finalTotalAmount      = confirmedOrder.FinalTotalAmount__c;
                    COWrapper.quantityOrdered       = confirmedOrder.QuantityOrdered__c;
                    // COWrapper.quantityCanceled      = confirmedOrder.QuantityCanceled__c;
                    COWrapper.status                = String.valueOf(confirmedOrder.get('statusLabel'));
                    if(confirmedOrder.Status__c == 'Awaiting Approval'){
                        COWrapper.needApproval = true;
                    }else{
                        COWrapper.needApproval = false;
                    }
                    COWrapperList.add(COWrapper);
                }
            }
            returnWrapper.confirmedOrderList = COWrapperList;

        } catch (Exception e) {
            System.debug(e.getMessage());
            System.debug(e.getLineNumber());
            System.debug(e.getStackTraceString());
        }
        return returnWrapper;
    }

    @AuraEnabled(cacheable=true)
    public static DetailReturnWrapper getSelectedConfirmedOrder(String currentStatus, String confirmedOrderId){ 
        DetailReturnWrapper detailReturnWrapper  = new DetailReturnWrapper();

        try{
            List<String> availableStatusList = new List<String>();
            Decimal availableQuantity   = 0;
            Decimal returnedQuantity    = 0;

            // 확정 주문 Status 체크
            if(currentStatus == 'Cancel'){
                availableStatusList.add('Awaiting Approval');
                availableStatusList.add('Allocated');
                availableStatusList.add('Assigned');
            }else {
                availableStatusList.add('Fulfilled');
                availableStatusList.add('Delivery Completed');
            }

            // 일반 주문
            List<ConfirmedOrder__c> selectedConfirmedOrder = [ SELECT Id
                                                                    , OrderItemSummary__c
                                                                    , Status__c
                                                                    , Product__r.Name
                                                                    , QuantityOrdered__c
                                                                    , QuantityCanceled__c
                                                                    , ReasonforRejection__c
                                                                    , FinalTotalAmount__c
                                                                    , UnitPrice__c
                                                               FROM ConfirmedOrder__c
                                                               WHERE Id =: confirmedOrderId
                                                               AND Status__c IN: availableStatusList 
                                                               LIMIT 1 ];
            if(selectedConfirmedOrder.size() > 0){
                availableQuantity = selectedConfirmedOrder[0].QuantityOrdered__c - selectedConfirmedOrder[0].QuantityCanceled__c;
            } 

            // 반품 주문
            List<ConfirmedOrder__c> returnedConfirmedOrder = [ SELECT Id
                                                                    , OrderItemSummary__c
                                                                    , Product__r.Name
                                                                    , QuantityOrdered__c
                                                                    , ReasonforRejection__c
                                                                    , FinalTotalAmount__c
                                                                    , UnitPrice__c
                                                               FROM ConfirmedOrder__c
                                                               WHERE OriginalConfirmedOrder__c =: confirmedOrderId
                                                               AND Status__c IN ('Fulfilled, Delivery Completed') ];
                                           
            if(returnedConfirmedOrder.size() > 0){
                for(ConfirmedOrder__c returnedCO : returnedConfirmedOrder){
                    returnedQuantity += returnedCO.QuantityOrdered__c;
                }
                availableQuantity = availableQuantity - returnedQuantity;
            } 

            if(selectedConfirmedOrder.size() > 0){
                for(ConfirmedOrder__c selectedCO : selectedConfirmedOrder){
                    DetailConfirmedOrderWrapper detailCOWrapper = new DetailConfirmedOrderWrapper();
                    detailCOWrapper.id                          = selectedCO.Id;
                    detailCOWrapper.orderItemSummary            = selectedCO.OrderItemSummary__c;
                    detailCOWrapper.status                      = selectedCO.Status__c;      
                    detailCOWrapper.productName                 = selectedCO.Product__r.Name;  
                    detailCOWrapper.quantityOrdered             = selectedCO.QuantityOrdered__c;
                    detailCOWrapper.availableQuantity           = availableQuantity;        
                    detailCOWrapper.reasonforRejection          = selectedCO.ReasonforRejection__c;          
                    detailCOWrapper.finalTotalAmount            = selectedCO.FinalTotalAmount__c;      
                    detailCOWrapper.unitPrice                   = selectedCO.UnitPrice__c;  
                    detailReturnWrapper.selectedConfirmedOrder  = detailCOWrapper;
                }
            }
            detailReturnWrapper.code = 'SUCCESS';
        }catch(Exception e){
            System.debug(e.getMessage());
            System.debug(e.getLineNumber());
            System.debug(e.getStackTraceString());
            detailReturnWrapper.code                = 'ERROR';
            detailReturnWrapper.msg                 = e.getMessage();
        }
        return detailReturnWrapper;
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getPicklistValues(String objectApiName, String fieldApiName) {
        List<String> picklistValues = new List<String>();

        try {
            Schema.SObjectType objectType               = Schema.getGlobalDescribe().get(objectApiName);
            Schema.DescribeSObjectResult objectDescribe = objectType.getDescribe();
            Schema.SObjectField objectField             = objectDescribe.fields.getMap().get(fieldApiName);
            Schema.DescribeFieldResult fieldDescribe    = objectField.getDescribe();

            List<Schema.PicklistEntry> picklistEntries = fieldDescribe.getPicklistValues();
            for (Schema.PicklistEntry entry : picklistEntries) {
                picklistValues.add(entry.getValue());
            }
            
        }catch(Exception e) {
            System.debug(e.getMessage());
            System.debug(e.getLineNumber());
            System.debug(e.getStackTraceString());
        }
        return picklistValues;
    }

    public static void callInsertFlow(){
        Map<String, String> param = new Map<String, String>();
        param.put('classify', 'insert');

        Review_SANDI__c review = new Review_SANDI__c();
        review.Description__c = 'inserttest';
        review.Product__c = '01t1y0000060oHxAAI';
        review.Rating__c = '5';
        
        param.put('descriptionField', review.Description__c);
        param.put('productField', review.Product__c);
        param.put('ratingField', review.Rating__c);
        Flow.Interview.TestReview testInsertFlow = new Flow.Interview.TestReview(param);
        testInsertFlow.start();

        String test =(String)testInsertFlow.getvariableValue('trueVal');
        system.debug('test::: '+test);
    }

    public static void callSingleFlow(){
        Map<String, String> param = new Map<String, String>();
        param.put('classify', 'one');
        Flow.Interview.TestReview testSingleFlow = new Flow.Interview.TestReview(param);
        testSingleFlow.start();

        Review_SANDI__c test =(Review_SANDI__c)testSingleFlow.getvariableValue('singleQuery');
        system.debug('test::: '+test);
    }

    public static void callMultiFlow(){
        Map<String, String> param = new Map<String, String>();
        param.put('classify', 'multi');
        Flow.Interview.TestReview testMultiFlow = new Flow.Interview.TestReview(param);
        testMultiFlow.start();

        List<Review_SANDI__c> test =(List<Review_SANDI__c>)testMultiFlow.getvariableValue('setmutltrec');
        system.debug('test::: '+test);
    }

    
    public static void fulfillmentOrderTest(){
        ConnectApi.FulfillmentOrderInputRepresentation InputRepresentation                      = new ConnectApi.FulfillmentOrderInputRepresentation();
        List<ConnectApi.OrderItemSummaryInputRepresentation> OrderItemSummaryListDeliveryCharge = new List<ConnectApi.OrderItemSummaryInputRepresentation>();

        List<ConnectApi.FulfillmentGroupInputRepresentation> fulfillmentGroups                  = new List<ConnectApi.FulfillmentGroupInputRepresentation>();


        List<ConnectApi.FulfillmentGroupInputRepresentation> FulfillmentGroupsVar               = new List<ConnectApi.FulfillmentGroupInputRepresentation>();

        ConnectApi.FulfillmentGroupInputRepresentation FulfillmentGroup                         = new ConnectApi.FulfillmentGroupInputRepresentation();
        FulfillmentGroup.orderItemSummaries                                                     = new List<ConnectApi.OrderItemSummaryInputRepresentation>();

        Schema.Location LocationToFulfill   = new Schema.Location();
        String FulfillmentType              = '';
        Boolean ExistingFulfillmentGroup    = false;
        Integer LoopIterationCount = 0;

        //A Default Warehouse Location
        // Location DefaultWarehouserLocation = [ SELECT Id, LocationType
        //                                        FROM Location
        //                                        WHERE LocationType = 'Warehouse'
        //                                        LIMIT 1 ];

        //Order Delivery Group Summaries
        List<OrderDeliveryGroupSummary> OrderDeliveryGroupSummaries = [ SELECT Id, OriginalOrderDeliveryGroupId
                                                                        FROM OrderDeliveryGroupSummary
                                                                        WHERE OrderSummaryId = '1Os1y0000008PWECA2' ];
                
        //Order Delivery Group Summaries
        for(OrderDeliveryGroupSummary OrderDeliveryGroupSummaryRecord : OrderDeliveryGroupSummaries){

            //Reset Input Variables
            InputRepresentation.orderSummaryId              = '';
            InputRepresentation.orderDeliveryGroupSummaryId = '';
            InputRepresentation.fulfillmentGroups           = new List<ConnectApi.FulfillmentGroupInputRepresentation>();
            OrderItemSummaryListDeliveryCharge              = new List<ConnectApi.OrderItemSummaryInputRepresentation>();

            //Order Product Summaries
            List<OrderItemSummary> OrderSummaryItems = [ SELECT Id, Quantity, Type, Partner__c, ProductCode
                                                         FROM OrderItemSummary
                                                         WHERE OrderDeliveryGroupSummaryId =: OrderDeliveryGroupSummaryRecord.Id
                                                         AND OrderSummaryId = '1Os1y0000008PWECA2' ];

            for(OrderItemSummary OrderProductSummaryRecord : OrderSummaryItems){      
                ConnectApi.OrderItemSummaryInputRepresentation OrderItemSummaryInputRepresentation = new ConnectApi.OrderItemSummaryInputRepresentation();                              //Loop Order Product Summaries  
                OrderItemSummaryInputRepresentation.orderItemSummaryId  = OrderProductSummaryRecord.Id;             //Set Item Summary Input Representation
                OrderItemSummaryInputRepresentation.quantity            = OrderProductSummaryRecord.Quantity;

                System.debug('Partner: '+OrderProductSummaryRecord.Partner__c);

                if(OrderProductSummaryRecord.Type == 'Delivery Charge'){                                            //Product Fulfillment Location - Product is Delivery Charge
                    OrderItemSummaryListDeliveryCharge.add(OrderItemSummaryInputRepresentation);                    //Add Product to Delivery Charge List
                    // continue;
                    
                    //Location
                    LocationToFulfill = [ SELECT Id, LocationType
                                          FROM Location 
                                          WHERE Partner__c =: OrderProductSummaryRecord.Partner__c 
                                          LIMIT 1 ];                  

                }else if(String.IsNotEmpty(OrderProductSummaryRecord.Partner__c)){                                  //Product Fulfillment Location - Location is Specified

                    //Location
                    LocationToFulfill = [ SELECT Id, LocationType
                                          FROM Location 
                                          WHERE Partner__c =: OrderProductSummaryRecord.Partner__c 
                                          LIMIT 1 ];      
                }else{                                                                                              //Product Fulfillment Location - Location is not Specified
                    //Check Inventory ~ Get Suggested Location
                }
                
                
                if(LocationToFulfill != null && LocationToFulfill.LocationType == 'Warehouse'){                     //Location Type - Existing Warehouse Location
                    System.debug('---Order Product---');
                    
                    FulfillmentType             = 'Warehouse';                                                      //Set Type to Warehouse
                    FulfillmentGroups           = InputRepresentation.fulfillmentGroups;                            //Set Existing Groups on Input Representation
                    ExistingFulfillmentGroup    = false;                                                            //Reset ExistingFulfillmentGroup Flag

                    for(ConnectApi.FulfillmentGroupInputRepresentation FulfillmentGroupVar : FulfillmentGroups){ //Existing Fulfillment Groups
                        System.debug('FulfillmentGroups.size(): '+FulfillmentGroups.size());
                        System.debug('FulfillmentGroupVar: '+FulfillmentGroupVar);
                        // 조건 안타니까 여기부터 보기
                        System.debug('fulfilledFromLocationId: '+FulfillmentGroupVar.fulfilledFromLocationId);
                        System.debug('LocationToFulfill.Id: '+LocationToFulfill.Id);
                        if(FulfillmentGroupVar.fulfilledFromLocationId == LocationToFulfill.Id){                    //Location Has Existing Group? - Yes
                            System.debug('---Existing---');
                            InputRepresentation.fulfillmentGroups = new List<ConnectApi.FulfillmentGroupInputRepresentation>(); //Remove Group from Input Representation  미심쩍어
                            System.debug('before--------FulfillmentGroupVar.orderItemSummaries: '+FulfillmentGroupVar.orderItemSummaries);
                            FulfillmentGroupVar.orderItemSummaries.add(OrderItemSummaryInputRepresentation);        //Add Order Product Summary to Group
                            System.debug('after--------FulfillmentGroupVar.orderItemSummaries: '+FulfillmentGroupVar.orderItemSummaries);
                            ExistingFulfillmentGroup = true;                                                        //Set ExistingFulfillmentGroup Flag to True
                        }else{                                                                                      //Location Has Existing Group? - No
                            //nothing
                        }
                    }

                    if(ExistingFulfillmentGroup == true){                                                           //Added to Existing Group? - Yes
                        //nothing
                    }else{                                                                                          //Added to Existing Group? - No
                        FulfillmentGroup.fulfilledFromLocationId    = '';                                           //Reset Fulfillment Group
                        FulfillmentGroup.fulfillmentType            = '';
                        // FulfillmentGroup.orderItemSummaries         = new List<ConnectApi.OrderItemSummaryInputRepresentation>();

                        FulfillmentGroup.fulfilledFromLocationId    = LocationToFulfill.Id;                         //Create Group for Order Product Summary   
                        FulfillmentGroup.fulfillmentType            = FulfillmentType;
                        System.debug('orderItemSummaries.size(): '+FulfillmentGroup.orderItemSummaries.size());
                        if(FulfillmentGroup.orderItemSummaries.size() > 0) System.debug('orderItemSummaries[0]: '+FulfillmentGroup.orderItemSummaries[0]);
                        if(FulfillmentGroup.orderItemSummaries.size() > 1)System.debug('orderItemSummaries[1]: '+FulfillmentGroup.orderItemSummaries[1]);
                        
                        System.debug('before orderItemSummaries: '+FulfillmentGroup.orderItemSummaries);
                        FulfillmentGroup.orderItemSummaries.add(OrderItemSummaryInputRepresentation);
                        System.debug('after orderItemSummaries: '+FulfillmentGroup.orderItemSummaries);
                    }
                    InputRepresentation.fulfillmentGroups.add(FulfillmentGroup);

                }else if(LocationToFulfill != null && LocationToFulfill.LocationType != 'Warehouse'){               //Location Type - Existing Store Location
                    // Set Type to Store
                }else{                                                                                              //Location Not Found
                    //Use Default Warehouse Location
                }
            }

            if(OrderItemSummaryListDeliveryCharge.size() > 0){                                                      //Any Delivery Charges? - Yes
                FulfillmentGroups = InputRepresentation.fulfillmentGroups;                                          //Get Fulfillment Groups 
                LoopIterationCount = 0;                                                                             //Reset Loop Iteration Counter

                // //All Fulfillment Groups
                // for(ConnectApi.FulfillmentGroupInputRepresentation FulfillmentGroupNewVar : FulfillmentGroups){

                //     //Increment Counter
                //     LoopIterationCount += 1;
                    
                //     //First Loop Iteration? - Yes
                //     if(LoopIterationCount == 1){
                //         //Remove Group from Input Representation
                //         InputRepresentation.fulfillmentGroups.remove(0);

                //         //Add Delivery Charges to Group
                //         FulfillmentGroupNewVar.orderItemSummaries = OrderItemSummaryListDeliveryCharge;

                //         // Add Group to Input Representation
                //         InputRepresentation.fulfillmentGroups.add(FulfillmentGroupNewVar);

                //     //First Loop Iteration? - No
                //         // nothing
                //     }
                // }

                    
                    LoopIterationCount += 1;                                                                            //Increment Counter
                    
                    if(LoopIterationCount == 1){                                                                        //First Loop Iteration? - Yes
                        System.debug('InputRepresentation.fulfillmentGroups: '+InputRepresentation.fulfillmentGroups);  //Remove Group from Input Representation
                        InputRepresentation.fulfillmentGroups.remove(0);

                        FulfillmentGroups[0].orderItemSummaries = OrderItemSummaryListDeliveryCharge;                   //Add Delivery Charges to Group
                        System.debug('after: '+FulfillmentGroups[0].orderItemSummaries);
                        InputRepresentation.fulfillmentGroups.add(FulfillmentGroups[0]);                                // Add Group to Input Representation
                    }
                
                
            //Any Delivery Charges? - No
            }else{
                // nothing
            }

            //Set Input Representation
            InputRepresentation.orderSummaryId              = '1Os1y0000008PWECA2';
            InputRepresentation.orderDeliveryGroupSummaryId = OrderDeliveryGroupSummaryRecord.Id;
        }
        System.debug('InputRepresentation: '+InputRepresentation);

        //Create Fulfillment Order
        // ConnectApi.FulfillmentOrderOutputRepresentation FulfillmentOrdersOutput = ConnectAPI.FulfillmentOrder.createFulfillmentOrders(InputRepresentation);
        // System.debug('FulfillmentOrdersOutput: '+FulfillmentOrdersOutput);
    }

    public class ReturnWrapper{
        @AuraEnabled
        public List<ConfirmedOrderWrapper> confirmedOrderList;
    }

    public class ConfirmedOrderWrapper{        
        @AuraEnabled
        public String confirmedOrderId;       
        @AuraEnabled
        public String confirmedOrderLink;     
        @AuraEnabled
        public String recordTypeId;
        @AuraEnabled
        public String partnerName;     
        @AuraEnabled
        public String confirmedOrderNumber;
        @AuraEnabled
        public String recordTypeName;
        @AuraEnabled
        public String status;
        @AuraEnabled
        public String productName;
        @AuraEnabled
        public Decimal finalTotalAmount;
        @AuraEnabled
        public Decimal quantityOrdered;
        // @AuraEnabled
        // public Decimal quantityCanceled;
        @AuraEnabled
        public Boolean needApproval;
    }

    public class DetailReturnWrapper{
        @AuraEnabled
        public String code;
        @AuraEnabled
        public String msg;
        @AuraEnabled
        public DetailConfirmedOrderWrapper selectedConfirmedOrder;
    }

    public class DetailConfirmedOrderWrapper{
        @AuraEnabled
        public String id;
        @AuraEnabled
        public String orderItemSummary;
        @AuraEnabled
        public String status;
        @AuraEnabled
        public String productName;
        @AuraEnabled
        public Decimal quantityOrdered;
        @AuraEnabled
        public Decimal availableQuantity;
        @AuraEnabled
        public String reasonforRejection;
        @AuraEnabled
        public Decimal finalTotalAmount;
        @AuraEnabled
        public Decimal unitPrice;
    }
}