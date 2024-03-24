public with sharing class Sandi_OpptyRequestController {
    /*public static final String SALESTYPE_SANDI = 'QuoteProduct_SANDI__c';

    @AuraEnabled(Cacheable=true)
    public static Boolean getSalesType(Id productId) {
        //List<String> picklistValues = new List<String>();
        // Product2 오브젝트 레코드 조회
        Product2 product = [SELECT Id, QuoteProduct_SANDI__c FROM Product2 WHERE Id = :productId];

        String picklistFieldValue = product.QuoteProduct_SANDI__c;

        // Product2 레코드에서 멀티-선택 필드 값 가져오기
        //String multiSelectFieldValue = product.QuoteProduct_SANDI__c;
        // 쉼표로 구분된 값들을 리스트로 분할
        // if (!String.isEmpty(multiSelectFieldValue)) {
        //     picklistValues = multiSelectFieldValue.split(',');
        // }
        //return picklistValues.contains('견적형');

        return !String.isEmpty(picklistFieldValue);
    }*/

    // 사용자의 정보를 가져오는 메서드
    @AuraEnabled(Cacheable=true)
    public static UserInfoWrapper getContactInfo(Id userId) {
        // Wrapper 객체 생성
        UserInfoWrapper userInfo = new UserInfoWrapper();
        
        // 현재 사용자의 세션 정보 가져오기
        User currentUser = [SELECT Id, ContactId FROM User WHERE Id = :userId]; //'0051y00000OZmXoAAL'
        
        // 만약 사용자가 연락처를 가지고 있지 않은 경우 isGuest를 true로 설정하고 리턴
        if(currentUser.ContactId == null) {
            userInfo.isGuest = true;
            return userInfo;
        }
        
        // Contact 레코드 가져오기
        Contact loggedInContact = [SELECT Id, Name, FirstName, 	LastName, Email, Phone, AccountId FROM Contact WHERE Id = :currentUser.ContactId LIMIT 1];
        
        // 사용자의 정보 설정
        userInfo.Name = loggedInContact.Name;
        userInfo.FirstName = loggedInContact.FirstName;
        userInfo.LastName = loggedInContact.LastName;
        userInfo.Email = loggedInContact.Email;
        userInfo.Phone = loggedInContact.Phone;
        userInfo.AccountId = loggedInContact.AccountId;
        
        // isGuest를 false로 설정하고 리턴
        userInfo.isGuest = false;
        return userInfo;
    }

        public class UserInfoWrapper {
        @AuraEnabled public Boolean isGuest { get; set; }
        @AuraEnabled public String Name { get; set; }
        @AuraEnabled public String FirstName { get; set; }
        @AuraEnabled public String LastName { get; set; }
        @AuraEnabled public String Email { get; set; }
        @AuraEnabled public String Phone { get; set; }
        @AuraEnabled public String AccountId { get; set; }
    }

}