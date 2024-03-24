/**
 * Created by MZC01-DGCHOI on 2024-03-21.
 */

public with sharing class Sandi_ContactPointAddressController {

    /**
     * @return 유저별 배송지 리턴
     */
    @AuraEnabled(Cacheable=true)
    public static List<ContactPointAddress> getContactPointAddressesByUserId(String userId) {
        System.debug('userId :::: ' + UserInfo.getUserId());

        Id accountId = [
                SELECT Id, AccountId
                FROM User
                WHERE Id = :userId
                LIMIT 1
        ].AccountId;

        List<ContactPointAddress> contactPointAddresses = [
                SELECT Id, Name, Address, IsDefault
                FROM ContactPointAddress
                WHERE ParentId = :accountId
                ORDER BY CreatedDate
        ];

        return contactPointAddresses;
    }

    /**
     * @param addressId ContactPointAddress Id
     * @param addressInfoMap 주소 정보 Map
     * @description ContactPointAddress 주소 정보 업데이트
     */
    @AuraEnabled
    public static void updateContactPointAddress(String addressId, Map<String, String> addressInfoMap) {
        ContactPointAddress cpa = new ContactPointAddress();
        cpa.Id = addressId;

        for (String addressInfoKey : addressInfoMap.keySet()) {
            cpa.put('addressInfoKey', addressInfoMap.get(addressInfoKey));
        }

        update cpa;
    }

    /**
     * @param userId
     * @param addressInfoMap 주소 정보 Map
     *
     * @return ContactPointAddress 생성
     */
    @AuraEnabled
    public static void createContactPointAddress(String userId, Map<String, String> addressInfoMap) {
        System.debug('userId :::: ' + UserInfo.getUserId());

        Id accountId = [
                SELECT Id, AccountId
                FROM User
                WHERE Id = :userId
                LIMIT 1
        ].AccountId;

        ContactPointAddress cpa = new ContactPointAddress();
        cpa.ParentId            = accountId;
        cpa.AddressType         = 'Shipping';

        for (String addressInfoKey : addressInfoMap.keySet()) {
            cpa.put(addressInfoKey, addressInfoMap.get(addressInfoKey));
        }

        insert cpa;
    }
}