/**
 * @description       : 
 * @author            : jisoolee@mz.co.kr
 * @group             : 
 * @last modified on  : 2023-10-18
 * @last modified by  : jisoolee@mz.co.kr
**/

trigger GroupTrigger on Group__c (after insert, after update) {
    new Group_tr().run();
}