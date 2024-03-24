/**
 * @description       : 
 * @author            : junghwa@mz.co.kr
 * @group             : 
 * @last modified on  : 2023-02-06
 * @last modified by  : junghwa@mz.co.kr
**/
global without sharing class BATCH_MigDeleteData implements DataBase.Batchable<SObject>, DataBase.stateful {
    public String objectType; //delete target obj
    public String order;
    global BATCH_MigDeleteData(){}
    global BATCH_MigDeleteData(String objectType){
        this.objectType = objectType;
    } 

    global BATCH_MigDeleteData(String objectType, String order){
        this.objectType = objectType;
        this.order = order;
    } 
    global Database.QueryLocator start(Database.BatchableContext BC){
        System.debug('BATCH_MigDeleteData Batch START');
        String query = ' SELECT Id ';
        query += ' FROM '+ this.objectType;
		//query += ' limit 1'; // test용
		if(String.isNotBlank(order)) query += ' order by id ' + order;
        return Database.getQueryLocator(query);
    }
 
    global void execute(Database.BatchableContext BC, List<sObject> objList){
        System.debug('BATCH_MigDeleteData Batch Excute START');
        try{
            System.debug('objList.size : '+objList.size());
            delete objList;
        }catch(Exception e){
            System.debug('e : '+e);
            System.debug('e.getLine : '+e.getLineNumber());
            System.debug('e.getMessage : '+e.getMessage());
        }
    }
    
    global void finish(Database.BatchableContext BC){
        System.debug('BATCH_MigDeleteData Batch Finish START');
        try{
            
        }catch(Exception e){
            System.debug('ERROR      : ' + e);
            System.debug('ERROR LINE : ' + e.getLineNumber());
            System.debug('ERROR MSG  : ' + e.getMessage());
        }
        System.debug('BATCH_MigDeleteData Batch Finish END');
    }
}