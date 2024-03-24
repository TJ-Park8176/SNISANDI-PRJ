/**
 * Created by MZC01-DGCHOI on 2023-03-28.
 */

public with sharing class CustomLookup {
    @AuraEnabled(Cacheable=true)
    public static List<SObject> search(String searchTerm, String myObject, String filter) {
        String myQuery = null;

        System.debug('@searchTerm: ' + searchTerm);
        System.debug('@myObject: ' + myObject);
        System.debug('@filter: ' + filter);

        if(filter != null && filter != ''){
            myQuery = ' SELECT Id, Name FROM ' + myObject
                    + ' WHERE Name Like  \'%' + searchTerm + '%\' '
                    + ' AND (AccountSubjectsort__c = \'' + filter + '\' OR MiddleSort__c = \'매출원가\') ' +
                    + ' AND UpperSort__c NOT IN (\'공통비배부(용)\', \'공통비배부(판)\')';
        }
        else {
            if(searchTerm == null || searchTerm == ''){
                myQuery = ' SELECT Id, Name '
                        + ' FROM ' + myObject
                        + ' WHERE UpperSort__c NOT IN (\'공통비배부(용)\', \'공통비배부(판)\')'
                        + ' ORDER BY LastViewedDate DESC ';
            }
            else {
                myQuery = ' SELECT Id, Name '
                        + ' FROM ' + myObject
                        + ' WHERE Name Like  \'%' + searchTerm + '%\''
                        + ' AND UpperSort__c NOT IN (\'공통비배부(용)\', \'공통비배부(판)\')';
            }
        }
        List<SObject> lookUpList = Database.query(myQuery);
        return lookUpList;
    }
}