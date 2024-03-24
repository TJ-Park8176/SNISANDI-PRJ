// Apex class to retrieve Case record values
public with sharing class GetCaseRecordValues {

    // Invocable method to retrieve Case record values by Id
    @InvocableMethod(label='Get Case Record Values' description='Retrieve Case record values by Id')
    public static List<Case> getCaseRecordValues(List<Id> caseIds) {
        // Query Case records based on the provided Ids
        List<Case> cases = [SELECT Id, Subject, Status, Priority, Description FROM Case WHERE Id IN :caseIds];
        return cases;
    }
}