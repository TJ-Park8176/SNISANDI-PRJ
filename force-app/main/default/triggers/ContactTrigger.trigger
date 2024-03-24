/**
 * Created by MZC01-DGCHOI on 2023-04-26.
 */

trigger ContactTrigger on Contact (after insert, after update, after delete) {
    new Contact_tr().run();
}