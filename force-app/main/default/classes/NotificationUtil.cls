/**
 * @description       : NotificationUtil
 * @author            : sungho.jo@mz.co.kr
 * @group             : MegazoneCloud
 * @last modified on  : 2024-03-14
 * @last modified by  : sungho.jo@mz.co.kr
**/
public with sharing class NotificationUtil {
    
    /**
    * @description check list size
    * @author sungho.jo@mz.co.kr | 2024-03-08 
    * @param objs 
    * @return Boolean 
    **/
    public static Boolean isNotEmpty(List<Object> objs){
        return (objs != null && !objs.isEmpty());
    }

    /**
    * @description check map size
    * @author sungho.jo@mz.co.kr | 2024-03-08 
    * @param objs 
    * @return Boolean 
    **/
    public static Boolean isNotEmpty(Map<String, Object> objs){
        return (objs != null && !objs.isEmpty());
    }

    /**
    * @description sObject에서 key를 통해 값을 가져옴
    * @author sungho.jo@mz.co.kr | 2024-03-11 
    * @param sObj : sObject
    * @param key : String
    * @return String 
    **/
    public static String getValue(sObject sObj, String key){
        return sObj.get(key) != null ? (String)sObj.get(key) : '';
    }

    /**
    * @description 공통으로 값을 text로 뺄 수 있도록 JSON으로 처리함.
    * @author sungho.jo@mz.co.kr | 2024-03-08 
    * @param splitFieldNames : List<String> 
    * @param mapJson : Map<String, Object>
    * @return String 
    **/
    public static String getValue(List<String> splitFieldNames, Map<String, Object> mapJson){
        String result = '';
        // relation data를 가져오기 위해 재귀 호출
        while(!splitFieldNames.isEmpty()){
            String key = splitFieldNames[0];
            // 다음 필드 값을 가져오기 위해 remove(0), remove 후 splitFieldNames가 비어있으면 최종 리턴
            splitFieldNames.remove(0);
            if(splitFieldNames.size() == 0){                
                result = (mapJson.containsKey(key)) ? (String) mapJson.get(key) : '' ;
            } else if(splitFieldNames.size() != 0 && mapJson.containsKey(key)) {
                result = getValue(splitFieldNames, (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(mapJson.get(key))));
            } else if(splitFieldNames.size() != 0 && !mapJson.containsKey(key)){
                splitFieldNames.remove(0);
            }
        }
        return result;
    }


    /**
    * @description sObject객체를 Map<String, Object>로 변환
    * @author sungho.jo@mz.co.kr | 2024-03-11 
    * @param sObj : sObject
    * @return Map<String, Object> 
    **/
    public static Map<String, Object> convertJsonObjToMap(sObject sObj){
        return (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(sObj));
    }

    /**
    * @description list merge
    * @author sungho.jo@mz.co.kr | 2024-03-13 
    * @param merges : List<String>
    * @param targets : List<String>
    **/
    public static void mergeList(List<String> merges, List<String> targets){
        if(NotificationUtil.isNotEmpty(targets)){
            for(String obj : targets){
                merges.add(obj);
            }
        }
    }
}