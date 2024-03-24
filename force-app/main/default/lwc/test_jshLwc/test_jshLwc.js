/**
 * @description       : 
 * @author            : sungho.jo@mz.co.kr
 * @group             : 
 * @last modified on  : 2024-03-22
 * @last modified by  : sungho.jo@mz.co.kr
**/
import { 
    LightningElement
    , api
    , wire
    , track
 } from 'lwc';

import apex_getCase from'@salesforce/apex/TEST_JSHClass.getCase';

export default class Test_jshLwc extends LightningElement {


    connectedCallback(){
        apex_getCase().then((res)=> console.log('#Test_jshLwc ', res));
    }
}