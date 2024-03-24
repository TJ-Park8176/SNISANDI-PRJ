/**
 * @description       : SANDI_NicepayRequest 
 *                      request 용 wrap
 * @author            : sungho.jo@mz.co.kr
 * @group             : MegazoneCloud
 * @last modified on  : 2024-03-22
 * @last modified by  : sungho.jo@mz.co.kr
**/
public with sharing class SANDI_NicepayRequest {
    /**
    * @description nicepay 요청 파라미터 공통
    * @author sungho.jo@mz.co.kr | 2024-03-22
    **/
    public virtual class NicepayRequest {
        /**
        * @description 거래번호, 인증결과로 받은 TxTid 파라미터 설정 예시) nicepay00m03011911140919215275
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/
        @AuraEnabled public String TID;

        /**
        * @description 인증 TOKEN, 인증결과로 받은 AuthToken 파라미터 설정 예시) NICETOKNF435F661A2D54ED799BFB9F4B3F7E369
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/
        @AuraEnabled public String AuthToken;

        /**
        * @description 상점 ID
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/
        @AuraEnabled public String MID;

        /**
        * @description 결제금액
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/
        @AuraEnabled public String Amt;

        /**
        * @description 전문생성일시 (YYYYMMDDHHMISS)
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/
        @AuraEnabled public String EdiDate;

        /**
        * @description 위변조 검증 Data 생성규칙 : hex(sha256(AuthToken + MID + Amt + EdiDate + MerchantKey))
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/
        @AuraEnabled public String SignData;

        /**
        * @description 응답파라메터 인코딩 방식
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/
        @AuraEnabled public String Charset;

        /**
        * @description 응답전문 유형 (default(미설정): JSON / KV(설정): Key=Value형식 응답)
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/
        @AuraEnabled public String EdiType;

        /**
        * @description 상점 정보 전달용 예비필드 (Nicepay 가공없음)
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/
        @AuraEnabled public String MallReserved;
    }

    /**
    * @description 승인 요청 파라미터
    * @author sungho.jo@mz.co.kr | 2024-03-22
    **/
    public class NicepayApprRequest extends NicepayRequest{}


    /**
    * @description 망취소 요청 파라미터
    * @author sungho.jo@mz.co.kr | 2024-03-22
    **/
    public class NicepayNetCancelRequest extends NicepayRequest{
        /**
        * @description 망취소 여부, 망취소 시 “1” 설정
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/
        @AuraEnabled public String NetCancel;
    }

    /**
    * @description 승인 취소 요청 파라미터
    * @author sungho.jo@mz.co.kr | 2024-03-22
    **/  
    public class NicepayCancelRequest extends NicepayRequest{
        /**
        * @description 상점에서 부여하는 취소 주문번호 (Unique하게 구성)
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/
        @AuraEnabled public String Moid;

        /**
        * @description 취소 금액
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/
        @AuraEnabled public String CancelAmt;

        /**
        * @description 취소 사유
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/
        @AuraEnabled public String CancelMsg;

        /**
        * @description 부분취소 여부(전체취소 : 0 / 부분취소 : 1)
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/
        @AuraEnabled public String PartialCancelCode;

        /**
        * @description 별도 공급가액 설정 시 사용
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/
        @AuraEnabled public String SupplyAmt;

        /**
        * @description 별도 부가세 설정 시 사용
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/
        @AuraEnabled public String GoodsVat;

        /**
        * @description 별도 봉사료 설정 시 사용
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/
        @AuraEnabled public String ServiceAmt;

        /**
        * @description 별도 면세금액 설정 시 사용
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/
        @AuraEnabled public String TaxFreeAmt;

        /**
        * @description 장바구니 결제 유형 (장바구니 결제: 1 / 그 외:0 )
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/
        @AuraEnabled public String CartType;

        /**
        * @description 환불계좌번호
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/
        @AuraEnabled public String RefundAcctNo;

        /**
        * @description 환불계좌 은행코드
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/
        @AuraEnabled public String RefundBankCd;

        /**
        * @description 환불계좌주명
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/
        @AuraEnabled public String RefundAcctNm;
    }
}