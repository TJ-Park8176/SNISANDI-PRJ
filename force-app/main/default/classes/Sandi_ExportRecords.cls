/**
 * @description       : 
 * @author            : jisoolee@mz.co.kr
 * @group             : 
 * @last modified on  : 2024-03-05
 * @last modified by  : jisoolee@mz.co.kr
**/

public class Sandi_ExportRecords { 
    @AuraEnabled(cacheable=true)
    public static List<Account> ExportCSV(){
        String guId = generateGuid();
        
        // get Query Data
        List<Account > acclist = [SELECT Id, Name, CreatedDate, LastModifiedDate 
                                  FROM Account];
        return acclist;
        // String header = 'Record Id, Name , Created Date, Modified Date \n';
        // String data = header;
        // for(Account a : acclist){
        //     data += a.id + ',' + a.Name + ',' + a.CreatedDate + ',' + a.LastModifiedDate +'\n';
        // }
        // System.debug('data: '+data);
        
        // Document o = new Document(
        //     FolderId = UserInfo.getUserId(),
        //     Name = 'Account'+guId+'.csv',
        //     Body = Blob.valueOf(data)
        // );
        // insert o;
        // system.debug('o.Id: '+o.Id);
        // return '/servlet/servlet.FileDownload?file=' + o.Id;
    }     

    public static String generateGuid() {
        Datetime now = Datetime.now();
        String strDate = now.format('YYYYMMdd', 'Asia/Seoul');
        String strTime = now.format('HHmmssSSS', 'Asia/Seoul');

        Integer randomNum = (Math.random() * 10000).intValue();
        String randomStr = String.valueOf(randomNum).leftPad(4, '0');

        return strDate + strTime + randomStr;
    }
}