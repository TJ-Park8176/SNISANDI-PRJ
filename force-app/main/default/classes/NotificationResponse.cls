/**
 * @description       : NotificationResponse
 * @author            : sungho.jo@mz.co.kr
 * @group             : MegazoneCloud
 * @last modified on  : 2024-03-11
 * @last modified by  : sungho.jo@mz.co.kr
 * 
 * To-do
 * 2024-03-07 api 정의서에 맞게 수정, 아직 정의서 받지 못함.
**/
public with sharing class NotificationResponse {

    /**
    * @description Result code : S, F
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    public String resultCode;
    /**
    * @description Result message
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    public String resultMsg;
    /**
    * @description I/F Response traceid
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    public String traceId;

    /**
    * @description constructor
    * @author sungho.jo@mz.co.kr | 2024-03-07 
    **/
    public NotificationResponse() {
        this.resultCode = 'S';
        this.resultMsg  = '';
        this.traceId    = '';
    }

    /**
    * @description Error result 설정
    * @author sungho.jo@mz.co.kr | 2024-03-11 
    * @param resultMsg : String
    * @param e : Exception
    **/
    public void setErrorResult(String resultMsg, Exception e){
        this.resultCode = 'F';
        this.resultMsg  = (String.isNotBlank(resultMsg)) ? resultMsg : (e != null ? e.getMessage() : '');
    }

    /**
    * @description Success result 설정
    * @author sungho.jo@mz.co.kr | 2024-03-11 
    * @param httpResponse : HttpResponse
    **/
    public void setSuccessResult(HttpResponse httpResponse){
        this.resultCode = 'S';
        // 임시로 성공 uuid 생성
        this.resultMsg  = '';
        this.traceId    = UUID.randomUUID().toString();
    }
}