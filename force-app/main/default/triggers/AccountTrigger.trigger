/**
 * Created by MZC01-DGCHOI on 2023-09-13.
 */

trigger AccountTrigger on Account (before insert, before update) {
    new Account_tr().run();
}