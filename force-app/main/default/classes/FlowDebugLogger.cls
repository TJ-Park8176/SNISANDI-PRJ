/**
 * @description       : 
 * @author            : jisoolee@mz.co.kr
 * @group             : 
 * @last modified on  : 2024-03-22
 * @last modified by  : jisoolee@mz.co.kr
**/

public with sharing class FlowDebugLogger {
    @InvocableMethod(label='Log Debug Message' description='Outputs messages to the debug log')
    public static void trace(List<String> debugMessages) {
        for (String debugMessage : debugMessages) {
            system.debug(logginglevel.error, debugMessage);
        }
    }
}