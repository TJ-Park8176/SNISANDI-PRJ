/**
 * @description       : SANDI_NicepayResponse
 *                      response wrap
 * @author            : sungho.jo@mz.co.kr
 * @group             : 
 * @last modified on  : 2024-03-22
 * @last modified by  : sungho.jo@mz.co.kr
**/
public class SANDI_NicepayResponse {
    /**
    * @description Nicepay response 공통
    * @author sungho.jo@mz.co.kr | 2024-03-22
    **/  
    public virtual class NicepayResponse {
        /**
        * @description 결제 결과 코드 (결제수단별 성공코드) 신용카드: 3001, 계좌이체: 4000, 가상계좌: 4100, 휴대폰: A000, SSG은행계좌: 0000
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/
        @AuraEnabled public String ResultCode;

        /**
        * @description 결제 결과 메시지 예시) 카드 결제 성공
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/
        @AuraEnabled public String ResultMsg;

        /**
        * @description 상점 아이디 예시) nicepay00m
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/
        @AuraEnabled public String MID;

        /**
        * @description 상점 주문번호 예시) mnoid1234567890
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/
        @AuraEnabled public String Moid;

        /**
        * @description 위변조 검증 데이터 - 생성규칙 : hex(sha256(TID + MID + Amt + MerchantKey)) - 데이터 유효성 검증을 위해, 가맹점 수준에서 비교하는 로직 구현 필수 *9. 암호화 항목 참조
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/
        @AuraEnabled public String Signature;

        /**
        * @description 거래번호, 거래를 구분하는 transaction ID 예시) nicepay00m03011911140919215275
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/
        @AuraEnabled public String TID;

        /**
        * @description 결제 수단 코드 CARD: 신용카드(SSG페이포함) / BANK: 계좌이체 / VBANK: 가상계좌 / CELLPHONE: 휴대폰결제 /SSG_BANK: SSG 은행계좌 / GIFT_SSG: SSG머니 / GIFT_CULT: 문화상품권
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/
        @AuraEnabled public String PayMethod;

        /**
        * @description 상점 정보 전달용 예비필드 (승인 요청 시 전달한 값 그대로 반환, Nicepay 가공없음)
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/
        @AuraEnabled public String MallReserved;
    }


    /**
    * @description Nicepay 공통 승인 요청 response 값
    * @author sungho.jo@mz.co.kr | 2024-03-22
    **/   
    public virtual class NicepayApprResponse extends NicepayResponse{

        /**
        * @description 거래금액 예시) 000000001004
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/
        @AuraEnabled public String Amt;

        /**
        * @description 구매자 이메일
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/
        @AuraEnabled public String BuyerEmail;

        /**
        * @description 구매자 전화번호
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/
        @AuraEnabled public String BuyerTel;

        /**
        * @description 구매자명
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/
        @AuraEnabled public String BuyerName;

        /**
        * @description 상품명
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/
        @AuraEnabled public String GoodsName;

        /**
        * @description 승인번호 (신용카드, 계좌이체, 휴대폰)
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/
        @AuraEnabled public String AuthCode;

        /**
        * @description 승인날짜 (YYMMDDHHMMSS) 예시) 190419165200
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/
        @AuraEnabled public String AuthDate;

        /**
        * @description 장바구니 데이터
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/
        @AuraEnabled public String CartData;
    }

    /**
    * @description Nicepay 카드 승인 요청 추가 response 값
    * @author sungho.jo@mz.co.kr | 2024-03-22
    **/   
    public class NicepayApprResponseCard extends NicepayApprResponse{
        /**
        * @description 결제 카드사 코드 *11. 파트너사 코드 항목 참조
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/
        @AuraEnabled public String CardCode;

        /**
        * @description 결제 카드사명

        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/
        @AuraEnabled public String CardName;

        /**
        * @description 카드번호
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/
        @AuraEnabled public String CardNo;

        /**
        * @description 할부개월
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/
        @AuraEnabled public String CardQuota;

        /**
        * @description CardInterest 1 상점분담 무이자 적용 여부 (0:일반, 1:무이자)

        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/
        @AuraEnabled public String CardInterest;

        /**
        * @description 매입카드사코드
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/
        @AuraEnabled public String AcquCardCode;

        /**
        * @description 매입카드사명
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/
        @AuraEnabled public String AcquCardName;

        /**
        * @description 카드 구분 (0: 신용, 1: 체크)
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/
        @AuraEnabled public String CardCl;

        /**
        * @description 부분취소 가능 여부 (0: 불가능, 1: 가능)
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/
        @AuraEnabled public String CcPartCl;

        /**
        * @description 간편결제 서비스명
                        6: SKPAY / 8: SAMSUNGPAY (구버전 사용 시) / 15: PAYCO /
                        16: KAKAOPAY / 20: NAVERPAY / 21: SAMSUNGPAY / 22: APPLEPAY
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/
        @AuraEnabled public String ClickpayCl;

        /**
        * @description 쿠폰금액
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/
        @AuraEnabled public String CouponAmt;

        /**
        * @description 쿠폰최소기준금액
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/
        @AuraEnabled public String CouponMinAmt;

        /**
        * @description 포인트승인금액
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/
        @AuraEnabled public String PointAppAmt;

        /**
        * @description (페이코, 카카오 결제 시에만 응답) 복합결제 여부, 1:복합결제 사용, 0:복합결제 미사용
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/
        @AuraEnabled public String MultiCl;

        /**
        * @description (페이코, 카카오 결제 시에만 응답)
                        복합 신용카드 금액, 숫자 형식으로 응답. 예시) 1000 원인 경우 -> 1000
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/
        @AuraEnabled public String MultiCardAcquAmt;

        /**
        * @description (페이코, 카카오 결제 시에만 응답)
                        복합 포인트(카카오머니, 페이코머니) 금액, 숫자 형식으로 응답. 예시) 5000 원인 경우 -> 5000
                        *카카오머니 즉시 할인 시 할인 금액 제외(제외된 할인 금액은 MultiDiscountAmt 로 응답)
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/
        @AuraEnabled public String MultiPointAmt;

        /**
        * @description (카카오머니 결제 시에만 응답, 영업담당자와 사전 협의된 가맹점에 한하여 사용 가능)
                        카카오머니 즉시할인 금액, 숫자 형식으로 응답. 예시) 1000 원인 경우 -> 1000
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/
        @AuraEnabled public String MultiDiscountAmt;

        /**
        * @description (페이코, 카카오 결제 시에만 응답)
                        복합 쿠폰(카카오/페이코 포인트) 금액, 숫자 형식으로 응답. 예시) 5000원인 경우 -> 5000
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/
        @AuraEnabled public String MultiCouponAmt;

        /**
        * @description (네이버페이-포인트 결제 시에만 응답) 현금영수증 타입,
                        예시) 1:소득공제, 2:지출증빙, 그외: 발행안함
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/
        @AuraEnabled public String RcptType;

        /**
        * @description (네이버페이-포인트 결제 시에만 응답) 현금영수증 TID, 현금영수증 거래인 경우 필수
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/
        @AuraEnabled public String RcptTID;

        /**
        * @description (네이버페이-포인트 결제 시에만 응답) 현금영수증 승인번호, 현금영수증 거래인 경우 필수
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/
        @AuraEnabled public String RcptAuthCode;

        /**
        * @description 카드형태 (01: 개인, 02: 법인, 03: 해외)
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/
        @AuraEnabled public String CardType;
    }

    /**
    * @description Nicepay 계좌이체 승인 요청 추가 response 값
    * @author sungho.jo@mz.co.kr | 2024-03-22
    **/   
    public class NicepayApprResponseBank extends NicepayApprResponse{
        /**
        * @description 결제은행 코드 *11. 파트너사 코드 항목 참조
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/   
        @AuraEnabled public String  BankCode;

        /**
        * @description 결제은행 명
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/   
        @AuraEnabled public String  BankName;

        /**
        * @description 현금영수증 타입 (0:발행안함, 1:소득공제, 2:지출증빙)
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/   
        @AuraEnabled public String  RcptType;

        /**
        * @description 현금영수증 TID
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/   
        @AuraEnabled public String  RcptTID;

        /**
        * @description 현금영수증 승인번호
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/   
        @AuraEnabled public String  RcptAuthCode;
    }


    /**
    * @description Nicepay 가상계좌 승인 요청 추가 response 값
    * @author sungho.jo@mz.co.kr | 2024-03-22
    **/   
    public class NicepayApprResponseVBank extends NicepayApprResponse{
        /**
        * @description Nicepay 결제은행 코드 *11. 파트너사 코드 항목 참조
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/   
        @AuraEnabled public String VbankBankCode;

        /**
        * @description 결제은행명 예시) SC제일은행
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/   
        @AuraEnabled public String VbankBankName;

        /**
        * @description 가상계좌 번호 
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/   
        @AuraEnabled public String VbankNum;

        /**
        * @description 가상계좌 입금 만료일(yyyyMMdd) 예시) 20190101
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/   
        @AuraEnabled public String VbankExpDate;
        
        /**
        * @description 가상계좌 입금 만료시간(HHmmss) 예시) 235959
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/   
        @AuraEnabled public String VbankExpTime;
    }

    /**
    * @description 취소 응답 response 공통
    * @author sungho.jo@mz.co.kr | 2024-03-22
    **/  
    public class NicepayCancelResponse extends NicepayResponse{
        /**
        * @description 에러코드
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/
        @AuraEnabled public String ErrorCD;

        /**
        * @description 에러메시지
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/
        @AuraEnabled public String ErrorMsg;

        /**
        * @description 금액
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/
        @AuraEnabled public String CancelAmt;

        /**
        * @description 취소일자, YYYYMMDD
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/
        @AuraEnabled public String CancelDate;

        /**
        * @description 취소시간, HHmmss
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/
        @AuraEnabled public String CancelTime;

        /**
        * @description 취소번호
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/
        @AuraEnabled public String CancelNum;

        /**
        * @description 취소 후 잔액, 예시) 잔액이 1000원인 경우 -> 000000001000
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/
        @AuraEnabled public String RemainAmt;

        /**
        * @description 휴대폰 부분취소/부분환불일 경우 응답됨. 2회차 이상의 휴대폰 부분취소/부분환불 요청 시, 응답전문 내 OTID 로 취소요청 되어야 함.
                        *승인요청 취소에만 있음.
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/
        @AuraEnabled public String OTID;
    }

    /**
    * @description 취소 응답 카드 추가 response
    * @author sungho.jo@mz.co.kr | 2024-03-22
    **/  
    public class NicepayCardCancelResponse extends NicepayResponse{
        /**
        * @description 쿠폰금액, 예시) 1000원인 경우 -> 000000001000
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/
        @AuraEnabled public String CouponAmt;

        /**
        * @description 간편결제 서비스명
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/
        @AuraEnabled public String ClickpayCl;

        /**
        * @description (페이코, 카카오 결제 시에만 응답) 간편결제 복합 신용카드 금액
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/
        @AuraEnabled public String MultiCardAcquAmt;

        /**
        * @description (페이코, 카카오 결제 시에만 응답) 간편결제 복합 포인트 금액
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/
        @AuraEnabled public String MultiPointAmt;

        /**
        * @description (페이코, 카카오 결제 시에만 응답) 간편결제 복합 쿠폰 금액
        * @author sungho.jo@mz.co.kr | 2024-03-22
        **/
        @AuraEnabled public String MultiCouponAmt;
    }
}