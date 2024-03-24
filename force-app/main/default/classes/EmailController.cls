/**
 * Created by MZC01-DGCHOI on 2023-01-10.
 */

public with sharing class EmailController {
    public static void sendEmail(String title, String body) {
        String currentUserId = UserInfo.getUserId();
        User currentUser = [SELECT Email, Name
                            FROM User
                            WHERE Id =: currentUserId limit 1];

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage(); //단일 이메일 메시지 객체를 인스턴스화
        String[] toAddresses = new String[] {currentUser.Email}; //수신 주소를 저장할 문자열
        mail.setToAddresses(toAddresses); //메일 객체에 TO 주소 할당
        //String[] ccAddresses = new String[] {'cdg9808@naver.com'}; //List of ccAddress
        //mail.setCcAddresses(ccAddresses); //참조 주소 할당
        mail.setReplyTo('dgchoi@mz.co.kr'); //수신자가 답장할 주소 //임시....
        mail.setSenderDisplayName(currentUser.Name); //display Name 으로 사용할 이름을 지정
        mail.setSubject(title); //이메일 제목
        mail.setBccSender(false); //자신을 숨은 참조로 하려면 true
        mail.setHtmlBody(body); //HTML Body //setPlainTextBody
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail }); //이메일 전송
    }
}