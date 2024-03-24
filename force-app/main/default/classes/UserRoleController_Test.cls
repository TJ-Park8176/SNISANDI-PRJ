/**
 * Created by MZC01-DGCHOI on 2023-03-30.
 */

@IsTest
public with sharing class UserRoleController_Test {

    @IsTest
    static void test() {
        Test.startTest();

        Id userId              = UserInfo.getUserId();
        Id userRoleId          = UserRoleController.getUserRoleId(userId);
        Boolean isHeadOfCenter = UserRoleController.isUserRoleHeadOfCenter(userRoleId);
        Set<Id> subRoleSet     = UserRoleController.getSubordinateRoles(userRoleId);
        Boolean isAdmin        = UserRoleController.isSystemAdmin();

        Test.stopTest();
    }
}