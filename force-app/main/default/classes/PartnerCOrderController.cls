/**
 * @description       : 
 * @author            : heoyeonu@mz.co.kr
 * @group             : 
 * @last modified on  : 2024-03-22
 * @last modified by  : heoyeonu@mz.co.kr
**/
public with sharing class PartnerCOrderController {

    public static final List<String> statusAllList = new List<String>{'Allocated', 'Rejected', 'Assigned', 'Fulfilled', 'Delivery Completed', 'Canceled'};
    public static final Id ORDER_RECORDTYPE_ID = [SELECT Id FROM RecordType WHERE SObjectType = 'ConfirmedOrder__c' AND DeveloperName = 'Sales'].Id;

    @AuraEnabled
    public static Map<String, Object> getinitOrderList() {
        List<wrapperOrderData> resultData = new List<wrapperOrderData>();
        Map<String, Object> resultMap = new Map<String, Object>();
        try {
            Date oneWeekAgo = System.today().addDays(-7);
            Date today = System.today();
            System.debug('getinitOrderList oneWeekAgo :::: '+ oneWeekAgo);
            System.debug('getinitOrderList today :::: '+ today);

            List<ConfirmedOrder__c> orderList = [SELECT Id, Name, ConfirmedOrderNumber__c ,Status__c,Account__r.Name ,Accountaddress__c,Account__r.Phone
                                                        , FinalTotalAmount__c, Product__r.name,QuantityOrdered__c ,TotalOrderedQuantity__c
                                                        , DeliveryCompany__c,TransportDocNumber__c ,CreatedDate
                                                FROM ConfirmedOrder__c WHERE RecordTypeId =:ORDER_RECORDTYPE_ID AND CreatedDate >= :oneWeekAgo AND CreatedDate <= :today AND Status__c In: statusAllList Order by CreatedDate];  
            
            Map<String, String> pleMap = getFieldPicklistMap('ConfirmedOrder__c', 'Status__c');
            if(orderList.size()>0){
                for(ConfirmedOrder__c ol:  orderList){
                    ol.Status__c = pleMap.get(ol.Status__c);
                    resultData.add(new wrapperOrderData(ol));
                }
                resultMap.put('orderList', resultData);
            }

             return resultMap; 
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
       
    }
    @AuraEnabled
    public static Map<String, object> changeStatus(String statusaction,List<Id> selectedIds) {
        List<wrapperOrderData> resultData = new List<wrapperOrderData>();
        Map<String, Object> resultMap = new Map<String, Object>();
        try {
            List<ConfirmedOrder__c> updateList = new List<ConfirmedOrder__c>();
            List<ConfirmedOrder__c> orderList = [SELECT Id, Name, ConfirmedOrderNumber__c ,Status__c,Account__r.Name ,Accountaddress__c,Account__r.Phone
                                                , FinalTotalAmount__c, Product__r.name,QuantityOrdered__c ,TotalOrderedQuantity__c
                                                , DeliveryCompany__c,TransportDocNumber__c ,CreatedDate
                                                FROM ConfirmedOrder__c WHERE Id In:selectedIds];  

            for(ConfirmedOrder__c ol:  orderList){
                if(statusaction == 'Assigned'){
                    ol.Status__c = 'Assigned';
                }else if(statusaction == 'Rejected'){
                    ol.Status__c = 'Rejected';
                }else if(statusaction == 'Fulfilled'){
                    ol.Status__c = 'Fulfilled';
                }else if(statusaction == 'Delivery Completed'){
                    ol.Status__c = 'Delivery Completed';
                }
                updateList.add(ol);
            }
            if(updateList.size() > 0){
                update updateList;
            }
            Map<String, String> pleMap = getFieldPicklistMap('ConfirmedOrder__c', 'Status__c');

            if(updateList.size()>0){
                for(ConfirmedOrder__c ol:  updateList){
                    ol.Status__c = pleMap.get(ol.Status__c);
                    resultData.add(new wrapperOrderData(ol));
                }
                resultMap.put('updateorderList', resultData);
            }
             return resultMap; 
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    public static Map<String, String> getFieldPicklistMap(String objectName, String fieldName) {
        Map<String, String> picklistMap = new Map<String, String>();
        try {
            Schema.DescribeFieldResult fieldResult = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().get(fieldName).getDescribe();
            List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
            for (Schema.PicklistEntry entry : picklistValues) {
                picklistMap.put(entry.getValue(), entry.getLabel());
            }
        } catch (Exception e) {
            System.debug('Error fetching picklist values: ' + e.getMessage());
        }
        return picklistMap;
    }
    public static String convertEmptyString(String getvalue) {
        return String.isEmpty(getvalue) ? '' : getvalue;
    }

    public static String PhoneFormatt(String phone){
        String tmp = '';
        
        if(String.isNotBlank(phone)){
            String regex82plus = '+82';
            String regexSpace = ' ';
            String regex09 = '([^0-9])';

            tmp = phone.replace(regex82plus, '');
            if( phone.subString(0,2) == '82') tmp = phone.replace('82', '');
            tmp = tmp.replaceAll(regexSpace, '');
            tmp = tmp.replaceAll(regex09, '');
            
            if(tmp.left(1) == '1') tmp = '0'+tmp;
        }

        return tmp;

    }
    @AuraEnabled
    public static Map<String, Object> getSearchOrderList(String StartDate, String EndDate, String Status, String Filter, String SearchContents) {
        List<wrapperOrderData> resultData = new List<wrapperOrderData>();
        Map<String, Object> resultMap = new Map<String, Object>();
        try {
     
            System.debug('getSearchOrderList StartDate :::: '+ StartDate);
            System.debug('getSearchOrderList EndDate :::: '+ EndDate);
            System.debug('getSearchOrderList Status :::: '+ Status);
            System.debug('getSearchOrderList Filter :::: '+ Filter);
            System.debug('getSearchOrderList SearchContents :::: '+ SearchContents);
            Datetime StartDateTime;
            Datetime EndDateTime;
            if(StartDate != null){
                List<String> sdt = StartDate.split('-');
                StartDateTime = Datetime.newInstance(
                    Integer.valueOf(sdt[0]),
                    Integer.valueOf(sdt[1]),
                    Integer.valueOf(sdt[2]),
                    0, 0, 0
                );
            }
            if(EndDate != null){
                List<String> edt = EndDate.split('-');
                EndDateTime = Datetime.newInstance(
                    Integer.valueOf(edt[0]),
                    Integer.valueOf(edt[1]),
                    Integer.valueOf(edt[2]),
                    23, 59, 59
                );
            }

            String query = 'SELECT Id, Name, ConfirmedOrderNumber__c, Status__c';
            query += ', Account__r.Name, Accountaddress__c, Account__r.Phone';
            query += ', FinalTotalAmount__c, Product__r.name, QuantityOrdered__c ,TotalOrderedQuantity__c';
            query += ', DeliveryCompany__c, TransportDocNumber__c, CreatedDate';
            query += ' FROM ConfirmedOrder__c WHERE RecordTypeId =:ORDER_RECORDTYPE_ID ';

            if (Status != 'all') {
                query += ' AND Status__c = :Status';
            }

            if (StartDate != null  && EndDate != null) {   
                query += ' AND CreatedDate >= :StartDateTime AND CreatedDate <= :EndDateTime';
            } else if (StartDate != null) {
                query += ' AND CreatedDate >= :StartDateTime';
            } else if (EndDate != null) {
                query += ' AND CreatedDate <= :EndDateTime';
            }

            if ( SearchContents != null) {
                String[] searchKeywords = SearchContents.split(',');
                String dynamicQuery = '';
                for (String keyword : searchKeywords) {
                    if (Filter == 'OrderName') {
                        dynamicQuery += ' OR ConfirmedOrderNumber__c LIKE \'%' + keyword.trim() + '%\'';
                    } else if (Filter == 'AccountName') {
                        dynamicQuery += ' OR Account__r.Name LIKE \'%' + keyword.trim() + '%\'';
                    } else if (Filter == 'ProductName') {
                        dynamicQuery += ' OR Product__r.name LIKE \'%' + keyword.trim() + '%\'';
                    } else if (Filter == 'TransportDocNumber') {
                        dynamicQuery += ' OR TransportDocNumber__c LIKE \'%' + keyword.trim() + '%\'';
                    }
                }
                if (dynamicQuery != '') {
                    query += ' AND (' + dynamicQuery.substring(4) + ')';
                }
            }

            query += ' ORDER BY CreatedDate';
            List<ConfirmedOrder__c> orderList = Database.query(query); 

            if (orderList.size() > 0) {
                Map<String, String> pleMap = getFieldPicklistMap('ConfirmedOrder__c', 'Status__c');  
                for (ConfirmedOrder__c ol : orderList) {
                    ol.Status__c = pleMap.get(ol.Status__c);
                    resultData.add(new wrapperOrderData(ol));
                }
                resultMap.put('searchorderList', resultData);
            }

            return resultMap;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }                                        
    }
   
    public class wrapperOrderData {
        @AuraEnabled public Id orderId {get;set;}
        @AuraEnabled public String orderName {get;set;}
        @AuraEnabled public String orderStatus {get;set;}
        @AuraEnabled public String accountName {get;set;}
        @AuraEnabled public String accountAddress {get;set;}
        @AuraEnabled public String accountPhone {get;set;}
        @AuraEnabled public String orderfta {get;set;}
        @AuraEnabled public String orderPName {get;set;}
        @AuraEnabled public String orderQuantity {get;set;}
        @AuraEnabled public String orderDCompany {get;set;}
        @AuraEnabled public String ordertdnumber {get;set;}
        @AuraEnabled public Datetime createdDate {get;set;}

        wrapperOrderData() {

        }

        public wrapperOrderData(ConfirmedOrder__c orderData) {
            this.orderId = orderData.Id;
            this.orderName = orderData.ConfirmedOrderNumber__c;
            this.orderStatus = orderData.Status__c;
            this.accountName =  convertEmptyString(orderData.Account__r.Name);
            this.accountAddress = convertEmptyString(orderData.Accountaddress__c);
            this.accountPhone = convertEmptyString(PhoneFormatt(orderData.Account__r.Phone));
            this.orderfta = orderData.FinalTotalAmount__c.format() != null ? orderData.FinalTotalAmount__c.format() : ''; 
            this.orderPName = convertEmptyString(orderData.Product__r.name);
            this.orderQuantity = orderData.TotalOrderedQuantity__c.format() != null ? orderData.TotalOrderedQuantity__c.format() : '';
            this.orderDCompany = convertEmptyString(orderData.DeliveryCompany__c);
            this.ordertdnumber = convertEmptyString(orderData.TransportDocNumber__c);
            this.createdDate = orderData.CreatedDate;    
        }
    }
   

}