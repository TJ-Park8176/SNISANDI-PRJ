global with sharing class BillingAddressController {

    @AuraEnabled(cacheable=true)
    public static String getCurrentObject(Id recId) {
        System.debug('recId: ' + recId);
        String objName = recId.getSObjectType().getDescribe().getName();
        System.debug('objName: ' + objName);
        return objName;
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getFieldList(Id recId){
        String objName = getCurrentObject((Id)recId);
        List<Map<String, String>> returnList = new List<Map<String, String>>();

        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType accSchema = schemaMap.get(objName);
        Map<String, Schema.SObjectField> fieldMap = accSchema.getDescribe().fields.getMap();

        for (String fieldName: fieldMap.keySet()) {
            Map<String, String> tmpMap = new Map<String, String>();
            Schema.DisplayType fielddataType = fieldMap.get(fieldName).getDescribe().getType();
            String fieldLabel = fieldMap.get(fieldName).getDescribe().getLabel();
            if(String.valueOf(fielddataType) == 'ADDRESS') {
                tmpMap.put('label', fieldLabel);
                tmpMap.put('value', fieldName);
                returnList.add(tmpMap);
            }
        }

        List<ContactPointAddress> contactPointAddresses = [
                SELECT Id
                FROM ContactPointAddress
                WHERE ParentId = '0011y00000liPY8AAM'
        ];

        System.debug(returnList);
        return returnList;
    }

    public string lexOrigin {
        get{
            return URL.getOrgDomainUrl().toExternalForm().split('.my.')[0]+'.lightning.force.com';
        } set;
    }

    @RemoteAction
    global static void updateBillingAddress(String recordId, Map<String, String> addrMap) {
        System.debug('recordId : ' + recordId);
        //System.debug('fieldKey : ' + fieldKey);
        System.debug('addrMap  : ' + addrMap);

        String objName = getCurrentObject((Id)recordId);

        try {
            SObject sObj = Database.query(' SELECT Id, Name, Address FROM ' + objName + ' WHERE Id = :recordId LIMIT 1 '); // \'' + String.valueOf(accId) + '\'

            System.debug(sObj);
            System.debug('User.getInfo : ' + UserInfo.getUserId());

            if(sObj != null) {
                 /*
                if(fieldKey.endsWith('__c')) { //Custom Object
                    String s = fieldKey.substring(0, fieldKey.length()-1);
                    sObj.put(s+'Street__s', addrMap.get('state') + ' ' + addrMap.get('city') + ' ' + addrMap.get('street')); //상세주소
                    sObj.put(s+'PostalCode__s', addrMap.get('zipCode')); //우편번호
                    sObj.put(s+'CountryCode__s', 'KR'); //국가
                } else { //Standard Object
                  */

                //String s = fieldKey.substring(0, fieldKey.lastIndexOf('address')); //billing, shipping.. 이런식

                sObj.put('state',      addrMap.get('state')); //시도
                sObj.put('city',       addrMap.get('city')); //시군구
                sObj.put('street',     addrMap.get('street')); //도로명
                sObj.put('postalCode', addrMap.get('zipCode')); //우편번호
                sObj.put('country',   'KR');
            }

            System.debug('before UPDATE: ' + sObj);
            update sObj;

            platformEvent('Update Success', 'success');
        } catch(Exception e) {
            platformEvent('Update Fail', 'error');
            System.debug(e);
            System.debug(e.getLineNumber());
            System.debug(e.getMessage());
        }

        Schema.SObjectType convertType = Schema.getGlobalDescribe().get(objName);
    }

    @AuraEnabled(cacheable=true)
    public static String getVFOrigin(){
        string vfOrigin = '';
        string baseURL = URL.getOrgDomainUrl().toExternalForm(); // Expected Format = https://domain.my.salesforce.com


        if(baseURL.contains('.sandbox.')) {
            baseURL.replace('.my.', '');
            vfOrigin = baseURL.split('.sandbox.')[0] + '--c.' + 'sandbox.vf.force.com';
        } else {
            vfOrigin = baseURL.split('.my.')[0] + '--c.' + 'visualforce.com';
        }

        // Expected Format for DE, Sandbox & Production ORgs = https://domain--c.visualforce.com
        System.debug('baseURL: ' + baseURL);
        System.debug('(return)vfOrigin: ' + vfOrigin);
        return vfOrigin;
    }

    @RemoteAction
    global static void platformEvent(String message, String status) {
        System.debug('platformEvent start() -----');
        System.debug(message + status);
        Search_Address__e event = new Search_Address__e();
        event.message__c = message;
        event.status__c = status;
        EventBus.publish(event);
    }

}