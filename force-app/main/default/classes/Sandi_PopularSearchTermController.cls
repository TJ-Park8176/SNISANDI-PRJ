/**
 * Created by MZC01-DGCHOI on 2024-03-06.
 */

public with sharing class Sandi_PopularSearchTermController {

    /**
     * @return 인기검색어 Rank 순으로 리턴
     */
    @AuraEnabled(Cacheable=true)
    public static List<Popular_Search_Term_SANDI__c> getPopularSearchTerms() {

        //우선 노출 False인 검색어 중 검색횟수 큰 순으로 5개 추출
        List<Popular_Search_Term_SANDI__c> popularTerms = [
            SELECT Id, Name, Rank__c
            FROM Popular_Search_Term_SANDI__c
            WHERE IsActive__c = TRUE
            AND PriorityExposure__c = FALSE
            ORDER BY NumberOfSearches__c DESC
            LIMIT 5
        ];

        //우선 노출 True인 검색어 랭크 추출
        List<Popular_Search_Term_SANDI__c> priorityTerms = [
            SELECT Id, Name, Rank__c
            FROM Popular_Search_Term_SANDI__c
            WHERE IsActive__c = TRUE
            AND PriorityExposure__c = TRUE
            ORDER BY Rank__c ASC
        ];

        for(Popular_Search_Term_SANDI__c priorityTerm : priorityTerms) {
            popularTerms.add(
                    Integer.valueOf(priorityTerm.Rank__c)-1,
                    priorityTerm
            );
        }

        System.debug('우선순위 add 후 리스트 ? ' + popularTerms);

        //최대 5개 추출
        if(popularTerms.size() > 5) {
            List<Popular_Search_Term_SANDI__c> trimmedTerms = new List<Popular_Search_Term_SANDI__c>();
            Integer endIndex = Math.min(5, popularTerms.size());
            for(Integer i=0; i< endIndex; i++) {
                trimmedTerms.add(popularTerms[i]);
            }

            return trimmedTerms;
        }

        return popularTerms;
    }

    /**
     * @param term update할 검색어
     */
    @AuraEnabled
    public static void updateTerm(String term) {
        List<Popular_Search_Term_SANDI__c> terms = [
                SELECT Id, Name, NumberOfSearches__c
                FROM Popular_Search_Term_SANDI__c
                WHERE Name =: term
                LIMIT 1
        ];

        if(terms.size() > 0) { //검색어 있을 경우 검색횟수 +1 업데이트
            terms[0].NumberOfSearches__c = terms[0].NumberOfSearches__c + 1;
            update terms;
        } else { //검색어 없을 경우 생성
            Popular_Search_Term_SANDI__c newTerm = new Popular_Search_Term_SANDI__c();
            newTerm.IsActive__c = true;
            newTerm.Name = term; //검색어
            insert newTerm;
        }
    }
}