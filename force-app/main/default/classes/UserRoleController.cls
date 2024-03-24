/**
 * Created by MZC01-DGCHOI on 2023-03-30.
 */

public without sharing class UserRoleController {

    //Get Child UserRole
    public static Set<Id> getSubordinateRoles(Id roleId) {
        Map<Id, Set<Id>> parentAndChildren = new Map<Id, Set<Id>>();
        Set<Id> children;
        for(UserRole ur : [SELECT Id, ParentRoleId FROM UserRole]) {
            children = parentAndChildren.containsKey(ur.ParentRoleId) ? parentAndChildren.get(ur.ParentRoleId) : new set<Id>();
            children.add(ur.Id);
            parentAndChildren.put(ur.ParentRoleId, children);
        }
        return getSubordinateRoles(roleId, parentAndChildren);
    }

    public static Set<Id> getSubordinateRoles(Id roleId, Map<Id, Set<Id>> parentAndChildren) {
        Set<Id> subordinateRoles = new Set<Id>();
        Set<Id> remainingSubordinateRoles = new Set<Id>();
        if(parentAndChildren.containsKey(roleId)) {
            subordinateRoles.addAll(parentAndChildren.get(roleId));
            for(Id subRoleId : subordinateRoles) {
                remainingSubordinateRoles.addAll(getSubordinateRoles(subRoleId, parentAndChildren));
            }
        }
        subordinateRoles.addAll(remainingSubordinateRoles);
        return subordinateRoles;
    }

    public static Id getUserRoleId(Id userId) {
        Id userRoleId = null;
        //current Upsert Role로 검색하기.. wbs 아님날온ㅁ어라니ㅓㅇ리ㅏ넝라ㅣ허능

        User stdUser = [
                SELECT Id, UserRoleId
                FROM User
                WHERE Id =: userId
        ];

        return stdUser.UserRoleId;
    }

    public static Boolean isUserRoleHeadOfCenter(Id userRoleId) {
        List<UserRole> userRoleList = [
                SELECT Id, Name
                FROM UserRole
                Where Id =: userRoleId
        ];

        if(!userRoleList.isEmpty() && userRoleList[0].Name.contains('센터장')) {
            return true;
        }
        return false;
    }

    //시스템 관리자인지 체크
    @AuraEnabled(Cacheable=true)
    public static Boolean isSystemAdmin() {
        //시스템관리자면 True
        Id userId = UserInfo.getProfileId();

        List<Profile> profiles = [
                SELECT Id, Name
                FROM Profile
                WHERE Id =: userId
                AND (Name = '시스템 관리자' OR Name = 'System Administrator')
        ];

        return !profiles.isEmpty();
    }

    /**
     * @param userId
     *
     * @return 해당 유저가 COC 팀인지 체크
     */
    @AuraEnabled
    public static Boolean isUserRoleCOC() {
        String userRoleName = [SELECT UserRole.Name FROM User WHERE Id =: UserInfo.getUserId() LIMIT 1].UserRole.Name;
        return userRoleName.equals('관리자(COC팀)') ? true : false;
    }
}